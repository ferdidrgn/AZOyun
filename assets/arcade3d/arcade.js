'use strict';

const $ = (id) => document.getElementById(id);
const sceneElement = $('scene');
let isMaze;
let instructions;
let hint;
let bestKey;
const direction = { up: [0, -1], down: [0, 1], left: [-1, 0], right: [1, 0] };
const keyDirection = { ArrowUp: 'up', ArrowDown: 'down', ArrowLeft: 'left', ArrowRight: 'right' };

let renderer;
let scene;
let camera;
let game;
let score = 0;
let best = 0;
let running = false;
let paused = false;
let lastFrame = 0;
let frameId;
const held = new Set();

function setText(id, value) {
  const text = String(value);
  if ($(id).textContent !== text) $(id).textContent = text;
}

function panel(heading, message, button) {
  setText('title', heading);
  setText('message', message);
  setText('start', button || '');
  $('start').hidden = !button;
  $('panel').hidden = false;
}

function start() {
  if (paused) {
    paused = false;
  } else {
    clearScene();
    score = 0;
    game = isMaze ? makeMaze() : makeOrbit();
  }
  held.clear();
  running = true;
  lastFrame = 0;
  $('panel').hidden = true;
  $('pause').hidden = false;
  $('controls').hidden = !isMaze;
  if (isMaze) $('controls').querySelector('button').focus();
  cancelAnimationFrame(frameId);
  frameId = requestAnimationFrame(frame);
}

function pause() {
  if (!running) return;
  running = false;
  paused = true;
  held.clear();
  cancelAnimationFrame(frameId);
  $('pause').hidden = true;
  panel('Duraklatıldı', instructions, 'Devam et');
}

function finish(won, details) {
  running = false;
  held.clear();
  if (score > best) {
    best = score;
    try { localStorage.setItem(bestKey, String(best)); } catch (_) { /* storage optional */ }
  }
  setText('score', score);
  setText('best', best);
  $('pause').hidden = true;
  $('controls').hidden = true;
  panel(won ? 'Görev tamamlandı' : 'Tur sona erdi', details, 'Tekrar oyna');
}

function clearScene() {
  scene.traverse((object) => {
    object.geometry?.dispose();
    object.material?.dispose();
  });
  scene.clear();
  scene.add(new THREE.HemisphereLight(0xd9f8ff, 0x32435c, 2.1));
  const key = new THREE.DirectionalLight(0xffe0a0, 2.5);
  key.position.set(-6, 10, 5);
  scene.add(key);
}

function mesh(geometry, color, x, y, z) {
  const object = new THREE.Mesh(geometry, new THREE.MeshStandardMaterial({ color, roughness: .68 }));
  object.position.set(x, y, z);
  scene.add(object);
  return object;
}

function box(color, x, y, z, w, h, d) {
  return mesh(new THREE.BoxGeometry(w, h, d), color, x, y, z);
}

function makeOrbit() {
  scene.background = new THREE.Color(0x141a36);
  scene.fog = new THREE.FogExp2(0x141a36, .022);
  camera.position.set(0, 5.6, 10);
  camera.lookAt(0, 1, -19);
  const floor = new THREE.GridHelper(175, 38, 0x395ba0, 0x294667);
  floor.position.set(0, -2, -64);
  scene.add(floor);
  const ship = mesh(new THREE.ConeGeometry(.48, 1.35, 4), 0x4cf1d7, 0, 1.5, 0);
  ship.rotation.x = -Math.PI / 2;
  const wing = box(0x4cf1d7, 0, 1.5, .18, 1.58, .1, .43);
  const cursor = mesh(new THREE.TorusGeometry(.23, .045, 6, 16), 0xffffff, 0, 1.5, -14);
  const rings = [];
  for (let index = 0; index < 12; index++) {
    const x = Math.sin(index * 1.75) * (index < 4 ? 2.1 : 3.4);
    const y = 1.8 + Math.cos(index * 1.38) * 1.35;
    const ring = mesh(new THREE.TorusGeometry(1.18, .11, 8, 28),
      index === 0 ? 0xff7767 : 0x6b9df3, x, y, -14 - index * 12);
    rings.push(ring);
  }
  let reached = 0;
  const target = { x: 0, y: 1.5 };
  function steer(dx, dy) {
    target.x = THREE.MathUtils.clamp(target.x + dx, -4.5, 4.5);
    target.y = THREE.MathUtils.clamp(target.y - dy, .35, 4.0);
  }
  return {
    steer,
    step(dt) {
      for (const name of held) {
        const [dx, dy] = direction[name];
        steer(dx * 6 * dt, dy * 5 * dt);
      }
      ship.position.x += (target.x - ship.position.x) * Math.min(1, dt * 12);
      ship.position.y += (target.y - ship.position.y) * Math.min(1, dt * 12);
      wing.position.set(ship.position.x, ship.position.y, .18);
      const speed = 6.5 + reached * .24;
      for (let index = reached; index < rings.length; index++) rings[index].position.z += speed * dt;
      const gate = rings[reached];
      if (gate && gate.position.z >= 0) {
        const distance = Math.hypot(gate.position.x - ship.position.x, gate.position.y - ship.position.y);
        if (distance <= 1.04) score += 100;
        gate.visible = false;
        reached++;
        if (rings[reached]) rings[reached].material.color.set(0xff7767);
      }
      const nextGate = rings[reached];
      if (nextGate) {
        cursor.position.set(ship.position.x, ship.position.y, nextGate.position.z + .2);
        const linedUp = Math.hypot(nextGate.position.x - ship.position.x,
          nextGate.position.y - ship.position.y) <= 1.04;
        cursor.material.color.set(linedUp ? 0x4cf1d7 : 0xffffff);
      }
      setText('clock', 12 - reached);
      if (reached === rings.length) finish(score >= 900, (score / 100) + ' / 12 halka');
    },
  };
}

