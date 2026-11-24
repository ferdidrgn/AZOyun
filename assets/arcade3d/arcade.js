'use strict';

const $ = (id) => document.getElementById(id);
const sceneElement = $('scene');
let isMaze;
let isBowling;
let isDrone;
let isFootballShot;
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
let pointer;
let resizeObserver;
let webglAvailable = true;
let listeningForResize = false;
let football2d = false;
let footballCanvas;
let footballContext;

const mobileProfile = /Android|iPhone|iPad|iPod/i.test(navigator.userAgent) ||
  window.matchMedia?.('(max-width: 760px)').matches;
const lowPowerProfile = mobileProfile &&
  ((navigator.deviceMemory != null && navigator.deviceMemory <= 3) ||
    (navigator.hardwareConcurrency != null && navigator.hardwareConcurrency <= 4));
const shadowProfile = !mobileProfile || !lowPowerProfile;

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
  if (!webglAvailable && !football2d) return;
  if (paused) {
    paused = false;
  } else {
    if (!football2d) clearScene();
    score = 0;
    game = football2d ? makeFootball2d() : isMaze ? makeMaze() : isBowling ? makeBowling() : isDrone ? makeDrones()
      : isFootballShot ? makeFootballShot() : mode === 'runway' ? makeRunway() : makeOrbit();
  }
  held.clear();
  pointer = undefined;
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
  pointer = undefined;
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
    const materials = Array.isArray(object.material) ? object.material : [object.material];
    for (const material of materials) material?.dispose();
  });
  scene.clear();
  scene.add(new THREE.HemisphereLight(0xd9f8ff, 0x263449, 2.35));
  const key = new THREE.DirectionalLight(0xffe0a0, 2.5);
  key.position.set(-6, 10, 5);
  key.castShadow = shadowProfile;
  const shadowSize = mobileProfile ? 384 : 768;
  key.shadow.mapSize.set(shadowSize, shadowSize);
  key.shadow.camera.left = -12;
  key.shadow.camera.right = 12;
  key.shadow.camera.top = 12;
  key.shadow.camera.bottom = -12;
  key.shadow.bias = -0.0004;
  scene.add(key);
  scene.add(key.target);
  const fill = new THREE.PointLight(0x4be9d5, 18, 32, 2);
  fill.position.set(5, 5, 2);
  scene.add(fill);
}

function mesh(geometry, color, x, y, z) {
  const object = new THREE.Mesh(geometry, new THREE.MeshStandardMaterial({
    color, roughness: .58, metalness: .08,
  }));
  object.position.set(x, y, z);
  object.castShadow = true;
  object.receiveShadow = true;
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
  floor.material.transparent = true;
  floor.material.opacity = .62;
  scene.add(floor);
  const starsGeometry = new THREE.BufferGeometry();
  const starPoints = [];
  for (let index = 0; index < 180; index++) {
    starPoints.push((Math.random() - .5) * 48, Math.random() * 23 - 2,
      -Math.random() * 145 - 10);
  }
  starsGeometry.setAttribute('position', new THREE.Float32BufferAttribute(starPoints, 3));
  const stars = new THREE.Points(starsGeometry, new THREE.PointsMaterial({
    color: 0xb7e5ff, size: .11, transparent: true, opacity: .78,
    sizeAttenuation: true,
  }));
  scene.add(stars);
  const ship = mesh(new THREE.ConeGeometry(.48, 1.35, 4), 0x4cf1d7, 0, 1.5, 0);
  ship.rotation.x = -Math.PI / 2;
  ship.material.emissive.set(0x063b37);
  const wing = box(0x4cf1d7, 0, 1.5, .18, 1.58, .1, .43);
  wing.material.emissive.set(0x063b37);
  const engine = mesh(new THREE.SphereGeometry(.2, 12, 8), 0xffa867, 0, 1.5, .62);
  engine.scale.set(.8, .8, .5);
  engine.material.emissive.set(0xff4b18);
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
      ship.rotation.z = THREE.MathUtils.clamp((target.x - ship.position.x) * -.12, -.32, .32);
      ship.rotation.y = Math.sin(performance.now() * .004) * .025;
      wing.position.set(ship.position.x, ship.position.y, .18);
      engine.position.set(ship.position.x, ship.position.y, .61);
      engine.scale.z = .5 + Math.sin(performance.now() * .018) * .12;
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
      camera.position.x += (ship.position.x * .16 - camera.position.x) * Math.min(1, dt * 2.5);
      camera.position.y += (5.6 + (ship.position.y - 1.5) * .12 - camera.position.y) * Math.min(1, dt * 2);
      camera.lookAt(ship.position.x * .1, 1.5, -19);
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
  scene.fog = new THREE.Fog(0x19373a, 9, 18);
  const floor = box(0x24565b, 0, -.12, 0, size, .22, size);
  floor.material.roughness = 1;
  floor.material.color.set(0x1d4b4e);
  const floorGrid = new THREE.GridHelper(size, size, 0x3f8785, 0x286365);
  floorGrid.position.y = .005;
  floorGrid.material.transparent = true;
  floorGrid.material.opacity = .28;
  scene.add(floorGrid);
  for (let z = 0; z < size; z++) {
    for (let x = 0; x < size; x++) {
      if (!cells[z][x]) {
        const wall = box(0x397781, center(x), .32, center(z), .94, .66, .94);
        wall.material.color.setHSL(.51 + ((x * 7 + z * 3) % 8) * .004, .42, .34 + ((x + z) % 3) * .025);
        wall.material.roughness = .38;
        const cap = mesh(new THREE.BoxGeometry(.86, .035, .86), 0x61a2a0,
          center(x), .66, center(z));
        cap.material.metalness = .22;
      }
    }
  }
  const exit = box(0xebbe62, center(1), .015, center(1), .85, .04, .85);
  exit.material.emissive.set(0x70470d);
  const locations = deadEnds.filter(([x, z]) => x !== 1 || z !== 1);
  const sites = [origin];
  const distanceToSites = ([x, z]) => Math.min(...sites.map(([sx, sz]) => Math.hypot(x - sx, z - sz)));
  for (let index = 0; index < 3; index++) {
    locations.sort((a, b) => distanceToSites(b) - distanceToSites(a));
    sites.push(locations.shift());
  }
  const crystals = sites.slice(1).map(([x, z]) => ({
    x, z, object: mesh(new THREE.OctahedronGeometry(.29), 0x78f1de, center(x), .62, center(z)),
  }));
  const player = mesh(new THREE.SphereGeometry(.25, 12, 8), 0xffc460, center(1), .26, center(1));
  player.material.emissive.set(0x61420c);
  let x = 1;
  let z = 1;
  let time = 85;
  let collected = 0;
  camera.position.set(center(1), 10.8, center(1) + 6.8);
  camera.lookAt(center(1), 0, center(1));
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
      player.position.y = .28 + Math.sin(performance.now() * .006) * .035;
      for (const crystal of crystals) {
        crystal.object.rotation.y += dt * 1.8;
        crystal.object.position.y = .62 + Math.sin(performance.now() * .003 + crystal.x) * .09;
      }
      camera.position.x += (center(x) - camera.position.x) * Math.min(1, dt * 4);
      camera.position.z += (center(z) + 6.8 - camera.position.z) * Math.min(1, dt * 4);
      camera.lookAt(center(x), 0, center(z));
      setText('clock', Math.ceil(time) + ' sn');
      if (time === 0) finish(false, collected + ' / 3 kristal');
    },
  };
}

