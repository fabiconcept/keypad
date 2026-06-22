document.addEventListener('DOMContentLoaded', () => {
  const kbBase = document.getElementById('kb-base');
  const kb3d = document.getElementById('kb3d');
  if (!kbBase && !kb3d) return;
  let heroShift = false;
  let heroCaps = false;

  function updateHeroKeys() {
    if (!kbBase) return;
    const keys = kbBase.querySelectorAll('.k[data-char]');
    keys.forEach(k => {
      const ch = k.getAttribute('data-char');
      const sh = k.getAttribute('data-shift');
      if (!sh) return;
      const isLetter = ch.length === 1 && /[a-z]/i.test(ch);
      const showShift = isLetter ? (heroCaps ? !heroShift : heroShift) : heroShift;
      k.textContent = showShift ? sh : ch;
    });
    if (heroCaps) { kbBase.classList.add('caps-on'); } else { kbBase.classList.remove('caps-on'); }
  }

  function update3DKeys() {
    if (!kb3d) return;
    const keys = kb3d.querySelectorAll('.kb3d-key[data-char]');
    keys.forEach(k => {
      const ch = k.getAttribute('data-char');
      const sh = k.getAttribute('data-shift');
      if (!sh) return;
      const span = k.querySelector('span');
      const isLetter = ch.length === 1 && /[a-z]/i.test(ch);
      const showShift = isLetter ? (heroCaps ? !heroShift : heroShift) : heroShift;
      const newMain = showShift ? sh : ch;
      const newSpan = showShift ? ch : sh;
      for (const node of k.childNodes) { if (node.nodeType === 3) { node.textContent = newMain; break; } }
      if (span) span.textContent = newSpan;
    });
  }

  function updateAllKeys() {
    updateHeroKeys();
    update3DKeys();
  }

  // ── CapsLock detection (derives from real modifier state) ────
  const capsKey3d = kb3d ? kb3d.querySelector('[data-key="CapsLock"]') : null;
  function updateCapsVisual() {
    if (capsKey3d) capsKey3d.classList.toggle('kb3d-active', heroCaps);
  }

  // ── Keyboard event handlers ──────────────────────────────────
  document.addEventListener('keydown', e => {
    if (e.code === 'ShiftLeft' || e.code === 'ShiftRight') {
      if (!heroShift) { heroShift = true; updateAllKeys(); }
    }
    // Read real capslock from hardware — no toggle needed
    const realCaps = !!(e.getModifierState && e.getModifierState('CapsLock'));
    if (realCaps !== heroCaps) {
      heroCaps = realCaps;
      updateAllKeys();
      updateCapsVisual();
    }
  });
  document.addEventListener('keyup', e => {
    if (e.code === 'ShiftLeft' || e.code === 'ShiftRight') {
      heroShift = false;
      updateAllKeys();
    }
    // Re-check on keyup in case capslock toggled
    const realCaps = !!(e.getModifierState && e.getModifierState('CapsLock'));
    if (realCaps !== heroCaps) {
      heroCaps = realCaps;
      updateAllKeys();
      updateCapsVisual();
    }
  });

  // ── On-screen button clicks (simulated — no hardware event) ─
  if (kbBase) {
    kbBase.querySelectorAll('.hero-shift-btn').forEach(btn => {
      btn.addEventListener('click', () => { heroShift = !heroShift; updateAllKeys(); });
    });
    kbBase.querySelectorAll('.hero-caps-btn').forEach(btn => {
      btn.addEventListener('click', () => {
        heroCaps = !heroCaps;
        updateAllKeys();
        updateCapsVisual();
      });
    });
  }
  if (kb3d) {
    if (capsKey3d) capsKey3d.addEventListener('click', () => {
      heroCaps = !heroCaps;
      updateAllKeys();
      updateCapsVisual();
    });
    kb3d.querySelectorAll('[data-key="ShiftLeft"],[data-key="ShiftRight"]').forEach(btn => {
      btn.addEventListener('click', () => { heroShift = !heroShift; updateAllKeys(); });
    });
  }
  updateCapsVisual();
});