function makeMaze() {
  scene.background = new THREE.Color(0x19373a);
  scene.fog = null;
  const size = 9;
  const cells = Array.from({ length: size }, () => Array(size).fill(false));
  const origin = [1, 1];
  const stack = [origin];
  const deadEnds = [];
  cells[1][1] = true;
  while (stack.length) {
    const [x, z] = stack[stack.length - 1];
    const options = Object.values(direction).map(([dx, dz]) => [x + dx * 2, z + dz * 2])
      .filter(([nx, nz]) => nx > 0 && nz > 0 && nx < size - 1 && nz < size - 1 && !cells[nz][nx]);
    if (!options.length) {
      deadEnds.push(stack.pop());
      continue;
    }
    const next = options[Math.floor(Math.random() * options.length)];
    cells[next[1]][next[0]] = true;
    cells[(next[1] + z) / 2][(next[0] + x) / 2] = true;
    stack.push(next);
  }

  const center = (coordinate) => coordinate - (size - 1) / 2;
  const floor = box(0x24565b, 0, -.12, 0, size, .22, size);
  floor.material.roughness = 1;
  for (let z = 0; z < size; z++) {
    for (let x = 0; x < size; x++) {
      if (!cells[z][x]) box(0x397781, center(x), .29, center(z), .96, .6, .96);
    }
  }
  box(0xebbe62, center(1), .015, center(1), .85, .04, .85);
  const locations = deadEnds.filter(([x, z]) => x !== 1 || z !== 1);
  const sites = [origin];
  const distanceToSites = ([x, z]) => Math.min(...sites.map(([sx, sz]) => Math.hypot(x - sx, z - sz)));
  for (let index = 0; index < 3; index++) {
    locations.sort((a, b) => distanceToSites(b) - distanceToSites(a));
    sites.push(locations.shift());
  }
  const crystals = sites.slice(1).map(([x, z]) => ({
    x, z, object: mesh(new THREE.OctahedronGeometry(.29), 0x78f1de, center(x), .5, center(z)),
  }));
  const player = mesh(new THREE.SphereGeometry(.25, 12, 8), 0xffc460, center(1), .26, center(1));
  let x = 1;
  let z = 1;
  let time = 85;
  let collected = 0;
  camera.position.set(0, 12.4, 7.0);
  camera.lookAt(0, 0, 0);
  function move(name) {
    const [dx, dz] = direction[name];
    const nextX = x + dx;
    const nextZ = z + dz;
    if (!cells[nextZ]?.[nextX]) return;
    x = nextX;
    z = nextZ;
    const crystal = crystals.find((item) => item.x === x && item.z === z && item.object.visible);
    if (crystal) {
      crystal.object.visible = false;
      score += 100;
      collected++;
    }
    setText('hint', collected === 3 ? 'Kristaller tamam. Altın çıkışa dön.' : collected + ' / 3 kristal');
    if (x === 1 && z === 1 && collected === 3) {
      score += Math.ceil(time) * 3;
      finish(true, 'Üç kristal kurtarıldı. ' + score + ' puan.');
    }
  }
  setText('hint', hint);
  return {
    move,
    step(dt) {
      time = Math.max(0, time - dt);
      player.position.x += (center(x) - player.position.x) * Math.min(1, dt * 16);
      player.position.z += (center(z) - player.position.z) * Math.min(1, dt * 16);
      for (const crystal of crystals) crystal.object.rotation.y += dt * 1.8;
      setText('clock', Math.ceil(time) + ' sn');
      if (time === 0) finish(false, collected + ' / 3 kristal');
    },
  };
}