function makeBowling() {
  scene.background = new THREE.Color(0x111b32);
  scene.fog = new THREE.Fog(0x111b32, 20, 42);
  camera.position.set(0, 7.4, 14);
  camera.lookAt(0, 1.2, -3);
  const lane = box(0xb98750, 0, -.18, -4, 5.2, .32, 19);
  lane.material.color.set(0xb98959);
  lane.material.roughness = .3;
  lane.material.metalness = .14;
  for (const side of [-1, 1]) {
    const gutter = box(0x26384d, side * 2.78, -.12, -4, .34, .18, 19);
    gutter.material.metalness = .65;
    box(0xf3ca7e, side * 3.02, .1, -4, .12, .5, 19);
  }
  for (let index = 0; index < 7; index++) {
    const marker = mesh(new THREE.ConeGeometry(.11, .24, 3), 0x4e392e,
      (index - 3) * .48, .005, 1 - Math.abs(index - 3) * .16);
    marker.rotation.x = Math.PI / 2;
    marker.rotation.z = Math.PI;
  }
  const aim = mesh(new THREE.TorusGeometry(.55, .035, 8, 32), 0x55ffe5, 0, .035, -8);
  aim.rotation.x = Math.PI / 2;
  aim.material.emissive.set(0x08655a);
  const ball = mesh(new THREE.SphereGeometry(.48, 28, 20), 0x24d1bd, 0, .48, 7);
  ball.material.roughness = .2;
  ball.material.metalness = .32;
  ball.material.emissive.set(0x06332f);
  const pinPositions = [];
  for (let row = 0; row < 4; row++) {
    for (let col = 0; col <= row; col++) pinPositions.push([(col - row / 2) * .56, -6.2 - row * .65]);
  }
  let pins = [];
  function resetPins() {
    for (const pin of pins) {
      scene.remove(pin);
      pin.traverse((part) => { part.geometry?.dispose(); part.material?.dispose(); });
    }
    pins = pinPositions.map(([x, z]) => {
      const group = new THREE.Group();
      const body = new THREE.Mesh(new THREE.CylinderGeometry(.18, .29, 1.08, 16),
        new THREE.MeshStandardMaterial({ color: 0xf3eee1, roughness: .3 }));
      body.position.y = .56;
      body.castShadow = true;
      const stripe = new THREE.Mesh(new THREE.CylinderGeometry(.205, .205, .12, 16),
        new THREE.MeshStandardMaterial({ color: 0xe64957, roughness: .35 }));
      stripe.position.y = .75;
      group.add(body, stripe);
      group.position.set(x, 0, z);
      group.userData.down = false;
      scene.add(group);
      return group;
    });
  }
  resetPins();
  let shot = 0;
  let moving = false;
  let targetX = 0;
  let velocityX = 0;
  let velocityZ = 0;
  let knocked = new Set();
  setText('clock', '1 / 3');
  setText('hint', 'Sürükleyerek hedef al, bırakınca topu fırlat.');
  function launch(power) {
    if (moving || shot >= 3) return;
    shot++;
    ball.position.set(0, .48, 7);
    velocityX = THREE.MathUtils.clamp(targetX * .72, -1.8, 1.8);
    velocityZ = -(8 + power * 8);
    moving = true;
    setText('clock', shot + ' / 3');
  }
  return {
    steer(dx) {
      if (moving) return;
      targetX = THREE.MathUtils.clamp(targetX + dx, -1.55, 1.55);
      aim.position.x = targetX;
    },
    launch,
    step(dt) {
      if (!moving) {
        ball.position.x += (targetX - ball.position.x) * Math.min(1, dt * 12);
        ball.rotation.z += dt * .35;
      } else {
        ball.position.x += velocityX * dt;
        ball.position.z += velocityZ * dt;
        ball.position.y = .48 + Math.abs(Math.sin((7 - ball.position.z) * .35)) * .12;
        ball.rotation.x += -velocityZ * dt * 1.8;
        ball.rotation.z += velocityX * dt * 1.5;
        for (let index = 0; index < pins.length; index++) {
          const pin = pins[index];
          if (knocked.has(index)) {
            pin.rotation.z += (pin.userData.fall || 0) * dt * 2;
            pin.position.x += (pin.userData.drift || 0) * dt;
          } else if (Math.hypot(ball.position.x - pin.position.x,
              ball.position.z - pin.position.z) < .72) {
            knocked.add(index);
            pin.userData.fall = Math.sign(pin.position.x - ball.position.x || 1) * 1.1;
            pin.userData.drift = velocityX * .65;
            score += 10;
          }
        }
        if (ball.position.z < -10 || Math.abs(ball.position.x) > 3.3) {
          moving = false;
          setText('hint', knocked.size + ' kukaata. ' + (shot < 3 ? 'Sonraki atış için hedef al.' : 'Tur tamamlandı.'));
          if (shot === 3) finish(true, knocked.size + ' / 10 kuka devrildi • ' + score + ' puan');
          else setTimeout(() => {
            if (!running) return;
            resetPins();
            knocked.clear();
            targetX = 0;
            aim.position.x = 0;
            ball.position.set(0, .48, 7);
          }, 500);
        }
      }
    },
  };
}