(() => {
  // Floating background keys
  const KEYS = ['Q','W','E','R','T','Y','U','I','O','P','A','S','D','F','G','H','J','K','L','Z','X','C','V','B','N','M','⌘','⌥','⇧','⇪','⏎','⌫','tab','ctrl','esc','spc'];
  const bg = document.getElementById('bg-keys');
  if (bg) {
    for (let i = 0; i < 20; i++) {
      const el = document.createElement('div');
      el.className = 'bg-key';
      el.textContent = KEYS[Math.floor(Math.random() * KEYS.length)];
      el.style.left = Math.random() * 100 + '%';
      el.style.setProperty('--rot', (Math.random() * 60 - 30) + 'deg');
      el.style.animationDuration = (14 + Math.random() * 20) + 's';
      el.style.animationDelay = (-Math.random() * 25) + 's';
      el.style.fontSize = (11 + Math.random() * 6) + 'px';
      bg.appendChild(el);
    }
  }

  // Letter effect for hero title and section titles
  function initLetterEffect(el) {
    const text = el.textContent;
    el.innerHTML = '';
    const letters = [];
    text.split('').forEach(ch => {
      if (ch === ' ') {
        const space = document.createTextNode(' ');
        el.appendChild(space);
        return;
      }
      const span = document.createElement('span');
      span.className = 'letter';
      span.textContent = ch;
      el.appendChild(span);
      letters.push(span);
    });
    letters.forEach((span, i) => {
      span.addEventListener('mouseenter', () => {
        span.classList.add('shrink');
        if (i > 0) letters[i - 1].classList.add('mild');
        if (i < letters.length - 1) letters[i + 1].classList.add('mild');
      });
      span.addEventListener('mouseleave', () => {
        span.classList.remove('shrink');
        if (i > 0) letters[i - 1].classList.remove('mild');
        if (i < letters.length - 1) letters[i + 1].classList.remove('mild');
      });
    });
  }

  // Hero title
  const heroTitle = document.getElementById('hero-title');
  if (heroTitle) initLetterEffect(heroTitle);

  // Footer logo
  const footerLogo = document.getElementById('footer-logo');
  if (footerLogo) initLetterEffect(footerLogo);

  // Section titles - get text node after the dot
  document.querySelectorAll('.section-title').forEach(title => {
    // Clone node to get just the text content (excluding the dot span)
    const clone = title.cloneNode(true);
    const dot = clone.querySelector('.dot');
    if (dot) dot.remove();
    const text = clone.textContent.trim();
    if (!text) return;
    // Remove existing text nodes
    title.childNodes.forEach(node => {
      if (node.nodeType === 3) node.remove();
    });
    // Create a wrapper span for the text
    const wrapper = document.createElement('span');
    wrapper.textContent = text;
    title.appendChild(wrapper);
    initLetterEffect(wrapper);
  });

  // ═══════════════════════════════════════════════════════════════
  // 3D KEYBOARD — interactive rotation + key press detection
  // ═══════════════════════════════════════════════════════════════
  (() => {
    const kb3d = document.getElementById('kb3d');
    const kbStage = document.querySelector('.kb3d-stage');
    if (!kb3d || !kbStage) return;

    // ── State ───────────────────────────────────────────────────
    let targetX = 47.019;   // target rotateX
    let targetY = -3.011;   // target rotateY
    let currentX = 47.019;  // current (animated) rotateX
    let currentY = -3.011;  // current (animated) rotateY
    const MIN_ANGLE = -20;  // deg — pan limit
    const MAX_ANGLE = 90;   // deg — pan limit
    const MIN_ANGLE_Y = -25;
    const MAX_ANGLE_Y = 25;
    const LERP = 0.08;      // easing factor (0–1, lower = smoother)
    let hovering = false;
    let rafId = null;

    function clamp(v, min, max) { return Math.max(min, Math.min(max, v)); }

    // ── Mouse tracking ──────────────────────────────────────────
    let baseX = 12;  // position when mouse entered
    let baseY = 0;
    kbStage.addEventListener('mouseenter', () => { 
      hovering = true;
      baseX = currentX;
      baseY = currentY;
    });
    kbStage.addEventListener('mouseleave', () => {
      hovering = false;
    });
    kbStage.addEventListener('mousemove', e => {
      if (!hovering) return;
      const rect = kbStage.getBoundingClientRect();
      // Normalized position: -1 to 1
      const nx = ((e.clientX - rect.left) / rect.width) * 2 - 1;
      const ny = ((e.clientY - rect.top) / rect.height) * 2 - 1;
      // Map to angle range with offset (dead zone in center)
      const offset = 0.15; // dead zone — mouse must move past 15% to start panning
      const sx = clamp((Math.abs(nx) - offset) / (1 - offset) * Math.sign(nx), -1, 1);
      const sy = clamp((Math.abs(ny) - offset) / (1 - offset) * Math.sign(ny), -1, 1);
      targetY = clamp(baseY + sx * MAX_ANGLE_Y, MIN_ANGLE, MAX_ANGLE);
      targetX = clamp(baseX + sy * 5, MIN_ANGLE, MAX_ANGLE);
    });

    // ── Animation loop (ease start + ease end via lerp) ─────────
    function animate() {
      // Lerp: current += (target - current) * factor
      // Ease-in: starts slow (small diff), accelerates
      // Ease-out: ends slow (small diff), decelerates
      currentX += (targetX - currentX) * LERP;
      currentY += (targetY - currentY) * LERP;

      // Snap when very close to avoid infinite tiny updates
      if (Math.abs(targetX - currentX) < 0.01) currentX = targetX;
      if (Math.abs(targetY - currentY) < 0.01) currentY = targetY;

      kb3d.style.transform = `rotateX(${currentX.toFixed(3)}deg) rotateY(${currentY.toFixed(3)}deg)`;
      rafId = requestAnimationFrame(animate);
    }
    rafId = requestAnimationFrame(animate);

    // ── Button controls (also use easing) ────────────────────────
    const step = 10;
    document.getElementById('kb3d-up')?.addEventListener('click', () => { targetX = clamp(targetX + step, MIN_ANGLE, MAX_ANGLE); });
    document.getElementById('kb3d-down')?.addEventListener('click', () => { targetX = clamp(targetX - step, MIN_ANGLE, MAX_ANGLE); });
    document.getElementById('kb3d-left')?.addEventListener('click', () => { targetY = clamp(targetY - step, MIN_ANGLE, MAX_ANGLE); });
    document.getElementById('kb3d-right')?.addEventListener('click', () => { targetY = clamp(targetY + step, MIN_ANGLE, MAX_ANGLE); });
    document.getElementById('kb3d-reset')?.addEventListener('click', () => { targetX = 47.019; targetY = -3.011; });

    // ── Arrow key rotation ──────────────────────────────────────
    window.addEventListener('keydown', e => {
      if (e.target.closest('.viewer-overlay') || e.target.closest('.kb3d-output')) return;
      switch (e.code) {
        case 'ArrowUp': e.preventDefault(); targetX = clamp(targetX + step, MIN_ANGLE, MAX_ANGLE); break;
        case 'ArrowDown': e.preventDefault(); targetX = clamp(targetX - step, MIN_ANGLE, MAX_ANGLE); break;
        case 'ArrowLeft': e.preventDefault(); targetY = clamp(targetY - step, MIN_ANGLE, MAX_ANGLE); break;
        case 'ArrowRight': e.preventDefault(); targetY = clamp(targetY + step, MIN_ANGLE, MAX_ANGLE); break;
      }
    });

    // ── Click keys to simulate press ────────────────────────────
    const kbOutput = document.getElementById('kb3d-output');
    const kbToggle = document.getElementById('kb3d-toggle');
    if (kbToggle && kbOutput) {
      kbToggle.addEventListener('click', () => {
        const visible = kbOutput.style.display !== 'none';
        kbOutput.style.display = visible ? 'none' : 'block';
        kbToggle.textContent = visible ? 'Show' : 'Hide';
      });
    }
    const keyMap = {
      'Backquote': '`', 'Digit1': '1', 'Digit2': '2', 'Digit3': '3', 'Digit4': '4',
      'Digit5': '5', 'Digit6': '6', 'Digit7': '7', 'Digit8': '8', 'Digit9': '9',
      'Digit0': '0', 'Minus': '-', 'Equal': '=', 'Backspace': 'Backspace',
      'Tab': '\t', 'KeyQ': 'q', 'KeyW': 'w', 'KeyE': 'e', 'KeyR': 'r',
      'KeyT': 't', 'KeyY': 'y', 'KeyU': 'u', 'KeyI': 'i', 'KeyO': 'o',
      'KeyP': 'p', 'BracketLeft': '[', 'BracketRight': ']', 'Backslash': '\\',
      'CapsLock': 'CapsLock', 'KeyA': 'a', 'KeyS': 's', 'KeyD': 'd', 'KeyF': 'f',
      'KeyG': 'g', 'KeyH': 'h', 'KeyJ': 'j', 'KeyK': 'k', 'KeyL': 'l',
      'Semicolon': ';', 'Quote': "'", 'Enter': '\n',
      'ShiftLeft': 'Shift', 'KeyZ': 'z', 'KeyX': 'x', 'KeyC': 'c', 'KeyV': 'v',
      'KeyB': 'b', 'KeyN': 'n', 'KeyM': 'm', 'Comma': ',', 'Period': '.',
      'Slash': '/', 'ShiftRight': 'Shift',
      'ControlLeft': 'Control', 'AltLeft': 'Alt', 'Space': ' ',
      'AltRight': 'Alt', 'ControlRight': 'Control'
    };

    function typeKey(code) {
      if (!kbOutput) return;
      const val = keyMap[code] || '';
      if (code === 'Backspace') {
        const text = kbOutput.textContent;
        kbOutput.textContent = text.slice(0, -1);
      } else if (code === 'Enter') {
        kbOutput.textContent += '\n';
      } else if (val && !['Shift', 'Control', 'Alt', 'CapsLock', 'Tab'].includes(val)) {
        kbOutput.textContent += val;
      }
      kbOutput.scrollTop = kbOutput.scrollHeight;
    }

    kb3d.querySelectorAll('.kb3d-key').forEach(keyEl => {
      const code = keyEl.dataset.key;
      keyEl.addEventListener('mousedown', () => {
        keyEl.classList.add('kb3d-active');
        typeKey(code);
        const ch = keyEl.getAttribute('data-char') || keyEl.textContent.trim().toLowerCase();
        playKeySound(ch);
      });
      keyEl.addEventListener('mouseup', () => {
        keyEl.classList.remove('kb3d-active');
      });
      keyEl.addEventListener('mouseleave', () => {
        keyEl.classList.remove('kb3d-active');
      });
    });
  })();

  // ── Physical key press → highlight matching 3D key ──────────
  (() => {
    const kb3d = document.getElementById('kb3d');
    if (!kb3d) return;

    window.addEventListener('keydown', e => {
      if (e.target.closest('.viewer-overlay') || e.target.closest('.kb3d-output')) return;
      const key = kb3d.querySelector(`[data-key="${e.code}"]`);
      if (key) {
        key.classList.add('kb3d-active');
        const ch = key.getAttribute('data-char') || key.textContent.trim().toLowerCase();
        playKeySound(ch);
        // Also type into output if visible
        const out = document.getElementById('kb3d-output');
        if (out && out.style.display !== 'none') {
          const keyMap = {
            'Backquote': '`', 'Digit1': '1', 'Digit2': '2', 'Digit3': '3', 'Digit4': '4',
            'Digit5': '5', 'Digit6': '6', 'Digit7': '7', 'Digit8': '8', 'Digit9': '9',
            'Digit0': '0', 'Minus': '-', 'Equal': '=', 'Space': ' ',
            'KeyQ': 'q', 'KeyW': 'w', 'KeyE': 'e', 'KeyR': 'r', 'KeyT': 't',
            'KeyY': 'y', 'KeyU': 'u', 'KeyI': 'i', 'KeyO': 'o', 'KeyP': 'p',
            'BracketLeft': '[', 'BracketRight': ']', 'Backslash': '\\',
            'KeyA': 'a', 'KeyS': 's', 'KeyD': 'd', 'KeyF': 'f', 'KeyG': 'g',
            'KeyH': 'h', 'KeyJ': 'j', 'KeyK': 'k', 'KeyL': 'l',
            'Semicolon': ';', 'Quote': "'",
            'KeyZ': 'z', 'KeyX': 'x', 'KeyC': 'c', 'KeyV': 'v',
            'KeyB': 'b', 'KeyN': 'n', 'KeyM': 'm', 'Comma': ',', 'Period': '.', 'Slash': '/'
          };
          const v = keyMap[e.code];
          if (v) out.textContent += v;
          else if (e.code === 'Backspace') out.textContent = out.textContent.slice(0, -1);
          else if (e.code === 'Enter') out.textContent += '\n';
        }
      }
    });
    window.addEventListener('keyup', e => {
      const key = kb3d.querySelector(`[data-key="${e.code}"]`);
      if (key) key.classList.remove('kb3d-active');
    });
  })();

  // ═══════════════════════════════════════════════════════════════
  // VERLET ROPE SIMULATION — position-based dynamics
  // ═══════════════════════════════════════════════════════════════
  //
  // Verlet integration: x(t+Δt) = 2·x(t) − x(t−Δt) + a·Δt²
  //   — no velocity storage needed (implicit in position delta)
  //   — unconditionally stable for constraint solving
  //
  // Distance constraint (Jacobsen 2001):
  //   ||p₁ − p₂|| = d  →  correct each point by ±Δ along normal
  //   Δ = (||p₁ − p₂|| − d) / ||p₁ − p₂|| · 0.5
  //
  // Gravity: a = (0, g) — constant downward acceleration
  // Damping: v *= μ each frame (μ ≈ 0.985 simulates air resistance)
  //
  (() => {
    const svg = document.getElementById('kb-rope');
    const ropePath = document.getElementById('rope-path');
    const anchorOuter = document.getElementById('rope-anchor-outer');
    const anchorInner = document.getElementById('rope-anchor-inner');
    const kbBase = document.getElementById('kb-base');
    const kbWrap = document.getElementById('kb-wrap');
    if (!svg || !ropePath || !kbBase) return;

    // ── Simulation parameters ───────────────────────────────────
    const SEGMENTS = 16;              // number of rope segments
    const GRAVITY = 0.6;              // px/frame² — gravitational acceleration
    const DAMPING = 0.9;              // velocity decay per frame (air resistance)
    const ITERATIONS = 20;            // constraint solver iterations per frame
    const ROPE_TOP = 40;              // px from top of kb-wrap — anchor point

    // ── Rope points ─────────────────────────────────────────────
    let points = [];
    let anchorX = 0;
    let ropeRestLen = 0;

    function initRope() {
      const wrapRect = kbWrap.getBoundingClientRect();
      anchorX = wrapRect.width / 2;
      const ropeHeight = 45; // px — rope length
      ropeRestLen = ropeHeight / SEGMENTS;

      points = [];
      for (let i = 0; i <= SEGMENTS; i++) {
        points.push({
          x: anchorX,
          y: ROPE_TOP + i * ropeRestLen,
          px: anchorX,
          py: ROPE_TOP + i * ropeRestLen,
          pinned: i === 0
        });
      }

      // Anchor circles
      anchorOuter.setAttribute('cx', anchorX);
      anchorOuter.setAttribute('cy', ROPE_TOP);
      anchorInner.setAttribute('cx', anchorX);
      anchorInner.setAttribute('cy', ROPE_TOP);
    }

    // Recalculate anchor on resize
    function onResize() {
      const wrapRect = kbWrap.getBoundingClientRect();
      anchorX = wrapRect.width / 2;
      points[0].x = anchorX;
      points[0].px = anchorX;
      anchorOuter.setAttribute('cx', anchorX);
      anchorInner.setAttribute('cx', anchorX);
    }
    window.addEventListener('resize', onResize);

    // ── Verlet integration ──────────────────────────────────────
    // x_new = x + (x − px) · damping + a · Δt²
    // (Δt = 1 frame, so a · Δt² = a)
    function integrate() {
      const tip = points[points.length - 1];
      for (const p of points) {
        if (p.pinned) continue;
        if (p === tip && dragging) continue;
        const vx = (p.x - p.px) * DAMPING;
        const vy = (p.y - p.py) * DAMPING;
        p.px = p.x;
        p.py = p.y;
        p.x += vx;
        p.y += vy + GRAVITY;
      }
    }

    // ── Distance constraints ────────────────────────────────────
    // For each segment pair, correct positions to maintain rest length
    // Uses Jacobi-style parallel correction (half Δ to each point)
    function constrain() {
      for (let iter = 0; iter < ITERATIONS; iter++) {
        for (let i = 0; i < points.length - 1; i++) {
          const a = points[i];
          const b = points[i + 1];
          const dx = b.x - a.x;
          const dy = b.y - a.y;
          const dist = Math.sqrt(dx * dx + dy * dy) || 0.001;
          const diff = (dist - ropeRestLen) / dist * 0.5;
          const ox = dx * diff;
          const oy = dy * diff;
          if (!a.pinned && !(i === 0 && dragging)) { a.x += ox; a.y += oy; }
          if (!(i + 1 === points.length - 1 && dragging)) { b.x -= ox; b.y -= oy; }
        }
        // Re-pin anchor
        points[0].x = anchorX;
        points[0].y = ROPE_TOP;
      }
    }

    // ── Render ──────────────────────────────────────────────────
    function render() {
      // Build smooth SVG path through rope points
      let d = `M ${points[0].x.toFixed(2)} ${points[0].y.toFixed(2)}`;
      for (let i = 1; i < points.length; i++) {
        d += ` L ${points[i].x.toFixed(2)} ${points[i].y.toFixed(2)}`;
      }
      ropePath.setAttribute('d', d);

      // Position keyboard at rope tip
      const tip = points[points.length - 1];
      const kbWidth = kbBase.offsetWidth;
      const left = tip.x - kbWidth / 2;
      const top = tip.y;
      kbBase.style.left = left.toFixed(2) + 'px';
      kbBase.style.top = top.toFixed(2) + 'px';
    }

    // ── Drag interaction ────────────────────────────────────────
    let dragging = false;
    let dragOffX = 0;
    let dragOffY = 0;

    function tip() { return points[points.length - 1]; }

    function isOnKeyboard(mx, my) {
      const t = tip();
      const kbRect = kbBase.getBoundingClientRect();
      const w = kbRect.width || 540;
      const h = kbRect.height || 160;
      return mx >= t.x - w / 2 - 8 && mx <= t.x + w / 2 + 8 &&
             my >= t.y - 8 && my <= t.y + h + 8;
    }

    function getCanvasPos(e) {
      const wrapRect = kbWrap.getBoundingClientRect();
      const scaleX = kbWrap.offsetWidth / wrapRect.width;
      const scaleY = kbWrap.offsetHeight / wrapRect.height;
      if (e.touches) {
        return {
          x: (e.touches[0].clientX - wrapRect.left) * scaleX,
          y: (e.touches[0].clientY - wrapRect.top) * scaleY
        };
      }
      return {
        x: (e.clientX - wrapRect.left) * scaleX,
        y: (e.clientY - wrapRect.top) * scaleY
      };
    }

    function onDragStart(e) {
      const p = getCanvasPos(e);
      if (isOnKeyboard(p.x, p.y)) {
        e.preventDefault();
        dragging = true;
        const t = tip();
        dragOffX = t.x - p.x;
        dragOffY = t.y - p.y;
        kbBase.style.cursor = 'grabbing';
      }
    }

    function onDragMove(e) {
      if (!dragging) return;
      e.preventDefault();
      const p = getCanvasPos(e);
      const t = tip();
      t.x = p.x + dragOffX;
      t.y = p.y + dragOffY;
      t.px = t.x;
      t.py = t.y;
    }

    function onDragEnd() {
      dragging = false;
      kbBase.style.cursor = 'grab';
    }

    // ── Bind events ─────────────────────────────────────────────
    kbBase.addEventListener('mousedown', onDragStart);
    kbBase.addEventListener('touchstart', onDragStart, { passive: false });
    window.addEventListener('mousemove', onDragMove);
    window.addEventListener('touchmove', onDragMove, { passive: false });
    window.addEventListener('mouseup', onDragEnd);
    window.addEventListener('touchend', onDragEnd);

    // Hover cursor
    kbBase.addEventListener('mousemove', e => {
      if (dragging) return;
      const p = getCanvasPos(e);
      kbBase.style.cursor = isOnKeyboard(p.x, p.y) ? 'grab' : 'default';
    });

    // ── Animation loop ──────────────────────────────────────────
    function loop() {
      integrate();
      constrain();
      render();
      requestAnimationFrame(loop);
    }

    // ── Init ────────────────────────────────────────────────────
    initRope();
    requestAnimationFrame(loop);
  })();

  // ── Keyboard Sound System (DRMFSLTD) ──────────────────────────
  const NOTE_FREQS = {
    do: 261.63, re: 293.66, mi: 329.63, fa: 349.23,
    sol: 392.00, la: 440.00, ti: 493.88, do2: 523.25
  };
  const KEY_NOTE_MAP = {
    'q':'do','w':'re','e':'mi','r':'fa','t':'sol','y':'la','u':'ti','i':'do2',
    'a':'do','s':'re','d':'mi','f':'fa','g':'sol','h':'la','j':'ti','k':'do2',
    'z':'do','x':'re','c':'mi','v':'fa','b':'sol','n':'la','m':'ti',
    '1':'do','2':'re','3':'mi','4':'fa','5':'sol','6':'la','7':'ti','8':'do2',
    '9':'do','0':'re','-':'mi','=':'fa',
    '[':'sol',']':'la','\\':'ti',
    ';':'do2',',':'re','.':'mi','/':'fa',
    '`':'do'
  };

  let _audioCtx;
  function getAudioCtx() {
    if (!_audioCtx) _audioCtx = new (window.AudioContext || window.webkitAudioContext)();
    return _audioCtx;
  }
  function playKeySound(keyChar) {
    try {
      const note = KEY_NOTE_MAP[keyChar] || 'do';
      const freq = NOTE_FREQS[note] || 261.63;
      const ctx = getAudioCtx();
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();
      osc.type = 'sine';
      osc.frequency.value = freq;
      gain.gain.setValueAtTime(0.06, ctx.currentTime);
      gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.12);
      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start();
      osc.stop(ctx.currentTime + 0.12);
    } catch(e) {}
  }

  document.querySelectorAll('.k').forEach(key => {
    key.addEventListener('mousedown', () => {
      key.classList.add('pressed');
      const ch = key.getAttribute('data-char') || key.textContent.trim().toLowerCase();
      playKeySound(ch);
    });
    key.addEventListener('mouseup', () => key.classList.remove('pressed'));
    key.addEventListener('mouseleave', () => key.classList.remove('pressed'));
    key.addEventListener('touchstart', e => { e.preventDefault(); key.classList.add('pressed'); }, {passive:false});
    key.addEventListener('touchend', () => key.classList.remove('pressed'));
  });

  // Settings tabs
  // Settings tray tabs
  document.querySelectorAll('.ttab').forEach(tab => {
    tab.addEventListener('click', () => {
      document.querySelectorAll('.ttab').forEach(t => t.classList.remove('active'));
      tab.classList.add('active');
      document.querySelectorAll('.tray-settings-img').forEach(p => p.classList.remove('active'));
      document.querySelector(`.tray-settings-img[data-ttab="${tab.dataset.ttab}"]`)?.classList.add('active');
    });
  });

  // Tray toggle
  const trayLid = document.getElementById('tray-lid');
  const traySurface = document.getElementById('tray-surface');
  const trayBtn = document.getElementById('tray-toggle');
  trayBtn?.addEventListener('click', () => {
    trayLid.classList.toggle('open');
    traySurface.classList.toggle('expanded');
    trayBtn.textContent = traySurface.classList.contains('expanded') ? '\u25B2 Close' : '\u25BC Open';
  });

  // Screenshots tabs
  document.querySelectorAll('.ss-tab').forEach(tab => {
    tab.addEventListener('click', () => {
      document.querySelectorAll('.ss-tab').forEach(t => t.classList.remove('active'));
      tab.classList.add('active');
      const ssVal = tab.dataset.ss;
      document.querySelectorAll('.ss-item').forEach(item => {
        if (ssVal === '0' || item.dataset.ss === ssVal) {
          item.classList.add('active');
        } else {
          item.classList.remove('active');
        }
      });
    });
  });

  // Photo viewer
  const allImages = [];
  let currentIndex = 0;
  let lastViewedIndex = -1;

  document.querySelectorAll('img[src]').forEach((img, i) => {
    if (img.closest('.viewer-overlay')) return;
    if (!img.src || img.src.includes('data:')) return;
    const idx = allImages.length;
    allImages.push({ src: img.src, alt: img.alt || img.src.split('/').pop() });
    img.style.cursor = 'pointer';
    img.addEventListener('click', (e) => {
      e.stopPropagation();
      openViewer(idx);
    });
  });

  const viewer = document.getElementById('viewer');
  const viewerImg = document.getElementById('viewer-img');
  const viewerCounter = document.getElementById('viewer-counter');
  const viewerTitle = document.getElementById('viewer-title');
  const viewerThumbs = document.getElementById('viewer-thumbs');

  allImages.forEach((item, i) => {
    const thumb = document.createElement('img');
    thumb.className = 'viewer-thumb';
    thumb.src = item.src;
    thumb.alt = item.alt;
    thumb.addEventListener('click', () => goTo(i));
    viewerThumbs.appendChild(thumb);
  });

  function openViewer(index) {
    if (!allImages[index]) return;
    currentIndex = index;
    lastViewedIndex = index;
    viewer.classList.add('open');
    document.body.style.overflow = 'hidden';
    requestAnimationFrame(() => updateViewer());
  }
  function closeViewer() {
    lastViewedIndex = currentIndex;
    viewer.classList.remove('open');
    document.body.style.overflow = '';
  }
  function goTo(index) {
    if (index < 0) index = allImages.length - 1;
    if (index >= allImages.length) index = 0;
    const dir = index > currentIndex ? 'left' : 'right';
    currentIndex = index;
    lastViewedIndex = index;
    viewerImg.classList.add(dir === 'left' ? 'slide-left' : 'slide-right');
    setTimeout(() => {
      updateViewer();
      viewerImg.classList.remove('slide-left', 'slide-right');
    }, 150);
  }
  function updateViewer() {
    if (!allImages[currentIndex]) return;
    const item = allImages[currentIndex];
    viewerImg.src = item.src;
    viewerImg.alt = item.alt;
    viewerCounter.textContent = `${currentIndex + 1} / ${allImages.length}`;
    viewerTitle.textContent = item.alt;
    viewerThumbs.querySelectorAll('.viewer-thumb').forEach((t, i) => t.classList.toggle('active', i === currentIndex));
    const active = viewerThumbs.querySelector('.viewer-thumb.active');
    if (active) active.scrollIntoView({ behavior: 'smooth', block: 'nearest', inline: 'center' });
  }

  document.getElementById('viewer-close').addEventListener('click', closeViewer);
  document.getElementById('viewer-prev').addEventListener('click', () => goTo(currentIndex - 1));
  document.getElementById('viewer-next').addEventListener('click', () => goTo(currentIndex + 1));
  viewer.addEventListener('click', e => { if (e.target === viewer || e.target.classList.contains('viewer-stage')) closeViewer(); });
  document.addEventListener('keydown', e => {
    if (!viewer.classList.contains('open')) return;
    if (e.key === 'Escape') closeViewer();
    if (e.key === 'ArrowLeft') goTo(currentIndex - 1);
    if (e.key === 'ArrowRight') goTo(currentIndex + 1);
  });
  let touchX = 0;
  viewer.addEventListener('touchstart', e => { touchX = e.touches[0].clientX; }, {passive:true});
  viewer.addEventListener('touchend', e => {
    const dx = e.changedTouches[0].clientX - touchX;
    if (Math.abs(dx) > 50) dx > 0 ? goTo(currentIndex - 1) : goTo(currentIndex + 1);
  });
})();

