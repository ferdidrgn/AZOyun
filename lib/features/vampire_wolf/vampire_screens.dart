import 'dart:async';
import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../../core/services/ad_service.dart';
import '../../core/services/room_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/az_theme.dart';
import '../../core/widgets/az_widgets.dart';
import '../../core/widgets/banner_ad_widget.dart';

class VampireLobbyScreen extends StatefulWidget {
  const VampireLobbyScreen({super.key});
  @override State<VampireLobbyScreen> createState() => _VLS();
}
class _VLS extends State<VampireLobbyScreen> {
  final _rooms=RoomService.instance; final _storage=StorageService.instance;
  final _codeCtrl=TextEditingController();
  String? _name; bool _loading=false;
  @override void initState(){super.initState();_load();}
  @override void dispose(){_codeCtrl.dispose();super.dispose();}
  Future<void> _load() async {
    final n=await _storage.getPlayerName(); if(!mounted)return;
    if(n!=null&&n.isNotEmpty)setState(()=>_name=n); else _ask();
  }
  Future<void> _ask() async {
    final n=await showNameDialog(context,current:_name,accentColor:Colors.deepPurple);
    if(n==null||!mounted)return; await _storage.setPlayerName(n); setState(()=>_name=n);
  }
  Future<void> _create() async {
    if(_name==null){await _ask(); if(_name==null)return;}
    setState(()=>_loading=true);
    try {
      final code=_rooms.generateCode();
      final id=await _rooms.createRoom(gamePath:GamePaths.vampire,data:{
        'code':code,'status':'waiting','createdAt':ServerValue.timestamp,'phase':'lobby',
        'players':{'p1':{'name':_name,'isHost':true,'role':null,'alive':true,'vote':''}},
      });
      if(!mounted)return;
      Navigator.push(context,MaterialPageRoute(builder:(final _)=>VampireRoomScreen(roomId:id,myKey:'p1',myName:_name!)));
    } catch(e){_snack('Hata: $e');}
    finally{if(mounted)setState(()=>_loading=false);}
  }
  Future<void> _join() async {
    if(_name==null){await _ask(); if(_name==null)return;}
    final code=_codeCtrl.text.trim().toUpperCase();
    if(code.length!=6){_snack('6 haneli kodu girin');return;}
    setState(()=>_loading=true);
    try {
      final r=await _rooms.findByCode(gamePath:GamePaths.vampire,code:code);
      if(r==null){_snack('Oda bulunamadı');return;}
      if(r.data['status']!='waiting'){_snack('Oyun başlamış');return;}
      final players=Map.from((r.data['players'] as Map?)??{});
      if(players.length>=8){_snack('Oda dolu');return;}
      final myKey='p${players.length+1}';
      await _rooms.updateRoom(gamePath:GamePaths.vampire,roomId:r.id,
          updates:{'players/$myKey':{'name':_name,'isHost':false,'role':null,'alive':true,'vote':''}});
      if(!mounted)return;
      Navigator.push(context,MaterialPageRoute(builder:(final _)=>VampireRoomScreen(roomId:r.id,myKey:myKey,myName:_name!)));
    } catch(e){_snack('Katılınamadı: $e');}
    finally{if(mounted)setState(()=>_loading=false);}
  }
  void _snack(final String m)=>ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(m)));
  @override
  Widget build(final BuildContext context) => AZGradientScaffold(
    gradient: AZColors.gradDark,
    child: Column(children:[
      Expanded(child:SingleChildScrollView(padding:const EdgeInsets.all(24),child:Column(children:[
        Align(alignment:Alignment.centerLeft,
            child:IconButton(icon:const Icon(Icons.arrow_back,color:Colors.white),onPressed:()=>Navigator.pop(context))),
        const Text('🧛',style:TextStyle(fontSize:72)),
        const Text('VAMPİR KÖYLÜ',style:TextStyle(color:Colors.white,fontSize:26,fontWeight:FontWeight.bold,letterSpacing:2)),
        const Text('4-8 Oyuncu · Rol bazlı · Mafia tarzı',style:TextStyle(color:Colors.white70,fontSize:13)),
        const SizedBox(height:24),
        GestureDetector(onTap:_ask,child:AZFrostCard(
          padding:const EdgeInsets.symmetric(horizontal:20,vertical:12),
          child:Row(mainAxisSize:MainAxisSize.min,children:[
            const Icon(Icons.person_rounded,color:Colors.white,size:20),const SizedBox(width:8),
            Text(_name??'Ad seç',style:const TextStyle(color:Colors.white,fontSize:16,fontWeight:FontWeight.bold)),
          ]),
        )),
        const SizedBox(height:24),
        AZButton(label:'YENİ ODA',icon:Icons.add_circle_outline_rounded,
            onPressed:_create,color:Colors.deepPurple,loading:_loading,width:280),
        const SizedBox(height:20),
        const Text('— veya —',style:TextStyle(color:Colors.white54)),
        const SizedBox(height:20),
        AZFrostCard(child:Column(children:[
          AZCodeField(controller:_codeCtrl),const SizedBox(height:14),
          AZJoinButton(onPressed:_join,loading:_loading),
        ])),
        const SizedBox(height:24),
        AZFrostCard(opacity:0.08,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:const[
          Text('🧛 Nasıl oynanır?',style:TextStyle(color:Colors.white,fontWeight:FontWeight.bold,fontSize:14)),
          SizedBox(height:8),
          Text('• 4-8 oyuncu\n• 🌙 Gece: Vampirler kurban seçer\n• ☀️ Gündüz: Herkes vampir sandığını oylar\n• Vampir kalmayınca Köylüler kazanır',
              style:TextStyle(color:Colors.white70,fontSize:13,height:1.6)),
        ])),
      ]))),
      const AdaptiveBannerAdWidget(),
    ]),
  );
}

