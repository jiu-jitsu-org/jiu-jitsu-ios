/* OSS 리액션 스티커 엔진 (움직임 연구용)
 * 띠 캐릭터 몸(흰 캡슐 + 검은 띠 + 띠 위 흰 선 눈)에 주짓수 동작 캐릭터의 얇은 고무호스 팔·다리,
 * 흰 장갑 손, 흰 신발을 붙여 손짓으로 리액션을 한다.
 * 한 장면 = 240×240 논리 좌표. 리액션마다 t(0~1, 한 바퀴) → 몸·팔·표정·효과를 돌려준다.
 * 스타일: A 소프트 3D · B 스포티 팝 · C 스트리트 스티커 */
(function () {
  const TAU = Math.PI * 2;
  const rad = (d) => (d * Math.PI) / 180;
  const clamp = (x, a = 0, b = 1) => Math.min(b, Math.max(a, x));
  const ss = (a, b, x) => { const t = clamp((x - a) / (b - a)); return t * t * (3 - 2 * t); };
  const seg = (t, a, b) => clamp((t - a) / (b - a));
  const hump = (t, a, b) => Math.sin(Math.PI * seg(t, a, b));
  const spring = (u) => (u <= 0 ? 0 : 1 - Math.exp(-5 * u) * Math.cos(9 * u));
  const eOut = (u) => 1 - Math.pow(1 - u, 3);
  const eIn = (u) => u * u * u;
  const eIO = (u) => (u < 0.5 ? 4 * u * u * u : 1 - Math.pow(-2 * u + 2, 3) / 2);
  const lerp = (a, b, k) => a + (b - a) * k;

  const INK = '#121317';
  const LIMB = '#2C2E34';
  const LEN = 100, WID = 50, NS = 36, LEGL = 28, GROUND = 214;
  const BAND0 = 0.64, BAND1 = 0.84, FACE = 0.74, SHOULDER = 0.5;

  const BELTS = {
    white: { label: '흰띠', body: '#F7F7F4', shade: '#C3C9D5', hi: '#FFFFFF', band: '#1E1F23', bandHi: '#4A4A53' },
    blue: { label: '파란띠', body: '#2E63EC', shade: '#1A3B9E', hi: '#86A8FF', band: '#1E1F23', bandHi: '#4A4A53' },
    purple: { label: '보라띠', body: '#8B45E0', shade: '#55239B', hi: '#BD97F7', band: '#1E1F23', bandHi: '#4A4A53' },
    brown: { label: '갈색띠', body: '#8E5B34', shade: '#57341A', hi: '#C99A6E', band: '#1E1F23', bandHi: '#4A4A53' },
    black: { label: '검은띠', body: '#2E2E34', shade: '#111114', hi: '#666672', band: '#D2232C', bandHi: '#FF6A71' },
  };

  function isDark(hex) {
    const n = parseInt(hex.slice(1), 16);
    const r = (n >> 16) & 255, g = (n >> 8) & 255, b = n & 255;
    return (0.299 * r + 0.587 * g + 0.114 * b) / 255 < 0.56;
  }
  function mix(hex, to, k) {
    const a = parseInt(hex.slice(1), 16), b = parseInt(to.slice(1), 16);
    const ch = (s) => Math.round(((a >> s) & 255) * (1 - k) + ((b >> s) & 255) * k);
    return `rgb(${ch(16)},${ch(8)},${ch(0)})`;
  }

  /* ---------- 몸 뼈대 ---------- */
  // lean: 엉덩이에서 기운 각, curve: 고른 휨, top: 위쪽 절반 휨, neck: 띠 아래 꺾임,
  // wave: S자 물결. 각도는 도, + 는 앞(오른쪽)으로 숙임
  function spine(p, L) {
    const pts = [[0, 0]];
    let a = -Math.PI / 2 + rad(p.lean || 0);
    const sl = L / NS;
    for (let i = 0; i < NS; i++) {
      const s = (i + 0.5) / NS;
      const d = (p.curve || 0) / NS
        + ((p.top || 0) * ss(0.5, 1, s)) / (NS * 0.25)
        + (p.wave || 0) * Math.sin(TAU * s - (p.phase || 0)) * (TAU / NS) * 0.5
        + ((p.neck || 0) * Math.exp(-Math.pow((s - 0.6) / 0.09, 2))) / (NS * 0.1595);
      a += rad(d);
      const q = pts[i];
      pts.push([q[0] + Math.cos(a) * sl, q[1] + Math.sin(a) * sl]);
    }
    return pts;
  }
  function at(pts, f) {
    const k = clamp(f) * NS, i = Math.min(NS - 1, Math.floor(k)), u = k - i;
    const a = pts[i], b = pts[i + 1];
    return [a[0] + (b[0] - a[0]) * u, a[1] + (b[1] - a[1]) * u, Math.atan2(b[1] - a[1], b[0] - a[0])];
  }
  function sub(pts, f0, f1) {
    const r = [at(pts, f0)];
    for (let i = Math.ceil(f0 * NS + 1e-6); i < f1 * NS; i++) r.push(pts[i]);
    r.push(at(pts, f1));
    return r;
  }
  function trace(ctx, pts, dx = 0, dy = 0) {
    ctx.beginPath();
    ctx.moveTo(pts[0][0] + dx, pts[0][1] + dy);
    for (let i = 1; i < pts.length - 1; i++) {
      const mx = (pts[i][0] + pts[i + 1][0]) / 2, my = (pts[i][1] + pts[i + 1][1]) / 2;
      ctx.quadraticCurveTo(pts[i][0] + dx, pts[i][1] + dy, mx + dx, my + dy);
    }
    const l = pts[pts.length - 1];
    ctx.lineTo(l[0] + dx, l[1] + dy);
  }
  function rr(ctx, x, y, w, h, r) {
    ctx.beginPath();
    ctx.moveTo(x + r, y);
    ctx.arcTo(x + w, y, x + w, y + h, r);
    ctx.arcTo(x + w, y + h, x, y + h, r);
    ctx.arcTo(x, y + h, x, y, r);
    ctx.arcTo(x, y, x + w, y, r);
    ctx.closePath();
  }

  /* ---------- 표정 (검은 띠 위 흰 선) ---------- */
  function drawFace(ctx, f, u) {
    ctx.strokeStyle = '#fff';
    ctx.fillStyle = '#fff';
    ctx.lineWidth = u * 0.08;
    ctx.lineCap = 'round';
    ctx.lineJoin = 'round';
    const ex = u * 0.2;
    const E = (fn) => [-1, 1].forEach((s) => fn(s, s * ex));
    const arc = (x, y, r, a0, a1) => { ctx.beginPath(); ctx.arc(x, y, r, a0, a1); ctx.stroke(); };
    const dot = (x, y, r) => { ctx.beginPath(); ctx.arc(x, y, r, 0, TAU); ctx.fill(); };
    const line = (x0, y0, x1, y1) => { ctx.beginPath(); ctx.moveTo(x0, y0); ctx.lineTo(x1, y1); ctx.stroke(); };
    const vee = (s, x) => { ctx.beginPath(); ctx.moveTo(x + s * u * 0.08, -u * 0.08); ctx.lineTo(x - s * u * 0.06, 0); ctx.lineTo(x + s * u * 0.08, u * 0.08); ctx.stroke(); };
    const star = (x, y, r) => {
      ctx.beginPath();
      for (let i = 0; i < 8; i++) {
        const a = (i * Math.PI) / 4 - Math.PI / 2, q = i % 2 ? r * 0.38 : r;
        ctx.lineTo(x + Math.cos(a) * q, y + Math.sin(a) * q);
      }
      ctx.closePath();
      ctx.fill();
    };
    switch (f) {
      case 'happy': E((s, x) => arc(x, u * 0.05, u * 0.1, Math.PI * 1.12, Math.PI * 1.88)); break;
      case 'calm': E((s, x) => arc(x, -u * 0.05, u * 0.1, Math.PI * 0.12, Math.PI * 0.88)); break;
      case 'shock': E((s, x) => { ctx.lineWidth = u * 0.055; arc(x, 0, u * 0.09, 0, TAU); dot(x, 0, u * 0.035); }); break;
      case 'focus': E((s, x) => { dot(x, u * 0.035, u * 0.06); line(x + s * u * 0.12, -u * 0.15, x - s * u * 0.07, -u * 0.06); }); break;
      case 'smug':
        E((s, x) => arc(x, -u * 0.04, u * 0.09, Math.PI * 0.15, Math.PI * 0.85));
        line(ex - u * 0.09, -u * 0.14, ex + u * 0.1, -u * 0.19);
        break;
      case 'bored': E((s, x) => { line(x - u * 0.1, -u * 0.02, x + u * 0.1, -u * 0.02); dot(x, u * 0.045, u * 0.04); }); break;
      case 'squint': E((s, x) => vee(-s, x)); break;
      case 'pain': vee(1, -ex); dot(ex, 0, u * 0.06); line(ex - u * 0.09, -u * 0.12, ex + u * 0.09, -u * 0.17); break;
      case 'star': E((s, x) => star(x, 0, u * 0.14)); break;
      case 'cross': E((s, x) => { line(x - u * 0.07, -u * 0.07, x + u * 0.07, u * 0.07); line(x - u * 0.07, u * 0.07, x + u * 0.07, -u * 0.07); }); break;
      case 'sleepy': E((s, x) => arc(x, -u * 0.09, u * 0.12, Math.PI * 0.3, Math.PI * 0.7)); break;
      case 'shy':
        E((s, x) => arc(x, u * 0.05, u * 0.1, Math.PI * 1.12, Math.PI * 1.88));
        ctx.fillStyle = '#FF8DB3';
        E((s, x) => { ctx.beginPath(); ctx.ellipse(x + s * u * 0.06, u * 0.36, u * 0.1, u * 0.055, 0, 0, TAU); ctx.fill(); });
        break;
      case 'wink': arc(-ex, u * 0.05, u * 0.1, Math.PI * 1.12, Math.PI * 1.88); dot(ex, 0, u * 0.065); break;
      default: E((s, x) => dot(x, 0, u * 0.065));
    }
  }

  /* ---------- 장갑 손 · 신발 (도형 목록 → 외곽선/흰 면) ---------- */
  // 로컬 좌표: +x 가 손끝 방향
  function gloveShapes(type) {
    const P = [];
    const C = (x, y, r) => P.push({ t: 'c', x, y, r });
    const L = (x0, y0, x1, y1, w) => P.push({ t: 'l', x0, y0, x1, y1, w });
    const R = (x, y, w, h, r) => P.push({ t: 'r', x, y, w, h, r });
    R(-15, -7.5, 8, 15, 3.5); // 소매
    switch (type) {
      case 'fist':
        C(0, 0, 9);
        C(6.5, -5.5, 3.8); C(7.5, 0, 3.8); C(6.5, 5.5, 3.8);
        L(-2, -7.5, 4, -7.5, 4.6);
        break;
      case 'point':
        C(0, 0, 8.6);
        C(5.5, 3, 3.6); C(5, 7, 3.4);
        L(3, -3, 17, -3, 5.4);
        L(-2, -7.5, 3, -8, 4.4);
        break;
      case 'thumb':
        C(0, 0, 8.6);
        C(6.5, -2, 3.7); C(7, 2.5, 3.7); C(6, 6.8, 3.5);
        L(-1, -6, -1, -18, 5.6);
        break;
      case 'flat':
        C(0, 0, 8.4);
        L(4, -4.2, 16, -4.2, 4.6); L(5, -0.8, 17.5, -0.8, 4.6); L(5, 2.6, 17, 2.6, 4.6); L(4, 6, 14.5, 6, 4.4);
        L(-1, -6.5, 5, -11, 4.6);
        break;
      default: // open
        C(0, 0, 8.6);
        [-34, -12, 10, 32].forEach((d, i) => {
          const a = rad(d), l = i === 0 || i === 3 ? 13 : 15.5;
          L(Math.cos(a) * 4, Math.sin(a) * 4, Math.cos(a) * l, Math.sin(a) * l, 4.8);
        });
        L(-2, -6, 2, -14, 4.8);
    }
    return P;
  }
  function shoeShapes() {
    return [
      { t: 'r', x: -9, y: -10, w: 22, h: 11, r: 5.5 },
      { t: 'r', x: -7, y: -15, w: 11, h: 8, r: 4 },
    ];
  }
  function paintShapes(ctx, P, pass, st) {
    // pass: 'cut' 흰 다이컷, 'ink' 외곽선, 'fill' 흰 면
    const o = pass === 'cut' ? 7 : pass === 'ink' ? (st === 'B' ? 2.4 : st === 'C' ? 2 : 1.4) : 0;
    const col = pass === 'fill' ? '#FFFFFF' : pass === 'cut' ? '#FFFFFF' : st === 'A' ? '#8A90A0' : INK;
    ctx.fillStyle = col;
    ctx.strokeStyle = col;
    ctx.lineCap = 'round';
    P.forEach((s) => {
      if (s.t === 'c') { ctx.beginPath(); ctx.arc(s.x, s.y, s.r + o, 0, TAU); ctx.fill(); }
      else if (s.t === 'l') { ctx.lineWidth = s.w + o * 2; ctx.beginPath(); ctx.moveTo(s.x0, s.y0); ctx.lineTo(s.x1, s.y1); ctx.stroke(); }
      else { rr(ctx, s.x - o, s.y - o, s.w + o * 2, s.h + o * 2, s.r + o); ctx.fill(); }
    });
  }
  function drawHand(ctx, h, pass, st, sc) {
    ctx.save();
    ctx.translate(h.x, h.y);
    ctx.rotate(h.ang);
    if (h.mirror) ctx.scale(1, -1);
    ctx.scale(sc * 1.32, sc * 1.32);
    const P = gloveShapes(h.type);
    paintShapes(ctx, P, pass, st);
    ctx.restore();
  }
  function drawShoe(ctx, f, pass, st, sc) {
    ctx.save();
    ctx.translate(f.x, f.y);
    ctx.rotate(f.ang || 0);
    ctx.scale(f.face * sc, sc);
    paintShapes(ctx, shoeShapes(), pass, st);
    if (pass === 'fill') {
      ctx.fillStyle = st === 'A' ? '#D5D9E2' : '#C9CDD6';
      rr(ctx, -9, -2.5, 22, 3.5, 1.7);
      ctx.fill();
    }
    ctx.restore();
  }
  function hose(ctx, a, c, b, w) {
    ctx.lineWidth = w;
    ctx.lineCap = 'round';
    ctx.beginPath();
    ctx.moveTo(a[0], a[1]);
    ctx.quadraticCurveTo(c[0], c[1], b[0], b[1]);
    ctx.stroke();
  }

  /* ---------- 캐릭터 ---------- */
  function rig(c) {
    const sc = c.s || 1, sq = c.sq || 0, fl = c.flip || 1;
    const L = LEN * sc * (1 - sq), W = WID * sc * (1 + sq * 0.7);
    const gy = c.y;
    const lift = c.lift || 0;
    const seat = c.seat ? 22 * sc : 0;
    const bx = c.x + fl * (c.bx || 0) * sc;
    const by = gy - (LEGL * sc + W * 0.42) - lift + seat;
    const pts = spine(c.p || {}, L).map(([x, y]) => [bx + fl * x, by + y]);
    const nrm = (f) => { const q = at(pts, f); return [q[0], q[1], -Math.sin(q[2]), Math.cos(q[2]), q[2]]; };
    // 어깨: 몸 가운데 높이, 앞(+1)/뒤(-1)
    const sh = (side) => { const q = nrm(SHOULDER); const k = side * fl * W * 0.46; return [q[0] + q[2] * k, q[1] + q[3] * k]; };
    const hip = (side) => { const q = nrm(0.02); const k = side * fl * W * 0.22; return [q[0] + q[2] * k, q[1] + q[3] * k + W * 0.3]; };
    const arms = (c.arms || [{ side: 1, dx: 6, dy: 30 }, { side: -1, dx: -6, dy: 30 }]).map((a) => {
      const s0 = sh(a.side);
      const hx = s0[0] + fl * a.dx * sc, hy = s0[1] + a.dy * sc;
      const mx = (s0[0] + hx) / 2, my = (s0[1] + hy) / 2;
      const bend = a.bend == null ? 1 : a.bend;
      const ctl = [mx + fl * a.side * 9 * bend * sc, my + 8 * bend * sc];
      const ang = a.rot != null ? (fl > 0 ? rad(a.rot) : Math.PI - rad(a.rot)) : Math.atan2(hy - ctl[1], hx - ctl[0]);
      return { side: a.side, s0, ctl, h: { x: hx, y: hy, ang, type: a.hand || 'fist', mirror: fl < 0 } };
    });
    const feet = (c.feet || [[-13, 0], [15, 0]]).map((f, i) => {
      const side = i === 0 ? -1 : 1;
      const fx = c.x + fl * f[0] * sc, fy = gy + f[1] * sc - (c.footLift || 0);
      const hp = hip(side);
      const ctl = [(hp[0] + fx) / 2 + fl * (f[2] != null ? f[2] : 5) * sc, (hp[1] + fy) / 2];
      return { side, hp, ctl, x: fx, y: fy, face: fl, ang: f[3] || 0 };
    });
    return { sc, fl, L, W, pts, arms, feet, by, lift };
  }

  function renderChar(ctx, tmp, c, st, beltKey, S) {
    const B = BELTS[beltKey] || BELTS.white;
    const g = rig(c);
    const { pts, W, sc } = g;
    const limbW = 5.2 * sc;
    const back = g.arms.filter((a) => a.side < 0), front = g.arms.filter((a) => a.side > 0);
    ctx.lineCap = 'round';
    ctx.lineJoin = 'round';

    if (st === 'A') {
      const k = clamp(g.lift / 50);
      ctx.save();
      ctx.fillStyle = `rgba(30,40,70,${0.16 * (1 - k * 0.6)})`;
      ctx.beginPath();
      ctx.ellipse(c.x + g.fl * 2, c.y + 1, 36 * sc * (1 - k * 0.3), 6 * sc, 0, 0, TAU);
      ctx.fill();
      ctx.restore();
    }
    if (st === 'C') {
      ctx.save();
      ctx.shadowColor = 'rgba(0,0,0,.28)';
      ctx.shadowBlur = 8;
      ctx.shadowOffsetY = 3;
      ctx.strokeStyle = '#fff';
      trace(ctx, pts);
      ctx.lineWidth = W + 16;
      ctx.stroke();
      g.feet.forEach((f) => { hose(ctx, f.hp, f.ctl, [f.x, f.y], limbW + 14); });
      g.arms.forEach((a) => { hose(ctx, a.s0, a.ctl, [a.h.x, a.h.y], limbW + 14); });
      ctx.restore();
      g.feet.forEach((f) => drawShoe(ctx, f, 'cut', st, sc));
      g.arms.forEach((a) => drawHand(ctx, a.h, 'cut', st, sc));
    }
    const limbs = (list) => {
      ctx.strokeStyle = LIMB;
      list.forEach((a) => hose(ctx, a.s0, a.ctl, [a.h.x, a.h.y], limbW));
      list.forEach((a) => { drawHand(ctx, a.h, 'ink', st, sc); drawHand(ctx, a.h, 'fill', st, sc); });
    };
    // 다리·신발
    ctx.strokeStyle = LIMB;
    g.feet.forEach((f) => hose(ctx, f.hp, f.ctl, [f.x, f.y - 4 * sc], limbW));
    g.feet.forEach((f) => { drawShoe(ctx, f, 'ink', st, sc); drawShoe(ctx, f, 'fill', st, sc); });
    // 뒤 팔
    limbs(back);
    // 몸
    if (st !== 'A') {
      trace(ctx, pts);
      ctx.strokeStyle = INK;
      ctx.lineWidth = W + (st === 'B' ? 6 : 4);
      ctx.stroke();
    }
    const t = tmp;
    t.save();
    t.setTransform(S, 0, 0, S, 0, 0);
    t.clearRect(0, 0, 240, 240);
    t.lineCap = 'round';
    t.lineJoin = 'round';
    trace(t, pts);
    t.strokeStyle = B.shade;
    t.lineWidth = W;
    t.stroke();
    t.globalCompositeOperation = 'source-atop';
    const soft = st === 'A';
    if (soft) t.filter = `blur(${(W * 0.09 * S).toFixed(1)}px)`;
    trace(t, pts, -W * 0.12, -W * 0.07);
    t.strokeStyle = B.body;
    t.lineWidth = W * (soft ? 0.86 : 0.9);
    t.stroke();
    if (soft) t.filter = `blur(${(W * 0.05 * S).toFixed(1)}px)`;
    trace(t, pts, -W * 0.23, -W * 0.16);
    t.strokeStyle = B.hi;
    t.globalAlpha = soft ? 0.95 : 0.9;
    t.lineWidth = W * (soft ? 0.24 : 0.16);
    t.stroke();
    t.globalAlpha = 1;
    t.filter = 'none';
    if (c.plaster != null) {
      const q = at(pts, c.plaster);
      t.save();
      t.translate(q[0], q[1]);
      t.rotate(q[2] + Math.PI / 2 + 0.55);
      t.fillStyle = '#F2C996';
      rr(t, -W * 0.7, -W * 0.15, W * 1.4, W * 0.3, W * 0.1);
      t.fill();
      t.fillStyle = '#E3AF73';
      t.fillRect(-W * 0.13, -W * 0.15, W * 0.26, W * 0.3);
      t.restore();
    }
    const bp = sub(pts, BAND0, BAND1);
    t.lineCap = 'butt';
    trace(t, bp);
    t.strokeStyle = B.band;
    t.lineWidth = W * 1.4;
    t.stroke();
    if (soft) t.filter = `blur(${(1.6 * S).toFixed(1)}px)`;
    const bm = at(pts, (BAND0 + BAND1) / 2);
    let nx = -Math.sin(bm[2]), ny = Math.cos(bm[2]);
    if (nx * -1 + ny * -0.6 < 0) { nx = -nx; ny = -ny; }
    trace(t, sub(pts, BAND0 + 0.012, BAND1 - 0.012), nx * W * 0.3, ny * W * 0.3);
    t.strokeStyle = B.bandHi;
    t.lineWidth = W * 0.18;
    t.globalAlpha = 0.75;
    t.stroke();
    t.globalAlpha = 1;
    t.filter = 'none';
    (c.stripes || []).forEach((sp) => {
      const k = sp.k == null ? 1 : sp.k;
      if (k <= 0) return;
      trace(t, sub(pts, sp.f, sp.f + 0.03 * Math.min(k, 1.15)));
      t.strokeStyle = '#F4F4F0';
      t.lineWidth = W * 1.4;
      t.stroke();
    });
    t.restore();
    ctx.save();
    ctx.setTransform(1, 0, 0, 1, 0, 0);
    ctx.drawImage(t.canvas, 0, 0);
    ctx.restore();
    ctx.setTransform(S, 0, 0, S, 0, 0);

    const h = at(pts, FACE);
    let phi = h[2] + Math.PI / 2;
    while (phi > Math.PI / 2) phi -= Math.PI;
    while (phi <= -Math.PI / 2) phi += Math.PI;
    ctx.save();
    ctx.translate(h[0], h[1]);
    ctx.rotate(phi);
    drawFace(ctx, c.face || 'happy', W);
    ctx.restore();
    // 앞 팔
    limbs(front);

    const tp = at(pts, 1);
    const tip = [tp[0] + Math.cos(tp[2]) * W * 0.5, tp[1] + Math.sin(tp[2]) * W * 0.5, tp[2]];
    const hand = (side) => { const a = g.arms.find((x) => x.side === side); return a ? [a.h.x, a.h.y, a.h.ang] : null; };
    return { pts, W, head: h, tip, hand, at: (f) => at(pts, f), feet: g.feet };
  }

  /* ---------- 배경 ---------- */
  const POP = ['#FFD60A', '#FF3D6E', '#2F5BFF', '#C6FF3A', '#FFFFFF', '#18D2C0'];
  function drawBg(ctx, st, R, t, idx) {
    if (st === 'A') {
      const g = ctx.createRadialGradient(120, 120, 20, 120, 130, 170);
      g.addColorStop(0, mix(R.bg, '#FFFFFF', 0.9));
      g.addColorStop(1, mix(R.bg, '#FFFFFF', 0.72));
      ctx.fillStyle = g;
      ctx.fillRect(0, 0, 240, 240);
      return;
    }
    if (st === 'B') {
      ctx.fillStyle = R.bg;
      ctx.fillRect(0, 0, 240, 240);
      const dark = isDark(R.bg);
      ctx.save();
      ctx.translate(120, 150);
      ctx.rotate((t * TAU) / 12);
      ctx.fillStyle = dark ? 'rgba(255,255,255,.10)' : 'rgba(0,0,0,.06)';
      for (let i = 0; i < 12; i += 2) {
        ctx.beginPath();
        ctx.moveTo(0, 0);
        ctx.arc(0, 0, 260, (i * TAU) / 12, ((i + 1) * TAU) / 12);
        ctx.closePath();
        ctx.fill();
      }
      ctx.restore();
      ctx.fillStyle = dark ? 'rgba(255,255,255,.16)' : 'rgba(255,255,255,.42)';
      ctx.beginPath();
      ctx.arc(120, 146, 76, 0, TAU);
      ctx.fill();
      const bob = Math.sin(TAU * t) * 3;
      const pick = (k) => { const c = POP[(idx + k) % POP.length]; return c === R.bg ? POP[(idx + k + 2) % POP.length] : c; };
      ctx.save();
      ctx.lineCap = 'round';
      ctx.lineJoin = 'round';
      ctx.strokeStyle = INK;
      const corners = [[212, 200], [26, 196], [214, 104], [24, 118]];
      const a = corners[idx % 4], b = corners[(idx + 2) % 4];
      ctx.lineWidth = 4;
      ctx.beginPath();
      for (let i = 0; i <= 4; i++) ctx.lineTo(a[0] - 18 + i * 9, a[1] + bob + (i % 2 ? -6 : 6));
      ctx.stroke();
      ctx.fillStyle = pick(1);
      ctx.beginPath();
      ctx.arc(b[0], b[1] - bob, 8, 0, TAU);
      ctx.fill();
      ctx.lineWidth = 3.5;
      ctx.stroke();
      ctx.fillStyle = pick(2);
      ctx.translate(b[0] + (b[0] > 120 ? -4 : 4), b[1] + 28 + bob);
      ctx.rotate(((t * TAU) / 3) * (idx % 2 ? 1 : -1));
      ctx.beginPath();
      ctx.moveTo(0, -9); ctx.lineTo(9, 7); ctx.lineTo(-9, 7); ctx.closePath();
      ctx.fill();
      ctx.lineWidth = 3;
      ctx.stroke();
      ctx.restore();
      return;
    }
    ctx.fillStyle = '#E8E9ED';
    ctx.fillRect(0, 0, 240, 240);
    ctx.save();
    ctx.shadowColor = 'rgba(0,0,0,.22)';
    ctx.shadowBlur = 10;
    ctx.shadowOffsetY = 4;
    ctx.fillStyle = '#fff';
    ctx.beginPath();
    ctx.arc(120, 140, 90, 0, TAU);
    ctx.fill();
    ctx.restore();
    ctx.save();
    ctx.beginPath();
    ctx.arc(120, 140, 82, 0, TAU);
    ctx.fillStyle = R.bg;
    ctx.fill();
    ctx.clip();
    ctx.fillStyle = isDark(R.bg) ? 'rgba(255,255,255,.22)' : 'rgba(0,0,0,.13)';
    for (let y = 56; y < 230; y += 8) {
      for (let x = 36; x < 206; x += 8) {
        const off = ((y / 8) % 2) * 4;
        const k = clamp((x + off - 40 + (y - 60) * 0.6) / 260);
        ctx.beginPath();
        ctx.arc(x + off, y, 0.6 + k * 2.6, 0, TAU);
        ctx.fill();
      }
    }
    ctx.restore();
    ctx.lineWidth = 3;
    ctx.strokeStyle = INK;
    ctx.beginPath();
    ctx.arc(120, 140, 82, 0, TAU);
    ctx.stroke();
  }

  /* ---------- 글자 ---------- */
  const FONT = '"Black Han Sans", "Apple SD Gothic Neo", "Malgun Gothic", sans-serif';
  function drawLabel(ctx, st, R, L) {
    const size = L.size || 30;
    ctx.save();
    ctx.translate(L.x, L.y);
    ctx.rotate(rad(L.r || 0));
    const k = L.k || 1;
    ctx.scale(k, k);
    ctx.font = `${size}px ${FONT}`;
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.lineJoin = 'round';
    if (st === 'A') {
      const w = ctx.measureText(L.t).width + 24, h = size + 12;
      ctx.shadowColor = 'rgba(20,30,60,.16)';
      ctx.shadowBlur = 10;
      ctx.shadowOffsetY = 3;
      rr(ctx, -w / 2, -h / 2, w, h, h / 2);
      ctx.fillStyle = '#fff';
      ctx.fill();
      ctx.shadowColor = 'transparent';
      ctx.fillStyle = R.deep;
      ctx.fillText(L.t, 0, 2);
    } else if (st === 'B') {
      ctx.lineWidth = 8;
      ctx.strokeStyle = INK;
      ctx.fillStyle = INK;
      ctx.strokeText(L.t, 3, 6);
      ctx.fillText(L.t, 3, 6);
      ctx.strokeText(L.t, 0, 2);
      ctx.fillStyle = '#fff';
      ctx.fillText(L.t, 0, 2);
    } else {
      const w = ctx.measureText(L.t).width + 20, h = size + 10;
      ctx.shadowColor = 'rgba(0,0,0,.25)';
      ctx.shadowBlur = 6;
      ctx.shadowOffsetY = 2;
      ctx.fillStyle = '#fff';
      rr(ctx, -w / 2 - 6, -h / 2 - 6, w + 12, h + 12, 9);
      ctx.fill();
      ctx.shadowColor = 'transparent';
      ctx.fillStyle = INK;
      rr(ctx, -w / 2, -h / 2, w, h, 4);
      ctx.fill();
      ctx.fillStyle = isDark(R.bg) ? '#FFFFFF' : R.bg;
      ctx.fillText(L.t, 0, 2);
    }
    ctx.restore();
  }

  /* ---------- 효과 ---------- */
  function mkApi(ctx, st, R) {
    const col = st === 'A' ? '#3A4256' : st === 'B' && isDark(R.bg) ? '#FFFFFF' : INK;
    const outline = st !== 'A';
    return {
      ctx, col,
      rays(x, y, n, r0, r1, a0, a1, w = 3, al = 1) {
        if (al <= 0) return;
        ctx.save();
        ctx.globalAlpha = clamp(al);
        ctx.strokeStyle = col;
        ctx.lineWidth = w;
        ctx.lineCap = 'round';
        for (let i = 0; i < n; i++) {
          const a = a0 + (a1 - a0) * (n === 1 ? 0.5 : i / (n - 1));
          ctx.beginPath();
          ctx.moveTo(x + Math.cos(a) * r0, y + Math.sin(a) * r0);
          ctx.lineTo(x + Math.cos(a) * r1, y + Math.sin(a) * r1);
          ctx.stroke();
        }
        ctx.restore();
      },
      swoosh(x, y, r, a0, a1, al = 1) {
        if (al <= 0) return;
        ctx.save();
        ctx.globalAlpha = clamp(al);
        ctx.strokeStyle = col;
        ctx.lineWidth = 3;
        ctx.lineCap = 'round';
        ctx.beginPath();
        ctx.arc(x, y, r, a0, a1);
        ctx.stroke();
        ctx.restore();
      },
      drop(x, y, s = 1, al = 1) {
        if (al <= 0) return;
        ctx.save();
        ctx.globalAlpha = clamp(al);
        ctx.translate(x, y);
        ctx.scale(s, s);
        ctx.beginPath();
        ctx.moveTo(0, -10);
        ctx.bezierCurveTo(4, -3, 7, 1, 7, 5);
        ctx.arc(0, 5, 7, 0, Math.PI);
        ctx.bezierCurveTo(-7, 1, -4, -3, 0, -10);
        ctx.fillStyle = '#8FD8FF';
        ctx.fill();
        if (outline) { ctx.lineWidth = 2.2; ctx.strokeStyle = INK; ctx.stroke(); }
        ctx.fillStyle = '#fff';
        ctx.beginPath();
        ctx.arc(-2.4, 4, 1.8, 0, TAU);
        ctx.fill();
        ctx.restore();
      },
      spark(x, y, r, al = 1, fill) {
        if (al <= 0 || r <= 0) return;
        ctx.save();
        ctx.globalAlpha = clamp(al);
        ctx.beginPath();
        for (let i = 0; i < 8; i++) {
          const a = (i * Math.PI) / 4 - Math.PI / 2, q = i % 2 ? r * 0.36 : r;
          ctx.lineTo(x + Math.cos(a) * q, y + Math.sin(a) * q);
        }
        ctx.closePath();
        ctx.fillStyle = fill || (st === 'A' ? '#FFC21A' : '#FFE14D');
        ctx.fill();
        if (outline) { ctx.lineWidth = 2; ctx.strokeStyle = INK; ctx.stroke(); }
        ctx.restore();
      },
      impact(x, y, r, al = 1) {
        if (al <= 0) return;
        ctx.save();
        ctx.globalAlpha = clamp(al);
        ctx.beginPath();
        const n = 9;
        for (let i = 0; i < n * 2; i++) {
          const a = (i * Math.PI) / n, q = i % 2 ? r * 0.5 : r;
          ctx.lineTo(x + Math.cos(a) * q, y + Math.sin(a) * q);
        }
        ctx.closePath();
        ctx.fillStyle = '#FFE14D';
        ctx.fill();
        ctx.lineWidth = 2.5;
        ctx.strokeStyle = outline ? INK : '#E0A800';
        ctx.stroke();
        ctx.restore();
      },
      heart(x, y, s, al = 1) {
        if (al <= 0) return;
        ctx.save();
        ctx.globalAlpha = clamp(al);
        ctx.translate(x, y);
        ctx.scale(s / 10, s / 10);
        ctx.beginPath();
        ctx.moveTo(0, 4);
        ctx.bezierCurveTo(-12, -4, -6, -14, 0, -7);
        ctx.bezierCurveTo(6, -14, 12, -4, 0, 4);
        ctx.fillStyle = '#FF4F8B';
        ctx.fill();
        if (outline) { ctx.lineWidth = 2; ctx.strokeStyle = INK; ctx.stroke(); }
        ctx.restore();
      },
      text(str, x, y, size, r = 0, al = 1) {
        if (al <= 0) return;
        ctx.save();
        ctx.globalAlpha = clamp(al);
        ctx.translate(x, y);
        ctx.rotate(r);
        ctx.font = `${size}px ${FONT}`;
        ctx.textAlign = 'center';
        ctx.textBaseline = 'middle';
        ctx.fillStyle = col;
        ctx.fillText(str, 0, 0);
        ctx.restore();
      },
      word(str, x, y, size, rDeg = 0) { drawLabel(ctx, st === 'C' ? 'B' : st, R, { t: str, x, y, r: rDeg, size }); },
      squiggle(x, y, w, amp, ph) {
        ctx.save();
        ctx.strokeStyle = col;
        ctx.lineWidth = 3.5;
        ctx.lineCap = 'round';
        ctx.lineJoin = 'round';
        ctx.beginPath();
        for (let i = 0; i <= 24; i++) { const u = i / 24; ctx.lineTo(x + u * w, y + Math.sin(u * TAU * 1.5 + ph) * amp); }
        ctx.stroke();
        ctx.restore();
      },
      mat(x0, x1, y) {
        ctx.save();
        ctx.fillStyle = st === 'A' ? 'rgba(60,70,95,.12)' : 'rgba(18,19,23,.16)';
        rr(ctx, x0, y, x1 - x0, 10, 5);
        ctx.fill();
        ctx.restore();
      },
    };
  }

  /* ---------- 리액션 16종 ---------- */
  // arms: side +1 앞 팔, -1 뒤 팔. dx, dy 는 어깨에서 손까지(앞쪽이 +dx). hand: open|fist|point|thumb|flat, rot: 손 방향(도)
  const HANG = (side, k = 0) => ({ side, dx: side * 16, dy: 34 + k, hand: 'fist', bend: 1.4 });
  const HIP = (side) => ({ side, dx: side * 22, dy: 20, hand: 'fist', bend: -1.8 });
  const REACTIONS = [
    {
      id: 'oss', group: 'cheer', name: 'OSS!', T: 1.8, bg: '#FF5A1F', deep: '#C23A06',
      when: '도장에 들어설 때, 처음 인사할 때', motion: '두 주먹 내리고 꾸벅, 통 튀어 올라옴', use: '온보딩 환영 · 출석 체크',
      f(t) {
        const d = eIO(seg(t, 0.06, 0.3)), u = spring(seg(t, 0.52, 1)), b = d * (1 - u);
        return {
          chars: [{ x: 148, y: GROUND, p: { lean: 34 * b, curve: 18 * b, top: 14 * b }, sq: 0.07 * hump(t, 0.5, 0.6) - 0.04 * hump(t, 0.6, 0.78), face: b > 0.6 ? 'calm' : 'happy', arms: [HANG(1), HANG(-1)] }],
          label: { t: 'OSS!', x: 66, y: 48, r: -8, k: 1 + 0.16 * hump(t, 0.28, 0.48), size: 32 },
          fx(a, [c]) { const k = hump(t, 0.6, 0.85); a.rays(c.tip[0], c.tip[1], 3, c.W * 0.62, c.W * 0.62 + 13 * k, c.tip[2] - 0.9, c.tip[2] + 0.9, 3.2, k * 1.4); },
        };
      },
    },
    {
      id: 'fight', group: 'cheer', name: '화이팅!', T: 1.1, bg: '#C6FF3A', deep: '#4A7A00',
      when: '대회 전날, 친구 응원할 때', motion: '주먹 쥔 팔을 위로 두 번 쭉쭉', use: '대회 기록 입력 시작 · 응원 댓글',
      f(t) {
        const p = Math.pow(Math.max(0, Math.sin(TAU * 2 * t)), 0.7);
        return {
          chars: [{ x: 146, y: GROUND, p: { lean: -4 + 4 * p, curve: -6 }, sq: 0.06 * (1 - p) - 0.03 * p, face: 'focus',
            arms: [{ side: 1, dx: 12 + 4 * p, dy: -22 - 26 * p, hand: 'fist', bend: 0.8 }, { side: -1, dx: -10, dy: 20, hand: 'fist', bend: -1.4 }],
            feet: [[-16, 0], [18, 0]] }],
          label: { t: '화이팅!', x: 70, y: 46, r: -8 + 3 * Math.sin(TAU * 4 * t) * p, k: 1 + 0.1 * p, size: 30 },
          fx(a, [c]) { const h = c.hand(1); if (p > 0.3) a.rays(h[0], h[1], 3, 14, 14 + 12 * p, -Math.PI * 0.85, -Math.PI * 0.15, 3.2, p * 1.3); },
        };
      },
    },
    {
      id: 'bump', group: 'cheer', name: 'ㄱㄱ!', T: 1.5, bg: '#3DFFA2', deep: '#00844F',
      when: '롤(스파링) 시작 전 주먹 인사', motion: '둘이 다가가 주먹을 툭 맞댐', use: '스파링 모집 글 · 친구 맺기',
      f(t) {
        const k = t < 0.38 ? eIn(seg(t, 0, 0.38)) : 1 - spring(seg(t, 0.38, 1));
        const ch = (x, flip, belt) => ({ x, y: GROUND, s: 0.78, flip, belt, p: { lean: 6 + 12 * k, curve: 4 * k }, face: 'focus',
          arms: [{ side: 1, dx: 14 + 18 * k, dy: 2 - 4 * k, hand: 'fist', rot: 0, bend: 0.5 }, HANG(-1)] });
        return {
          chars: [ch(56, 1), ch(184, -1, '__other')],
          label: { t: 'ㄱㄱ!', x: 120, y: 38, r: -6, k: 1 + 0.2 * hump(t, 0.36, 0.56), size: 36 },
          fx(a, [c1, c2]) { const h = hump(t, 0.36, 0.54); const p = c1.hand(1), q = c2.hand(1); a.impact((p[0] + q[0]) / 2, (p[1] + q[1]) / 2 - 2, 8 + 14 * h, h * 1.4); },
        };
      },
    },
    {
      id: 'nice', group: 'cheer', name: '나이스!', T: 1.4, bg: '#FFD60A', deep: '#8F6E00',
      when: '좋은 기술 영상, 승급 소식에', motion: '엄지 척, 가슴 펴고 통통', use: '좋아요 · 칭찬 댓글',
      f(t) {
        const b = Math.abs(Math.sin(TAU * 2 * t));
        return {
          chars: [{ x: 140, y: GROUND, p: { lean: -7, curve: -8 }, sq: 0.06 * Math.pow(1 - b, 3), lift: 5 * b, face: 'wink',
            arms: [{ side: 1, dx: 24, dy: -6 - 3 * b, hand: 'thumb', rot: 0, bend: 0.7 }, HIP(-1)] }],
          label: { t: '나이스!', x: 66, y: 50, r: -8, k: 1 + 0.07 * b, size: 30 },
          fx(a, [c]) { const h = c.hand(1); for (let i = 0; i < 3; i++) { const an = t * TAU + (i * TAU) / 3; a.spark(h[0] + Math.cos(an) * 22, h[1] - 10 + Math.sin(an) * 16, 5 + 2.5 * Math.sin(TAU * 2 * t + i), 1); } },
        };
      },
    },
    {
      id: 'nono', group: 'reply', name: '노노', T: 1.0, bg: '#2F5BFF', deep: '#1D3FD0',
      when: '"그거 반칙 아님?" 받아칠 때', motion: '검지 세워 까딱까딱, 몸은 반대로 살짝', use: '댓글 리액션',
      f(t) {
        const w = Math.sin(TAU * 2 * t);
        return {
          chars: [{ x: 150, y: GROUND, p: { lean: -3 * w, curve: -4 * w, top: -6 * w }, face: 'smug',
            arms: [{ side: 1, dx: 16 + 7 * w, dy: -36, hand: 'point', rot: -90 + 24 * w, bend: 1 }, HIP(-1)] }],
          label: { t: 'NO NO', x: 66, y: 58, r: -6, k: 1, size: 32 },
          fx(a, [c]) {
            const h = c.hand(1);
            const cx = h[0] - Math.cos(h[2]) * 4, cy = h[1] + 16;
            a.swoosh(cx, cy, 30, -Math.PI / 2 - 0.75, -Math.PI / 2 - 0.35, Math.max(0, -w));
            a.swoosh(cx, cy, 30, -Math.PI / 2 + 0.35, -Math.PI / 2 + 0.75, Math.max(0, w));
          },
        };
      },
    },
    {
      id: 'soso', group: 'reply', name: '쏘쏘', T: 1.6, bg: '#A9B8D0', deep: '#4A5873',
      when: '"오늘 롤 어땠어?" "그냥 그래"', motion: '손바닥 펴서 좌우로 시소, 한 손은 머리 긁적', use: '오늘 운동 기분 기록',
      f(t) {
        const s = Math.sin(TAU * t);
        return {
          chars: [{ x: 146, y: GROUND, p: { lean: 5 * s, curve: -6 * s }, face: 'bored',
            arms: [{ side: 1, dx: 28, dy: 0, hand: 'flat', rot: 24 * s, bend: 0.7 }, { side: -1, dx: 2, dy: -40, hand: 'open', rot: -60, bend: 1.2 }] }],
          label: { t: 'SO SO', x: 66, y: 54, r: -7 * s, k: 1, size: 32 },
          fx(a) { a.squiggle(40, 88, 54, 4, TAU * t); },
        };
      },
    },
    {
      id: 'respect', group: 'reply', name: 'ㅇㅈ', T: 1.3, bg: '#00B8FF', deep: '#0070A8',
      when: '"인정" — 맞는 말에 박수', motion: '끄덕이며 짝짝 박수', use: '댓글 리액션 · 공감',
      f(t) {
        const n = Math.max(0, Math.sin(TAU * 2 * seg(t, 0, 0.7)));
        const o = Math.abs(Math.sin(TAU * 4 * t));
        return {
          chars: [{ x: 148, y: GROUND, p: { top: 24 * n, curve: 4 * n }, face: 'calm',
            arms: [{ side: 1, dx: 22 + 6 * o, dy: -2, hand: 'open', rot: -110, bend: 0.4 }, { side: -1, dx: 26 - 2 * o, dy: 2, hand: 'open', rot: -60, bend: -0.4 }] }],
          label: { t: 'ㅇㅈ', x: 70, y: 62, r: -8, k: 1 + 0.08 * n, size: 46 },
          fx(a, [c]) { const h = c.hand(1); a.rays(h[0], h[1] - 4, 3, 13, 21, -Math.PI * 0.8, -Math.PI * 0.2, 3, 1 - o); },
        };
      },
    },
    {
      id: 'lol', group: 'reply', name: 'ㅋㅋㅋ', T: 1.0, bg: '#FF9F1C', deep: '#A85C00',
      when: '웃긴 도장 썰에', motion: '배 잡고 들썩, 무릎 탁탁', use: '댓글 리액션',
      f(t) {
        const b = Math.abs(Math.sin(TAU * 3 * t)), s = Math.sin(TAU * 3 * t);
        return {
          chars: [{ x: 156, y: GROUND, p: { lean: 8 + 5 * s, wave: 8 * Math.sin(TAU * 6 * t) }, lift: 6 * b, sq: 0.08 * Math.pow(1 - b, 3), face: 'squint',
            arms: [{ side: 1, dx: 22, dy: 30 + 6 * s, hand: 'open', rot: 100, bend: 0.8 }, { side: -1, dx: 10, dy: 22, hand: 'open', rot: 30, bend: 1 }] }],
          label: null,
          fx(a) { for (let i = 0; i < 3; i++) a.word('ㅋ', 34 + i * 30, 66 - 12 * Math.abs(Math.sin(TAU * 3 * t + i * 0.9)), 34, -10 + i * 7); },
        };
      },
    },
    {
      id: 'tap', group: 'mat', name: '탭!', T: 0.9, bg: '#FF3D6E', deep: '#C21848',
      when: '항복 신호 — 졌다, 인정', motion: '매트에 앉아 손바닥으로 바닥을 탁탁', use: '로그아웃 · 그만두기 확인',
      f(t) {
        const g = 1 - Math.abs(Math.sin(TAU * t)), hit = Math.pow(g, 6), down = Math.pow(g, 2.2);
        return {
          chars: [{ x: 110, y: GROUND, seat: true, p: { lean: -16 + 4 * hit, curve: -6 }, sq: 0.04 * hit, face: 'squint',
            arms: [{ side: 1, dx: 40, dy: lerp(-30, 62, down), hand: 'open', rot: lerp(-70, 90, down), bend: 0.6 }, { side: -1, dx: -26, dy: 52, hand: 'open', rot: 150, bend: 1 }],
            feet: [[36, 0, -2, -0.2], [56, -2, -2, -0.1]] }],
          label: { t: 'TAP!', x: 176, y: 48, r: 6, k: 1 + 0.18 * hit, size: 40 },
          fx(a, [c]) {
            a.mat(14, 226, GROUND + 2);
            const h = c.hand(1);
            a.impact(h[0] + 4, h[1] + 8, 9 + 12 * hit, hit * 1.3);
            a.drop(c.head[0] - 26, c.head[1] - 10, 0.75, 0.95);
          },
        };
      },
    },
    {
      id: 'roll', group: 'mat', name: '한판 ㄱ?', T: 1.5, bg: '#7A3CFF', deep: '#5A22D6',
      when: '"한 판 더?" 도발할 때', motion: '손바닥 위로 내밀고 까딱까딱 — 덤벼', use: '스파링 상대 찾기',
      f(t) {
        const u = t / 0.62, k = u < 1 ? (1 - Math.cos(TAU * 2 * u)) / 2 : 0;
        return {
          chars: [{ x: 120, y: GROUND, p: { lean: 12, curve: 6 }, face: 'smug',
            arms: [{ side: 1, dx: 34 - 6 * k, dy: -4 - 4 * k, hand: k > 0.5 ? 'fist' : 'open', rot: -20 - 50 * k, bend: 0.6 }, HIP(-1)],
            feet: [[-20, 0], [20, 0]] }],
          label: { t: '한판 ㄱ?', x: 72, y: 44, r: -7, k: 1, size: 28 },
          fx(a, [c]) { const h = c.hand(1); a.rays(h[0], h[1], 3, 15, 24, -Math.PI * 0.7, -Math.PI * 0.1, 3, (k - 0.4) * 2); },
        };
      },
    },
    {
      id: 'gassed', group: 'mat', name: '헥헥', T: 1.4, bg: '#18D2C0', deep: '#00796E',
      when: '스파링 끝나고 숨 넘어갈 때', motion: '푹 숙이고 팔 축 늘어뜨린 채 헐떡', use: '운동 기록 저장 완료',
      f(t) {
        const b = Math.sin(TAU * 3 * t);
        return {
          chars: [{ x: 120, y: GROUND, p: { lean: 26, curve: 24, top: 46 + 7 * b }, sq: 0.04 * b, face: 'cross',
            arms: [{ side: 1, dx: 18, dy: 50 + 3 * b, hand: 'open', rot: 95, bend: 0.6 }, { side: -1, dx: 8, dy: 52 + 3 * b, hand: 'open', rot: 85, bend: 0.6 }],
            feet: [[-22, 0, 9], [26, 0, 9]] }],
          label: { t: '헥헥..', x: 70, y: 44, r: -6, k: 1, size: 30 },
          fx(a, [c]) { for (let i = 0; i < 3; i++) { const ph = (t + i / 3) % 1; a.drop(c.head[0] + (i - 1) * 12 + 10, c.head[1] + 22 + ph * 40, 0.6, 1 - ph); } },
        };
      },
    },
    {
      id: 'ouch', group: 'mood', name: '아야', T: 1.2, bg: '#8FD3FF', deep: '#246F99',
      when: '부상, 무릎·손가락 삐었을 때', motion: '반창고 자리를 감싸 쥐고 바들바들', use: '부상 기록 · 휴식 알림',
      f(t) {
        const tr = Math.sin(TAU * 8 * t);
        return {
          chars: [{ x: 146, y: GROUND, p: { lean: 10 + 1.4 * tr, curve: 14, top: 16 + 4 * Math.sin(TAU * t) }, face: 'pain', plaster: 0.3,
            arms: [{ side: 1, dx: 4, dy: 16, hand: 'open', rot: 160, bend: -1.4 }, { side: -1, dx: 12, dy: 20, hand: 'open', rot: 20, bend: 1 }] }],
          label: { t: '아야..', x: 68, y: 50, r: -8, k: 1, size: 30 },
          fx(a, [c]) { a.drop(c.head[0] + 14, c.head[1] + 10 + t * 30, 0.55, 1 - t); a.rays(c.head[0], c.head[1], 3, c.W * 0.85, c.W * 0.85 + 8, -Math.PI * 0.85, -Math.PI * 0.55, 3, 0.6 + 0.4 * tr); },
        };
      },
    },
    {
      id: 'promote', group: 'mat', name: '승급!', T: 1.8, bg: '#FFB800', deep: '#9A6200',
      when: '그랄(줄)·띠 승급한 날', motion: '만세 점프, 공중에서 띠에 줄 하나 추가', use: '띠·그랄 수정 완료',
      f(t) {
        const crouch = hump(t, 0, 0.16), j = seg(t, 0.13, 0.55), air = j > 0 && j < 1;
        const lift = 34 * 4 * j * (1 - j), land = hump(t, 0.55, 0.7);
        const on = t > 0.34, pop = on ? Math.min(1.15, spring(seg(t, 0.34, 0.5))) : 0;
        const up = air ? 1 : 0;
        return {
          chars: [{
            x: 150, y: GROUND, s: 0.92, lift, footLift: lift,
            p: { wave: air ? 10 * Math.sin(TAU * 2 * j) : 0 },
            sq: 0.14 * crouch + 0.1 * land - (air ? 0.06 * Math.sin(Math.PI * j) : 0),
            face: on ? 'star' : 'focus',
            stripes: [{ f: 0.665, k: 1 }, { f: 0.715, k: pop }],
            arms: up ? [{ side: 1, dx: 22, dy: -34, hand: 'open', rot: -60 }, { side: -1, dx: -20, dy: -34, hand: 'open', rot: -120 }] : [HANG(1), HANG(-1)],
            feet: air ? [[-10, 0, 6], [12, 0, 6]] : [[-14, 0], [16, 0]],
          }],
          label: { t: '승급!', x: 66, y: 60, r: -8, k: on ? 1 + 0.22 * hump(t, 0.34, 0.5) : 1, size: 34 },
          fx(a, [c]) { if (!on) return; const k = seg(t, 0.34, 0.85); for (let i = 0; i < 6; i++) { const an = (i / 6) * TAU + 0.3, r = c.W * 0.8 + 30 * k; a.spark(c.head[0] + Math.cos(an) * r, c.head[1] + Math.sin(an) * r, 7 * (1 - k) + 2, 1 - k); } },
        };
      },
    },
    {
      id: 'shock', group: 'mood', name: '헉!', T: 1.6, bg: '#FF4A3D', deep: '#BF1D10',
      when: '말도 안 되는 서브미션 영상에', motion: '두 손 번쩍 들며 뒤로 홱, 부르르', use: '오류 · 연결 끊김 안내',
      f(t) {
        const on = eOut(seg(t, 0.05, 0.13)), off = eIO(seg(t, 0.62, 0.95)), a = on * (1 - off);
        const sh = Math.sin(t * TAU * 14) * (1 - seg(t, 0.13, 0.5)) * a;
        return {
          chars: [{ x: 132, y: GROUND, p: { lean: -16 * a + 2.5 * sh, curve: -4 * a }, sq: -0.07 * a, face: a > 0.3 ? 'shock' : 'bored',
            arms: a > 0.15 ? [{ side: 1, dx: 24, dy: -24 * a, hand: 'open', rot: -40, bend: 0.8 }, { side: -1, dx: -22, dy: -22 * a, hand: 'open', rot: -140, bend: 1 }] : [HANG(1), HANG(-1)] }],
          label: { t: '헉!', x: 200, y: 52, r: 8, k: 1 + 0.25 * hump(t, 0.08, 0.25), size: 40 },
          fx(api, [c]) { api.rays(c.tip[0], c.tip[1] + 6, 5, c.W * 0.75, c.W * 0.75 + 12, -Math.PI * 0.92, -Math.PI * 0.08, 3, (a - 0.3) * 2); },
        };
      },
    },
    {
      id: 'shy', group: 'mood', name: '헤헤', T: 1.6, bg: '#FF8AC8', deep: '#B8307D',
      when: '칭찬받았을 때, 첫 메달 축하에', motion: '두 손 모으고 몸을 배배 꼼, 하트 퐁퐁', use: '받은 좋아요 알림',
      f(t) {
        const w = Math.sin(TAU * 2 * t);
        return {
          chars: [{ x: 150, y: GROUND, p: { lean: -5 + 3 * w, wave: 7 * Math.sin(TAU * t), top: -10 }, face: 'shy',
            arms: [{ side: 1, dx: 10, dy: -4, hand: 'fist', rot: -100, bend: -1.2 }, { side: -1, dx: 18, dy: -2, hand: 'fist', rot: -80, bend: -0.8 }],
            feet: [[-6, 0], [10, 0, 5, 0.2]] }],
          label: { t: '헤헤', x: 200, y: 52, r: 8, k: 1, size: 32 },
          fx(a, [c]) { for (let i = 0; i < 2; i++) { const ph = (t + i * 0.5) % 1; a.heart(c.head[0] - 40 - i * 10, c.head[1] - 20 - ph * 40, 8 + 3 * i, 1 - ph); } },
        };
      },
    },
    {
      id: 'sleepy', group: 'mood', name: '오늘 쉼', T: 2.6, bg: '#6E7BFF', deep: '#3E49C9',
      when: '운동 쉬는 날, 새벽 수업 전', motion: '꾸벅꾸벅 졸다가 화들짝', use: '빈 화면 · 기록 없는 날',
      f(t) {
        const d = eIn(seg(t, 0, 0.72)), up = spring(seg(t, 0.72, 1)), dr = d * (1 - up);
        const woke = t > 0.72 && t < 0.84;
        return {
          chars: [{ x: 140, y: GROUND, p: { top: 70 * dr, curve: 14 * dr, lean: 6 * dr }, face: woke ? 'shock' : 'sleepy',
            arms: woke ? [{ side: 1, dx: 18, dy: -16, hand: 'open', rot: -60 }, { side: -1, dx: -18, dy: -14, hand: 'open', rot: -120 }] : [HANG(1, 4 * dr), HANG(-1, 4 * dr)] }],
          label: { t: '오늘 쉼', x: 66, y: 44, r: -6, k: 1, size: 30 },
          fx(a, [c]) {
            if (dr > 0.25) for (let i = 0; i < 3; i++) { const ph = (t * 1.6 + i / 3) % 1; a.text('Z', c.head[0] + 20 + ph * 22, c.head[1] - 24 - ph * 36, 12 + i * 3 + ph * 6, -0.2, (dr - 0.25) * 1.4 * (1 - ph)); }
            if (woke) a.rays(c.tip[0], c.tip[1] + 4, 5, c.W * 0.75, c.W * 0.75 + 10, -Math.PI * 0.9, -Math.PI * 0.1, 3);
          },
        };
      },
    },
  ];
  const GROUPS = [
    { id: 'cheer', name: '인사·응원', note: '도장 문화 그대로. 인사하고, 응원하고, 주먹 맞대고, 엄지 척.' },
    { id: 'reply', name: '대답', note: '사람 손짓 그대로. 검지 까딱, 손바닥 시소, 박수, 배 잡고 웃기.' },
    { id: 'mat', name: '매트 위', note: '주짓수 하는 사람만 아는 순간. 탭, 도발, 헐떡, 승급.' },
    { id: 'mood', name: '기분', note: '놀람·부상·부끄·졸림. 앱 안 안내와 빈 화면에도 그대로.' },
  ];
  const BYID = Object.fromEntries(REACTIONS.map((r, i) => [r.id, Object.assign(r, { idx: i })]));

  /* ---------- 한 장면 그리기 ---------- */
  function drawSticker(cv, R, t, o) {
    const ctx = cv.getContext('2d');
    const S = cv.width / 240;
    ctx.setTransform(S, 0, 0, S, 0, 0);
    ctx.clearRect(0, 0, 240, 240);
    const st = o.style;
    drawBg(ctx, st, R, t, R.idx);
    if (!cv._tmp || cv._tmp.width !== cv.width) {
      cv._tmp = document.createElement('canvas');
      cv._tmp.width = cv._tmp.height = cv.width;
    }
    const tmp = cv._tmp.getContext('2d');
    const fr = R.f(t);
    const other = o.belt === 'blue' ? 'purple' : 'blue';
    const infos = fr.chars.map((c) => {
      ctx.save();
      const info = renderChar(ctx, tmp, c, st, c.belt === '__other' ? other : c.belt || o.belt, S);
      ctx.restore();
      return info;
    });
    ctx.setTransform(S, 0, 0, S, 0, 0);
    if (fr.fx) fr.fx(mkApi(ctx, st, R), infos);
    if (o.label !== false && fr.label) drawLabel(ctx, st, R, fr.label);
  }

  /* ---------- 재생 관리 ---------- */
  const state = { style: 'B', belt: 'white', speed: 1, playing: true };
  const reg = new Set();
  let clock = 0, last = performance.now();
  const io = 'IntersectionObserver' in window
    ? new IntersectionObserver((es) => es.forEach((e) => { e.target._vis = e.isIntersecting; }), { rootMargin: '120px' })
    : null;
  function fit(cv) {
    const dpr = Math.min(window.devicePixelRatio || 1, 2);
    const px = Math.max(60, Math.round(cv.clientWidth * dpr));
    if (cv.width !== px) { cv.width = px; cv.height = px; }
  }
  function drawCv(cv) {
    const R = BYID[cv.dataset.r];
    if (!R || !cv.clientWidth) return;
    fit(cv);
    const fixed = cv.dataset.t != null && cv.dataset.t !== '';
    const t = fixed ? +cv.dataset.t : ((clock / R.T) + (+cv.dataset.off || 0)) % 1;
    drawSticker(cv, R, t, { style: cv.dataset.style || state.style, belt: cv.dataset.belt || state.belt, label: cv.dataset.label !== 'off' });
  }
  function mount(root) {
    (root || document).querySelectorAll('canvas[data-r]').forEach((cv) => {
      if (reg.has(cv)) return;
      reg.add(cv);
      cv._vis = !io;
      if (io) io.observe(cv);
    });
  }
  function tick(now) {
    const dt = Math.min(0.1, (now - last) / 1000);
    last = now;
    if (state.playing) clock += dt * state.speed;
    reg.forEach((cv) => { if (cv._vis && cv.isConnected) drawCv(cv); });
    requestAnimationFrame(tick);
  }
  function redrawAll() { reg.forEach((cv) => { if (cv.isConnected) drawCv(cv); }); }

  window.Stickers = { REACTIONS, GROUPS, BELTS, BYID, state, mount, redrawAll, drawSticker, start() { requestAnimationFrame(tick); } };
})();