document.addEventListener('DOMContentLoaded', () => {
  const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        entry.target.classList.add('visible');
      }
    });
  }, { threshold: 0.1, rootMargin: '0px 0px -40px 0px' });

  document.querySelectorAll('.reveal, .reveal-left, .reveal-right, .reveal-scale, .reveal-up').forEach(el => {
    observer.observe(el);
  });
});

// Floating hanging hero - show after scrolling past hero
(() => {
  const hang = document.getElementById('floating-hang');
  const svg = document.getElementById('floating-hang-svg');
  const ropePath = document.getElementById('hang-rope-path');
  const anchorOuter = document.getElementById('hang-anchor-outer');
  const anchorInner = document.getElementById('hang-anchor-inner');
  const img = document.getElementById('floating-hang-img');
  if (!hang || !svg || !ropePath || !img) return;
  if (window.innerWidth < 768) return;

  const hero = document.querySelector('.hero');
  if (!hero) return;

  // Show/hide based on scroll position
  function checkScroll() {
    const heroBottom = hero.getBoundingClientRect().bottom;
    if (heroBottom < 0) {
      hang.classList.add('show');
    } else {
      hang.classList.remove('show');
    }
  }
  window.addEventListener('scroll', checkScroll, { passive: true });
  checkScroll();

  // Verlet rope simulation
  const SEGMENTS = 12;
  const GRAVITY = 0.5;
  const DAMPING = 0.92;
  const ITERATIONS = 15;
  const ROPE_TOP = 10;
  const ANCHOR_X = 0;

  let points = [];
  let ropeRestLen = 0;
  let dragging = false;
  let wasDragged = false;
  let dragStartX = 0;
  let dragStartY = 0;
  let dragOffX = 0;
  let dragOffY = 0;

  function init() {
    const ropeHeight = 100;
    ropeRestLen = ropeHeight / SEGMENTS;
    points = [];
    for (let i = 0; i <= SEGMENTS; i++) {
      points.push({
        x: ANCHOR_X,
        y: ROPE_TOP + i * ropeRestLen,
        px: ANCHOR_X,
        py: ROPE_TOP + i * ropeRestLen,
        pinned: i === 0
      });
    }
    anchorOuter.setAttribute('cx', ANCHOR_X);
    anchorOuter.setAttribute('cy', ROPE_TOP);
    anchorInner.setAttribute('cx', ANCHOR_X);
    anchorInner.setAttribute('cy', ROPE_TOP);
  }

  function integrate() {
    const tip = points[points.length - 1];
    for (const p of points) {
      if (p.pinned) continue;
      if (p === tip && dragging) continue;
      const vx = (p.x - p.px) * DAMPING;
      const vy = (p.y - p.py) * DAMPING;
      p.px = p.x;
      p.py = p.y;
      p.x += vx;
      p.y += vy + GRAVITY;
    }
  }

  function constrain() {
    for (let iter = 0; iter < ITERATIONS; iter++) {
      for (let i = 0; i < points.length - 1; i++) {
        const a = points[i];
        const b = points[i + 1];
        const dx = b.x - a.x;
        const dy = b.y - a.y;
        const dist = Math.sqrt(dx * dx + dy * dy) || 0.001;
        const diff = (dist - ropeRestLen) / dist * 0.5;
        const ox = dx * diff;
        const oy = dy * diff;
        if (!a.pinned && !(i === 0 && dragging)) { a.x += ox; a.y += oy; }
        if (!(i + 1 === points.length - 1 && dragging)) { b.x -= ox; b.y -= oy; }
      }
      points[0].x = ANCHOR_X;
      points[0].y = ROPE_TOP;
    }
  }

  function render() {
    let d = `M ${points[0].x.toFixed(2)} ${points[0].y.toFixed(2)}`;
    for (let i = 1; i < points.length; i++) {
      d += ` L ${points[i].x.toFixed(2)} ${points[i].y.toFixed(2)}`;
    }
    ropePath.setAttribute('d', d);

    const tip = points[points.length - 1];
    const imgW = img.offsetWidth || 280;
    img.style.left = (tip.x - imgW / 2).toFixed(2) + 'px';
    img.style.top = tip.y.toFixed(2) + 'px';
  }

  function tip() { return points[points.length - 1]; }

  function isOnImage(mx, my) {
    const t = tip();
    const imgW = img.offsetWidth || 280;
    const imgH = img.offsetHeight || 200;
    return mx >= t.x - imgW / 2 - 8 && mx <= t.x + imgW / 2 + 8 &&
           my >= t.y - 8 && my <= t.y + imgH + 8;
  }

  function getPos(e) {
    const rect = hang.getBoundingClientRect();
    if (e.touches) {
      return { x: e.touches[0].clientX - rect.left, y: e.touches[0].clientY - rect.top };
    }
    return { x: e.clientX - rect.left, y: e.clientY - rect.top };
  }

  function onDragStart(e) {
    const p = getPos(e);
    if (isOnImage(p.x, p.y)) {
      e.preventDefault();
      dragging = true;
      wasDragged = false;
      dragStartX = p.x;
      dragStartY = p.y;
      const t = tip();
      dragOffX = t.x - p.x;
      dragOffY = t.y - p.y;
      img.style.cursor = 'grabbing';
    }
  }

  function onDragMove(e) {
    if (!dragging) return;
    e.preventDefault();
    const p = getPos(e);
    const dx = p.x - dragStartX;
    const dy = p.y - dragStartY;
    if (Math.abs(dx) > 3 || Math.abs(dy) > 3) wasDragged = true;
    const t = tip();
    t.x = p.x + dragOffX;
    t.y = p.y + dragOffY;
    t.px = t.x;
    t.py = t.y;
  }

  function onDragEnd() {
    dragging = false;
    img.style.cursor = 'grab';
  }

  img.addEventListener('mousedown', onDragStart);
  img.addEventListener('touchstart', onDragStart, { passive: false });
  window.addEventListener('mousemove', onDragMove);
  window.addEventListener('touchmove', onDragMove, { passive: false });
  window.addEventListener('mouseup', onDragEnd);
  window.addEventListener('touchend', onDragEnd);

  // Prevent photo viewer on drag
  img.addEventListener('click', (e) => {
    if (wasDragged) {
      e.stopPropagation();
      e.preventDefault();
    }
  }, true);

  img.addEventListener('mousemove', e => {
    if (dragging) return;
    const p = getPos(e);
    img.style.cursor = isOnImage(p.x, p.y) ? 'grab' : 'default';
  });

  function loop() {
    integrate();
    constrain();
    render();
    requestAnimationFrame(loop);
  }

  init();
  loop();
})();

