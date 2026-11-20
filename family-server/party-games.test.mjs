import assert from 'node:assert/strict';
import test from 'node:test';
import { applyAction, view } from './game.mjs';
import { familyServer } from './server.mjs';

test('eight concurrent role joins get separate seats and private HTTP projections', async (t) => {
  const server = familyServer();
  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  t.after(() => new Promise((resolve) => server.close(resolve)));
  const base = 'http://127.0.0.1:' + server.address().port + '/api/family/rooms';
  async function request(path, body, token) {
    const response = await fetch(base + path, {method:body?'POST':'GET',
      headers:{...(body && {'content-type':'application/json'}), ...(token && {Authorization:'Bearer '+token})},
      body:body?JSON.stringify(body):undefined});
    return {status:response.status, data:await response.json()};
  }
  const host = (await request('',{game:'roles'})).data;
  const path = '/'+host.code;
  const joined = await Promise.all(Array.from({length:8},(_,id)=>request(path+'/join',{name:'Oyuncu '+id})));
  assert.ok(joined.every((reply)=>reply.status===201));
  assert.equal(new Set(joined.map((reply)=>reply.data.token)).size,8);
  assert.equal((await request(path+'/join',{name:'Dokuzuncu'})).status,409);
  assert.equal((await request(path+'/action',{type:'start',revision:8},host.token)).status,200);
  const publicRoom=(await request(path)).data;
  assert.equal(publicRoom.private,undefined);
  const projections=await Promise.all(joined.map((reply)=>request(path,null,reply.data.token)));
  assert.equal(new Set(projections.map((reply)=>reply.data.seat)).size,8);
  for(const {data} of projections) {
    assert.ok(data.private.role);
    assert.ok(data.players.every((player)=>!('role' in player) && !('token' in player)));
    assert.equal(data.nightActions,undefined);
  }
  assert.equal((await request(path+'/action',{type:'nightChoice',target:null,revision:8},joined[0].data.token)).status,409);
});

function started(game, count = game === 'words' ? 2 : 6) {
  const room = {game, status:'lobby', revision:0,
    players:Array.from({length:count},(_,id)=>({name:'Oyuncu '+id, token:'secret-'+id}))};
  applyAction(room,-1,{type:'start'},(max)=>max-1);
  return room;
}

test('each word player receives exactly seven letters, TV and spectators receive none',()=>{
  const room=started('words');
  assert.equal(room.players[0].hand.length,7);
  assert.equal(view(room,-1).private,undefined);
  assert.equal(view(room,-2).private,undefined);
  assert.deepEqual(view(room,1).private.hand,room.players[1].hand);
  assert.ok(!JSON.stringify(view(room,1)).includes('secret-0'));
});

test('word placement is atomic, connects at the center and consumes only newly placed letters',()=>{
  const room=started('words');
  room.players[0].hand=['E','L','M','A','K','İ','R'];
  const before=structuredClone(room);
  assert.throws(()=>applyAction(room,0,{type:'placeWord',word:'ELMA',row:0,col:0,vertical:false}),/yıldız/);
  assert.deepEqual(room,before);
  assert.throws(()=>applyAction(room,1,{type:'placeWord',word:'ELMA',row:5,col:5,vertical:false}),/Sıra/);
  applyAction(room,0,{type:'placeWord',word:'ELMA',row:5,col:5,vertical:false});
  assert.equal(room.board.slice(60,64).join(''),'ELMA');
  assert.equal(room.players[0].score,8);
  assert.equal(room.players[0].hand.length,7);
  assert.equal(room.turn,1);
  room.players[1].hand=['A','L','İ','K','R','N','E'];
  applyAction(room,1,{type:'placeWord',word:'AL',row:4,col:6,vertical:true});
  assert.equal(room.board[50],'A');
  assert.equal(room.board[61],'L');
  assert.equal(room.turn,0);
});

test('unrecognised words, missing letters, outside boards and invalid crosswords change nothing',()=>{
  const room=started('words'); room.players[0].hand=['E','L','M','A','K','İ','R'];
  for (const action of [
    {word:'XYZ',row:5,col:5}, {word:'ELMA',row:10,col:10},
    {word:'KÖPEK',row:5,col:5}, {word:'ELMA',row:-1,col:5},
  ]) {
    const before=structuredClone(room);
    assert.throws(()=>applyAction(room,0,{type:'placeWord',vertical:false,...action}));
    assert.deepEqual(room,before);
  }
});