function makeRunway() {
  scene.background = new THREE.Color(0x10172d);
  scene.fog = new THREE.FogExp2(0x10172d, .025);
  camera.position.set(0, 5.8, 10);
  camera.lookAt(0, 1, -18);
  const floor = box(0x18233b, 0, -.2, -28, 8, .35, 78);
  floor.material.roughness = .36;
  for (let lane = -1; lane <= 1; lane++) {
    const rail = box(0x18b9b2, lane * 2.1, -.005, -27, .035, .04, 76);
    rail.material.emissive.set(0x08746e);
  }
  const ship = mesh(new THREE.ConeGeometry(.55, 1.3, 5), 0x4cf1d7, 0, 1.05, 1);
  ship.rotation.x = -Math.PI / 2;
  ship.material.emissive.set(0x063b37);
  const wing = box(0x72f6e2, 0, 1.05, 1.18, 1.55, .1, .36);
  wing.material.emissive.set(0x063b37);
  let lane = 0;
  let elapsed = 0;
  let spawnAt = .7;
  let lives = 3;
  const objects = [];
  function spawn() {
    const blocked = Math.floor(Math.random() * 3) - 1;
    const energy = blocked + (Math.random() < .5 ? 1 : -1);
    for (const [track, kind] of [[blocked, 'block'], [energy, 'energy']]) {
      const object = kind === 'block'
        ? box(0xff816d, track * 2.1, .66, -34, 1.2, 1.3, .8)
        : mesh(new THREE.OctahedronGeometry(.48), 0x72f1d5, track * 2.1, .7, -34);
      object.material.emissive.set(kind === 'block' ? 0x52201c : 0x075548);
      objects.push({ object, lane: track, kind, hit: false });
    }
  }
  return {
    steer(dx) { lane = THREE.MathUtils.clamp(Math.round(lane + dx * 3), -1, 1); },
    step(dt) {
      elapsed += dt;
      if (held.has('left')) lane = -1;
      if (held.has('right')) lane = 1;
      if (held.has('up')) lane = 0;
      ship.position.x += (lane * 2.1 - ship.position.x) * Math.min(1, dt * 12);
      wing.position.x = ship.position.x;
      spawnAt -= dt;
      if (spawnAt <= 0) {
        spawn();
        spawnAt = Math.max(.66, 1.25 - elapsed * .012);
      }
      for (let i = objects.length - 1; i >= 0; i--) {
        const item = objects[i];
        item.object.position.z += (8 + elapsed * .18) * dt;
        if (!item.hit && Math.abs(item.object.position.z - 1) < .6 && item.lane === lane) {
          item.hit = true;
          if (item.kind === 'block') lives--;
          else score += 5;
        }
        if (item.object.position.z > 7) {
          scene.remove(item.object);
          item.object.geometry.dispose();
          item.object.material.dispose();
          objects.splice(i, 1);
        }
      }
      setText('hint', 'Can ' + lives + ' • Turuncu engellerden kaç, enerji küplerini topla.');
      setText('clock', Math.max(0, Math.ceil(35 - elapsed)) + ' sn');
      if (elapsed >= 35 || lives <= 0) finish(elapsed >= 35 && lives > 0, lives + ' can • ' + score + ' puan');
    },
  };
}

