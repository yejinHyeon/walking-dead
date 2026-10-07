// 워커 맵 — UI / 지도 / 상태 관리
(function () {
  const STORAGE_KEY = 'walkerMap.v1';
  const DEFAULT_CENTER = { lat: 37.5665, lng: 126.9780 }; // 서울시청
  const MAX_PER_CATEGORY = 200;

  const $ = s => document.querySelector(s);
  const $$ = s => [...document.querySelectorAll(s)];
  const esc = s => String(s ?? '').replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));

  // ---------- 상태 ----------
  const state = {
    scenario: 7,
    time: 'day',
    radius: 1000,
    enabled: Object.fromEntries(Object.keys(CATEGORIES).map(k => [k, true])),
    showThreat: true,
    showLabels: false,
    me: null,
    base: null,              // {lat,lng,name,id?}
    route: [],               // [{id,lat,lng,name,cat}]
    markers: [],             // [{id,type,lat,lng,note}]
    inventory: { people: 4, food: 20, water: 30, medical: 1, ammo: 12, melee: 3, fuel: 0 },
    view: null,              // {lat,lng,zoom}
    scan: null               // {lat,lng,radius,places,demo}
  };

  function save() {
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
    } catch (e) { /* 저장 불가 환경 */ }
  }
  function load() {
    try {
      const raw = localStorage.getItem(STORAGE_KEY);
      if (raw) applySaved(JSON.parse(raw));
    } catch (e) { /* 무시 */ }
  }
  function applySaved(s) {
    for (const k of Object.keys(state)) if (s[k] !== undefined) state[k] = s[k];
    state.enabled = { ...Object.fromEntries(Object.keys(CATEGORIES).map(k => [k, true])), ...(s.enabled || {}) };
    if (!SCENARIOS[state.scenario]) state.scenario = 7;
  }

  load();

  // ---------- 지도 ----------
  const start = state.view || { ...DEFAULT_CENTER, zoom: 15 };
  const map = L.map('map', { zoomControl: false, preferCanvas: true }).setView([start.lat, start.lng], start.zoom);
  L.control.zoom({ position: 'bottomleft' }).addTo(map);
  L.control.scale({ position: 'bottomleft', imperial: false }).addTo(map);

  const darkTiles = L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png', {
    maxZoom: 19, subdomains: 'abcd',
    attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> &copy; <a href="https://carto.com/">CARTO</a>'
  });
  const osmTiles = L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
    maxZoom: 19, attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
  });
  darkTiles.addTo(map);
  L.control.layers({ '폐허 (어둡게)': darkTiles, '일반 지도': osmTiles }, null, { position: 'bottomleft' }).addTo(map);

  const threatLayer = L.layerGroup().addTo(map);
  const placeLayer = L.layerGroup().addTo(map);
  const planLayer = L.layerGroup().addTo(map);
  const scanAreaLayer = L.layerGroup().addTo(map);
  let meMarker = null;

  map.on('moveend', () => {
    const c = map.getCenter();
    state.view = { lat: c.lat, lng: c.lng, zoom: map.getZoom() };
    save();
  });

  function emojiIcon(emoji, color, cls = '') {
    return L.divIcon({
      className: 'poi-icon ' + cls,
      html: `<span style="--c:${color}">${emoji}</span>`,
      iconSize: [28, 28], iconAnchor: [14, 14], popupAnchor: [0, -14]
    });
  }

  // ---------- 분석 ----------
  let analysis = null;

  function origin() {
    if (state.base) return state.base;
    if (state.me) return state.me;
    if (state.scan) return { lat: state.scan.lat, lng: state.scan.lng };
    const c = map.getCenter();
    return { lat: c.lat, lng: c.lng };
  }
  function originLabel() {
    if (state.base) return '거점';
    if (state.me) return '내 위치';
    return '정찰 중심';
  }

  function recompute() {
    if (!state.scan) { analysis = null; return; }
    analysis = analyzeArea(state.scan.places, origin(), SCENARIOS[state.scenario], state.time, state.inventory);
  }

  // ---------- 렌더: 장소 ----------
  function renderPlaces() {
    placeLayer.clearLayers();
    threatLayer.clearLayers();
    if (!analysis) return;
    const byCat = {};
    for (const p of analysis.enriched) (byCat[p.cat] ||= []).push(p);
    for (const [cat, list] of Object.entries(byCat)) {
      if (!state.enabled[cat]) continue;
      const def = CATEGORIES[cat];
      list.sort((a, b) => a.dist - b.dist).slice(0, MAX_PER_CATEGORY).forEach(p => {
        const m = L.marker([p.lat, p.lng], { icon: emojiIcon(def.emoji, def.color, p.threat >= 70 ? 'hot' : ''), riseOnHover: true });
        m.bindPopup(() => placePopup(p), { maxWidth: 300, minWidth: 240 });
        const title = p.name || def.label;
        m.bindTooltip(esc(title), { direction: 'top', offset: [0, -12], permanent: state.showLabels, className: 'poi-label' });
        m.addTo(placeLayer);
        if (state.showThreat && p.walkers >= 5) {
          L.circle([p.lat, p.lng], {
            radius: clamp(Math.sqrt(p.walkers) * 6, 15, 220),
            stroke: false, fillColor: '#ff1744', fillOpacity: clamp(0.08 + p.threat / 500, 0.08, 0.3),
            interactive: false
          }).addTo(threatLayer);
        }
      });
    }
  }

  function bar(v, max = 5, cls = '') {
    return `<span class="bar ${cls}"><i style="width:${clamp(v / max * 100, 0, 100)}%"></i></span>`;
  }

  function placePopup(p) {
    const def = CATEGORIES[p.cat];
    const from = origin();
    const res = Object.entries(p.resources)
      .filter(([, v]) => v > 0.05)
      .map(([k, v]) => `<div class="res"><span>${RESOURCE_LABELS[k]}</span>${bar(v)}</div>`).join('');
    const inRoute = state.route.some(w => w.id === p.id);
    const div = document.createElement('div');
    div.className = 'popup';
    div.innerHTML = `
      <div class="popup-head"><span class="pe">${def.emoji}</span><div><b>${esc(p.name || def.label)}</b><small>${def.label} · ${originLabel()}에서 ${bearingKo(from, p)}쪽 ${formatDistance(p.dist)}</small></div></div>
      <div class="popup-stats">
        <div><b class="red">${p.walkers.toLocaleString()}</b><span>워커</span></div>
        <div><b class="green">${p.survivors.toLocaleString()}</b><span>생존자</span></div>
        <div><b>${p.threat}</b><span>위협도</span></div>
      </div>
      ${bar(p.threat, 100, 'threat')}
      <div class="res-list">${res}</div>
      <p class="tip">💬 ${esc(def.tip)}</p>
      <p class="muted small">남은 물자 약 ${Math.round(p.lootLeft * 100)}% (${SCENARIOS[state.scenario].label})</p>
      <div class="row gap">
        <button type="button" class="btn small" data-act="base">🏰 거점 지정</button>
        <button type="button" class="btn small" data-act="route" ${inRoute ? 'disabled' : ''}>${inRoute ? '✓ 루트에 있음' : '➕ 경유지 추가'}</button>
      </div>`;
    div.querySelector('[data-act=base]').onclick = () => { setBase({ id: p.id, lat: p.lat, lng: p.lng, name: p.name || def.label, cat: p.cat }); map.closePopup(); };
    const rb = div.querySelector('[data-act=route]');
    rb.onclick = () => { addWaypoint(p); rb.disabled = true; rb.textContent = '✓ 루트에 있음'; };
    return div;
  }

  // ---------- 렌더: 작전 레이어 ----------
  function renderPlan() {
    planLayer.clearLayers();
    if (state.base) {
      L.marker([state.base.lat, state.base.lng], { icon: emojiIcon('🏰', '#ffd54f', 'base'), zIndexOffset: 1000 })
        .bindTooltip('거점: ' + esc(state.base.name), { direction: 'top', offset: [0, -14] })
        .addTo(planLayer);
      L.circle([state.base.lat, state.base.lng], { radius: 150, color: '#ffd54f', weight: 1, dashArray: '4 6', fillOpacity: 0.04, interactive: false }).addTo(planLayer);
    }
    const startPt = state.base || state.me;
    if (startPt && state.route.length) {
      const pts = [startPt, ...state.route, startPt].map(p => [p.lat, p.lng]);
      L.polyline(pts, { color: '#ffd54f', weight: 3, opacity: 0.9, dashArray: '8 8' }).addTo(planLayer);
    }
    state.route.forEach((w, i) => {
      L.marker([w.lat, w.lng], {
        icon: L.divIcon({ className: 'route-num', html: `<span>${i + 1}</span>`, iconSize: [20, 20], iconAnchor: [-4, 24] }),
        interactive: false, zIndexOffset: 900
      }).addTo(planLayer);
    });
    state.markers.forEach(mk => {
      const def = CUSTOM_MARKERS[mk.type] || CUSTOM_MARKERS.note;
      const m = L.marker([mk.lat, mk.lng], { icon: emojiIcon(def.emoji, '#fff', 'custom'), draggable: true, zIndexOffset: 800 });
      m.bindTooltip(esc(def.label + (mk.note ? ': ' + mk.note : '')), { direction: 'top', offset: [0, -14] });
      m.on('dragend', () => { const ll = m.getLatLng(); mk.lat = ll.lat; mk.lng = ll.lng; save(); });
      m.on('click', () => {
        const note = window.prompt(def.label + ' 메모 (비우고 확인하면 유지, "삭제" 입력 시 제거)', mk.note || '');
        if (note === null) return;
        if (note.trim() === '삭제') state.markers = state.markers.filter(x => x !== mk);
        else mk.note = note.trim();
        save(); renderPlan(); renderMarkerList();
      });
      m.addTo(planLayer);
    });
  }

  // ---------- 렌더: 정찰 패널 ----------
  function placeItem(p, extra = '') {
    const def = CATEGORIES[p.cat];
    return `<li data-id="${esc(p.id)}" class="clickable">
      <span class="li-emoji">${def.emoji}</span>
      <span class="li-main"><b>${esc(p.name || def.label)}</b><small>${def.label} · ${bearingKo(origin(), p)} ${formatDistance(p.dist)}</small></span>
      <span class="li-side">${extra}</span></li>`;
  }
  function threatBadge(t) {
    const cls = t >= 70 ? 'hi' : t >= 40 ? 'mid' : 'lo';
    return `<span class="badge ${cls}">위협 ${t}</span>`;
  }

  function renderIntel() {
    const has = !!analysis;
    $('#intelEmpty').hidden = has;
    $('#intelBody').hidden = !has;
    const notice = $('#dataNotice');
    if (state.scan?.demo) {
      notice.hidden = false;
      notice.textContent = '⚠️ 지도 데이터 서버에 연결하지 못해 가상의 데모 도시를 표시합니다. 네트워크 연결 후 다시 정찰하세요.';
    } else notice.hidden = true;
    if (!has) return;

    $('#survivalIndex').textContent = analysis.survivalIndex;
    $('.score-ring').style.setProperty('--p', analysis.survivalIndex);
    $('#survivalVerdict').textContent = verdict(analysis.survivalIndex);
    $('#statWalkers').textContent = analysis.totalWalkers.toLocaleString();
    $('#statSurvivors').textContent = analysis.totalSurvivors.toLocaleString();
    $('#statPlaces').textContent = analysis.enriched.length.toLocaleString();
    $('#originText').textContent = `거리 기준: ${originLabel()} · ${SCENARIOS[state.scenario].label} · ${TIME_LABEL[state.time]} · 반경 ${formatDistance(state.scan.radius)}`;

    $('#nearestList').innerHTML = analysis.nearest.map(({ label, place }) =>
      place ? placeItem(place, threatBadge(place.threat)).replace('<span class="li-emoji">', `<span class="li-tag">${label}</span><span class="li-emoji">`)
            : `<li class="none"><span class="li-tag">${label}</span><span class="muted">반경 내 없음</span></li>`).join('');
    $('#baseList').innerHTML = analysis.bases.slice(0, 5).map(p => placeItem(p, `${p.walkers ? `<span class="badge mid" title="내부 정리가 필요한 워커">🧟${p.walkers}</span>` : ''}<span class="badge score">${p.baseScore}점</span>`)).join('') || '<li class="none muted">후보 없음</li>';
    $('#lootList').innerHTML = analysis.loot.filter(p => p.id !== state.base?.id).slice(0, 6).map(p => placeItem(p, threatBadge(p.threat))).join('') || '<li class="none muted">없음</li>';
    $('#threatList').innerHTML = analysis.threats.slice(0, 5).filter(p => p.walkers > 0).map(p => placeItem(p, `<span class="badge hi">워커 ${p.walkers.toLocaleString()}</span>`)).join('') || '<li class="none muted">없음</li>';
  }

  function focusPlace(id) {
    const p = analysis?.enriched.find(e => e.id === id);
    if (!p) return;
    if (!state.enabled[p.cat]) { state.enabled[p.cat] = true; renderLayersPanel(); renderPlaces(); }
    map.flyTo([p.lat, p.lng], Math.max(map.getZoom(), 17), { duration: 0.6 });
    placeLayer.eachLayer(l => {
      const ll = l.getLatLng();
      if (Math.abs(ll.lat - p.lat) < 1e-9 && Math.abs(ll.lng - p.lng) < 1e-9) setTimeout(() => l.openPopup(), 650);
    });
    if (window.innerWidth < 800) document.body.classList.remove('panel-open');
  }

  // ---------- 렌더: 레이어 패널 ----------
  function renderLayersPanel() {
    const counts = {};
    (state.scan?.places || []).forEach(p => counts[p.cat] = (counts[p.cat] || 0) + 1);
    const groups = {};
    for (const [k, c] of Object.entries(CATEGORIES)) (groups[c.group] ||= []).push(k);
    $('#layerGroups').innerHTML = Object.entries(groups).map(([g, keys]) => `
      <h3>${g}</h3>
      <div class="layer-grid">${keys.map(k => {
        const c = CATEGORIES[k];
        return `<label class="layer"><input type="checkbox" data-cat="${k}" ${state.enabled[k] ? 'checked' : ''}>
          <span class="dot" style="--c:${c.color}">${c.emoji}</span>${c.label}<em>${counts[k] || 0}</em></label>`;
      }).join('')}</div>`).join('');
  }

  // ---------- 작전 ----------
  function setBase(b) {
    state.base = b;
    save(); recompute(); renderAll();
    toast(`🏰 거점 지정: ${b.name}`);
  }

  function addWaypoint(p) {
    if (state.route.some(w => w.id === p.id)) return;
    state.route.push({ id: p.id, lat: p.lat, lng: p.lng, name: p.name || CATEGORIES[p.cat]?.label || '지점', cat: p.cat || null });
    save(); renderPlan(); renderRoute();
    toast(`➕ 경유지 ${state.route.length}: ${p.name || CATEGORIES[p.cat]?.label || '지점'}`);
  }

  function renderBaseBox() {
    const b = state.base;
    $('#baseBox').innerHTML = b
      ? `<b>${CATEGORIES[b.cat]?.emoji || '🏰'} ${esc(b.name)}</b><br><span class="muted small">${b.lat.toFixed(5)}, ${b.lng.toFixed(5)}</span>`
      : '<span class="muted">아직 거점이 없습니다. 추천 거점 목록이나 장소 팝업에서 지정하세요.</span>';
  }

  function renderRoute() {
    const list = $('#routeList');
    const startPt = state.base || state.me;
    list.innerHTML = state.route.map((w, i) => `
      <li><span class="li-emoji">${CATEGORIES[w.cat]?.emoji || '📍'}</span>
        <span class="li-main"><b>${i + 1}. ${esc(w.name)}</b></span>
        <span class="li-side">
          <button type="button" class="icon-btn" data-up="${i}" ${i === 0 ? 'disabled' : ''} title="위로">▲</button>
          <button type="button" class="icon-btn" data-down="${i}" ${i === state.route.length - 1 ? 'disabled' : ''} title="아래로">▼</button>
          <button type="button" class="icon-btn" data-del="${i}" title="삭제">✕</button>
        </span></li>`).join('') || '<li class="none muted">경유지가 없습니다.</li>';

    const box = $('#routeStats');
    if (!startPt) { box.innerHTML = state.route.length ? '<span class="muted">출발점이 필요합니다 — 거점을 지정하거나 📍 내 위치를 누르세요.</span>' : ''; return; }
    const s = routeStats(startPt, state.route, analysis?.enriched || []);
    if (!s) { box.innerHTML = ''; return; }
    const gain = Object.entries(s.gain).filter(([, v]) => v > 0.1)
      .sort((a, b) => b[1] - a[1]).map(([k, v]) => `${RESOURCE_LABELS[k]} ${v.toFixed(1)}`).join(' · ');
    const cls = s.risk >= 70 ? 'hi' : s.risk >= 40 ? 'mid' : 'lo';
    box.innerHTML = `
      <div class="stats">
        <div><b>${formatDistance(s.dist)}</b><span>왕복 거리</span></div>
        <div><b>${formatMinutes(s.minutes)}</b><span>예상 소요</span></div>
        <div><b>${s.encounter.toLocaleString()}</b><span>조우 예상 워커</span></div>
      </div>
      <div class="row gap"><span class="badge ${cls}">루트 위험도 ${s.risk}</span>${s.minutes > 240 && state.time === 'day' ? '<span class="badge mid">해 지기 전 복귀 어려움</span>' : ''}</div>
      ${gain ? `<p class="small">예상 획득: ${gain}</p>` : ''}`;
  }

  function renderMarkerList() {
    $('#markerTypeBtns').innerHTML = Object.entries(CUSTOM_MARKERS).map(([k, d]) =>
      `<button type="button" class="btn small" data-mode="marker" data-type="${k}">${d.emoji} ${d.label}</button>`).join('');
    $('#markerList').innerHTML = state.markers.map((m, i) => {
      const d = CUSTOM_MARKERS[m.type] || CUSTOM_MARKERS.note;
      return `<li class="clickable" data-marker="${i}"><span class="li-emoji">${d.emoji}</span>
        <span class="li-main"><b>${d.label}</b><small>${esc(m.note || '메모 없음')}</small></span>
        <span class="li-side"><button type="button" class="icon-btn" data-mdel="${i}" title="삭제">✕</button></span></li>`;
    }).join('') || '<li class="none muted">위 버튼을 누른 뒤 지도를 클릭해 표시하세요. 마커는 드래그로 옮길 수 있습니다.</li>';
  }

  // 지도 클릭 모드
  let mode = null; // {kind:'base'|'waypoint'|'marker', type?}
  function setMode(m) {
    mode = m;
    const banner = $('#modeBanner');
    document.body.classList.toggle('picking', !!m);
    if (!m) { banner.hidden = true; return; }
    const txt = m.kind === 'base' ? '🏰 거점으로 삼을 위치를 지도에서 클릭하세요'
      : m.kind === 'waypoint' ? '🧭 경유지를 지도에서 클릭하세요 (여러 번 가능)'
      : `${CUSTOM_MARKERS[m.type].emoji} ${CUSTOM_MARKERS[m.type].label} 위치를 클릭하세요`;
    $('#modeText').textContent = txt;
    banner.hidden = false;
    if (window.innerWidth < 800) document.body.classList.remove('panel-open');
  }

  map.on('click', e => {
    if (!mode) return;
    const { lat, lng } = e.latlng;
    if (mode.kind === 'base') {
      const name = window.prompt('거점 이름', '임시 거점');
      if (name !== null) setBase({ lat, lng, name: name.trim() || '임시 거점' });
      setMode(null);
    } else if (mode.kind === 'waypoint') {
      addWaypoint({ id: 'pt/' + Date.now(), lat, lng, name: '지점 ' + (state.route.length + 1) });
    } else if (mode.kind === 'marker') {
      const def = CUSTOM_MARKERS[mode.type];
      const note = window.prompt(def.label + ' 메모', '');
      if (note !== null) {
        state.markers.push({ id: Date.now(), type: mode.type, lat, lng, note: note.trim() });
        save(); renderPlan(); renderMarkerList();
      }
      setMode(null);
    }
  });

  // ---------- 보급 ----------
  function renderSupply() {
    const inv = state.inventory;
    $$('[data-inv]').forEach(el => { if (document.activeElement !== el) el.value = inv[el.dataset.inv] ?? 0; });
    const n = Math.max(1, inv.people || 1);
    const foodDays = (inv.food || 0) / n;
    const waterDays = (inv.water || 0) / (2 * n);
    const days = Math.min(foodDays, waterDays);
    const armed = (inv.melee || 0) + Math.floor((inv.ammo || 0) / 30);
    const lines = [
      `<div class="big ${days < 3 ? 'red' : days < 7 ? 'amber' : 'green'}">${days.toFixed(1)}일</div><div class="muted small">현재 물자로 버틸 수 있는 기간 (식량 ${foodDays.toFixed(1)}일 · 물 ${waterDays.toFixed(1)}일, 1인 하루 물 2L 기준)</div>`,
      `<p class="small">무장 인원 ${Math.min(armed, n)}/${n}명 · 구급 키트 ${inv.medical || 0}개 · 연료 ${inv.fuel || 0}L</p>`
    ];
    const warn = [];
    if (days < 3) warn.push('🚨 3일 내 물자 고갈 — 즉시 약탈 필요');
    if (armed < n) warn.push('⚔️ 무기가 부족한 인원이 있습니다');
    if ((inv.medical || 0) === 0) warn.push('🩹 구급 키트 0개 — 작은 상처도 치명적');
    if (warn.length) lines.push('<ul class="warn">' + warn.map(w => `<li>${w}</li>`).join('') + '</ul>');
    $('#supplyReport').innerHTML = lines.join('');

    const w = needWeights(inv);
    $('#needBars').innerHTML = Object.entries(w).map(([k, v]) =>
      `<div class="res"><span>${RESOURCE_LABELS[k]}</span>${bar(v, 3, v >= 2 ? 'threat' : '')}<em>×${v.toFixed(1)}</em></div>`).join('');
  }

  // ---------- 공통 ----------
  function renderAll() {
    renderPlaces(); renderPlan(); renderIntel(); renderLayersPanel();
    renderBaseBox(); renderRoute(); renderMarkerList(); renderSupply();
  }

  let toastTimer;
  function toast(msg) {
    const t = $('#toast');
    t.textContent = msg; t.hidden = false;
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => t.hidden = true, 2600);
  }

  function drawScanArea() {
    scanAreaLayer.clearLayers();
    if (!state.scan) return;
    L.circle([state.scan.lat, state.scan.lng], { radius: state.scan.radius, color: '#8bc34a', weight: 1, dashArray: '2 8', fill: false, interactive: false }).addTo(scanAreaLayer);
  }

  async function scan() {
    const c = map.getCenter();
    $('#loading').hidden = false;
    $('#scanBtn').disabled = true;
    try {
      const r = await fetchPlaces(c.lat, c.lng, state.radius);
      state.scan = { lat: c.lat, lng: c.lng, radius: state.radius, places: r.places, demo: r.demo };
      save(); recompute(); drawScanArea(); renderAll();
      if (state.radius >= 2000) map.fitBounds(L.latLng(c.lat, c.lng).toBounds(state.radius * 2));
      toast(r.demo ? '⚠️ 오프라인 — 데모 데이터로 표시' : `📡 정찰 완료: 장소 ${r.places.length}곳 확인`);
      switchTab('intel');
      if (window.innerWidth < 800) document.body.classList.add('panel-open');
    } finally {
      $('#loading').hidden = true;
      $('#scanBtn').disabled = false;
    }
  }

  function locate() {
    if (!navigator.geolocation) { toast('이 브라우저는 위치 기능을 지원하지 않습니다'); return; }
    toast('📍 위치 확인 중…');
    navigator.geolocation.getCurrentPosition(pos => {
      state.me = { lat: pos.coords.latitude, lng: pos.coords.longitude };
      save();
      drawMe();
      map.setView([state.me.lat, state.me.lng], 16);
      recompute(); renderAll();
      toast('📍 현재 위치 확인. 📡 정찰을 눌러 주변을 분석하세요');
    }, err => toast('위치를 가져오지 못했습니다: ' + err.message), { enableHighAccuracy: true, timeout: 10000 });
  }

  function drawMe() {
    if (meMarker) meMarker.remove();
    if (!state.me) return;
    meMarker = L.marker([state.me.lat, state.me.lng], { icon: L.divIcon({ className: 'me-icon', html: '<span></span>', iconSize: [18, 18] }), zIndexOffset: 1100 })
      .bindTooltip('내 위치', { direction: 'top' }).addTo(map);
  }

  function switchTab(name) {
    $$('.tabs button').forEach(b => b.classList.toggle('active', b.dataset.tab === name));
    $$('.tab-body').forEach(s => s.hidden = s.dataset.tab !== name);
  }

  // ---------- 이벤트 ----------
  const scenarioSelect = $('#scenarioSelect');
  scenarioSelect.innerHTML = Object.entries(SCENARIOS).map(([k, s]) => `<option value="${k}">${s.label}</option>`).join('');
  scenarioSelect.value = state.scenario;
  scenarioSelect.onchange = () => { state.scenario = +scenarioSelect.value; save(); recompute(); renderAll(); };

  $$('[data-time]').forEach(b => {
    b.classList.toggle('active', b.dataset.time === state.time);
    b.onclick = () => {
      state.time = b.dataset.time;
      $$('[data-time]').forEach(x => x.classList.toggle('active', x === b));
      document.body.classList.toggle('night', state.time === 'night');
      save(); recompute(); renderAll();
    };
  });
  document.body.classList.toggle('night', state.time === 'night');

  $('#radiusSelect').value = state.radius;
  $('#radiusSelect').onchange = e => { state.radius = +e.target.value; save(); };
  $('#scanBtn').onclick = scan;
  $('#locateBtn').onclick = locate;

  $$('.tabs button').forEach(b => b.onclick = () => switchTab(b.dataset.tab));
  $('#panelToggle').onclick = () => document.body.classList.toggle('panel-open');

  // 목록 클릭 → 지도 이동
  ['#nearestList', '#baseList', '#lootList', '#threatList'].forEach(sel =>
    $(sel).addEventListener('click', e => { const li = e.target.closest('li[data-id]'); if (li) focusPlace(li.dataset.id); }));

  $('#layerGroups').addEventListener('change', e => {
    const cat = e.target.dataset.cat; if (!cat) return;
    state.enabled[cat] = e.target.checked; save(); renderPlaces();
  });
  $('#layersAll').onclick = () => { Object.keys(state.enabled).forEach(k => state.enabled[k] = true); save(); renderLayersPanel(); renderPlaces(); };
  $('#layersNone').onclick = () => { Object.keys(state.enabled).forEach(k => state.enabled[k] = false); save(); renderLayersPanel(); renderPlaces(); };
  $('#threatToggle').checked = state.showThreat;
  $('#threatToggle').onchange = e => { state.showThreat = e.target.checked; save(); renderPlaces(); };
  $('#labelsToggle').checked = state.showLabels;
  $('#labelsToggle').onchange = e => { state.showLabels = e.target.checked; save(); renderPlaces(); };

  document.addEventListener('click', e => {
    const b = e.target.closest('[data-mode]');
    if (b) setMode({ kind: b.dataset.mode, type: b.dataset.type });
  });
  $('#modeCancel').onclick = () => setMode(null);
  document.addEventListener('keydown', e => { if (e.key === 'Escape') setMode(null); });

  $('#clearBase').onclick = () => { state.base = null; save(); recompute(); renderAll(); };
  $('#clearRoute').onclick = () => { state.route = []; save(); renderPlan(); renderRoute(); renderPlaces(); };
  $('#optimizeRoute').onclick = () => {
    const s = state.base || state.me;
    if (!s) { toast('출발점(거점 또는 내 위치)이 필요합니다'); return; }
    state.route = optimizeOrder(s, state.route);
    save(); renderPlan(); renderRoute(); toast('🧭 이동 거리가 가장 짧은 순서로 정렬했습니다');
  };
  $('#routeList').addEventListener('click', e => {
    const t = e.target, r = state.route;
    if (t.dataset.up) { const i = +t.dataset.up; [r[i - 1], r[i]] = [r[i], r[i - 1]]; }
    else if (t.dataset.down) { const i = +t.dataset.down; [r[i + 1], r[i]] = [r[i], r[i + 1]]; }
    else if (t.dataset.del) r.splice(+t.dataset.del, 1);
    else return;
    save(); renderPlan(); renderRoute();
  });
  $('#markerList').addEventListener('click', e => {
    if (e.target.dataset.mdel) { state.markers.splice(+e.target.dataset.mdel, 1); save(); renderPlan(); renderMarkerList(); return; }
    const li = e.target.closest('li[data-marker]');
    if (li) { const m = state.markers[+li.dataset.marker]; map.flyTo([m.lat, m.lng], 17, { duration: 0.6 }); }
  });

  $('#exportBtn').onclick = () => {
    const data = { app: 'walker-map', version: 1, exportedAt: new Date().toISOString(),
      base: state.base, route: state.route, markers: state.markers, inventory: state.inventory,
      scenario: state.scenario, time: state.time, view: state.view };
    const blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' });
    const a = document.createElement('a');
    a.href = URL.createObjectURL(blob);
    a.download = `walker-map-작전-${new Date().toISOString().slice(0, 10)}.json`;
    a.click();
    setTimeout(() => URL.revokeObjectURL(a.href), 1000);
  };
  $('#importInput').onchange = async e => {
    const f = e.target.files[0]; if (!f) return;
    try {
      const d = JSON.parse(await f.text());
      if (d.app !== 'walker-map') throw new Error('워커 맵 작전 파일이 아닙니다');
      ['base', 'route', 'markers', 'inventory', 'scenario', 'time'].forEach(k => { if (d[k] !== undefined) state[k] = d[k]; });
      if (d.view) map.setView([d.view.lat, d.view.lng], d.view.zoom);
      scenarioSelect.value = state.scenario;
      $$('[data-time]').forEach(x => x.classList.toggle('active', x.dataset.time === state.time));
      save(); recompute(); renderAll(); toast('📂 작전 파일을 불러왔습니다');
    } catch (err) { toast('불러오기 실패: ' + err.message); }
    e.target.value = '';
  };
  $('#resetAll').onclick = () => {
    if (!window.confirm('거점·루트·마커·보급 정보를 모두 지울까요?')) return;
    state.base = null; state.route = []; state.markers = [];
    state.inventory = { people: 4, food: 20, water: 30, medical: 1, ammo: 12, melee: 3, fuel: 0 };
    save(); recompute(); renderAll();
  };

  $('#inventoryForm').addEventListener('input', e => {
    const k = e.target.dataset.inv; if (!k) return;
    state.inventory[k] = Math.max(0, parseInt(e.target.value, 10) || 0);
    save(); recompute(); renderSupply(); renderIntel(); renderRoute();
  });

  // 검색
  const results = $('#searchResults');
  $('#searchForm').onsubmit = async e => {
    e.preventDefault();
    const q = $('#searchInput').value.trim(); if (!q) return;
    try {
      const list = await geocode(q);
      if (!list.length) { results.innerHTML = '<li class="muted">결과 없음</li>'; results.hidden = false; return; }
      results.innerHTML = list.map((r, i) => `<li data-i="${i}">${esc(r.display_name)}</li>`).join('');
      results.hidden = false;
      results.onclick = ev => {
        const li = ev.target.closest('li[data-i]'); if (!li) return;
        const r = list[+li.dataset.i];
        map.setView([+r.lat, +r.lon], 16);
        results.hidden = true;
        toast('📡 정찰 버튼을 눌러 이 지역을 분석하세요');
      };
    } catch (err) { toast('검색 실패 (네트워크 확인): ' + err.message); }
  };
  document.addEventListener('click', e => { if (!e.target.closest('.search')) results.hidden = true; });

  // ---------- 시작 ----------
  drawMe();
  drawScanArea();
  recompute();
  renderAll();
})();