// Blob parallax
(() => {
  const blobs = document.querySelectorAll('.blob');
  if (!blobs.length) return;

  let ticking = false;
  function update() {
    const scrollY = window.scrollY;
    blobs.forEach(blob => {
      const speed = parseFloat(blob.dataset.speed) || 0;
      const rect = blob.parentElement.getBoundingClientRect();
      const offset = (rect.top + scrollY) * speed;
      blob.style.transform = `translateY(${(scrollY * speed * 0.6).toFixed(1)}px) translateX(${(scrollY * speed * 0.2).toFixed(1)}px)`;
    });
    ticking = false;
  }

  window.addEventListener('scroll', () => {
    if (!ticking) {
      requestAnimationFrame(update);
      ticking = true;
    }
  }, { passive: true });

  update();
})();

// ═══════════════════════════════════════════════════════════════
// CAPSULE NAVBAR — show on scroll, scroll-spy, mobile menu
// ═══════════════════════════════════════════════════════════════
(() => {
  const navbar = document.getElementById('navbar');
  const hamburger = document.getElementById('nav-hamburger');
  const mobileMenu = document.getElementById('nav-mobile');
  if (!navbar) return;

  const hero = document.querySelector('.hero');
  const sections = document.querySelectorAll('[id]');
  const navLinks = document.querySelectorAll('.nav-links a, .nav-mobile a');

  // Show navbar after scrolling past hero
  function checkNavbar() {
    if (!hero) { navbar.classList.add('visible'); return; }
    const heroBottom = hero.getBoundingClientRect().bottom;
    if (heroBottom < 80) {
      navbar.classList.add('visible');
    } else {
      navbar.classList.remove('visible');
    }
  }

  // Scroll-spy: highlight active section link
  function scrollSpy() {
    let current = '';
    sections.forEach(section => {
      const top = section.offsetTop - 120;
      if (window.scrollY >= top) {
        current = section.getAttribute('id');
      }
    });
    navLinks.forEach(link => {
      link.classList.remove('active');
      if (link.getAttribute('href') === '#' + current) {
        link.classList.add('active');
      }
    });
  }

  // Smooth scroll for nav links
  navLinks.forEach(link => {
    link.addEventListener('click', e => {
      const href = link.getAttribute('href');
      if (href && href.startsWith('#')) {
        e.preventDefault();
        const target = document.querySelector(href);
        if (target) {
          target.scrollIntoView({ behavior: 'smooth', block: 'start' });
        }
        // Close mobile menu
        if (mobileMenu) mobileMenu.classList.remove('open');
        if (hamburger) hamburger.classList.remove('open');
      }
    });
  });

  // Hamburger toggle
  if (hamburger && mobileMenu) {
    hamburger.addEventListener('click', () => {
      hamburger.classList.toggle('open');
      mobileMenu.classList.toggle('open');
    });
    // Close on outside click
    document.addEventListener('click', e => {
      if (!navbar.contains(e.target)) {
        hamburger.classList.remove('open');
        mobileMenu.classList.remove('open');
      }
    });
  }

  window.addEventListener('scroll', () => {
    checkNavbar();
    scrollSpy();
  }, { passive: true });

  checkNavbar();
  scrollSpy();
})();