function makeFootballShot() {
  const penalty = mode === 'penalty';
  const grass = penalty ? 0x246b4e : 0x1c6246;
  scene.background = new THREE.Color(0x152638);
  scene.fog = new THREE.Fog(0x152638, 22, 52);
  camera.position.set(0, 5.1, 16);
  camera.lookAt(0, 2.0, -8);
  const field = box(grass, 0, -.18, -5, 28, .32, 42);
  field.material.roughness = .9;
  for (let stripe = 0; stripe < 10; stripe++) {
    const band = box(stripe % 2 ? 0x205f45 : 0x28734f, 0, -.005,
      15 - stripe * 4.2, 24, .025, 4.2);
    band.material.roughness = .95;
  }
  const lineColor = 0xe5f4dc;
  for (const x of [-3.8, 3.8]) {
    const post = mesh(new THREE.CylinderGeometry(.085, .085, 3.3, 16), lineColor, x, 1.65, -9.5);
    post.material.metalness = .35;
  }
  const crossbar = mesh(new THREE.CylinderGeometry(.09, .09, 7.7, 16), 0xf7f7e9, 0, 3.3, -9.5);
  crossbar.rotation.z = Math.PI / 2;
  crossbar.material.metalness = .35;
  const goalLine = box(0xe8f3dc, 0, .01, -9.45, 7.7, .025, .12);
  for (let x = -3.6; x <= 3.6; x += .6) {
    const netSide = box(0x9fc3b6, x, 1.55, -11, .025, 3.1, 3);
    netSide.material.transparent = true;
    netSide.material.opacity = .45;
  }
  for (let y = .4; y < 3.2; y += .45) {
    const netCross = box(0x9fc3b6, 0, y, -11, 7.2, .025, 3);
    netCross.material.transparent = true;
    netCross.material.opacity = .4;
  }
  const keeper = new THREE.Group();
  const keeperBody = new THREE.Mesh(new THREE.CapsuleGeometry(.38, .8, 4, 10),
    new THREE.MeshStandardMaterial({ color: 0xffa338, roughness: .5 }));
  keeperBody.position.y = .95;
  const keeperHead = new THREE.Mesh(new THREE.SphereGeometry(.28, 16, 12),
    new THREE.MeshStandardMaterial({ color: 0xe5a875, roughness: .68 }));
  keeperHead.position.y = 1.65;
  keeper.add(keeperBody, keeperHead);
  keeper.position.set(0, 0, -8.7);
  scene.add(keeper);
  const walls = [];
  if (!penalty) {
    for (let index = -1; index <= 1; index++) {
      const player = new THREE.Group();
      const body = new THREE.Mesh(new THREE.CapsuleGeometry(.3, .72, 4, 8),
        new THREE.MeshStandardMaterial({ color: 0x416be0, roughness: .7 }));
      body.position.y = .85;
      const head = new THREE.Mesh(new THREE.SphereGeometry(.24, 12, 8),
        new THREE.MeshStandardMaterial({ color: 0xc98f65 }));
      head.position.y = 1.55;
      player.add(body, head);
      player.position.set(index * 1.15, 0, -4.1);
      scene.add(player);
      walls.push(player);
    }
  }
  const ball = new THREE.Group();
  const sphere = new THREE.Mesh(new THREE.SphereGeometry(.42, 24, 16),
    new THREE.MeshStandardMaterial({ color: 0xf4f2e9, roughness: .3 }));
  ball.add(sphere);
  for (let i = 0; i < 5; i++) {
    const patch = new THREE.Mesh(new THREE.CircleGeometry(.085, 5),
      new THREE.MeshStandardMaterial({ color: 0x17202a, roughness: .8, side: THREE.DoubleSide }));
    patch.position.set(Math.cos(i * 1.26) * .28, Math.sin(i * 1.26) * .28, .32);
    ball.add(patch);
  }
  ball.position.set(0, .42, 13);
  scene.add(ball);
  const aimRing = mesh(new THREE.TorusGeometry(.42, .045, 8, 24), 0x76ffe1, 0, 1.6, -9.4);
  aimRing.material.emissive.set(0x0d6550);
  let attempt = 0;
  let goals = 0;
  let flying = false;
  let flight = 0;
  let shot = null;
  let keeperTarget = 0;
  setText('clock', '0 / 6');
  setText('hint', penalty ? 'Topun olduğu yerden yukarı ve yana sürükleyip bırak.'
    : 'Barajı aşmak için topu yukarı, falsolu vuruş için yana sürükle.');
  function aim(dx, dy) {
    const targetX = THREE.MathUtils.clamp(dx * 12, -4.8, 4.8);
    const power = THREE.MathUtils.clamp(-dy * 2.2, .08, 1.2);
    const targetY = THREE.MathUtils.clamp(.75 + power * 2.5, .7, 3.8);
    aimRing.position.x = targetX;
    aimRing.position.y = targetY;
    return { targetX, targetY, power, curve: penalty ? 0 : THREE.MathUtils.clamp(dx * 1.4, -1.2, 1.2) };
  }
  function launch(dx, dy) {
    if (flying || attempt >= 6) return;
    const next = aim(dx, dy);
    if (next.power < .16) {
      setText('hint', 'Daha yukarı sürükle, sonra bırakıp vur.');
      return;
    }
    attempt++;
    shot = next;
    flight = 0;
    flying = true;
    keeperTarget = ((attempt * 37) % 7 - 3) * .78;
    setText('clock', attempt + ' / 6');
    setText('hint', 'Şut çekildi!');
  }
  return {
    aim,
    launch,
    step(dt) {
      const time = performance.now() / 1000;
      if (!flying) {
        keeper.position.x = Math.sin(time * 1.7 + attempt) * 1.2;
      } else {
        flight = Math.min(1, flight + dt * .88);
        const t = flight;
        const curve = shot.curve * Math.sin(Math.PI * t) * .65;
        ball.position.x = shot.targetX * t + curve;
        ball.position.y = .42 + (shot.targetY - .42) * t + Math.sin(Math.PI * t) * shot.power * .45;
        ball.position.z = 13 - 23 * t;
        ball.rotation.x += dt * 8;
        ball.rotation.z += dt * 5;
        keeper.position.x += (keeperTarget - keeper.position.x) * Math.min(1, dt * 2.4);
        keeper.rotation.z = Math.sin(t * Math.PI) * Math.sign(keeperTarget || 1) * .24;
        if (!penalty && ball.position.z < -3.6 && Math.abs(ball.position.x - walls[1].position.x) < .95
            && ball.position.y < 1.75 && shot.power < .9) {
          flying = false;
          setText('hint', 'Barajda kaldı • ' + attempt + ' / 6 vuruş');
        } else if (ball.position.z < -8.1) {
          const onFrame = Math.abs(ball.position.x) < 3.75 && ball.position.y < 3.15 && ball.position.y > .1;
          const saved = Math.abs(ball.position.x - keeper.position.x) < .68 && ball.position.y < 2.45;
          const goal = onFrame && !saved;
          if (goal) {
            goals++;
            score += Math.abs(ball.position.x) > 2.5 || ball.position.y > 2.55 ? 3 : 2;
          }
          flying = false;
          setText('hint', !onFrame ? 'Aut • ' + attempt + ' / 6 vuruş'
            : saved ? 'Kaleci kurtardı • ' + attempt + ' / 6 vuruş'
              : goal ? 'GOL! ' + goals + ' gol • ' + attempt + ' / 6 vuruş'
                : 'Şut kaçtı • ' + attempt + ' / 6 vuruş');
        }
        if (!flying) {
          ball.position.set(0, .42, 13);
          keeper.rotation.z = 0;
          if (attempt >= 6) finish(goals > 0, goals + ' gol • ' + score + ' puan');
        }
      }
    },
  };
}