class VampireRoomScreen extends StatefulWidget {
  const VampireRoomScreen({super.key,required this.roomId,required this.myKey,required this.myName});
  final String roomId,myKey,myName;
  @override State<VampireRoomScreen> createState()=>_VRS();
}
class _VRS extends State<VampireRoomScreen> {
  final _rooms=RoomService.instance; StreamSubscription? _sub;
  Map<String,dynamic> _room={}; bool _nav=false;
  @override void initState(){super.initState();
  _sub=_rooms.watchRoom(gamePath:GamePaths.vampire,roomId:widget.roomId).listen(_onData);}
  @override void dispose(){_sub?.cancel();super.dispose();}
  void _onData(final Map<String,dynamic>? d){
    if(!mounted||d==null)return; setState(()=>_room=d);
    final players=(d['players'] as Map?)??{};
    if(players.isEmpty){_rooms.deleteRoom(gamePath:GamePaths.vampire,roomId:widget.roomId);if(mounted)Navigator.pop(context);return;}
    if(d['status']=='playing'&&!_nav){_nav=true;
    Navigator.pushReplacement(context,MaterialPageRoute(builder:(final _)=>VampireGameScreen(roomId:widget.roomId,myKey:widget.myKey,myName:widget.myName)));}
  }
  Map get _players=>(_room['players'] as Map?)??{};
  String get _code=>_room['code']??'------';
  bool get _isHost=>widget.myKey=='p1';
  bool get _canStart=>_players.length>=4;
  Future<void> _start() async {
    if(!_canStart){_snack('En az 4 oyuncu');return;}
    final keys=_players.keys.toList()..shuffle(Random.secure());
    final vc=max(1,(keys.length/4).floor());
    final updates=<String,dynamic>{'status':'playing','phase':'night','day':1,'nightVictim':null,'lastEliminated':null};
    for(var i=0;i<keys.length;i++){
      updates['players/${keys[i]}/role']=i<vc?'vampire':'villager';
      updates['players/${keys[i]}/vote']='';
      updates['players/${keys[i]}/alive']=true;
    }
    await _rooms.updateRoom(gamePath:GamePaths.vampire,roomId:widget.roomId,updates:updates);
  }
  Future<void> _leave() async {
    final pl=Map.from(_players)..remove(widget.myKey);
    if(pl.isEmpty||_isHost) await _rooms.deleteRoom(gamePath:GamePaths.vampire,roomId:widget.roomId);
    else await _rooms.removePlayer(gamePath:GamePaths.vampire,roomId:widget.roomId,playerKey:widget.myKey);
    if(mounted)Navigator.pop(context);
  }
  void _snack(final String m)=>ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(m)));
  @override
  Widget build(final BuildContext context)=>PopScope(canPop:false,onPopInvoked:(final _)=>_leave(),
      child:AZGradientScaffold(gradient:AZColors.gradDark,
          child:Padding(padding:const EdgeInsets.all(20),child:Column(children:[
            Row(children:[
              IconButton(icon:const Icon(Icons.close,color:Colors.white),onPressed:_leave),
              const Expanded(child:Text('VAMPİR KÖYLÜ',textAlign:TextAlign.center,
                  style:TextStyle(color:Colors.white,fontSize:18,fontWeight:FontWeight.bold))),
              const SizedBox(width:48),
            ]),
            const SizedBox(height:20),
            AZRoomCode(code:_code,accentColor:Colors.deepPurpleAccent),
            const SizedBox(height:20),
            AZFrostCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Text('Oyuncular (${_players.length}/8)',
                  style:const TextStyle(color:Colors.white,fontWeight:FontWeight.bold,fontSize:15)),
              const SizedBox(height:14),
              for(final e in _players.entries)
                AZPlayerTile(name:e.value['name'] as String??e.key,isMe:e.key==widget.myKey,
                    isHost:e.value['isHost']==true,emoji:'🧛',present:true),
              if(!_canStart) Text('En az ${4-_players.length} oyuncu daha',
                  style:const TextStyle(color:Colors.white54,fontSize:13)),
            ])),
            const Spacer(),
            if(_isHost) AZButton(label:'OYUNU BAŞLAT',icon:Icons.play_arrow_rounded,
                onPressed:_canStart?_start:null,color:Colors.deepPurple,width:double.infinity)
            else const AZWaitingCard(message:'Host oyunu başlatacak...'),
          ]))));
}

