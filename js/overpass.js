// OpenStreetMap(Overpass API) 데이터 수집 + 오프라인 데모 데이터
const OVERPASS_ENDPOINTS = [
  'https://overpass-api.de/api/interpreter',
  'https://overpass.kumi.systems/api/interpreter',
  'https://maps.mail.ru/osm/tools/overpass/api/interpreter'
];

function buildOverpassQuery(lat, lng, radius) {
  const a = `(around:${radius},${lat},${lng})`;
  const filters = [
    'nwr["shop"~"^(supermarket|wholesale|department_store|convenience|hardware|doityourself|weapons|hunting|outdoor)$"]',
    'nwr["amenity"~"^(restaurant|fast_food|food_court|police|fire_station|hospital|pharmacy|clinic|doctors|fuel|prison|shelter|place_of_worship|university|college|school)$"]',
    'nwr["landuse"="military"]',
    'nwr["military"]',
    'nwr["emergency"~"^(assembly_point|shelter)$"]',
    'nwr["building"="bunker"]',
    'nwr["station"="subway"]',
    'nwr["landuse"~"^(farmland|farmyard|orchard)$"]',
    'way["building"~"^(apartments|house|detached|semidetached_house)$"]',
    'nwr["leisure"="park"]'
  ];
  return `[out:json][timeout:40];(${filters.map(f => f + a + ';').join('')});out center tags;`;
}

async function fetchPlaces(lat, lng, radius) {
  const query = buildOverpassQuery(lat, lng, radius);
  let lastErr;
  for (const url of OVERPASS_ENDPOINTS) {
    try {
      const ctrl = new AbortController();
      const timer = setTimeout(() => ctrl.abort(), 45000);
      const res = await fetch(url, {
        method: 'POST',
        body: 'data=' + encodeURIComponent(query),
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        signal: ctrl.signal
      });
      clearTimeout(timer);
      if (!res.ok) throw new Error('HTTP ' + res.status);
      const json = await res.json();
      return { places: parseElements(json.elements || []), demo: false };
    } catch (e) {
      lastErr = e;
    }
  }
  console.warn('Overpass 실패, 데모 데이터 사용:', lastErr);
  return { places: generateDemoPlaces(lat, lng, radius), demo: true, error: lastErr };
}

function parseElements(elements) {
  const seen = new Set();
  const out = [];
  for (const el of elements) {
    const cat = classify(el.tags);
    if (!cat) continue;
    const lat = el.lat ?? el.center?.lat;
    const lng = el.lon ?? el.center?.lon;
    if (lat == null || lng == null) continue;
    const id = el.type + '/' + el.id;
    if (seen.has(id)) continue;
    seen.add(id);
    const t = el.tags || {};
    out.push({
      id, cat, lat, lng,
      name: t['name:ko'] || t.name || '',
      levels: parseInt(t['building:levels'], 10) || null
    });
  }
  return out;
}

// 네트워크가 막혔을 때 사용할 가상의 도시
function generateDemoPlaces(lat, lng, radius) {
  let seed = Math.floor(Math.abs(lat * 1000) + Math.abs(lng * 1000));
  const rand = () => { seed = (seed * 9301 + 49297) % 233280; return seed / 233280; };
  const counts = {
    supermarket: 3, convenience: 14, restaurant: 25, farm: 1, police: 2, military: 1, weapons_shop: 1,
    hardware: 3, fire_station: 1, hospital: 2, medical_school: 1, pharmacy: 8, clinic: 6, fuel: 3,
    prison: 1, shelter: 4, subway: 3, church: 5, university: 1, school: 4, apartment: 40, house: 30, park: 4
  };
  const names = {
    supermarket: ['이마트', '홈플러스', '롯데마트'], police: ['중앙경찰서', '역전지구대'],
    hospital: ['시립병원', '대학병원'], medical_school: ['국립의과대학'], university: ['한국대학교'],
    prison: ['남부교도소'], military: ['제51보병사단'], fire_station: ['중부소방서'],
    subway: ['시청역', '중앙역', '공원역'], shelter: ['민방위 대피소', '주민센터 대피소']
  };
  const places = [];
  const mPerDegLat = 111320, mPerDegLng = 111320 * Math.cos(lat * Math.PI / 180);
  for (const [cat, n] of Object.entries(counts)) {
    for (let i = 0; i < n; i++) {
      const r = radius * Math.sqrt(rand()) * 0.95;
      const th = rand() * Math.PI * 2;
      const pool = names[cat];
      places.push({
        id: `demo/${cat}/${i}`, cat,
        lat: lat + (r * Math.sin(th)) / mPerDegLat,
        lng: lng + (r * Math.cos(th)) / mPerDegLng,
        name: pool ? pool[i % pool.length] : '',
        levels: cat === 'apartment' ? 10 + Math.floor(rand() * 20) : null
      });
    }
  }
  return places;
}

// 장소 검색 (Nominatim)
async function geocode(q) {
  const url = 'https://nominatim.openstreetmap.org/search?format=json&limit=5&accept-language=ko&q=' + encodeURIComponent(q);
  const res = await fetch(url);
  if (!res.ok) throw new Error('HTTP ' + res.status);
  return res.json();
}