test('two full rounds of passes finish in a shared win, host can rematch with fresh letters',()=>{
  const room=started('words');
  for(let i=0;i<4;i++) applyAction(room,room.turn,{type:'passWord'});
  assert.equal(room.status,'finished'); assert.deepEqual(room.winners,[0,1]);
  assert.throws(()=>applyAction(room,0,{type:'rematch'}));
  applyAction(room,-1,{type:'rematch'},(max)=>max-1);
  assert.equal(room.status,'playing'); assert.equal(room.players[0].score,0);
  assert.equal(room.winners,undefined);
});

test('role distribution and private projections hide identities and targets until the result',()=>{
  const room=started('roles');
  assert.deepEqual(room.players.map((p)=>p.role),['seer','guardian','enemy','villager','villager','villager']);
  applyAction(room,0,{type:'nightChoice',target:2});
  const publicView=view(room,-1);
  assert.equal(publicView.private,undefined);
  assert.equal(publicView.nightActions,undefined);
  assert.equal(publicView.revealedRoles,undefined);
  assert.equal(publicView.players[0].role,undefined);
  assert.equal(publicView.submitted,1);
  const player=view(room,3);
  assert.equal(player.private.role,'villager');
  assert.equal(player.private.investigations.length,0);
  assert.throws(()=>applyAction(room,0,{type:'nightChoice',target:1}));
});

test('guardian saves, seer gets a private result, votes stay hidden until all living players vote',()=>{
  const room=started('roles');
  for(const [seat,target] of [[0,2],[1,3],[2,3],[3,null],[4,null],[5,null]])
    applyAction(room,seat,{type:'nightChoice',target});
  assert.equal(room.phase,'discussion'); assert.equal(room.players[3].out,false);
  assert.deepEqual(view(room,0).private.investigations,[{day:1,target:2,enemy:true}]);
  assert.equal(view(room,1).private.investigations.length,0);
  assert.throws(()=>applyAction(room,0,{type:'openVote'}));
  applyAction(room,-1,{type:'openVote'});
  applyAction(room,0,{type:'roleVote',target:2});
  assert.equal(view(room,-1).lastVotes.length,0);
  assert.equal(view(room,-1).votes,undefined);
  for(const seat of [1,2,3,4,5]) applyAction(room,seat,{type:'roleVote',target:seat===2?null:2});
  assert.equal(room.status,'finished'); assert.equal(room.teamWinner,'village');
  assert.equal(view(room,-1).revealedRoles[2],'enemy');
  assert.deepEqual(room.winners,[0,1,3,4,5]);
});

test('eliminated players cannot act; tied daytime votes keep the game running',()=>{
  const room=started('roles');
  for(const [seat,target] of [[0,2],[1,1],[2,3],[3,null],[4,null],[5,null]])
    applyAction(room,seat,{type:'nightChoice',target});
  assert.equal(room.players[3].out,true);
  applyAction(room,-1,{type:'openVote'});
  assert.throws(()=>applyAction(room,3,{type:'roleVote',target:2}));
  for(const seat of [0,1,2,4,5]) applyAction(room,seat,{type:'roleVote',target:null});
  assert.equal(room.status,'playing'); assert.equal(room.phase,'dusk');
  applyAction(room,-1,{type:'nextNight'});
  assert.equal(room.round,2); assert.equal(room.phase,'night');
  assert.equal(view(room,2).private.submitted,false);
});

test('seven and eight players have two allied saboteurs with a team victory at parity',()=>{
  const room=started('roles',8);
  const enemies=room.players.flatMap((p,id)=>p.role==='enemy'?[id]:[]);
  assert.equal(enemies.length,2);
  assert.deepEqual(view(room,enemies[0]).private.allies,enemies);
  assert.throws(()=>applyAction(room,enemies[0],{type:'nightChoice',target:enemies[1]}));
  for(const seat of [0,1,3,4]) room.players[seat].out=true;
  for(const seat of [2,5,6,7]) applyAction(room,seat,{type:'nightChoice',target:room.players[seat].role==='enemy'?5:null});
  assert.equal(room.status,'finished'); assert.equal(room.teamWinner,'enemy');
  assert.deepEqual(room.winners,enemies);
});