// ═══════════════════════════════════════════════════════════
// GAME — BUG FIX: _processing lock, host-only resolution
// ═══════════════════════════════════════════════════════════
class VampireGameScreen extends StatefulWidget {
  const VampireGameScreen({super.key,required this.roomId,required this.myKey,required this.myName});
  final String roomId,myKey,myName;
  @override State<VampireGameScreen> createState()=>_VGS();
}
class _VGS extends State<VampireGameScreen> {
  final _db=FirebaseDatabase.instance.ref();
  late DatabaseReference _ref; StreamSubscription? _sub;
  Map<String,dynamic> _room={}; bool _finalShown=false,_processing=false;
  @override void initState(){super.initState();
  _ref=_db.child('${GamePaths.vampire}/${widget.roomId}');
  _sub=_ref.onValue.listen(_onFB);}
  @override void dispose(){_sub?.cancel();super.dispose();}

  void _onFB(final DatabaseEvent e){
    if(!mounted||e.snapshot.value==null)return;
    final d=Map<String,dynamic>.from(e.snapshot.value as Map);
    setState(()=>_room=d);
    if(d['status']=='finished'&&!_finalShown){
      _finalShown=true; AdService.instance.onGameEnd();
      Future.delayed(const Duration(milliseconds:300),_showFinal);}
    // BUG FIX: Sadece p1 (host) oy kontrolü yapar
    if(!_processing&&widget.myKey=='p1'&&d['status']=='playing'){
      _checkVotes(d);}
  }