function resize() {
  const width = sceneElement.clientWidth;
  const height = sceneElement.clientHeight;
  if (width < 1 || height < 1) return;
  const aspect = width / height;
  camera.aspect = aspect;
  camera.fov = isMaze ? Math.max(45, 2 * Math.atan(.42 / aspect) * 180 / Math.PI)
    : Math.max(55, 2 * Math.atan(.43 / aspect) * 180 / Math.PI);
  camera.updateProjectionMatrix();
  renderer.setSize(width, height, false);
  renderer.domElement.style.width = width + 'px';
  renderer.domElement.style.height = height + 'px';
  renderer.render(scene, camera);
}

function frame(time) {
  if (!running) return;
  const dt = lastFrame === 0 ? 0 : Math.min(.05, (time - lastFrame) / 1000);
  lastFrame = time;
  game.step(dt);
  setText('score', score);
  renderer.render(scene, camera);
  if (running) frameId = requestAnimationFrame(frame);
}

function initialize(mode) {
  if (renderer) return;
  isMaze = mode === 'maze';
  const title = isMaze ? 'Kristal Labirent' : 'Yörünge Pilotu';
  instructions = isMaze
    ? 'Üç kristali topla ve altın çıkışa dön. Her turda yollar değişir.'
    : 'Gemiyi sürükleyerek halkalardan geç. 12 halkanın en az 9’unu yakala.';
  hint = isMaze
    ? 'Yön tuşlarıyla ilerle. Altın karo çıkışı gösterir.'
    : 'Sürükle veya okları kullan. Nişangâhı kırmızı halkanın içine getir.';
  bestKey = 'az-arcade-' + mode;
  try {
    renderer = new THREE.WebGLRenderer({ antialias: true });
    renderer.setPixelRatio(Math.min(devicePixelRatio, 1.65));
    scene = new THREE.Scene();
    camera = new THREE.PerspectiveCamera(54, 1, .1, 195);
    sceneElement.prepend(renderer.domElement);
    renderer.domElement.addEventListener('webglcontextlost', (event) => {
      event.preventDefault();
      pause();
      panel('3D görüntü kesildi', 'Oyun ekranını kapatıp yeniden aç.', null);
    });
    scene.background = new THREE.Color(0x15252e);
    resize();
    new ResizeObserver(resize).observe(sceneElement);
  } catch (_) {
    panel('3D görüntü açılamadı', 'Bu oyun WebGL destekli bir tarayıcı veya güncel Android System WebView gerektiriyor.', null);
    return;
  }

  try { best = Number(localStorage.getItem(bestKey)) || 0; } catch (_) { /* storage optional */ }
  setText('best', best);
  setText('hint', hint);
  panel(title, instructions, 'Başla');
  $('start').addEventListener('click', start);
  $('pause').addEventListener('click', pause);
  document.addEventListener('visibilitychange', () => { if (document.hidden) pause(); });
  window.addEventListener('blur', () => held.clear());
  window.addEventListener('keydown', (event) => {
    const name = keyDirection[event.key];
    if (!name || !running) return;
    event.preventDefault();
    if (isMaze) game.move(name);
    else held.add(name);
  });
  window.addEventListener('keyup', (event) => held.delete(keyDirection[event.key]));
  for (const button of $('controls').querySelectorAll('button')) {
    button.addEventListener('click', () => { if (running) game.move(button.dataset.direction); });
  }
  let pointer;
  sceneElement.addEventListener('pointerdown', (event) => {
    if (isMaze || !running || pointer) return;
    pointer = { id: event.pointerId, x: event.clientX, y: event.clientY };
    sceneElement.setPointerCapture(event.pointerId);
  });
  sceneElement.addEventListener('pointermove', (event) => {
    if (!running || pointer?.id !== event.pointerId) return;
    game.steer((event.clientX - pointer.x) * .027, (event.clientY - pointer.y) * .021);
    pointer.x = event.clientX;
    pointer.y = event.clientY;
  });
  function clearPointer(event) {
    if (event.pointerId === pointer?.id) pointer = undefined;
  }
  sceneElement.addEventListener('pointerup', clearPointer);
  sceneElement.addEventListener('pointercancel', clearPointer);
  sceneElement.addEventListener('lostpointercapture', clearPointer);
}

const mode = new URLSearchParams(location.search).get('game');
if (mode) initialize(mode);
