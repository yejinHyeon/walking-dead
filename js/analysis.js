// 위험도·자원·거점·루트 계산 (DOM 없음, Node에서도 테스트 가능)
const WALK_KMH = 4;          // 은밀 이동 속도
const LOOT_MINUTES = 15;     // 경유지 1곳당 수색 시간

function haversine(a, b) {
  const R = 6371000, toRad = d => d * Math.PI / 180;
  const dLat = toRad(b.lat - a.lat), dLng = toRad(b.lng - a.lng);
  const h = Math.sin(dLat / 2) ** 2 + Math.cos(toRad(a.lat)) * Math.cos(toRad(b.lat)) * Math.sin(dLng / 2) ** 2;
  return 2 * R * Math.asin(Math.sqrt(h));
}

function bearingKo(from, to) {
  const toRad = d => d * Math.PI / 180;
  const y = Math.sin(toRad(to.lng - from.lng)) * Math.cos(toRad(to.lat));
  const x = Math.cos(toRad(from.lat)) * Math.sin(toRad(to.lat)) -
            Math.sin(toRad(from.lat)) * Math.cos(toRad(to.lat)) * Math.cos(toRad(to.lng - from.lng));
  const deg = (Math.atan2(y, x) * 180 / Math.PI + 360) % 360;
  return ['북', '북동', '동', '남동', '남', '남서', '서', '북서'][Math.round(deg / 45) % 8];
}

function formatDistance(m) {
  return m < 1000 ? Math.round(m) + 'm' : (m / 1000).toFixed(1) + 'km';
}

function formatMinutes(min) {
  min = Math.round(min);
  return min < 60 ? min + '분' : Math.floor(min / 60) + '시간 ' + (min % 60) + '분';
}

const clamp = (v, lo, hi) => Math.max(lo, Math.min(hi, v));

// 장소 하나의 추정 인원·위험·남은 물자
function assessPlace(p, scenario, time) {
  const cat = CATEGORIES[p.cat];
  let people = cat.people[time];
  if (p.cat === 'apartment') people *= clamp((p.levels || 15) / 15, 0.3, 3);
  const walkers = Math.round(people * scenario.infection);
  const survivors = Math.round(people * (1 - scenario.infection) * scenario.survivors);
  const threat = Math.round(clamp(cat.risk * 8 + Math.log10(walkers + 1) * 20, 0, 100));
  const lootLeft = scenario.loot + (1 - scenario.loot) * cat.stash;
  const resources = {};
  for (const k of Object.keys(cat.resources)) resources[k] = cat.resources[k] * (k === 'shelter' ? 1 : lootLeft);
  return { walkers, survivors, threat, lootLeft, resources };
}

// 보유 물자 → 자원별 가중치 (부족할수록 큼)
function needWeights(inv) {
  const n = Math.max(1, inv.people || 1);
  const foodDays = (inv.food || 0) / n;
  const waterDays = (inv.water || 0) / (2 * n);
  const w = {
    food: 1 + 2 * clamp(1 - foodDays / 14, 0, 1),
    water: 1 + 2 * clamp(1 - waterDays / 14, 0, 1),
    medical: 1 + 1.5 * clamp(1 - (inv.medical || 0) / n, 0, 1),
    weapons: 1 + 1.5 * clamp(1 - ((inv.melee || 0) + (inv.ammo || 0) / 30) / n, 0, 1),
    tools: 0.8,
    fuel: 0.5 + 1 * clamp(1 - (inv.fuel || 0) / 40, 0, 1)
  };
  return w;
}

function lootScore(a, weights) {
  let s = 0;
  for (const k of Object.keys(weights)) s += (a.resources[k] || 0) * weights[k];
  return s;
}

const TIME_LABEL = { day: '주간', night: '야간' };

