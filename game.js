(() => {
  'use strict';

  const canvas = document.getElementById('game');
  const ctx = canvas.getContext('2d');
  const hud = document.getElementById('hud');
  const scoreEl = document.getElementById('score');
  const bestEl = document.getElementById('best');
  const overlay = document.getElementById('overlay');
  const menuScreen = document.getElementById('menu');
  const gameoverScreen = document.getElementById('gameover');
  const finalScoreEl = document.getElementById('final-score');
  const newRecordEl = document.getElementById('new-record');
  const playBtn = document.getElementById('play-btn');
  const retryBtn = document.getElementById('retry-btn');

  const STORAGE_KEY = 'eclipse-best';

  let W, H, cx, cy, orbitRadius;
  let state = 'menu';
  let score = 0;
  let best = parseInt(localStorage.getItem(STORAGE_KEY) || '0', 10);
  let angle = 0;
  let direction = 1;
  let speed = 0.028;
  let playerRadius = 10;
  let hazards = [];
  let stars = [];
  let particles = [];
  let hazardTimer = 0;
  let starTimer = 0;
  let bgStars = [];
  let shake = 0;
  let lastTime = 0;

  bestEl.textContent = `Record : ${best}`;

  function resize() {
    W = canvas.width = window.innerWidth * devicePixelRatio;
    H = canvas.height = window.innerHeight * devicePixelRatio;
    canvas.style.width = window.innerWidth + 'px';
    canvas.style.height = window.innerHeight + 'px';
    ctx.setTransform(devicePixelRatio, 0, 0, devicePixelRatio, 0, 0);

    const minDim = Math.min(window.innerWidth, window.innerHeight);
    cx = window.innerWidth / 2;
    cy = window.innerHeight / 2;
    orbitRadius = minDim * 0.32;
    playerRadius = minDim * 0.022;

    if (bgStars.length === 0) {
      for (let i = 0; i < 80; i++) {
        bgStars.push({
          x: Math.random() * window.innerWidth,
          y: Math.random() * window.innerHeight,
          r: Math.random() * 1.5 + 0.3,
          a: Math.random() * 0.5 + 0.1,
          tw: Math.random() * Math.PI * 2
        });
      }
    }
  }

  function showScreen(screen) {
    menuScreen.classList.remove('active');
    gameoverScreen.classList.remove('active');
    screen.classList.add('active');
    overlay.style.pointerEvents = screen === null ? 'none' : 'auto';
    if (screen) overlay.style.display = 'flex';
    else overlay.style.display = 'none';
  }

  function resetGame() {
    score = 0;
    angle = Math.random() * Math.PI * 2;
    direction = Math.random() > 0.5 ? 1 : -1;
    speed = 0.028;
    hazards = [];
    stars = [];
    particles = [];
    hazardTimer = 60;
    starTimer = 30;
    shake = 0;
    scoreEl.textContent = '0';
  }

  function startGame() {
    state = 'playing';
    resetGame();
    showScreen(null);
    hud.classList.remove('hidden');
  }

  function endGame() {
    state = 'gameover';
    hud.classList.add('hidden');
    finalScoreEl.textContent = score;
    const isNew = score > best;
    if (isNew) {
      best = score;
      localStorage.setItem(STORAGE_KEY, best);
      bestEl.textContent = `Record : ${best}`;
    }
    newRecordEl.classList.toggle('hidden', !isNew);
    showScreen(gameoverScreen);
  }

  function spawnHazard() {
    const arcSize = 0.5 + Math.random() * 0.8;
    hazards.push({
      startAngle: Math.random() * Math.PI * 2,
      arcSize,
      rotation: (Math.random() > 0.5 ? 1 : -1) * (0.003 + score * 0.00005)
    });
  }

  function spawnStar() {
    stars.push({
      angle: Math.random() * Math.PI * 2,
      collected: false,
      pulse: Math.random() * Math.PI * 2
    });
  }

  function spawnParticles(x, y, color, count = 12) {
    for (let i = 0; i < count; i++) {
      const a = (Math.PI * 2 * i) / count + Math.random() * 0.3;
      const sp = 2 + Math.random() * 4;
      particles.push({
        x, y,
        vx: Math.cos(a) * sp,
        vy: Math.sin(a) * sp,
        life: 1,
        color
      });
    }
  }

  function playerPos() {
    return {
      x: cx + Math.cos(angle) * orbitRadius,
      y: cy + Math.sin(angle) * orbitRadius
    };
  }

  function normalizeAngle(a) {
    while (a < 0) a += Math.PI * 2;
    while (a >= Math.PI * 2) a -= Math.PI * 2;
    return a;
  }

  function angleInArc(a, start, arc) {
    a = normalizeAngle(a);
    start = normalizeAngle(start);
    const end = normalizeAngle(start + arc);
    if (start <= end) return a >= start && a <= end;
    return a >= start || a <= end;
  }

  function checkCollision() {
    for (const h of hazards) {
      if (angleInArc(angle, h.startAngle, h.arcSize)) {
        return true;
      }
    }
    return false;
  }

  function checkStars() {
    for (const s of stars) {
      if (s.collected) continue;
      let diff = Math.abs(normalizeAngle(angle) - normalizeAngle(s.angle));
      if (diff > Math.PI) diff = Math.PI * 2 - diff;
      if (diff < 0.18) {
        s.collected = true;
        score++;
        scoreEl.textContent = score;
        speed = Math.min(0.065, 0.028 + score * 0.0015);
        const pos = {
          x: cx + Math.cos(s.angle) * orbitRadius,
          y: cy + Math.sin(s.angle) * orbitRadius
        };
        spawnParticles(pos.x, pos.y, '#ffe066', 16);
      }
    }
    stars = stars.filter(s => !s.collected);
  }

  function update(dt) {
    if (state !== 'playing') return;

    angle += direction * speed * dt;

    hazardTimer -= dt;
    if (hazardTimer <= 0) {
      spawnHazard();
      hazardTimer = Math.max(35, 90 - score * 2);
    }

    starTimer -= dt;
    if (starTimer <= 0) {
      spawnStar();
      starTimer = Math.max(25, 55 - score);
    }

    for (const h of hazards) {
      h.startAngle += h.rotation * dt;
    }

    if (hazards.length > 6 + Math.floor(score / 5)) {
      hazards.shift();
    }

    checkStars();

    if (checkCollision()) {
      shake = 12;
      const pos = playerPos();
      spawnParticles(pos.x, pos.y, '#ff4466', 20);
      endGame();
    }

    for (const p of particles) {
      p.x += p.vx;
      p.y += p.vy;
      p.vx *= 0.96;
      p.vy *= 0.96;
      p.life -= 0.025 * dt;
    }
    particles = particles.filter(p => p.life > 0);

    if (shake > 0) shake *= 0.85;
  }

  function drawBackground() {
    const grad = ctx.createRadialGradient(cx, cy, 0, cx, cy, orbitRadius * 2.5);
    grad.addColorStop(0, '#151530');
    grad.addColorStop(1, '#0a0a1a');
    ctx.fillStyle = grad;
    ctx.fillRect(0, 0, window.innerWidth, window.innerHeight);

    const t = Date.now() * 0.001;
    for (const s of bgStars) {
      const alpha = s.a + Math.sin(t * 2 + s.tw) * 0.15;
      ctx.beginPath();
      ctx.arc(s.x, s.y, s.r, 0, Math.PI * 2);
      ctx.fillStyle = `rgba(255,255,255,${alpha})`;
      ctx.fill();
    }
  }

  function drawSun() {
    const glow = ctx.createRadialGradient(cx, cy, 0, cx, cy, 40);
    glow.addColorStop(0, 'rgba(255, 220, 100, 0.9)');
    glow.addColorStop(0.4, 'rgba(255, 160, 60, 0.4)');
    glow.addColorStop(1, 'rgba(255, 100, 50, 0)');
    ctx.fillStyle = glow;
    ctx.beginPath();
    ctx.arc(cx, cy, 40, 0, Math.PI * 2);
    ctx.fill();

    ctx.beginPath();
    ctx.arc(cx, cy, 14, 0, Math.PI * 2);
    ctx.fillStyle = '#ffe066';
    ctx.fill();
  }

  function drawOrbit() {
    ctx.beginPath();
    ctx.arc(cx, cy, orbitRadius, 0, Math.PI * 2);
    ctx.strokeStyle = 'rgba(255, 255, 255, 0.08)';
    ctx.lineWidth = 1.5;
    ctx.stroke();
  }

  function drawHazards() {
    for (const h of hazards) {
      ctx.beginPath();
      ctx.arc(cx, cy, orbitRadius, h.startAngle, h.startAngle + h.arcSize);
      ctx.strokeStyle = 'rgba(30, 10, 40, 0.95)';
      ctx.lineWidth = 22;
      ctx.lineCap = 'round';
      ctx.stroke();

      ctx.beginPath();
      ctx.arc(cx, cy, orbitRadius, h.startAngle, h.startAngle + h.arcSize);
      ctx.strokeStyle = 'rgba(120, 60, 180, 0.6)';
      ctx.lineWidth = 3;
      ctx.stroke();
    }
  }

  function drawStars() {
    const t = Date.now() * 0.003;
    for (const s of stars) {
      const pulse = 1 + Math.sin(t + s.pulse) * 0.2;
      const x = cx + Math.cos(s.angle) * orbitRadius;
      const y = cy + Math.sin(s.angle) * orbitRadius;
      const r = 8 * pulse;

      ctx.save();
      ctx.translate(x, y);
      ctx.rotate(s.angle + Math.PI / 2);
      ctx.beginPath();
      for (let i = 0; i < 5; i++) {
        const a = (Math.PI * 2 * i) / 5 - Math.PI / 2;
        const a2 = a + Math.PI / 5;
        const method = i === 0 ? 'moveTo' : 'lineTo';
        ctx[method](Math.cos(a) * r, Math.sin(a) * r);
        ctx.lineTo(Math.cos(a2) * r * 0.4, Math.sin(a2) * r * 0.4);
      }
      ctx.closePath();
      ctx.fillStyle = '#ffe066';
      ctx.shadowColor = '#ffe066';
      ctx.shadowBlur = 15;
      ctx.fill();
      ctx.restore();
    }
  }

  function drawPlayer() {
    const pos = playerPos();

    const trail = ctx.createRadialGradient(pos.x, pos.y, 0, pos.x, pos.y, playerRadius * 3);
    trail.addColorStop(0, 'rgba(100, 200, 255, 0.5)');
    trail.addColorStop(1, 'rgba(100, 200, 255, 0)');
    ctx.fillStyle = trail;
    ctx.beginPath();
    ctx.arc(pos.x, pos.y, playerRadius * 3, 0, Math.PI * 2);
    ctx.fill();

    ctx.beginPath();
    ctx.arc(pos.x, pos.y, playerRadius, 0, Math.PI * 2);
    ctx.fillStyle = '#66ccff';
    ctx.shadowColor = '#66ccff';
    ctx.shadowBlur = 20;
    ctx.fill();
    ctx.shadowBlur = 0;
  }

  function drawParticles() {
    for (const p of particles) {
      ctx.globalAlpha = p.life;
      ctx.beginPath();
      ctx.arc(p.x, p.y, 3 * p.life, 0, Math.PI * 2);
      ctx.fillStyle = p.color;
      ctx.fill();
    }
    ctx.globalAlpha = 1;
  }

  function drawDirectionHint() {
    if (state !== 'playing' || score > 3) return;
    ctx.font = '14px -apple-system, sans-serif';
    ctx.fillStyle = 'rgba(255,255,255,0.35)';
    ctx.textAlign = 'center';
    ctx.fillText('👆 Touche pour inverser', cx, window.innerHeight - 40);
  }

  function render() {
    ctx.save();
    if (shake > 0.5) {
      ctx.translate(
        (Math.random() - 0.5) * shake,
        (Math.random() - 0.5) * shake
      );
    }

    drawBackground();
    drawSun();
    drawOrbit();
    drawHazards();
    drawStars();
    drawPlayer();
    drawParticles();
    drawDirectionHint();

    ctx.restore();
  }

  function loop(timestamp) {
    const dt = lastTime ? Math.min((timestamp - lastTime) / 16.67, 3) : 1;
    lastTime = timestamp;
    update(dt);
    render();
    requestAnimationFrame(loop);
  }

  function flip() {
    if (state === 'playing') {
      direction *= -1;
      const pos = playerPos();
      spawnParticles(pos.x, pos.y, '#66ccff', 6);
    }
  }

  function handleTap(e) {
    if (e.target.closest('.btn')) return;
    e.preventDefault();
    flip();
  }

  playBtn.addEventListener('click', startGame);
  retryBtn.addEventListener('click', startGame);

  canvas.addEventListener('touchstart', handleTap, { passive: false });
  canvas.addEventListener('click', handleTap);
  document.addEventListener('keydown', (e) => {
    if (e.code === 'Space') {
      e.preventDefault();
      if (state === 'menu') startGame();
      else if (state === 'gameover') startGame();
      else flip();
    }
  });

  window.addEventListener('resize', resize);
  resize();
  requestAnimationFrame(loop);
})();
