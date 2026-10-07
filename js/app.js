// 생존수첩 — 화면 / 상태 / 도구
(function () {
  const KEY = 'survivalNote.v1';
  const $ = s => document.querySelector(s);
  const $$ = s => [...document.querySelectorAll(s)];
  const esc = s => String(s ?? '').replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));

  // ---------- 상태 (기기에만 저장) ----------
  const state = {
    me: null,              // {lat,lng,acc,at}
    view: null,
    places: null,          // {lat,lng,at,items:[]}
    typeFilter: null,
    pins: [],              // [{id,lat,lng,label}]
    bag: {},               // 체크리스트
    meds: [],              // [{id,name,use,qty,exp}]
    family: {},
    contacts: [],
    medId: {},
    apiKey: '',
    scanMode: 'medicine',
    history: []            // [{id,at,mode,thumb,result}]
  };
  function save() { try { localStorage.setItem(KEY, JSON.stringify(state)); } catch (e) { toast('⚠️ 저장 공간이 부족합니다'); } }
  try { Object.assign(state, JSON.parse(localStorage.getItem(KEY) || '{}')); } catch (e) { /* 무시 */ }

  let toastTimer;
  function toast(msg) {
    const t = $('#toast'); t.textContent = msg; t.hidden = false;
    clearTimeout(toastTimer); toastTimer = setTimeout(() => t.hidden = true, 2800);
  }

  // ---------- 네트워크 상태 ----------
  function renderNet() {
    const on = navigator.onLine;
    $('#netStatus').textContent = on ? '● 온라인' : '● 오프라인';
    $('#netStatus').className = 'net ' + (on ? 'on' : 'off');
  }
  addEventListener('online', renderNet); addEventListener('offline', renderNet); renderNet();

  // ---------- 화면 전환 ----------
  function show(name) {
    $$('.screen').forEach(s => s.classList.toggle('active', s.id === 'screen-' + name));
    $$('.bottom-nav button').forEach(b => b.classList.toggle('active', b.dataset.screen === name));
    if (name === 'map') initMap();
    scrollTo(0, 0);
  }
  $$('.bottom-nav button').forEach(b => b.onclick = () => show(b.dataset.screen));

  // ---------- 모달 ----------
  function openModal(html) {
    $('#modalContent').innerHTML = html;
    $('#modal').hidden = false;
    $('#modal .modal-body').scrollTop = 0;
  }
  function closeModal() { $('#modal').hidden = true; stopMetronome(); }
  $('#modalClose').onclick = closeModal;
  $('#modal').addEventListener('click', e => { if (e.target.id === 'modal') closeModal(); });
  document.addEventListener('keydown', e => { if (e.key === 'Escape') { closeModal(); closeFullscreen(); } });

  // ================= 긴급 =================
  $('#hotlines').innerHTML = HOTLINES.map(h =>
    `<a class="hotline ${h.main ? 'main' : ''}" href="tel:${h.num}"><span class="hl-emoji">${h.emoji}</span><b>${h.num}</b><small>${h.label}</small></a>`).join('');

  $('#alertGrid').innerHTML = ALERTS.map(a =>
    `<button type="button" class="alert-btn" data-alert="${a.id}"><span>${a.emoji}</span><b>${a.title}</b><small>${a.sound.split(' (')[0]}</small></button>`).join('');
  $('#alertGrid').addEventListener('click', e => {
    const b = e.target.closest('[data-alert]'); if (!b) return;
    const a = ALERTS.find(x => x.id === b.dataset.alert);
    openModal(`
      <h2>${a.emoji} ${a.title}</h2>
      <p class="muted">${a.meaning}<br>🔊 ${a.sound}</p>
      <ol class="steps">${a.steps.map(s => `<li>${esc(s)}</li>`).join('')}</ol>
      ${a.id === 'air' ? '<button type="button" class="btn primary block" data-goto-map>🗺️ 가까운 대피소·지하철역 찾기</button>' : ''}
      ${(a.guides || []).map(g => guideLink(g)).join('')}`);
  });

  const quick = ['cpr', 'bleeding', 'choking', 'burn', 'trauma', 'fracture'];
  $('#quickAid').innerHTML = quick.map(id => {
    const g = GUIDES.find(x => x.id === id);
    return `<button type="button" class="quick" data-guide="${g.id}"><span>${g.emoji}</span>${g.title.split(' (')[0]}</button>`;
  }).join('');

  // 위치
  function renderLoc() {
    const m = state.me;
    if (!m) { $('#myCoords').textContent = '위치 확인 전'; $('#locActions').hidden = true; return; }
    const ago = Math.round((Date.now() - m.at) / 60000);
    $('#myCoords').innerHTML = `${m.lat.toFixed(5)}, ${m.lng.toFixed(5)} <small class="muted">±${Math.round(m.acc || 0)}m · ${ago < 1 ? '방금' : ago + '분 전'}</small>`;
    $('#locActions').hidden = false;
    $('#smsLoc').href = 'sms:?&body=' + encodeURIComponent(locText());
  }
  function locText() {
    const m = state.me;
    return `[긴급] 제 위치입니다: ${m.lat.toFixed(5)}, ${m.lng.toFixed(5)} https://maps.google.com/?q=${m.lat.toFixed(5)},${m.lng.toFixed(5)}`;
  }
  function locate(then) {
    if (!navigator.geolocation) { toast('이 기기는 위치 기능을 지원하지 않습니다'); return; }
    toast('📍 위치 확인 중… (GPS는 인터넷 없이도 동작)');
    navigator.geolocation.getCurrentPosition(p => {
      state.me = { lat: p.coords.latitude, lng: p.coords.longitude, acc: p.coords.accuracy, at: Date.now() };
      save(); renderLoc(); drawMe();
      then && then();
    }, err => toast('위치를 가져오지 못했습니다: ' + (err.code === 1 ? '위치 권한을 허용해 주세요' : err.message)),
    { enableHighAccuracy: true, timeout: 15000, maximumAge: 30000 });
  }
  $('#locBtn').onclick = () => locate();
  $('#copyLoc').onclick = async () => { try { await navigator.clipboard.writeText(locText()); toast('📋 복사했습니다'); } catch (e) { toast('복사 실패'); } };
  $('#shareLoc').onclick = async () => {
    if (navigator.share) { try { await navigator.share({ text: locText() }); } catch (e) { /* 취소 */ } }
    else { try { await navigator.clipboard.writeText(locText()); toast('공유 기능이 없어 복사했습니다'); } catch (e) { /* 무시 */ } }
  };
  renderLoc();

  // ---------- 전체화면 도구 ----------
  let wakeLock = null, sosTimer = null, audioCtx = null;
  async function keepAwake() { try { wakeLock = await navigator.wakeLock?.request('screen'); } catch (e) { /* 미지원 */ } }
  function openFullscreen(html, cls) {
    $('#fsContent').innerHTML = html;
    $('#fullscreen').className = 'fullscreen ' + (cls || '');
    $('#fullscreen').hidden = false;
    keepAwake();
  }
  function closeFullscreen() {
    $('#fullscreen').hidden = true;
    clearTimeout(sosTimer); sosTimer = null;
    try { wakeLock?.release(); } catch (e) { /* 무시 */ }
    wakeLock = null;
  }
  $('#fsClose').onclick = closeFullscreen;

  function beep(freq, ms) {
    audioCtx ||= new (window.AudioContext || window.webkitAudioContext)();
    const o = audioCtx.createOscillator(), g = audioCtx.createGain();
    o.frequency.value = freq; o.type = 'square';
    g.gain.value = 0.4;
    o.connect(g); g.connect(audioCtx.destination);
    o.start(); o.stop(audioCtx.currentTime + ms / 1000);
  }

  $('#toolLight').onclick = () => openFullscreen('<p class="fs-hint">화면 밝기를 최대로 올리세요</p>', 'light');
  $('#toolSos').onclick = () => {
    openFullscreen('<div class="sos-text">SOS</div><p class="fs-hint">··· ─── ··· 빛과 소리로 반복 송신 중</p>', 'sos');
    // 모스부호 SOS: 단점 1, 장점 3, 글자 내 간격 1, 글자 간 3, 반복 간 7 (단위 220ms)
    const U = 220, seq = [];
    const letter = dur => dur.forEach((d, i) => { seq.push([true, d]); seq.push([false, i < dur.length - 1 ? 1 : 3]); });
    letter([1, 1, 1]); letter([3, 3, 3]); letter([1, 1, 1]); seq[seq.length - 1][1] = 7;
    let i = 0;
    const fs = $('#fullscreen');
    const step = () => {
      if (fs.hidden) return;
      const [on, d] = seq[i % seq.length];
      fs.classList.toggle('flash', on);
      if (on) try { beep(880, d * U); } catch (e) { /* 소리 불가 */ }
      i++;
      sosTimer = setTimeout(step, d * U);
    };
    step();
  };
  $('#toolWhistle').onclick = () => {
    openFullscreen('<button type="button" class="whistle-btn" id="whistleBtn">📣<br>누르는 동안 소리</button><p class="fs-hint">호루라기 신호: 짧게 3번 = 구조 요청</p>', 'whistle');
    const b = $('#whistleBtn');
    let osc = null;
    const startW = e => {
      e.preventDefault();
      audioCtx ||= new (window.AudioContext || window.webkitAudioContext)();
      osc = audioCtx.createOscillator(); const g = audioCtx.createGain();
      osc.frequency.value = 3150; osc.type = 'square'; g.gain.value = 0.5;
      osc.connect(g); g.connect(audioCtx.destination); osc.start();
    };
    const stopW = () => { try { osc?.stop(); } catch (e) { /* 무시 */ } osc = null; };
    b.addEventListener('pointerdown', startW); b.addEventListener('pointerup', stopW); b.addEventListener('pointerleave', stopW);
  };
  $('#toolMedId').onclick = () => {
    const m = state.medId, c = state.contacts;
    const rows = [['이름', m.name], ['생년월일', m.birth], ['혈액형', m.blood], ['지병', m.conditions], ['복용 약', m.meds], ['알레르기', m.allergy]]
      .filter(([, v]) => v).map(([k, v]) => `<div class="mid-row"><span>${k}</span><b>${esc(v)}</b></div>`).join('');
    openFullscreen(`<div class="medid">
      <h2>🪪 의료 정보 MEDICAL ID</h2>
      ${rows || '<p>등록된 정보가 없습니다. 준비 → 가족 계획에서 입력하세요.</p>'}
      ${c.length ? `<h3>비상 연락처</h3>${c.map(x => `<a class="mid-row" href="tel:${esc(x.phone)}"><span>${esc(x.name)}</span><b>${esc(x.phone)}</b></a>`).join('')}` : ''}
    </div>`, 'medid-fs');
  };

  // ================= 응급처치 =================
  function guideCard(g) {
    return `<button type="button" class="guide ${g.urgent ? 'urgent' : ''}" data-guide="${g.id}">
      <span class="g-emoji">${g.emoji}</span><span class="g-main"><b>${g.title}</b><small>${esc(g.summary)}</small></span></button>`;
  }
  function guideLink(id) {
    const g = GUIDES.find(x => x.id === id);
    return g ? `<button type="button" class="guide-link" data-guide="${g.id}">${g.emoji} ${g.title} 보기 →</button>` : '';
  }
  function renderGuides(q = '') {
    const words = q.trim().toLowerCase().split(/\s+/).filter(Boolean);
    const list = GUIDES.filter(g => !words.length || words.every(w => (g.title + ' ' + g.tags + ' ' + g.summary).toLowerCase().includes(w)));
    $('#guideList').innerHTML = list.map(guideCard).join('') || '<p class="muted">검색 결과가 없습니다. 다른 단어로 찾아보세요.</p>';
  }
  $('#aidSearch').addEventListener('input', e => renderGuides(e.target.value));
  renderGuides();

  function openGuide(id) {
    const g = GUIDES.find(x => x.id === id); if (!g) return;
    openModal(`
      <h2>${g.emoji} ${g.title}</h2>
      <p class="lead">${esc(g.summary)}</p>
      ${g.call ? `<a class="call-box" href="tel:119">📞 ${esc(g.call)}</a>` : ''}
      ${g.tool === 'metronome' ? `<div class="metronome"><button type="button" class="btn primary block" id="metroBtn">▶ 압박 박자 (분당 110회) 켜기</button><div class="beat" id="beat"></div><div class="small muted" id="metroCount"></div></div>` : ''}
      <h3>해야 할 일</h3>
      <ol class="steps">${g.steps.map(s => `<li>${esc(s)}</li>`).join('')}</ol>
      ${g.dont.length ? `<h3>❌ 하지 말 것</h3><ul class="dont">${g.dont.map(s => `<li>${esc(s)}</li>`).join('')}</ul>` : ''}
      ${g.notes.length ? `<h3>📌 참고</h3><ul class="notes">${g.notes.map(s => `<li>${esc(s)}</li>`).join('')}</ul>` : ''}
      <p class="disclaimer">의료진의 진료를 대신하지 않습니다.</p>`);
    if (g.tool === 'metronome') $('#metroBtn').onclick = toggleMetronome;
  }
  document.addEventListener('click', e => {
    const g = e.target.closest('[data-guide]');
    if (g) { openGuide(g.dataset.guide); return; }
    if (e.target.closest('[data-goto-map]')) { closeModal(); show('map'); state.typeFilter = 'refuge'; findNearby(); }
  });

  // CPR 메트로놈
  let metroTimer = null, metroN = 0;
  function toggleMetronome() {
    if (metroTimer) { stopMetronome(); return; }
    metroN = 0;
    keepAwake();
    const tick = () => {
      metroN++;
      try { beep(metroN % 30 === 0 ? 660 : 1000, 60); } catch (e) { /* 무시 */ }
      const b = $('#beat'); if (b) { b.classList.remove('on'); void b.offsetWidth; b.classList.add('on'); }
      const c = $('#metroCount'); if (c) c.textContent = `압박 ${metroN}회 · ${Math.floor(metroN / 110 * 60)}초 경과 — 2분마다 교대`;
    };
    tick();
    metroTimer = setInterval(tick, 60000 / 110);
    $('#metroBtn').textContent = '⏸ 박자 끄기';
  }
  function stopMetronome() {
    clearInterval(metroTimer); metroTimer = null;
    const b = $('#metroBtn'); if (b) b.textContent = '▶ 압박 박자 (분당 110회) 켜기';
  }

  // ================= 지도 =================
  let map = null, meMarker = null;
  const placeLayer = L.layerGroup(), pinLayer = L.layerGroup();
  let pinMode = false;

  function initMap() {
    if (map) { setTimeout(() => map.invalidateSize(), 50); return; }
    const c = state.view || state.me || { lat: 37.5665, lng: 126.9780 };
    map = L.map('map', { zoomControl: false }).setView([c.lat, c.lng], state.view?.zoom || 15);
    L.control.zoom({ position: 'topright' }).addTo(map);
    L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
      maxZoom: 19, attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
    }).addTo(map);
    placeLayer.addTo(map); pinLayer.addTo(map);
    map.on('moveend', () => { const m = map.getCenter(); state.view = { lat: m.lat, lng: m.lng, zoom: map.getZoom() }; save(); });
    map.on('click', e => {
      if (!pinMode) return;
      const label = prompt('이 장소의 이름 (예: 우리 가족 집결지, 물 받는 곳, 위험 — 무너진 건물)');
      if (label !== null) { state.pins.push({ id: Date.now(), lat: e.latlng.lat, lng: e.latlng.lng, label: label.trim() || '내 장소' }); save(); drawPins(); }
      setPinMode(false);
    });
    drawMe(); drawPins(); renderPlaces();
    setTimeout(() => map.invalidateSize(), 50);
  }

  function icon(emoji, color, cls = '') {
    return L.divIcon({ className: 'poi ' + cls, html: `<span style="--c:${color}">${emoji}</span>`, iconSize: [30, 30], iconAnchor: [15, 15], popupAnchor: [0, -14] });
  }
  function drawMe() {
    if (!map || !state.me) return;
    meMarker?.remove();
    meMarker = L.marker([state.me.lat, state.me.lng], { icon: L.divIcon({ className: 'me', html: '<span></span>', iconSize: [20, 20] }), zIndexOffset: 1000 })
      .bindTooltip('내 위치').addTo(map);
  }
  function drawPins() {
    pinLayer.clearLayers();
    state.pins.forEach(p => {
      const m = L.marker([p.lat, p.lng], { icon: icon('📌', '#ffd54f', 'pin'), draggable: true })
        .bindPopup(`<b>${esc(p.label)}</b><br><button type="button" class="btn small" data-delpin="${p.id}">삭제</button>`);
      m.on('dragend', () => { const ll = m.getLatLng(); p.lat = ll.lat; p.lng = ll.lng; save(); });
      m.addTo(pinLayer);
    });
  }
  document.addEventListener('click', e => {
    const d = e.target.closest('[data-delpin]'); if (!d) return;
    state.pins = state.pins.filter(p => String(p.id) !== d.dataset.delpin); save(); drawPins(); map?.closePopup();
  });
  function setPinMode(on) { pinMode = on; $('#pinBanner').hidden = !on; $('#map').classList.toggle('picking', on); }
  $('#mapPin').onclick = () => setPinMode(true);
  $('#pinCancel').onclick = () => setPinMode(false);
  $('#mapLocate').onclick = () => locate(() => map && map.setView([state.me.lat, state.me.lng], 16));

  const REFUGE_TYPES = ['shelter', 'subway'];
  function origin() { return state.me || (state.places ? { lat: state.places.lat, lng: state.places.lng } : null); }

  function renderChips() {
    const counts = {};
    (state.places?.items || []).forEach(p => counts[p.type] = (counts[p.type] || 0) + 1);
    const refuge = (counts.shelter || 0) + (counts.subway || 0);
    $('#typeChips').innerHTML = `<button type="button" class="chip ${!state.typeFilter ? 'active' : ''}" data-type="">전체</button>` +
      `<button type="button" class="chip ${state.typeFilter === 'refuge' ? 'active' : ''}" data-type="refuge">🛡️ 대피 가능 곳${refuge ? ` <em>${refuge}</em>` : ''}</button>` +
      Object.entries(PLACE_TYPES).map(([k, t]) =>
        `<button type="button" class="chip ${state.typeFilter === k ? 'active' : ''}" data-type="${k}">${t.emoji} ${t.label}${counts[k] ? ` <em>${counts[k]}</em>` : ''}</button>`).join('');
  }
  $('#typeChips').addEventListener('click', e => {
    const c = e.target.closest('[data-type]'); if (!c) return;
    state.typeFilter = c.dataset.type || null; save(); renderPlaces();
  });

  function renderPlaces() {
    renderChips();
    placeLayer.clearLayers();
    const data = state.places;
    if (!data) { $('#placeList').innerHTML = ''; return; }
    const o = origin();
    const items = data.items
      .filter(p => !state.typeFilter || p.type === state.typeFilter || (state.typeFilter === 'refuge' && REFUGE_TYPES.includes(p.type)))
      .map(p => ({ ...p, dist: haversine(o, p) }))
      .sort((a, b) => a.dist - b.dist);
    const ago = Math.round((Date.now() - data.at) / 60000);
    $('#mapInfo').innerHTML = `${items.length}곳 · ${ago < 60 ? ago + '분' : Math.round(ago / 60) + '시간'} 전 검색${navigator.onLine ? '' : ' · <b>오프라인 저장본</b>'} · 거리 기준: ${state.me ? '내 위치' : '검색 중심'}`;
    items.slice(0, 300).forEach(p => {
      const t = PLACE_TYPES[p.type];
      L.marker([p.lat, p.lng], { icon: icon(t.emoji, t.color) }).bindPopup(placePopup(p)).addTo(placeLayer);
    });
    $('#placeList').innerHTML = items.slice(0, 40).map(p => {
      const t = PLACE_TYPES[p.type];
      return `<li data-place="${esc(p.id)}"><span class="li-emoji">${t.emoji}</span>
        <span class="li-main"><b>${esc(p.name || t.label)}</b><small>${t.label} · ${bearingKo(o, p)}쪽 ${fmtDist(p.dist)} · 도보 ${walkMin(p.dist)}분</small></span>
        <a class="btn small" href="${navUrl(p)}" target="_blank" rel="noopener">길찾기</a></li>`;
    }).join('') || '<li class="muted">이 종류의 시설이 검색 범위에 없습니다. 지도를 옮겨 다시 찾아보세요.</li>';
  }
  function navUrl(p) {
    const name = encodeURIComponent((p.name || PLACE_TYPES[p.type].label).replace(/,/g, ' '));
    return `https://map.kakao.com/link/to/${name},${p.lat},${p.lng}`;
  }
  function placePopup(p) {
    const t = PLACE_TYPES[p.type];
    return `<b>${t.emoji} ${esc(p.name || t.label)}</b><br><small>${t.label}</small>
      ${p.level ? `<br>층: ${esc(p.level)}` : ''}${p.desc ? `<br>${esc(p.desc)}` : ''}${p.hours ? `<br>🕘 ${esc(p.hours)}` : ''}
      ${p.phone ? `<br><a href="tel:${esc(p.phone)}">📞 ${esc(p.phone)}</a>` : ''}
      <br><a href="${navUrl(p)}" target="_blank" rel="noopener">🧭 카카오맵 길찾기</a>`;
  }
  $('#placeList').addEventListener('click', e => {
    if (e.target.closest('a')) return;
    const li = e.target.closest('[data-place]'); if (!li) return;
    const p = state.places.items.find(x => x.id === li.dataset.place);
    map.setView([p.lat, p.lng], 18);
    placeLayer.eachLayer(l => { const ll = l.getLatLng(); if (ll.lat === p.lat && ll.lng === p.lng) l.openPopup(); });
    scrollTo({ top: 0, behavior: 'smooth' });
  });

  async function findNearby() {
    initMap();
    if (!navigator.onLine) { toast('오프라인입니다. 마지막으로 저장된 검색 결과를 보여드립니다'); renderPlaces(); return; }
    const c = map.getCenter();
    const btn = $('#mapScan'); btn.disabled = true; btn.textContent = '찾는 중…';
    try {
      const items = await fetchNearby(c.lat, c.lng, 1500);
      state.places = { lat: c.lat, lng: c.lng, at: Date.now(), items };
      save(); renderPlaces();
      toast(`반경 1.5km에서 ${items.length}곳을 찾았습니다`);
    } catch (e) {
      toast('검색 실패 — 네트워크를 확인하세요. 저장된 결과를 표시합니다');
      renderPlaces();
    } finally { btn.disabled = false; btn.textContent = '주변 시설 찾기'; }
  }
  $('#mapScan').onclick = findNearby;

  const results = $('#searchResults');
  $('#searchForm').onsubmit = async e => {
    e.preventDefault();
    const q = $('#searchInput').value.trim(); if (!q) return;
    try {
      const list = await geocode(q);
      results.innerHTML = list.length ? list.map((r, i) => `<li data-i="${i}">${esc(r.display_name)}</li>`).join('') : '<li class="muted">결과 없음</li>';
      results.hidden = false;
      results.onclick = ev => {
        const li = ev.target.closest('[data-i]'); if (!li) return;
        const r = list[+li.dataset.i];
        map.setView([+r.lat, +r.lon], 16); results.hidden = true;
      };
    } catch (err) { toast('검색 실패 (인터넷 연결 필요)'); }
  };
  document.addEventListener('click', e => { if (!e.target.closest('.map-search')) results.hidden = true; });

  // ================= 사진 분석 =================
  let photo = null;
  function renderModes() {
    $('#modeGrid').innerHTML = Object.entries(SCAN_MODES).map(([k, m]) =>
      `<button type="button" class="mode ${state.scanMode === k ? 'active' : ''}" data-mode="${k}"><span>${m.emoji}</span>${m.label}</button>`).join('');
    $('#modeHint').textContent = SCAN_MODES[state.scanMode].hint;
  }
  $('#modeGrid').addEventListener('click', e => {
    const b = e.target.closest('[data-mode]'); if (!b) return;
    state.scanMode = b.dataset.mode; save(); renderModes();
  });
  renderModes();

  $('#photoInput').onchange = async e => {
    const f = e.target.files[0]; if (!f) return;
    try {
      photo = await resizeImage(f);
      $('#photoPreview').src = photo.preview; $('#photoPreview').hidden = false;
      $('#captureText').textContent = '📸 다시 찍기';
      $('#analyzeBtn').disabled = false;
      $('#scanResult').innerHTML = '';
    } catch (err) { toast(err.message); }
    e.target.value = '';
  };

  function setStatus(html, cls = '') { const s = $('#scanStatus'); s.innerHTML = html; s.className = 'status ' + cls; s.hidden = !html; }

  $('#analyzeBtn').onclick = async () => {
    if (!photo) return;
    if (!state.apiKey) { openSettings('사진 분석을 쓰려면 Anthropic API 키가 필요합니다.'); return; }
    if (!navigator.onLine) { setStatus(esc(aiErrorMessage(null)) + offlineGuideLinks(), 'err'); return; }
    const btn = $('#analyzeBtn'); btn.disabled = true;
    setStatus('<span class="spinner"></span> 분석 중… (10~40초)');
    try {
      const result = await analyzePhoto({ apiKey: state.apiKey, mode: state.scanMode, base64: photo.base64, note: $('#scanNote').value.trim() });
      setStatus('');
      $('#scanResult').innerHTML = resultHtml(result, state.scanMode);
      state.history.unshift({ id: Date.now(), at: Date.now(), mode: state.scanMode, thumb: photo.thumb, result });
      state.history = state.history.slice(0, 20);
      save(); renderHistory();
    } catch (err) {
      console.error(err);
      setStatus('⚠️ ' + esc(aiErrorMessage(err)) + offlineGuideLinks(), 'err');
    } finally { btn.disabled = false; }
  };

  function offlineGuideLinks() {
    const ids = { medicine: [], plant: ['dehydration'], wound: ['bleeding', 'wound', 'burn'], other: ['water'] }[state.scanMode];
    return ids.length ? '<div class="small">' + ids.map(guideLink).join('') + '</div>' : '';
  }

  function resultHtml(r, mode) {
    const lvl = { '안전': 'lo', '주의': 'mid', '위험': 'hi', '불명': 'unk' }[r.danger_level] || 'unk';
    return `<div class="result">
      <div class="result-head">
        <span class="r-emoji">${SCAN_MODES[mode]?.emoji || '🔎'}</span>
        <div><h3>${esc(r.title)}</h3>
        <div class="row gap wrap"><span class="badge ${lvl}">${esc(r.danger_level)}</span><span class="badge unk">신뢰도 ${esc(r.confidence)}</span></div></div>
      </div>
      ${r.call_emergency ? '<a class="call-box" href="tel:119">🚨 의료진의 도움이 필요한 상태일 수 있습니다. 가능하면 119에 연락하세요.</a>' : ''}
      <p>${esc(r.summary)}</p>
      ${r.warnings?.length ? `<ul class="dont">${r.warnings.map(w => `<li>${esc(w)}</li>`).join('')}</ul>` : ''}
      ${(r.sections || []).map(s => `<h4>${esc(s.heading)}</h4><ul>${s.items.map(i => `<li>${esc(i)}</li>`).join('')}</ul>`).join('')}
      ${(r.related_guides || []).map(guideLink).join('')}
      <p class="disclaimer">AI 분석 결과는 틀릴 수 있습니다.${mode === 'plant' ? ' 확실하지 않은 식물·버섯은 먹지 마세요.' : ''}</p>
    </div>`;
  }

  function renderHistory() {
    $('#scanHistory').innerHTML = state.history.map(h =>
      `<li data-hist="${h.id}"><img src="${h.thumb}" alt="" class="thumb"><span class="li-main"><b>${esc(h.result.title)}</b>
        <small>${SCAN_MODES[h.mode]?.label || ''} · ${new Date(h.at).toLocaleString('ko-KR', { month: 'numeric', day: 'numeric', hour: '2-digit', minute: '2-digit' })}</small></span>
        <button type="button" class="icon-btn" data-delhist="${h.id}" aria-label="삭제">✕</button></li>`).join('') || '<li class="muted small">아직 없습니다. 분석 결과는 기기에 저장되어 오프라인에서도 다시 볼 수 있습니다.</li>';
  }
  $('#scanHistory').addEventListener('click', e => {
    const d = e.target.closest('[data-delhist]');
    if (d) { state.history = state.history.filter(h => String(h.id) !== d.dataset.delhist); save(); renderHistory(); return; }
    const li = e.target.closest('[data-hist]'); if (!li) return;
    const h = state.history.find(x => String(x.id) === li.dataset.hist);
    openModal(`<img src="${h.thumb}" alt="" class="hist-img">` + resultHtml(h.result, h.mode));
  });
  renderHistory();

  // 설정
  function openSettings(msg) {
    openModal(`
      <h2>⚙️ 설정</h2>
      ${msg ? `<p class="notice">${esc(msg)}</p>` : ''}
      <h3>사진 분석 (Anthropic API 키)</h3>
      <p class="small muted">사진 분석은 Claude AI를 사용합니다. <a href="https://console.anthropic.com/settings/keys" target="_blank" rel="noopener">console.anthropic.com</a>에서 API 키를 발급받아 입력하세요. 키는 이 기기에만 저장되며 Anthropic 외의 곳으로 전송되지 않습니다. 사용량에 따라 요금이 부과됩니다.</p>
      <input type="password" id="apiKeyInput" class="search-big" placeholder="sk-ant-..." value="${esc(state.apiKey)}" autocomplete="off">
      <div class="row gap"><button type="button" class="btn primary" id="saveKey">저장</button><button type="button" class="btn" id="clearKey">삭제</button></div>
      <h3>오프라인 사용</h3>
      <p class="small muted">이 앱은 한 번 열면 기기에 저장되어 인터넷이 끊겨도 응급처치·경보 행동요령·체크리스트·저장된 지도 검색 결과를 쓸 수 있습니다. 브라우저 메뉴에서 <b>홈 화면에 추가</b>하세요. 지도 배경은 미리 본 지역만 오프라인에서 보입니다.</p>
      <h3>데이터</h3>
      <p class="small muted">모든 기록은 이 기기의 브라우저에만 저장됩니다.</p>
      <button type="button" class="btn danger" id="wipeAll">모든 데이터 삭제</button>`);
    $('#saveKey').onclick = () => { state.apiKey = $('#apiKeyInput').value.trim(); save(); toast('저장했습니다'); closeModal(); };
    $('#clearKey').onclick = () => { state.apiKey = ''; save(); $('#apiKeyInput').value = ''; toast('삭제했습니다'); };
    $('#wipeAll').onclick = () => { if (confirm('모든 기록(체크리스트·약·연락처·분석 기록·API 키)을 삭제할까요?')) { localStorage.removeItem(KEY); location.reload(); } };
  }
  $('#settingsBtn').onclick = () => openSettings();

  // ================= 준비 =================
  $$('#prepTabs button').forEach(b => b.onclick = () => {
    $$('#prepTabs button').forEach(x => x.classList.toggle('active', x === b));
    $$('.prep').forEach(p => p.hidden = p.dataset.prep !== b.dataset.prep);
  });

  function renderBag() {
    let total = 0, done = 0;
    $('#checklist').innerHTML = CHECKLIST.map(g => `<h3>${g.group}</h3><div class="checks">${g.items.map(([k, label]) => {
      total++; if (state.bag[k]) done++;
      return `<label class="check"><input type="checkbox" data-bag="${k}" ${state.bag[k] ? 'checked' : ''}><span>${label}</span></label>`;
    }).join('')}</div>`).join('');
    $('#bagProgress').style.width = (done / total * 100) + '%';
    $('#bagCount').textContent = `${done} / ${total} 준비 완료`;
  }
  $('#checklist').addEventListener('change', e => { const k = e.target.dataset.bag; if (k) { state.bag[k] = e.target.checked; save(); renderBag(); } });
  renderBag();

  function renderMeds() {
    const today = new Date(); today.setHours(0, 0, 0, 0);
    $('#medList').innerHTML = state.meds.slice().sort((a, b) => (a.exp || '9999').localeCompare(b.exp || '9999')).map(m => {
      let badge = '';
      if (m.exp) {
        const days = Math.round((new Date(m.exp + 'T00:00') - today) / 86400000);
        badge = days < 0 ? '<span class="badge hi">기한 지남</span>' : days <= 30 ? `<span class="badge mid">${days}일 남음</span>` : `<span class="badge lo">${m.exp}</span>`;
      }
      return `<li><span class="li-emoji">💊</span><span class="li-main"><b>${esc(m.name)}</b><small>${esc([m.use, m.qty].filter(Boolean).join(' · '))}</small></span>${badge}
        <button type="button" class="icon-btn" data-delmed="${m.id}" aria-label="삭제">✕</button></li>`;
    }).join('') || '<li class="muted small">등록된 약이 없습니다.</li>';
  }
  $('#medForm').onsubmit = e => {
    e.preventDefault();
    const f = new FormData(e.target);
    state.meds.push({ id: Date.now(), name: f.get('name').trim(), use: f.get('use').trim(), qty: f.get('qty').trim(), exp: f.get('exp') });
    e.target.reset(); save(); renderMeds();
  };
  $('#medList').addEventListener('click', e => { const d = e.target.dataset.delmed; if (d) { state.meds = state.meds.filter(m => String(m.id) !== d); save(); renderMeds(); } });
  renderMeds();

  $$('[data-fam]').forEach(i => { i.value = state.family[i.dataset.fam] || ''; i.oninput = () => { state.family[i.dataset.fam] = i.value; save(); }; });
  $$('[data-mid]').forEach(i => { i.value = state.medId[i.dataset.mid] || ''; i.oninput = () => { state.medId[i.dataset.mid] = i.value; save(); }; });

  function renderContacts() {
    $('#contactList').innerHTML = state.contacts.map((c, i) =>
      `<li><span class="li-emoji">👤</span><span class="li-main"><b>${esc(c.name)}</b><small>${esc(c.phone)}</small></span>
        <a class="btn small" href="tel:${esc(c.phone)}">📞</a><a class="btn small" href="sms:${esc(c.phone)}">✉️</a>
        <button type="button" class="icon-btn" data-delc="${i}" aria-label="삭제">✕</button></li>`).join('') || '<li class="muted small">등록된 연락처가 없습니다.</li>';
  }
  $('#contactForm').onsubmit = e => {
    e.preventDefault(); const f = new FormData(e.target);
    state.contacts.push({ name: f.get('name').trim(), phone: f.get('phone').trim() }); e.target.reset(); save(); renderContacts();
  };
  $('#contactList').addEventListener('click', e => { const d = e.target.dataset.delc; if (d !== undefined) { state.contacts.splice(+d, 1); save(); renderContacts(); } });
  renderContacts();

  function renderCalc() {
    const n = Math.max(1, +$('#calcPeople').value || 1), d = Math.max(1, +$('#calcDays').value || 1);
    const water = n * d * 3;
    $('#calcResult').innerHTML = `
      <div class="calc-row"><span>💧 물</span><b>${water}L</b><small>2L 생수 ${Math.ceil(water / 2)}병</small></div>
      <div class="calc-row"><span>🍚 열량</span><b>${(n * d * 2000).toLocaleString()}kcal</b><small>하루 3끼 기준 약 ${n * d * 3}끼</small></div>
      <div class="calc-row"><span>🔋 건전지</span><b>${Math.ceil(d / 3) * 4}개+</b><small>라디오·손전등용</small></div>
      <div class="calc-row"><span>🧻 휴지</span><b>${Math.ceil(n * d / 7)}롤+</b><small>물티슈 별도</small></div>`;
  }
  $('#calcPeople').oninput = renderCalc; $('#calcDays').oninput = renderCalc; renderCalc();

  // ---------- 오프라인 캐시 (서비스 워커) ----------
  if ('serviceWorker' in navigator && location.protocol !== 'file:') {
    navigator.serviceWorker.register('sw.js').catch(e => console.warn('SW 등록 실패', e));
  }
})();