function makeDrones() {
  scene.background = new THREE.Color(0x14162d);
  scene.fog = new THREE.Fog(0x14162d, 16, 38);
  camera.position.set(0, 2.8, 10);
  camera.lookAt(0, 1.8, -12);
  const starPositions = [];
  for (let i = 0; i < 42; i++) {
    starPositions.push((Math.random() - .5) * 20, Math.random() * 10, -Math.random() * 35);
  }
  const starGeometry = new THREE.BufferGeometry();
  starGeometry.setAttribute('position', new THREE.Float32BufferAttribute(starPositions, 3));
  scene.add(new THREE.Points(starGeometry, new THREE.PointsMaterial({
    color: 0x8aa8df, size: .08, transparent: true, opacity: .8,
  })));
  const drones = [];
  let elapsed = 0;
  let spawnAt = .5;
  let missed = 0;
  function spawn() {
    const group = new THREE.Group();
    const core = new THREE.Mesh(new THREE.IcosahedronGeometry(.48, 1),
      new THREE.MeshStandardMaterial({ color: 0xff6c74, metalness: .45, roughness: .28,
        emissive: 0x481014 }));
    const ring = new THREE.Mesh(new THREE.TorusGeometry(.76, .055, 8, 24),
      new THREE.MeshStandardMaterial({ color: 0xffbd72, emissive: 0x67401c,
        metalness: .6, roughness: .25 }));
    ring.rotation.x = Math.PI / 2.5;
    group.add(core, ring);
    group.position.set((Math.random() - .5) * 9, .7 + Math.random() * 4, -30);
    group.userData.core = core;
    scene.add(group);
    drones.push(group);
  }
  return {
    tap(clientX, clientY) {
      const bounds = sceneElement.getBoundingClientRect();
      const x = ((clientX - bounds.left) / bounds.width) * 2 - 1;
      const y = -((clientY - bounds.top) / bounds.height) * 2 + 1;
      let closest;
      let closestDistance = .14;
      for (const drone of drones) {
        const projected = drone.position.clone().project(camera);
        const distance = Math.hypot(projected.x - x, projected.y - y);
        if (projected.z < 1 && distance < closestDistance) {
          closest = drone;
          closestDistance = distance;
        }
      }
      if (!closest) return;
      scene.remove(closest);
      closest.traverse((part) => { part.geometry?.dispose(); part.material?.dispose(); });
      drones.splice(drones.indexOf(closest), 1);
      score += 10;
    },
    step(dt) {
      elapsed += dt;
      spawnAt -= dt;
      if (spawnAt <= 0) {
        spawn();
        spawnAt = Math.max(.42, 1.12 - elapsed * .012);
      }
      for (let i = drones.length - 1; i >= 0; i--) {
        const drone = drones[i];
        drone.position.z += (5 + elapsed * .12) * dt;
        drone.position.y += Math.sin(elapsed * 2 + i) * dt * .25;
        drone.rotation.y += dt * 1.5;
        if (drone.position.z > 8) {
          scene.remove(drone);
          drone.traverse((part) => { part.geometry?.dispose(); part.material?.dispose(); });
          drones.splice(i, 1);
          missed++;
        }
      }
      setText('hint', 'Kaçan dron ' + missed + '/4 • Yaklaşan dronlara dokun.');
      setText('clock', Math.max(0, Math.ceil(40 - elapsed)) + ' sn');
      if (elapsed >= 40 || missed >= 4) finish(elapsed >= 40 && missed < 4,
        missed + ' dron kaçtı • ' + score + ' puan');
    },
  };
}

function resize() {
  if (football2d) {
    game?.draw();
    return;
  }
  if (!renderer || !scene || !camera || !webglAvailable) return;
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
  if (football2d) game.draw();
  else renderer.render(scene, camera);
}

function frame(time) {
  if (!running) return;
  const dt = lastFrame === 0 ? 0 : Math.min(.05, (time - lastFrame) / 1000);
  lastFrame = time;
  game.step(dt);
  setText('score', score);
  if (football2d) game.draw();
  else renderer.render(scene, camera);
  if (running) frameId = requestAnimationFrame(frame);
}

function enableFootball2d() {
  football2d = true;
  if (renderer?.domElement) renderer.domElement.hidden = true;
  if (!footballCanvas) {
    footballCanvas = document.createElement('canvas');
    footballCanvas.id = 'football-2d';
    footballCanvas.setAttribute('aria-label', 'Sürükleyerek oynanan 2D futbol sahası');
    sceneElement.prepend(footballCanvas);
  }
  footballContext = footballCanvas.getContext('2d');
  if (!footballContext) return false;
  sceneElement.setAttribute('aria-label', '2D futbol sahası');
  return true;
}

