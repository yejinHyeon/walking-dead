// 주변 시설 검색 (OpenStreetMap / Overpass API)
const PLACE_TYPES = {
  shelter:   { label: '대피소·집결지', emoji: '🛡️', color: '#26c6da' },
  subway:    { label: '지하철역 (지하)', emoji: '🚇', color: '#00897b' },
  er:        { label: '응급실', emoji: '🚨', color: '#ff1744' },
  hospital:  { label: '병원', emoji: '🏥', color: '#ec407a' },
  clinic:    { label: '의원·보건소', emoji: '🩺', color: '#f48fb1' },
  pharmacy:  { label: '약국', emoji: '💊', color: '#ff80ab' },
  aed:       { label: '자동심장충격기', emoji: '⚡', color: '#ffea00' },
  police:    { label: '경찰', emoji: '🚓', color: '#42a5f5' },
  fire:      { label: '소방서', emoji: '🚒', color: '#ff7043' },
  water:     { label: '식수·우물', emoji: '🚰', color: '#29b6f6' },
  food:      { label: '마트·편의점', emoji: '🛒', color: '#66bb6a' },
  fuel:      { label: '주유소', emoji: '⛽', color: '#ffa726' },
  toilet:    { label: '화장실', emoji: '🚻', color: '#9e9e9e' }
};

function classifyPlace(t) {
  if (t.emergency === 'defibrillator') return 'aed';
  if (t.emergency === 'assembly_point' || t.emergency === 'shelter' || t.building === 'bunker' || t.military === 'bunker') return 'shelter';
  if (t.amenity === 'shelter' && !['public_transport', 'picnic_shelter', 'gazebo', 'weather_shelter', 'field_shelter', 'lean_to', 'sun_shelter'].includes(t.shelter_type)) return 'shelter';
  if (t.station === 'subway' || (t.railway === 'station' && t.subway === 'yes')) return 'subway';
  if (t.amenity === 'hospital') return t.emergency === 'yes' ? 'er' : 'hospital';
  if (t.amenity === 'clinic' || t.amenity === 'doctors') return 'clinic';
  if (t.amenity === 'pharmacy') return 'pharmacy';
  if (t.amenity === 'police') return 'police';
  if (t.amenity === 'fire_station') return 'fire';
  if (t.amenity === 'drinking_water' || t.amenity === 'water_point' || t.man_made === 'water_well' || t.natural === 'spring') return 'water';
  if (t.shop === 'supermarket' || t.shop === 'convenience') return 'food';
  if (t.amenity === 'fuel') return 'fuel';
  if (t.amenity === 'toilets') return 'toilet';
  return null;
}

const OVERPASS_ENDPOINTS = [
  'https://overpass-api.de/api/interpreter',
  'https://overpass.kumi.systems/api/interpreter',
  'https://maps.mail.ru/osm/tools/overpass/api/interpreter'
];

function overpassQuery(lat, lng, r) {
  const a = `(around:${r},${lat},${lng})`;
  const f = [
    'nwr["emergency"~"^(defibrillator|assembly_point|shelter)$"]',
    'nwr["amenity"~"^(shelter|hospital|clinic|doctors|pharmacy|police|fire_station|drinking_water|water_point|fuel|toilets)$"]',
    'nwr["building"="bunker"]', 'nwr["military"="bunker"]',
    'nwr["station"="subway"]',
    'nwr["man_made"="water_well"]', 'nwr["natural"="spring"]',
    'nwr["shop"~"^(supermarket|convenience)$"]'
  ];
  return `[out:json][timeout:30];(${f.map(x => x + a + ';').join('')});out center tags;`;
}

async function fetchNearby(lat, lng, radius) {
  let lastErr;
  for (const url of OVERPASS_ENDPOINTS) {
    try {
      const ctrl = new AbortController();
      const timer = setTimeout(() => ctrl.abort(), 35000);
      const res = await fetch(url, {
        method: 'POST', signal: ctrl.signal,
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: 'data=' + encodeURIComponent(overpassQuery(lat, lng, radius))
      });
      clearTimeout(timer);
      if (!res.ok) throw new Error('HTTP ' + res.status);
      const json = await res.json();
      return parsePlaces(json.elements || []);
    } catch (e) { lastErr = e; }
  }
  throw lastErr || new Error('검색 실패');
}

function parsePlaces(elements) {
  const out = [], seen = new Set();
  for (const el of elements) {
    const t = el.tags || {};
    const type = classifyPlace(t);
    if (!type) continue;
    const lat = el.lat ?? el.center?.lat, lng = el.lon ?? el.center?.lon;
    if (lat == null || lng == null) continue;
    const id = el.type + '/' + el.id;
    if (seen.has(id)) continue;
    seen.add(id);
    out.push({
      id, type, lat, lng,
      name: t['name:ko'] || t.name || '',
      phone: t.phone || t['contact:phone'] || '',
      hours: t.opening_hours || '',
      level: t.level || t['addr:floor'] || '',
      desc: t.description || t['defibrillator:location'] || ''
    });
  }
  return out;
}

function haversine(a, b) {
  const R = 6371000, rad = d => d * Math.PI / 180;
  const dLat = rad(b.lat - a.lat), dLng = rad(b.lng - a.lng);
  const h = Math.sin(dLat / 2) ** 2 + Math.cos(rad(a.lat)) * Math.cos(rad(b.lat)) * Math.sin(dLng / 2) ** 2;
  return 2 * R * Math.asin(Math.sqrt(h));
}

function bearingKo(from, to) {
  const rad = d => d * Math.PI / 180;
  const y = Math.sin(rad(to.lng - from.lng)) * Math.cos(rad(to.lat));
  const x = Math.cos(rad(from.lat)) * Math.sin(rad(to.lat)) - Math.sin(rad(from.lat)) * Math.cos(rad(to.lat)) * Math.cos(rad(to.lng - from.lng));
  const deg = (Math.atan2(y, x) * 180 / Math.PI + 360) % 360;
  return ['북', '북동', '동', '남동', '남', '남서', '서', '북서'][Math.round(deg / 45) % 8];
}

function fmtDist(m) { return m < 1000 ? Math.round(m) + 'm' : (m / 1000).toFixed(1) + 'km'; }
function walkMin(m) { return Math.max(1, Math.round(m / 1000 / 4 * 60)); } // 도보 4km/h

async function geocode(q) {
  const res = await fetch('https://nominatim.openstreetmap.org/search?format=json&limit=5&countrycodes=kr&accept-language=ko&q=' + encodeURIComponent(q));
  if (!res.ok) throw new Error('HTTP ' + res.status);
  return res.json();
}