  Future<void> _checkVotes(final Map<String,dynamic> d) async {
    if(_processing)return;
    final phase=d['phase'] as String??'night';
    if(phase=='dawn'||phase=='dusk')return; // geçiş aşamaları, bekle
    final players=Map<String,dynamic>.from((d['players'] as Map?)??{});
    final alive=players.entries.where((final e)=>e.value['alive'] as bool?==true).toList();
    final voters=phase=='night'
        ? alive.where((final e)=>(e.value['role'] as String?)=='vampire').toList()
        : alive;
    if(voters.isEmpty)return;
    final allVoted=voters.every((final e)=>((e.value['vote'] as String?)?? '').isNotEmpty);
    if(!allVoted)return;
    setState(()=>_processing=true);
    try {
      final votes=<String,int>{};
      for(final v in voters){final g=v.value['vote'] as String??'';if(g.isNotEmpty)votes[g]=(votes[g]??0)+1;}
      String? elim; int mx=0; votes.forEach((final k,final v){if(v>mx){mx=v;elim=k;}});
      final upd=<String,dynamic>{};
      for(final p in alive) upd['players/${p.key}/vote']='';
      if(phase=='night'){
        // Gece: kurbanı sakla, şafağa geç
        upd['nightVictim']=elim; upd['phase']='dawn';
        await _ref.update(upd);
        await Future.delayed(const Duration(seconds:3));
        final finalUpd=<String,dynamic>{'phase':'day','nightVictim':null};
        if(elim!=null){finalUpd['players/$elim/alive']=false;finalUpd['lastEliminated']=elim;}
        await _ref.update(finalUpd);
        await _checkWin();
      } else {
        // Gündüz: elim, akşama geç, sonra geceye
        if(elim!=null){upd['players/$elim/alive']=false;upd['lastEliminated']=elim;}
        upd['phase']='dusk'; upd['day']=(d['day'] as int??1)+1;
        await _ref.update(upd);
        await _checkWin();
        await Future.delayed(const Duration(seconds:3));
        final statusSnap=await _ref.child('status').get();
        if((statusSnap.value as String?)!='finished'){
          await _ref.update({'phase':'night','lastEliminated':null});}
      }
    } finally { if(mounted)setState(()=>_processing=false); }
  }

  Future<void> _checkWin() async {
    final snap=await _ref.child('players').get(); if(!snap.exists)return;
    final players=Map<String,dynamic>.from(snap.value as Map);
    final alive=players.entries.where((final e)=>e.value['alive'] as bool?==true);
    final vamps=alive.where((final e)=>(e.value['role'] as String?)=='vampire').length;
    final villagers=alive.where((final e)=>(e.value['role'] as String?)=='villager').length;
    if(vamps==0) await _ref.update({'status':'finished','winner':'villagers'});
    else if(vamps>=villagers) await _ref.update({'status':'finished','winner':'vampires'});
  }

  Map get _players=>(_room['players'] as Map?)??{};
  String get _phase=>(_room['phase'] as String?)?? 'night';
  int get _day=>(_room['day'] as int?)?? 1;
  bool get _isNight=>_phase=='night';
  bool get _isAlive=>(_players[widget.myKey]?['alive'] as bool?)?? true;
  String get _myRole=>(_players[widget.myKey]?['role'] as String?)?? 'villager';
  bool get _isVampire=>_myRole=='vampire';
  String get _myVote=>(_players[widget.myKey]?['vote'] as String?)?? '';
  bool get _hasVoted=>_myVote.isNotEmpty;
  String? get _lastElim=>_room['lastEliminated'] as String?;
  String? get _nightVictim=>_room['nightVictim'] as String?;

  List<MapEntry<String,dynamic>> get _targets => _players.entries
      .where((final e)=>e.key!=widget.myKey&&(e.value['alive'] as bool?)==true&&
      (_isNight?(e.value['role'] as String?)!='vampire':true))
      .toList();

  int get _votedCount {
    final alive=_players.entries.where((final e)=>(e.value['alive'] as bool?)==true);
    final voters=_isNight? alive.where((final e)=>(e.value['role'] as String?)=='vampire'):alive;
    return voters.where((final e)=>((e.value['vote'] as String?)?? '').isNotEmpty).length;
  }
  int get _voterCount {
    final alive=_players.entries.where((final e)=>(e.value['alive'] as bool?)==true);
    final voters=_isNight? alive.where((final e)=>(e.value['role'] as String?)=='vampire'):alive;
    return voters.length;
  }

  Future<void> _vote(final String key) async {
    if(_hasVoted||!_isAlive)return;
    if(_isNight&&!_isVampire)return;
    await _ref.update({'players/${widget.myKey}/vote':key});
  }

