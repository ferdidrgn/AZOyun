const roleNames = {enemy:'Sabotajcı', seer:'Gözcü', guardian:'Koruyucu', villager:'Köylü'};

export function partyBoard(state, escape, host) {
  const name = (id) => escape(state.players[id]?.name ?? 'Çekimser');
  if (state.game === 'words') {
    return `<p>Torba ${Number(state.stockCount) || 0} harf · Aile sözlüğü · En çok 40 hamle</p>
      <div class="word-board" aria-label="Kelime tahtası">${(state.board ?? Array(121).fill(null)).map((letter,index) =>
        `<button class="word-cell" data-action="wordCell" data-value="${index}" aria-label="${Math.floor(index/11)+1}. satır ${index%11+1}. sütun">${escape(letter ?? (index===60?'★':''))}</button>`).join('')}</div>
      <ul>${state.players.map((player) => `<li>${escape(player.name)} · ${Number(player.score)||0} puan</li>`).join('')}</ul>
      ${state.status === 'finished' ? `<p>Kazanan · ${(state.winners??[]).map(name).join(', ')}</p>` : ''}
      <details><summary>Aile sözlüğü ve kurallar</summary><p>İlk kelime yıldızdan geçer ve iki kat puan alır. Sonraki kelimeler mevcut harflere bağlanır. Yedi harfle +20 puan. Art arda iki tur pas oyunu bitirir.</p><p>${escape((state.dictionary??[]).join(' · '))}</p></details>`;
  }
  const stages = {night:'Gece', discussion:'Tartışma', vote:'Oylama', dusk:'Gün sonu'};
  return `<h3>${Number(state.round)||1}. gün · ${stages[state.phase] ?? ''}</h3>
    ${['night','vote'].includes(state.phase) ? `<p>${Number(state.submitted)||0}/${state.players.filter((p)=>!p.out).length} seçim tamamlandı</p>` : ''}
    ${state.status === 'finished' && state.teamWinner ? `<p class="turn">${state.teamWinner==='enemy'?'Sabotajcılar kazandı':'Köy kazandı'}</p>` : ''}
    ${host && state.status==='playing' && ['discussion','dusk'].includes(state.phase) ? `<button class="button primary" data-action="${state.phase==='discussion'?'openVote':'nextNight'}">${state.phase==='discussion'?'Tartışma bitti · Oylamayı aç':'Sonraki gece'}</button>` : ''}
    ${(state.lastVotes??[]).length ? `<h3>Açıklanan oylar</h3><ul>${state.lastVotes.map((vote)=>`<li>${name(vote.voter)} → ${name(vote.target)}</li>`).join('')}</ul>` : ''}
    <ul>${(state.events??[]).map((event)=>`<li>${event.day}. gün · ${event.phase==='night'?'Gece':'Oylama'} · ${event.eliminated==null?'Kimse elenmedi':name(event.eliminated)+' elendi'}</li>`).join('')}</ul>
    ${state.revealedRoles ? `<ul>${state.revealedRoles.map((role,id)=>`<li>${name(id)} · ${roleNames[role]}</li>`).join('')}</ul>` : ''}`;
}

export function partyControls(state, escape) {
  const name = (id) => escape(state.players[id]?.name ?? 'Çekimser');
  if (state.game === 'words') {
    const mine=state.turn===state.seat;
    return `<h3>Harflerin</h3><p class="tile-row">${(state.private.hand??[]).map((letter)=>`<span class="tile">${escape(letter)}</span>`).join('')}</p>
      ${mine ? `<form class="stack" data-form="word">
        <label class="control">Kelime<input name="word" maxlength="11" required autocomplete="off"></label>
        <label class="control">Başlangıç satırı<input name="row" type="number" value="6" min="1" max="11" required></label>
        <label class="control">Başlangıç sütunu<input name="col" type="number" value="6" min="1" max="11" required></label>
        <label class="control">Yön<select name="direction"><option value="horizontal">Yatay →</option><option value="vertical">Dikey ↓</option></select></label>
        <button class="button primary">Kelimeyi onayla</button></form>
        <button class="button outline" data-action="passWord">Pas</button>
        <button class="button outline" data-action="swapLetters">Harfleri değiştir ve geç</button>` : '<p>Sıranı bekle.</p>'}`;
  }
  const own=state.private, me=state.players[state.seat], night=state.phase==='night';
  const active=['enemy','guardian','seer'].includes(own.role);
  const eligible=state.players.flatMap((p,id)=>!p.out && (night || id!==state.seat) &&
    (!night || own.role!=='enemy' || !(own.allies??[]).includes(id)) ? [id] : []);
  return `<details><summary>Gizli rolünü göster</summary><h3>${roleNames[own.role]??''}</h3>
    <p>${({enemy:'Her gece köyden birini seç. Takımın diğer oyuncuların sayısına ulaşınca kazanır.',seer:'Her gece bir oyuncunun sabotajcı olup olmadığını öğren.',guardian:'Her gece bir oyuncuyu saldırıdan koru.',villager:'Gece dinlen. Gündüz sabotajcıları bulmak için konuş ve oy ver.'})[own.role]??''}</p>
    ${(own.allies??[]).length>1 ? `<p>Takımın · ${own.allies.map(name).join(', ')}</p>` : ''}</details>
    ${me.out ? '<p>Elendin. Ortak masayı izleyebilirsin.</p>' : own.submitted ? '<p>Seçimin alındı. Diğer oyuncular bekleniyor.</p>' : ['night','vote'].includes(state.phase) ?
      `<form class="stack" data-form="role"><label class="control">${night?'Gece görevin':'Oy ver'}<select name="target">
      ${!night || !active ? '<option value="">'+(night?'Dinlen':'Çekimser')+'</option>' : ''}
      ${!night || active ? eligible.map((id)=>`<option value="${id}">${name(id)}</option>`).join(''):''}
      </select></label><button class="button primary">${night?'Görevi onayla':'Oyu onayla'}</button></form>` : '<p>Ortak masayı takip et.</p>'}
    <ul>${(own.investigations??[]).map((item)=>`<li>${item.day}. gece · ${name(item.target)} · ${item.enemy?'Sabotajcı':'Köyden'}</li>`).join('')}</ul>`;
}