function initialize(mode) {
  if (renderer) return;
  isMaze = mode === 'maze';
  isBowling = mode === 'bowling';
  isDrone = mode === 'drones';
  isFootballShot = mode === 'freeKick' || mode === 'penalty';
  const title = isMaze ? 'Kristal Labirent' : isBowling ? '3D Mini Bowling' : isDrone ? 'Sinyal Avı'
    : mode === 'freeKick' ? 'Frikik Ustası' : mode === 'penalty' ? 'Penaltı Antrenmanı'
      : mode === 'runway' ? 'Neon Pist' : 'Yörünge Pilotu';
  instructions = isMaze
    ? 'Üç kristali topla ve altın çıkışa dön. Her turda yollar değişir.'
    : isBowling ? 'Topu sürükleyerek hedefle ve bırakıp fırlat. Üç atışta en çok kukayı devir.'
    : isDrone ? 'Yaklaşan keşif dronlarına dokun. Dört dron kaçarsa görev biter.'
    : isFootballShot ? 'Topu yukarı ve yana sürükleyip bırak. Altı vuruşta en yüksek skoru yap.'
    : mode === 'runway' ? 'Şerit değiştir, engellerden kaç ve enerji küplerini topla. 35 saniye dayan.'
      : 'Gemiyi sürükleyerek halkalardan geç. 12 halkanın en az 9\'unu yakala.';
  hint = isMaze
    ? 'Yön tuşlarıyla ilerle. Altın karo çıkışı gösterir.'
    : isBowling ? 'Sürükleyerek hedef al, bırakınca topu fırlat.'
    : isDrone ? 'Dronlara dokunarak yakala.'
    : isFootballShot ? (mode === 'penalty' ? 'Topu yukarı ve yana sürükleyerek vur.' : 'Yukarı sürükle, yana çekerek falsolu vur.')
    : mode === 'runway' ? 'Sürükle veya sol/sağ okları kullan.'
      : 'Sürükle veya okları kullan. Nişangâhı kırmızı halkanın içine getir.';
  bestKey = 'az-arcade-' + mode;
  try {
    renderer = new THREE.WebGLRenderer({
      antialias: !mobileProfile,
      powerPreference: 'low-power',
      stencil: false,
      failIfMajorPerformanceCaveat: false,
    });
    const pixelRatioLimit = lowPowerProfile ? 1 : mobileProfile ? 1.25 : 1.5;
    renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, pixelRatioLimit));
    renderer.shadowMap.enabled = shadowProfile;
    renderer.shadowMap.type = THREE.PCFSoftShadowMap;
    renderer.outputColorSpace = THREE.SRGBColorSpace;
    renderer.toneMapping = THREE.ACESFilmicToneMapping;
    renderer.toneMappingExposure = 1.08;
    scene = new THREE.Scene();
    camera = new THREE.PerspectiveCamera(54, 1, .1, 195);
    sceneElement.prepend(renderer.domElement);
    renderer.domElement.addEventListener('webglcontextlost', (event) => {
      event.preventDefault();
      webglAvailable = false;
      running = false;
      paused = false;
      held.clear();
      pointer = undefined;
      cancelAnimationFrame(frameId);
      $('pause').hidden = true;
      $('controls').hidden = true;
      if (isFootballShot && enableFootball2d()) {
        game = makeFootball2d();
        panel(title, '3D görüntü kesildi. Oyuna 2D saha modunda devam edebilirsin.', '2D devam et');
        return;
      }
      panel('3D görüntü durakladı', 'Grafik belleği yeniden hazırlanıyor. Görüntü geri gelmezse oyunu kapatıp aç.', null);
    });
    renderer.domElement.addEventListener('webglcontextrestored', () => {
      webglAvailable = true;
      panel('Görüntü hazır', 'Sahne yeniden kurulacak.', 'Yeniden başlat');
    });
    scene.background = new THREE.Color(0x15252e);
    resize();
  } catch (_) {
    if (!isFootballShot) {
      panel('3D görüntü açılamadı', 'Bu oyun WebGL destekli bir tarayıcı veya güncel Android System WebView gerektiriyor.', null);
      return;
    }
    if (!enableFootball2d()) {
      panel('Oyun açılamadı', 'Tarayıcının 2D çizim alanı kullanılamıyor.', null);
      return;
    }
  }

  if ('ResizeObserver' in window) {
    resizeObserver = new ResizeObserver(resize);
    resizeObserver.observe(sceneElement);
  } else {
    window.addEventListener('resize', resize);
    listeningForResize = true;
  }

  try { best = Number(localStorage.getItem(bestKey)) || 0; } catch (_) { /* storage optional */ }
  setText('best', best);
  setText('hint', hint);
  panel(title, football2d ? instructions + ' (2D saha modu)' : instructions, 'Başla');
  $('start').addEventListener('click', start);
  $('pause').addEventListener('click', pause);
  document.addEventListener('visibilitychange', () => { if (document.hidden) pause(); });
  window.addEventListener('blur', () => {
    held.clear();
    pointer = undefined;
  });
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
  sceneElement.addEventListener('pointerdown', (event) => {
    if (!running) return;
    if (isDrone) { game.tap(event.clientX, event.clientY); return; }
    if (isMaze || pointer) return;
    pointer = { id: event.pointerId, x: event.clientX, y: event.clientY,
      startX: event.clientX, startY: event.clientY };
    sceneElement.setPointerCapture(event.pointerId);
  });
  sceneElement.addEventListener('pointermove', (event) => {
    if (!running || pointer?.id !== event.pointerId) return;
    if (isFootballShot) {
      const bounds = sceneElement.getBoundingClientRect();
      game.aim((event.clientX - pointer.startX) / bounds.width,
        (pointer.startY - event.clientY) / bounds.height);
    } else {
      game.steer((event.clientX - pointer.x) * (isBowling ? .018 : .027),
        isBowling ? undefined : (event.clientY - pointer.y) * .021);
    }
    pointer.x = event.clientX;
    pointer.y = event.clientY;
  });
  function clearPointer(event) {
    if (event.pointerId === pointer?.id) {
      if (event.type === 'pointerup' && isBowling && running && game?.launch) {
        const power = THREE.MathUtils.clamp(Math.abs(pointer.startY - event.clientY) / 180, .25, 1);
        game.launch(power);
      } else if (event.type === 'pointerup' && isFootballShot && running) {
        const bounds = sceneElement.getBoundingClientRect();
        game.launch((event.clientX - pointer.startX) / bounds.width,
          (pointer.startY - event.clientY) / bounds.height);
      }
      pointer = undefined;
    }
  }
  sceneElement.addEventListener('pointerup', clearPointer);
  sceneElement.addEventListener('pointercancel', clearPointer);
  sceneElement.addEventListener('lostpointercapture', clearPointer);
}