  void _showFinal(){
    if(!mounted)return;
    final winner=(_room['winner'] as String?)?? 'villagers';
    final iWon=winner=='vampires'?_isVampire:!_isVampire;
    showDialog(context:context,barrierDismissible:false,builder:(final _)=>AlertDialog(
      title:Text(winner=='vampires'?'🧛 Vampirler Kazandı!':'🎉 Köylüler Kazandı!',textAlign:TextAlign.center),
      content:Column(mainAxisSize:MainAxisSize.min,children:[
        Text(iWon?'🏆 Kazandın!':'😔 Kaybettin',textAlign:TextAlign.center,
            style:const TextStyle(fontSize:22,fontWeight:FontWeight.bold)),
        const SizedBox(height:12),const Divider(),
        const Text('Roller:',style:TextStyle(fontWeight:FontWeight.bold)),
        ..._players.entries.map((final e)=>Padding(padding:const EdgeInsets.symmetric(vertical:3),
            child:Row(mainAxisAlignment:MainAxisAlignment.center,children:[
              Text((e.value['role'] as String?)=='vampire'?'🧛':'👨‍🌾'),const SizedBox(width:8),
              Text(e.value['name'] as String??e.key),
              if(e.value['alive']!=true) const Text(' ☠️'),
            ]))),
      ]),
      actions:[FilledButton(
          style:FilledButton.styleFrom(backgroundColor:Colors.deepPurple),
          onPressed:() async {
            await _db.child('${GamePaths.vampire}/${widget.roomId}').remove(); // oda silinir
            if(mounted)Navigator.popUntil(context,(final r)=>r.isFirst);},
          child:const Text('Ana Menü'))],
    ));
  }