// 지역 전체 분석
function analyzeArea(places, origin, scenario, time, inv) {
  const weights = needWeights(inv);
  const enriched = places.map(p => {
    const a = assessPlace(p, scenario, time);
    const dist = haversine(origin, p);
    return { ...p, ...a, dist, loot: lootScore(a, weights) };
  });

  const totalWalkers = enriched.reduce((s, p) => s + p.walkers, 0);
  const totalSurvivors = enriched.reduce((s, p) => s + p.survivors, 0);
  const totalLoot = enriched.reduce((s, p) => s + p.loot, 0);

  // 생존 지수: 남은 물자 대비 워커 수
  const supply = Math.log10(totalLoot + 1) * 30;
  const danger = Math.log10(totalWalkers + 1) * 18;
  const survivalIndex = Math.round(clamp(50 + supply - danger - 25, 0, 100));

  const nearestGroups = {
    '🍞 식량': ['supermarket', 'convenience', 'restaurant', 'farm'],
    '💊 의약품': ['hospital', 'medical_school', 'pharmacy', 'clinic'],
    '🔪 무기': ['police', 'military', 'weapons_shop', 'hardware', 'fire_station'],
    '⛽ 연료': ['fuel'],
    '🛡️ 은신처': ['prison', 'shelter', 'church', 'school', 'house']
  };
  const nearest = Object.entries(nearestGroups).map(([label, cats]) => {
    const c = enriched.filter(p => cats.includes(p.cat)).sort((x, y) => x.dist - y.dist);
    return { label, place: c[0] || null };
  });

  // 거점 후보 점수
  const bases = enriched
    .filter(p => CATEGORIES[p.cat].resources.shelter >= 2 && p.cat !== 'park')
    .map(p => {
      const cat = CATEGORIES[p.cat];
      let nearbyWalkers = 0, nearbyLoot = 0;
      for (const q of enriched) {
        if (q === p) continue;
        const d = haversine(p, q);
        if (d < 300) nearbyWalkers += q.walkers;
        if (d < 600) nearbyLoot += q.loot;
      }
      const score = cat.defense * 12 + cat.resources.shelter * 6 +
        Math.min(25, Math.log10(nearbyLoot + 1) * 10) -
        p.threat * 0.25 - Math.log10(p.walkers + 1) * 8 - Math.log10(nearbyWalkers + 1) * 6;
      return { ...p, baseScore: Math.round(score), nearbyWalkers };
    })
    .sort((a, b) => b.baseScore - a.baseScore);

  const loot = enriched
    .filter(p => p.loot > 0)
    .map(p => ({ ...p, priority: p.loot / (1 + p.threat / 25) / (1 + p.dist / 500) }))
    .sort((a, b) => b.priority - a.priority);

  const threats = [...enriched].sort((a, b) => b.walkers - a.walkers);

  return { enriched, totalWalkers, totalSurvivors, survivalIndex, nearest, bases, loot, threats, weights };
}

function verdict(idx) {
  if (idx >= 75) return '비교적 안전 — 정착을 고려할 만한 지역';
  if (idx >= 55) return '버틸 만함 — 거점 확보 후 신중한 약탈';
  if (idx >= 35) return '위험 — 짧게 털고 빠져나갈 것';
  return '사지(死地) — 즉시 이탈 권장';
}

// 루트: 출발점 → 경유지들 → 출발점 복귀
function routeStats(start, waypoints, enriched) {
  if (!start || !waypoints.length) return null;
  const pts = [start, ...waypoints, start];
  let dist = 0;
  const exposed = new Map();
  for (let i = 0; i < pts.length - 1; i++) {
    const a = pts[i], b = pts[i + 1];
    const d = haversine(a, b);
    dist += d;
    const steps = Math.max(1, Math.ceil(d / 50));
    for (let s = 0; s <= steps; s++) {
      const pt = { lat: a.lat + (b.lat - a.lat) * s / steps, lng: a.lng + (b.lng - a.lng) * s / steps };
      for (const p of enriched) {
        if (p.walkers > 0 && !exposed.has(p.id) && haversine(pt, p) < 120) exposed.set(p.id, p);
      }
    }
  }
  // 경유지 자체는 들어가야 하므로 그곳의 워커는 전부 조우
  const encounter = [...exposed.values()].reduce((s, p) => {
    const isStop = waypoints.some(w => w.id === p.id);
    return s + (isStop ? p.walkers : p.walkers * 0.15);
  }, 0);
  const gain = {};
  for (const w of waypoints) {
    const p = enriched.find(e => e.id === w.id);
    if (!p) continue;
    for (const [k, v] of Object.entries(p.resources)) if (k !== 'shelter') gain[k] = (gain[k] || 0) + v;
  }
  const minutes = dist / 1000 / WALK_KMH * 60 + waypoints.length * LOOT_MINUTES;
  const risk = Math.round(clamp(Math.log10(encounter + 1) * 35, 0, 100));
  return { dist, minutes, encounter: Math.round(encounter), risk, gain };
}

// 최근접 이웃 + 2-opt 로 경유지 순서 최적화 (거리 기준)
function optimizeOrder(start, waypoints) {
  if (waypoints.length < 3) return waypoints.slice();
  const rest = waypoints.slice();
  const order = [];
  let cur = start;
  while (rest.length) {
    let bi = 0;
    for (let i = 1; i < rest.length; i++) if (haversine(cur, rest[i]) < haversine(cur, rest[bi])) bi = i;
    cur = rest.splice(bi, 1)[0];
    order.push(cur);
  }
  const total = o => { const p = [start, ...o, start]; let d = 0; for (let i = 0; i < p.length - 1; i++) d += haversine(p[i], p[i + 1]); return d; };
  let improved = true;
  while (improved) {
    improved = false;
    for (let i = 0; i < order.length - 1; i++) {
      for (let j = i + 1; j < order.length; j++) {
        const cand = [...order.slice(0, i), ...order.slice(i, j + 1).reverse(), ...order.slice(j + 1)];
        if (total(cand) + 1e-6 < total(order)) { order.splice(0, order.length, ...cand); improved = true; }
      }
    }
  }
  return order;
}

if (typeof module !== 'undefined') {
  module.exports = { haversine, bearingKo, assessPlace, needWeights, analyzeArea, routeStats, optimizeOrder, verdict };
}