function makeFootball2d() {
  const penalty = mode === 'penalty';
  const state = {
    attempt: 0, goals: 0, targetX: .5, targetY: .23, power: .45, curve: 0,
    flight: 0, inFlight: false, keeperX: .5, keeperTarget: .5,
    result: '', resultTime: 0, ballX: .5, ballY: .86, wallHit: false,
  };
  setText('clock', '0 / 6');
  setText('hint', penalty
    ? 'Topu sürükleyip kalenin istediğin köşesine bırak. Kaleciyi geç!'
    : 'Barajı aşmak için yukarı; falsolu vuruş için yana sürükle.');

  function dimensions() {
    const rect = footballCanvas.getBoundingClientRect();
    const scale = Math.min(window.devicePixelRatio || 1, 2);
    const width = Math.max(1, rect.width);
    const height = Math.max(1, rect.height);
    if (footballCanvas.width !== Math.round(width * scale) ||
        footballCanvas.height !== Math.round(height * scale)) {
      footballCanvas.width = Math.round(width * scale);
      footballCanvas.height = Math.round(height * scale);
    }
    footballContext.setTransform(scale, 0, 0, scale, 0, 0);
    return { width, height };
  }

  function draw() {
    if (!footballContext) return;
    const { width: w, height: h } = dimensions();
    const c = footballContext;
    c.clearRect(0, 0, w, h);
    const field = c.createLinearGradient(0, 0, 0, h);
    field.addColorStop(0, '#18283b'); field.addColorStop(.34, '#1e563e'); field.addColorStop(1, '#246447');
    c.fillStyle = field; c.fillRect(0, 0, w, h);
    // Stadium band and mowing stripes give the 2D fallback its own art direction.
    c.fillStyle = '#101b2b'; c.fillRect(0, 0, w, h * .105);
    c.fillStyle = 'rgba(12,25,22,.19)'; c.fillRect(w * .08, h * .13, w * .84, h * .84);
    for (let i = 0; i < 8; i++) {
      c.fillStyle = i % 2 ? 'rgba(114,221,149,.045)' : 'rgba(6,34,22,.06)';
      c.fillRect(0, h * (.17 + i * .1), w, h * .1);
    }
    c.strokeStyle = 'rgba(244,255,246,.42)'; c.lineWidth = 2;
    c.beginPath(); c.moveTo(w * .08, h * .98); c.lineTo(w * .17, h * .15);
    c.lineTo(w * .83, h * .15); c.lineTo(w * .92, h * .98); c.stroke();
    const gx = w * .19, gw = w * .62, gy = h * .14, gh = h * .2;
    c.fillStyle = 'rgba(5,12,20,.3)'; c.fillRect(gx, gy, gw, gh);
    c.strokeStyle = '#f5f4e8'; c.lineWidth = Math.max(4, w * .009); c.strokeRect(gx, gy, gw, gh);
    c.strokeStyle = 'rgba(230,244,236,.3)'; c.lineWidth = 1;
    for (let i = 1; i < 10; i++) { c.beginPath(); c.moveTo(gx + gw * i / 10, gy); c.lineTo(gx + gw * i / 10, gy + gh); c.stroke(); }
    for (let i = 1; i < 4; i++) { c.beginPath(); c.moveTo(gx, gy + gh * i / 4); c.lineTo(gx + gw, gy + gh * i / 4); c.stroke(); }
    c.strokeStyle = 'rgba(236,249,239,.38)'; c.lineWidth = 2; c.strokeRect(w * .1, h * .23, w * .8, h * .29);
    if (!penalty) {
      const wallY = h * .535;
      c.strokeStyle = 'rgba(244,249,247,.48)'; c.setLineDash([7, 7]); c.lineWidth = 2;
      c.beginPath(); c.moveTo(w * .29, wallY + 13); c.lineTo(w * .71, wallY + 13); c.stroke(); c.setLineDash([]);
      for (let i = 0; i < 3; i++) {
        const x = w * (.4 + i * .1);
        c.fillStyle = '#456fe0'; c.fillRect(x - 9, wallY - 1, 18, 29);
        c.fillStyle = '#d7a17b'; c.beginPath(); c.arc(x, wallY - 8, 7, 0, Math.PI * 2); c.fill();
      }
    }
    // Keeper waits at the middle, chooses a side, and dives as the ball arrives.
    const keeper = state.inFlight
      ? state.keeperX + (state.keeperTarget - state.keeperX) * Math.min(1, state.flight * 2.2)
      : state.keeperX;
    const kx = w * keeper, ky = h * .29 + (state.inFlight && state.flight > .72 ? h * .025 : 0);
    c.fillStyle = '#f5a13d'; c.strokeStyle = '#fff0c9'; c.lineWidth = 3;
    c.beginPath(); c.arc(kx, ky - 13, 9, 0, Math.PI * 2); c.fill(); c.stroke();
    c.lineWidth = 8; c.lineCap = 'round'; c.beginPath(); c.moveTo(kx, ky - 2); c.lineTo(kx, ky + 19);
    c.moveTo(kx, ky + 3); c.lineTo(kx - 20, ky + 6); c.moveTo(kx, ky + 3); c.lineTo(kx + 20, ky + 6); c.stroke();
    if (!state.inFlight && !state.result) {
      c.strokeStyle = 'rgba(129,255,222,.84)'; c.setLineDash([5, 7]); c.lineWidth = 2;
      c.beginPath(); c.moveTo(w * .5, h * .86); c.lineTo(w * state.targetX, h * state.targetY); c.stroke(); c.setLineDash([]);
      c.strokeStyle = '#83ffe1'; c.lineWidth = 3; c.beginPath(); c.arc(w * state.targetX, h * state.targetY, 11, 0, Math.PI * 2); c.stroke();
    }
    const bx = w * state.ballX, by = h * state.ballY, radius = Math.max(8, Math.min(15, w * .025));
    c.fillStyle = 'rgba(0,0,0,.26)'; c.beginPath(); c.ellipse(bx + 2, by + radius * .6, radius * 1.2, radius * .52, 0, 0, Math.PI * 2); c.fill();
    c.fillStyle = '#fbf8e9'; c.strokeStyle = '#acb6af'; c.lineWidth = 1.5; c.beginPath(); c.arc(bx, by, radius, 0, Math.PI * 2); c.fill(); c.stroke();
    c.fillStyle = '#1b2930';
    for (let i = 0; i < 5; i++) { const a = i * Math.PI * 2 / 5; c.beginPath(); c.arc(bx + Math.cos(a) * radius * .5, by + Math.sin(a) * radius * .5, radius * .15, 0, Math.PI * 2); c.fill(); }
    if (state.result) {
      c.fillStyle = 'rgba(10,18,28,.68)'; c.fillRect(w * .16, h * .64, w * .68, 44);
      c.fillStyle = state.result.startsWith('GOL') ? '#c4ff5c' : '#fff'; c.textAlign = 'center';
      c.font = '700 17px system-ui'; c.fillText(state.result, w * .5, h * .64 + 28);
    }
  }

  function aim(dx, dy) {
    const power = Math.max(.08, Math.min(1.2, -dy * 2.2));
    state.targetX = Math.max(.13, Math.min(.87, .5 + dx * 1.05));
    state.power = power;
    state.targetY = Math.max(.15, Math.min(.34, .34 - power * .16));
    state.curve = penalty ? 0 : Math.max(-1, Math.min(1, dx * 2));
    state.result = ''; state.resultTime = 0;
    draw();
    return { power };
  }

  function finishShot() {
    const onFrame = state.targetX > .2 && state.targetX < .8 && state.targetY > .14 && state.targetY < .34;
    const saved = onFrame && Math.abs(state.targetX - state.keeperTarget) < (state.power > .8 ? .08 : .14);
    if (state.wallHit) state.result = 'Barajda kaldı';
    else if (!onFrame) state.result = 'Aut';
    else if (saved) state.result = 'Kaleci kurtardı';
    else {
      state.goals++;
      score += (state.targetX < .28 || state.targetX > .72 || state.targetY < .19) ? 3 : 2;
      state.result = 'GOL! ' + state.goals + ' gol';
    }
    state.inFlight = false; state.resultTime = 1.15;
    setText('hint', state.result + ' · ' + state.attempt + ' / 6 vuruş');
    if (state.attempt >= 6) window.setTimeout(() => finish(state.goals > 0,
      state.goals + ' gol · ' + score + ' puan'), 1150);
  }

  return {
    aim,
    launch(dx, dy) {
      if (state.inFlight || state.attempt >= 6) return;
      const { power } = aim(dx, dy);
      if (power < .16) { setText('hint', 'Daha yukarı sürükle, sonra bırakıp şut çek.'); return; }
      state.attempt++; state.inFlight = true; state.flight = 0; state.wallHit = false;
      state.ballX = .5; state.ballY = .86;
      state.keeperTarget = .2 + Math.floor(Math.random() * 5) * .15;
      setText('clock', state.attempt + ' / 6'); setText('hint', 'Şut! Kalecinin hamlesini geç.');
    },
    draw,
    step(dt) {
      if (!state.inFlight) {
        state.keeperX = .5 + Math.sin(performance.now() / 850) * .12;
        if (state.resultTime > 0 && (state.resultTime -= dt) <= 0) {
          state.result = ''; state.ballX = .5; state.ballY = .86;
        }
        return;
      }
      state.flight = Math.min(1, state.flight + dt * 1.15);
      const t = state.flight;
      state.ballX = .5 + (state.targetX - .5) * t + state.curve * Math.sin(Math.PI * t) * .075;
      state.ballY = .86 + (state.targetY - .86) * t - Math.sin(Math.PI * t) * state.power * .1;
      if (!penalty && t > .48 && t < .64 && state.targetY > .26 && state.power < .56) state.wallHit = true;
      state.keeperX += (state.keeperTarget - state.keeperX) * Math.min(1, dt * 2.5);
      if (t >= 1) finishShot();
    },
  };
}

window.addEventListener('pagehide', (event) => {
  if (event.persisted) {
    if (running) pause();
    return;
  }
  running = false;
  held.clear();
  pointer = undefined;
  cancelAnimationFrame(frameId);
  resizeObserver?.disconnect();
  if (listeningForResize) window.removeEventListener('resize', resize);
  renderer?.dispose();
});

const mode = new URLSearchParams(location.search).get('game');
if (mode) initialize(mode);