(() => {
  const SEGMENTS = 10;
  const GRAVITY = 0.12;
  const DAMPING = 0.93;
  const ITERATIONS = 10;
  const SPREAD = 0.25;
  const CENTER_X = 10;
  const HEIGHT = 60;

  document.querySelectorAll('.wire-divider').forEach(divider => {
    const svg = divider.querySelector('.rope-svg');
    const path = divider.querySelector('.wire-rope');
    if (!svg || !path) return;

    const points = [];
    for (let i = 0; i <= SEGMENTS; i++) {
      const y = (HEIGHT / SEGMENTS) * i;
      points.push({ x: CENTER_X, y, ox: CENTER_X, oy: y });
    }

    let dragging = false;
    let dragIdx = -1;

    function getMousePos(e) {
      const rect = svg.getBoundingClientRect();
      const clientY = e.touches ? e.touches[0].clientY : e.clientY;
      return ((clientY - rect.top) / rect.height) * HEIGHT;
    }

    function onDragStart(e) {
      e.preventDefault();
      dragging = true;
      const y = getMousePos(e);
      let minDist = Infinity;
      points.forEach((p, i) => {
        if (i === 0 || i === SEGMENTS) return;
        const d = Math.abs(p.y - y);
        if (d < minDist) { minDist = d; dragIdx = i; }
      });
    }

    divider.addEventListener('mousedown', onDragStart);
    divider.addEventListener('touchstart', onDragStart, { passive: false });

    function onDragMove(e) {
      if (!dragging || dragIdx < 0) return;
      e.preventDefault();
      points[dragIdx].y = getMousePos(e);
      points[dragIdx].x = CENTER_X + (Math.random() - 0.5) * 3;
    }

    window.addEventListener('mousemove', onDragMove);
    window.addEventListener('touchmove', onDragMove, { passive: false });

    function onDragEnd() { dragging = false; dragIdx = -1; }
    window.addEventListener('mouseup', onDragEnd);
    window.addEventListener('touchend', onDragEnd);

    function verlet() {
      for (let i = 1; i < SEGMENTS; i++) {
        if (dragging && i === dragIdx) continue;
        const p = points[i];
        const vx = (p.x - p.ox) * DAMPING;
        const vy = (p.y - p.oy) * DAMPING;
        p.ox = p.x;
        p.oy = p.y;
        p.x += vx + (Math.random() - 0.5) * 0.06;
        p.y += vy + GRAVITY;
        if (!isFinite(p.x) || !isFinite(p.y)) { p.x = CENTER_X; p.y = (HEIGHT / SEGMENTS) * i; p.ox = p.x; p.oy = p.y; }
      }
      points[0].x = CENTER_X; points[0].y = 0;
      points[SEGMENTS].x = CENTER_X; points[SEGMENTS].y = HEIGHT;
      for (let iter = 0; iter < ITERATIONS; iter++) {
        for (let i = 0; i < SEGMENTS; i++) {
          const a = points[i], b = points[i + 1];
          const dx = b.x - a.x, dy = b.y - a.y;
          const dist = Math.sqrt(dx * dx + dy * dy) || 0.001;
          const diff = (1 - dist) * SPREAD * 0.5;
          const ox = dx * diff, oy = dy * diff;
          if (!(dragging && i === 0)) { a.x -= ox; a.y -= oy; }
          if (!(dragging && i + 1 === SEGMENTS)) { b.x += ox; b.y += oy; }
        }
        points[0].x = CENTER_X; points[0].y = 0;
        points[SEGMENTS].x = CENTER_X; points[SEGMENTS].y = HEIGHT;
      }
    }

    function buildPath() {
      let d = `M${points[0].x.toFixed(1)},${points[0].y.toFixed(1)}`;
      for (let i = 1; i <= SEGMENTS; i++) {
        const prev = points[i - 1];
        const curr = points[i];
        const px = isFinite(prev.x) ? prev.x : CENTER_X;
        const py = isFinite(prev.y) ? prev.y : (HEIGHT / SEGMENTS) * (i - 1);
        const cx = isFinite(curr.x) ? curr.x : CENTER_X;
        const cy = isFinite(curr.y) ? curr.y : (HEIGHT / SEGMENTS) * i;
        const mx = (px + cx) / 2;
        const my = (py + cy) / 2;
        d += ` Q${px.toFixed(1)},${py.toFixed(1)} ${mx.toFixed(1)},${my.toFixed(1)}`;
      }
      return d;
    }

    // Init with sag
    for (let i = 1; i < SEGMENTS; i++) {
      const t = i / SEGMENTS;
      points[i].x = CENTER_X + Math.sin(t * Math.PI) * 2;
      points[i].ox = points[i].x;
    }

    (function loop() {
      verlet();
      path.setAttribute('d', buildPath());
      requestAnimationFrame(loop);
    })();
  });

  // ═══════════════════════════════════════════════════════════════
  // KEYBOARD-THEMED VIDEO PLAYER
  // ═══════════════════════════════════════════════════════════════
  (() => {
    const video = document.getElementById('kb-video');
    const overlay = document.getElementById('kb-video-overlay');
    const playBtn = document.getElementById('kb-video-play');
    const toggleBtn = document.getElementById('kb-video-toggle');
    const iconPlay = toggleBtn?.querySelector('.kb-icon-play');
    const iconPause = toggleBtn?.querySelector('.kb-icon-pause');
    const progress = document.getElementById('kb-video-progress');
    const progressBar = document.getElementById('kb-video-progress-bar');
    const progressThumb = document.getElementById('kb-video-progress-thumb');
    const timeDisplay = document.getElementById('kb-video-time');
    const fullscreenBtn = document.getElementById('kb-video-fullscreen');
    const iconExpand = fullscreenBtn?.querySelector('.kb-icon-expand');
    const iconShrink = fullscreenBtn?.querySelector('.kb-icon-shrink');
    const muteBtn = document.getElementById('kb-video-mute');
    const iconVolume = muteBtn?.querySelector('.kb-icon-volume');
    const iconMuted = muteBtn?.querySelector('.kb-icon-muted');
    const volumeSlider = document.getElementById('kb-video-volume-slider');
    const volumeFill = document.getElementById('kb-video-volume-fill');
    const speedBtn = document.getElementById('kb-video-speed-btn');
    const speedMenu = document.getElementById('kb-video-speed-menu');
    const speedContainer = document.getElementById('kb-video-speed');
    const kbOverlay = document.getElementById('kb-video-kb-overlay');
    const kbToggleBtn = document.getElementById('kb-video-kb-toggle');
    const player = document.getElementById('kb-video-player');
    if (!video || !player) return;

    let isSeeking = false;
    let hideControlsTimer = null;
    let lastVolume = 0.8;
    let isInView = true;
    let wasPlayingBeforeHide = false;

    // ── Helpers ──────────────────────────────────────────────
    function formatTime(s) {
      if (isNaN(s)) return '0:00';
      const m = Math.floor(s / 60);
      const sec = Math.floor(s % 60);
      return m + ':' + (sec < 10 ? '0' : '') + sec;
    }

    function clamp(v, min, max) { return Math.max(min, Math.min(max, v)); }

    // ── Play / Pause ─────────────────────────────────────────
    function togglePlay() {
      video.paused ? video.play() : video.pause();
    }

    function updatePlayIcon() {
      if (video.paused) {
        iconPlay.style.display = '';
        iconPause.style.display = 'none';
        overlay.classList.remove('hidden');
      } else {
        iconPlay.style.display = 'none';
        iconPause.style.display = '';
        overlay.classList.add('hidden');
      }
    }

    video.addEventListener('play', updatePlayIcon);
    video.addEventListener('pause', updatePlayIcon);

    playBtn?.addEventListener('click', (e) => { e.stopPropagation(); togglePlay(); });
    overlay?.addEventListener('click', togglePlay);
    video.addEventListener('click', togglePlay);
    toggleBtn?.addEventListener('click', togglePlay);

    // ── Progress bar ─────────────────────────────────────────
    function updateUI() {
      if (!isSeeking && video.duration) {
        const pct = (video.currentTime / video.duration) * 100;
        progressBar.style.width = pct + '%';
        progressThumb.style.left = pct + '%';
        timeDisplay.textContent = formatTime(video.currentTime) + ' / ' + formatTime(video.duration);
      }
    }

    function seekTo(e) {
      const rect = progress.getBoundingClientRect();
      const pct = clamp((e.clientX - rect.left) / rect.width, 0, 1);
      video.currentTime = pct * video.duration;
      progressBar.style.width = (pct * 100) + '%';
      progressThumb.style.left = (pct * 100) + '%';
    }

    progress?.addEventListener('mousedown', (e) => {
      isSeeking = true;
      seekTo(e);
      const onMove = (ev) => seekTo(ev);
      const onUp = () => { isSeeking = false; window.removeEventListener('mousemove', onMove); window.removeEventListener('mouseup', onUp); };
      window.addEventListener('mousemove', onMove);
      window.addEventListener('mouseup', onUp);
    });

    video.addEventListener('timeupdate', updateUI);
    video.addEventListener('loadedmetadata', updateUI);

    // ── Volume ───────────────────────────────────────────────
    function updateVolumeIcon() {
      if (video.muted || video.volume === 0) {
        iconVolume.style.display = 'none';
        iconMuted.style.display = '';
      } else {
        iconVolume.style.display = '';
        iconMuted.style.display = 'none';
      }
      volumeFill.style.width = (video.muted ? 0 : video.volume * 100) + '%';
    }

    muteBtn?.addEventListener('click', () => {
      if (video.muted) {
        video.muted = false;
        video.volume = lastVolume || 0.8;
      } else {
        lastVolume = video.volume;
        video.muted = true;
      }
      updateVolumeIcon();
    });

    volumeSlider?.addEventListener('mousedown', (e) => {
      const rect = volumeSlider.getBoundingClientRect();
      const setVol = (ev) => {
        const pct = clamp((ev.clientX - rect.left) / rect.width, 0, 1);
        video.volume = pct;
        video.muted = pct === 0;
        lastVolume = pct || lastVolume;
        updateVolumeIcon();
      };
      setVol(e);
      const onMove = (ev) => setVol(ev);
      const onUp = () => { window.removeEventListener('mousemove', onMove); window.removeEventListener('mouseup', onUp); };
      window.addEventListener('mousemove', onMove);
      window.addEventListener('mouseup', onUp);
    });

    video.addEventListener('volumechange', updateVolumeIcon);
    video.volume = 0.8;
    updateVolumeIcon();

    // ── Playback speed ───────────────────────────────────────
    let speedOpen = false;
    function toggleSpeed() {
      speedOpen = !speedOpen;
      speedContainer.classList.toggle('open', speedOpen);
    }
    function closeSpeed() {
      speedOpen = false;
      speedContainer.classList.remove('open');
    }

    speedBtn?.addEventListener('click', (e) => { e.stopPropagation(); toggleSpeed(); });

    speedMenu?.querySelectorAll('.kb-video-speed-option').forEach(opt => {
      opt.addEventListener('click', (e) => {
        e.stopPropagation();
        const spd = parseFloat(opt.dataset.speed);
        video.playbackRate = spd;
        speedBtn.textContent = spd === 1 ? '1x' : spd + 'x';
        speedMenu.querySelectorAll('.kb-video-speed-option').forEach(o => o.classList.remove('active'));
        opt.classList.add('active');
        closeSpeed();
      });
    });

    document.addEventListener('click', (e) => {
      if (!speedContainer?.contains(e.target)) closeSpeed();
    });

    // ── Keyboard overlay toggle ──────────────────────────────
    let kbOverlayVisible = false;
    kbToggleBtn?.addEventListener('click', () => {
      kbOverlayVisible = !kbOverlayVisible;
      kbOverlay.classList.toggle('show', kbOverlayVisible);
      kbToggleBtn.classList.toggle('active', kbOverlayVisible);
    });

    // Animate keyboard keys when video plays
    const kbKeys = kbOverlay?.querySelectorAll('.kb-video-kb-key');
    let kbAnimInterval = null;
    function startKbAnim() {
      if (kbAnimInterval) return;
      kbAnimInterval = setInterval(() => {
        if (!kbKeys || video.paused) return;
        const idx = Math.floor(Math.random() * kbKeys.length);
        const key = kbKeys[idx];
        key.classList.add('pressed');
        setTimeout(() => key.classList.remove('pressed'), 180);
      }, 120);
    }
    function stopKbAnim() {
      clearInterval(kbAnimInterval);
      kbAnimInterval = null;
      kbKeys?.forEach(k => k.classList.remove('pressed'));
    }
    video.addEventListener('play', startKbAnim);
    video.addEventListener('pause', stopKbAnim);

    // ── Fullscreen ───────────────────────────────────────────
    function updateFullscreenIcon() {
      const isFs = !!document.fullscreenElement;
      iconExpand.style.display = isFs ? 'none' : '';
      iconShrink.style.display = isFs ? '' : 'none';
    }

    fullscreenBtn?.addEventListener('click', () => {
      if (document.fullscreenElement) document.exitFullscreen();
      else player.requestFullscreen();
    });
    document.addEventListener('fullscreenchange', updateFullscreenIcon);

    // ── Auto-hide controls ───────────────────────────────────
    function showControls() {
      player.classList.remove('controls-hidden');
      clearTimeout(hideControlsTimer);
      if (!video.paused) {
        hideControlsTimer = setTimeout(() => {
          if (!video.paused) player.classList.add('controls-hidden');
        }, 3000);
      }
    }

    player.addEventListener('mousemove', showControls);
    player.addEventListener('mouseleave', () => {
      if (!video.paused) {
        hideControlsTimer = setTimeout(() => player.classList.add('controls-hidden'), 1000);
      }
    });
    video.addEventListener('play', showControls);
    video.addEventListener('pause', () => {
      clearTimeout(hideControlsTimer);
      player.classList.remove('controls-hidden');
    });

    // ── Keyboard shortcuts (only when in view) ──────────────
    player.addEventListener('keydown', (e) => {
      if (!isInView) return;
      if (e.target.closest('.kb-video-speed-menu')) return;
      switch (e.code) {
        case 'Space':
          e.preventDefault(); togglePlay(); break;
        case 'ArrowLeft':
          e.preventDefault(); video.currentTime = Math.max(0, video.currentTime - 5); break;
        case 'ArrowRight':
          e.preventDefault(); video.currentTime = Math.min(video.duration || 0, video.currentTime + 5); break;
        case 'ArrowUp':
          e.preventDefault(); video.volume = clamp(video.volume + 0.1, 0, 1); video.muted = false; updateVolumeIcon(); break;
        case 'ArrowDown':
          e.preventDefault(); video.volume = clamp(video.volume - 0.1, 0, 1); updateVolumeIcon(); break;
        case 'KeyF':
          fullscreenBtn?.click(); break;
        case 'KeyM':
          muteBtn?.click(); break;
        case 'KeyK':
          kbToggleBtn?.click(); break;
        case 'Comma':
          if (e.shiftKey) { const opts = speedMenu?.querySelectorAll('.kb-video-speed-option'); const cur = video.playbackRate; const speeds = [0.25,0.5,0.75,1,1.5,2]; const i = speeds.indexOf(cur); if (i > 0) opts?.[i-1]?.click(); }
          break;
        case 'Period':
          if (e.shiftKey) { const opts = speedMenu?.querySelectorAll('.kb-video-speed-option'); const cur = video.playbackRate; const speeds = [0.25,0.5,0.75,1,1.5,2]; const i = speeds.indexOf(cur); if (i < speeds.length-1) opts?.[i+1]?.click(); }
          break;
      }
      showControls();
    });

    // ── Double-click for fullscreen ──────────────────────────
    let lastClick = 0;
    video.addEventListener('click', (e) => {
      const now = Date.now();
      if (now - lastClick < 300) {
        fullscreenBtn?.click();
        e.stopPropagation();
      }
      lastClick = now;
    });

    // ── Visibility: pause when out of view, disable shortcuts ──
    const visibilityObserver = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        isInView = entry.isIntersecting;
        if (!isInView) {
          // Out of view: pause video, stop keyboard anim
          if (!video.paused) {
            wasPlayingBeforeHide = true;
            video.pause();
          }
          stopKbAnim();
          // Hide controls
          player.classList.add('controls-hidden');
          clearTimeout(hideControlsTimer);
        } else {
          // Back in view: resume if was playing
          if (wasPlayingBeforeHide) {
            wasPlayingBeforeHide = false;
            video.play().catch(() => {});
          }
        }
      });
    }, { threshold: 0.3 });

    visibilityObserver.observe(player);

    // Clean up on page unload
    window.addEventListener('beforeunload', () => {
      visibilityObserver.disconnect();
      video.pause();
    });
  })();
})();