  @override
  Widget build(final BuildContext context){
    if(_room.isEmpty) return const Scaffold(backgroundColor:Color(0xFF1A1A2E),
        body:Center(child:CircularProgressIndicator(color:Colors.purple)));
    final isTransition=_phase=='dawn'||_phase=='dusk';
    return Scaffold(
      backgroundColor:_isNight? const Color(0xFF0D0D1F):const Color(0xFFFFF9C4),
      body:SafeArea(child:Column(children:[
        // Phase banner
        Container(width:double.infinity,
          decoration:BoxDecoration(gradient:LinearGradient(colors:_isNight||isTransition
              ? [Colors.deepPurple.shade900,Colors.indigo.shade900]
              : [Colors.orange.shade700,Colors.yellow.shade600])),
          padding:const EdgeInsets.symmetric(vertical:14),
          child:Row(mainAxisAlignment:MainAxisAlignment.center,children:[
            Text(_isNight?'🌙':isTransition?'🌅':'☀️',style:const TextStyle(fontSize:22)),
            const SizedBox(width:10),
            Text('${_isNight?"GECE":isTransition?"GEÇIŞ":"GÜNDÜZ"}${_day>1?" — Gün $_day":""}',
                style:const TextStyle(color:Colors.white,fontSize:17,fontWeight:FontWeight.bold)),
          ]),
        ),
        // Rol bilgisi
        Container(margin:const EdgeInsets.all(12),
          padding:const EdgeInsets.symmetric(horizontal:16,vertical:10),
          decoration:BoxDecoration(
              gradient:LinearGradient(colors:_isVampire
                  ? [Colors.red.shade900,Colors.purple.shade900]
                  : [Colors.green.shade800,Colors.teal.shade800]),
              borderRadius:BorderRadius.circular(14)),
          child:Row(children:[
            Text(_isVampire?'🧛':'👨‍🌾',style:const TextStyle(fontSize:28)),
            const SizedBox(width:10),
            Expanded(child:Text(_isVampire?'SEN BİR VAMPİRSİN':'SEN BİR KÖYLÜSÜN',
                style:const TextStyle(color:Colors.white,fontWeight:FontWeight.bold,fontSize:15))),
          ]),
        ),
        // Son eliminasyon
        if(_lastElim!=null&&_lastElim!.isNotEmpty&&!_isNight)
          Container(margin:const EdgeInsets.symmetric(horizontal:12,vertical:4),
              padding:const EdgeInsets.symmetric(horizontal:12,vertical:8),
              decoration:BoxDecoration(color:Colors.red.shade900.withAlpha(180),
                  borderRadius:BorderRadius.circular(10),
                  border:Border.all(color:Colors.red.shade400)),
              child:Row(children:[
                const Text('☠️',style:TextStyle(fontSize:18)),const SizedBox(width:8),
                Text('${_players[_lastElim]?['name']??_lastElim} elendi! '
                    '(${(_players[_lastElim]?['role'] as String?)=="vampire"?"🧛 Vampir":"👨‍🌾 Köylü"})',
                    style:const TextStyle(color:Colors.white,fontWeight:FontWeight.bold)),
              ])),
        // _processing göstergesi
        if(_processing)
          Container(color:Colors.black54,padding:const EdgeInsets.all(8),
              child:const Row(mainAxisAlignment:MainAxisAlignment.center,children:[
                SizedBox(width:14,height:14,child:CircularProgressIndicator(color:Colors.white,strokeWidth:2)),
                SizedBox(width:8),Text('Sonuç hesaplanıyor...',style:TextStyle(color:Colors.white,fontSize:12)),
              ])),
        // Ana içerik
        Expanded(child:Builder(builder:(final _){
          // Elenmiş
          if(!_isAlive) return Center(child:AZFrostCard(child:const Column(mainAxisSize:MainAxisSize.min,children:[
            Text('☠️',style:TextStyle(fontSize:48)),SizedBox(height:8),
            Text('Elendin',style:TextStyle(color:Colors.white,fontSize:18,fontWeight:FontWeight.bold)),
            Text('Oyunu izlemeye devam et',style:TextStyle(color:Colors.white60,fontSize:13)),
          ])));
          // Geçiş
          if(isTransition) return Center(child:AZFrostCard(child:Column(mainAxisSize:MainAxisSize.min,children:[
            Text(_phase=='dawn'?'🌅':'🌆',style:const TextStyle(fontSize:48)),const SizedBox(height:8),
            Text(_phase=='dawn'?'Yeni gün başlıyor...':'Gece bastırıyor...',
                style:const TextStyle(color:Colors.white,fontSize:16,fontWeight:FontWeight.bold)),
            const SizedBox(height:12),
            const SizedBox(width:24,height:24,child:CircularProgressIndicator(color:Colors.white,strokeWidth:2)),
          ])));
          // Gece, köylü — uyu
          if(_isNight&&!_isVampire) return Center(child:AZFrostCard(child:const Column(mainAxisSize:MainAxisSize.min,children:[
            Text('😴',style:TextStyle(fontSize:48)),SizedBox(height:8),
            Text('Uyku vakti...',style:TextStyle(color:Colors.white,fontSize:16,fontWeight:FontWeight.bold)),
            Text('Vampirler kurban seçiyor',style:TextStyle(color:Colors.white60,fontSize:13)),
          ])));
          // Oy verildi
          if(_hasVoted) return Center(child:AZFrostCard(child:Column(mainAxisSize:MainAxisSize.min,children:[
            Text(_isNight?'🩸':'🗳️',style:const TextStyle(fontSize:48)),const SizedBox(height:8),
            Text(_isNight?'Kurbanın seçildi!':'Oyunu verdin!',
                style:const TextStyle(color:Colors.white,fontSize:16,fontWeight:FontWeight.bold)),
            Text('$_votedCount/$_voterCount oy toplandı',style:const TextStyle(color:Colors.white60,fontSize:13)),
            const SizedBox(height:12),
            const SizedBox(width:24,height:24,child:CircularProgressIndicator(color:Colors.white,strokeWidth:2)),
          ])));
          // Oy ver
          return Padding(padding:const EdgeInsets.all(12),child:Column(children:[
            Text(_isNight?'🩸 Kimi ısıralım?':'🗳️ Kim vampir?',
                style:TextStyle(color:_isNight?Colors.purpleAccent:Colors.amber.shade700,
                    fontSize:18,fontWeight:FontWeight.bold)),
            Text('$_votedCount/$_voterCount oy',style:const TextStyle(color:Colors.white54,fontSize:12)),
            const SizedBox(height:12),
            Expanded(child:ListView(children:_targets.map((final e)=>Padding(
              padding:const EdgeInsets.only(bottom:10),
              child:ElevatedButton(
                  onPressed:()=>_vote(e.key),
                  style:ElevatedButton.styleFrom(
                      backgroundColor:_isNight?Colors.deepPurple.shade700:Colors.amber.shade600,
                      foregroundColor:Colors.white,padding:const EdgeInsets.all(16),
                      shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(14))),
                  child:Text(e.value['name'] as String??e.key,
                      style:const TextStyle(fontSize:18,fontWeight:FontWeight.bold))),
            )).toList())),
          ]));
        })),
        const BannerAdWidget(),
      ])),
    );
  }
}
