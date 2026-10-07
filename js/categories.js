// 장소 카테고리 정의
// resources: 0~5 (food 식량, water 물, medical 의약품, weapons 무기, tools 도구, fuel 연료, shelter 은신 가치)
// people: 평상시 한 장소에 있을 것으로 추정되는 인원 { day 주간, night 야간 }
// risk: 구조적 위험도 0~5 (좁은 통로, 시야 확보 어려움, 감염 확산 속도 등)
// defense: 방어 용이성 0~5 (담장, 철문, 출입구 수 등) — 거점 추천에 사용
// stash: 약탈되기 어려운 정도 0~1 (높을수록 시간이 지나도 물자가 남아있음)
const CATEGORIES = {
  supermarket: {
    label: '마트', emoji: '🛒', color: '#4caf50', group: '보급',
    resources: { food: 5, water: 5, medical: 1, weapons: 0, tools: 2, fuel: 0, shelter: 2 },
    people: { day: 150, night: 10 }, risk: 3, defense: 2, stash: 0.1,
    tip: '초반 약탈 1순위. 사람이 몰리기 전에 들어가고, 하역장(뒷문)으로 진입하세요.'
  },
  convenience: {
    label: '편의점', emoji: '🏪', color: '#8bc34a', group: '보급',
    resources: { food: 2, water: 3, medical: 1, weapons: 0, tools: 1, fuel: 0, shelter: 1 },
    people: { day: 8, night: 3 }, risk: 1, defense: 1, stash: 0.2,
    tip: '작지만 어디에나 있음. 창고(백룸)를 꼭 확인하세요.'
  },
  restaurant: {
    label: '음식점', emoji: '🍜', color: '#cddc39', group: '보급',
    resources: { food: 2, water: 2, medical: 0, weapons: 1, tools: 1, fuel: 1, shelter: 1 },
    people: { day: 25, night: 15 }, risk: 2, defense: 1, stash: 0.4,
    tip: '주방에 칼·가스통, 냉동창고에 식재료. 냉동창고는 정전 후 며칠이 한계.'
  },
  farm: {
    label: '농장', emoji: '🌾', color: '#a1887f', group: '보급',
    resources: { food: 4, water: 3, medical: 0, weapons: 1, tools: 4, fuel: 2, shelter: 3 },
    people: { day: 5, night: 3 }, risk: 0, defense: 2, stash: 0.8,
    tip: '허셸의 농장처럼 장기 식량 확보 가능. 시야가 넓어 접근하는 워커가 잘 보입니다.'
  },
  police: {
    label: '경찰서', emoji: '🚓', color: '#2196f3', group: '무기',
    resources: { food: 1, water: 1, medical: 2, weapons: 5, tools: 3, fuel: 2, shelter: 3 },
    people: { day: 40, night: 20 }, risk: 4, defense: 4, stash: 0.5,
    tip: '무기고·방탄복. 하지만 감염된 경찰이 가장 먼저 몰린 곳이기도 합니다.'
  },
  military: {
    label: '군부대', emoji: '🪖', color: '#3f51b5', group: '무기',
    resources: { food: 4, water: 3, medical: 3, weapons: 5, tools: 4, fuel: 5, shelter: 5 },
    people: { day: 300, night: 250 }, risk: 5, defense: 5, stash: 0.6,
    tip: '물자는 최고, 위험도 최고. 함락된 부대는 무장 워커 소굴입니다.'
  },
  weapons_shop: {
    label: '총포사/사냥용품', emoji: '🔫', color: '#673ab7', group: '무기',
    resources: { food: 0, water: 0, medical: 0, weapons: 4, tools: 2, fuel: 0, shelter: 1 },
    people: { day: 3, night: 0 }, risk: 1, defense: 2, stash: 0.2,
    tip: '한국은 총기 보관이 경찰서라 실탄은 드뭅니다. 석궁·활·칼류를 노리세요.'
  },
  hardware: {
    label: '철물점/공구', emoji: '🔧', color: '#795548', group: '무기',
    resources: { food: 0, water: 0, medical: 0, weapons: 3, tools: 5, fuel: 1, shelter: 1 },
    people: { day: 5, night: 0 }, risk: 1, defense: 1, stash: 0.6,
    tip: '도끼·쇠지렛대·철조망·자물쇠. 거점 보강 자재의 보고.'
  },
  fire_station: {
    label: '소방서', emoji: '🚒', color: '#f44336', group: '무기',
    resources: { food: 1, water: 4, medical: 3, weapons: 2, tools: 5, fuel: 3, shelter: 3 },
    people: { day: 25, night: 20 }, risk: 2, defense: 3, stash: 0.5,
    tip: '소방도끼, 방화복(물림 방지), 구급 장비, 차량.'
  },
  hospital: {
    label: '병원', emoji: '🏥', color: '#e91e63', group: '의료',
    resources: { food: 2, water: 2, medical: 5, weapons: 0, tools: 2, fuel: 2, shelter: 2 },
    people: { day: 1200, night: 600 }, risk: 5, defense: 2, stash: 0.3,
    tip: '감염 초기 환자가 몰린 곳. 1층은 포기하고 약제부·창고만 노리세요.'
  },
  medical_school: {
    label: '의과대학', emoji: '🧬', color: '#ad1457', group: '의료',
    resources: { food: 1, water: 2, medical: 5, weapons: 0, tools: 3, fuel: 1, shelter: 3 },
    people: { day: 1500, night: 150 }, risk: 4, defense: 3, stash: 0.6,
    tip: 'CDC처럼 연구 자료·실험 장비·대량 의약품. 야간엔 비교적 한산.'
  },
  pharmacy: {
    label: '약국', emoji: '💊', color: '#ff4081', group: '의료',
    resources: { food: 0, water: 1, medical: 4, weapons: 0, tools: 0, fuel: 0, shelter: 1 },
    people: { day: 6, night: 1 }, risk: 1, defense: 1, stash: 0.2,
    tip: '항생제·진통제·소독약. 동네 약국은 빨리 털립니다.'
  },
  clinic: {
    label: '의원/보건소', emoji: '🩺', color: '#f06292', group: '의료',
    resources: { food: 0, water: 1, medical: 3, weapons: 0, tools: 1, fuel: 0, shelter: 1 },
    people: { day: 20, night: 1 }, risk: 2, defense: 1, stash: 0.4,
    tip: '대형병원보다 안전하게 의약품 확보 가능.'
  },
  fuel: {
    label: '주유소', emoji: '⛽', color: '#ff9800', group: '보급',
    resources: { food: 1, water: 1, medical: 0, weapons: 0, tools: 2, fuel: 5, shelter: 0 },
    people: { day: 6, night: 2 }, risk: 1, defense: 0, stash: 0.3,
    tip: '발전기·차량용 연료. 화재 위험 지역이니 총기 사용 금지.'
  },
  prison: {
    label: '교도소', emoji: '⛓️', color: '#607d8b', group: '거점',
    resources: { food: 3, water: 3, medical: 2, weapons: 3, tools: 2, fuel: 2, shelter: 5 },
    people: { day: 1500, night: 1500 }, risk: 4, defense: 5, stash: 0.7,
    tip: '릭의 교도소. 이중 담장·감시탑·텃밭 공간. 내부 정리만 되면 최고의 요새.'
  },
  shelter: {
    label: '대피소', emoji: '🛡️', color: '#00bcd4', group: '거점',
    resources: { food: 2, water: 3, medical: 2, weapons: 0, tools: 1, fuel: 0, shelter: 4 },
    people: { day: 30, night: 30 }, risk: 3, defense: 3, stash: 0.2,
    tip: '피난민이 몰리는 곳. 한 명만 감염돼도 순식간에 함락됩니다.'
  },
  subway: {
    label: '지하철역', emoji: '🚇', color: '#009688', group: '거점',
    resources: { food: 1, water: 1, medical: 1, weapons: 0, tools: 1, fuel: 0, shelter: 3 },
    people: { day: 2000, night: 100 }, risk: 5, defense: 2, stash: 0.2,
    tip: '터널은 어둡고 퇴로가 없습니다. 지하 대피소로 지정된 곳이 많지만 함정이 되기 쉽습니다.'
  },
  church: {
    label: '교회/성당/절', emoji: '⛪', color: '#9c27b0', group: '거점',
    resources: { food: 1, water: 1, medical: 0, weapons: 0, tools: 1, fuel: 0, shelter: 3 },
    people: { day: 20, night: 5 }, risk: 1, defense: 2, stash: 0.4,
    tip: '가브리엘 신부의 교회. 튼튼한 문, 높은 천장. 시즌5를 기억하세요.'
  },
  university: {
    label: '대학교', emoji: '🎓', color: '#ffc107', group: '거점',
    resources: { food: 2, water: 3, medical: 1, weapons: 0, tools: 2, fuel: 1, shelter: 3 },
    people: { day: 8000, night: 800 }, risk: 4, defense: 2, stash: 0.4,
    tip: '넓은 부지와 건물 다수. 기숙사는 위험, 연구동·체육관은 거점 후보.'
  },
  school: {
    label: '학교', emoji: '🏫', color: '#ffeb3b', group: '거점',
    resources: { food: 2, water: 2, medical: 1, weapons: 0, tools: 1, fuel: 0, shelter: 3 },
    people: { day: 800, night: 5 }, risk: 3, defense: 3, stash: 0.4,
    tip: '담장과 운동장(시야 확보). 야간 발생이면 비어있을 가능성이 높습니다.'
  },
  apartment: {
    label: '아파트', emoji: '🏢', color: '#9e9e9e', group: '주거',
    resources: { food: 2, water: 2, medical: 1, weapons: 0, tools: 1, fuel: 0, shelter: 2 },
    people: { day: 120, night: 300 }, risk: 5, defense: 2, stash: 0.5,
    tip: '세대마다 식량이 있지만 인구 밀도가 압도적. 계단 통제가 핵심.'
  },
  house: {
    label: '주택', emoji: '🏠', color: '#bdbdbd', group: '주거',
    resources: { food: 2, water: 1, medical: 1, weapons: 1, tools: 2, fuel: 0, shelter: 3 },
    people: { day: 1, night: 3 }, risk: 1, defense: 2, stash: 0.6,
    tip: '알렉산드리아처럼 단독주택 단지는 담장만 세우면 공동체 거점이 됩니다.'
  },
  park: {
    label: '공원', emoji: '🌳', color: '#2e7d32', group: '지형',
    resources: { food: 0, water: 1, medical: 0, weapons: 0, tools: 0, fuel: 0, shelter: 1 },
    people: { day: 60, night: 5 }, risk: 1, defense: 0, stash: 0,
    tip: '시야가 트여 이동로로 좋지만 숨을 곳이 없습니다.'
  }
};

// 사용자 정의 마커 종류
const CUSTOM_MARKERS = {
  danger: { label: '위험 지대', emoji: '☠️' },
  rally:  { label: '집결지', emoji: '🚩' },
  hide:   { label: '은신처', emoji: '⛺' },
  trap:   { label: '함정/바리케이드', emoji: '🚧' },
  cache:  { label: '물자 은닉', emoji: '📦' },
  note:   { label: '메모', emoji: '📝' }
};

// 사태 경과일 시나리오
// infection: 감염 비율, loot: 남아있는 물자 비율(약탈 진행), survivors: 감염되지 않은 사람 중 그 자리에 남아있는 비율
const SCENARIOS = {
  1:   { label: 'Day 1 — 발생 직후', infection: 0.08, loot: 1.0, survivors: 0.6 },
  7:   { label: 'Day 7 — 붕괴',     infection: 0.55, loot: 0.6, survivors: 0.3 },
  30:  { label: 'Day 30 — 무법지대', infection: 0.85, loot: 0.3, survivors: 0.1 },
  180: { label: 'Day 180 — 새 질서', infection: 0.93, loot: 0.12, survivors: 0.05 }
};

const RESOURCE_LABELS = {
  food: '식량', water: '물', medical: '의약품', weapons: '무기', tools: '도구', fuel: '연료', shelter: '은신'
};

// OSM 태그 → 카테고리. 순서가 중요 (의과대학을 대학교보다 먼저 검사)
function classify(tags) {
  const t = tags || {};
  const name = (t.name || t['name:ko'] || '') + ' ' + (t['name:en'] || '');
  if (t.amenity === 'prison') return 'prison';
  if (t.landuse === 'military' || t.military) return 'military';
  if (t.amenity === 'police') return 'police';
  if (t.amenity === 'fire_station') return 'fire_station';
  if ((t.amenity === 'university' || t.amenity === 'college') && /의과|의대|의학|간호|medic|nursing/i.test(name)) return 'medical_school';
  if (t.amenity === 'hospital') return 'hospital';
  if (t.amenity === 'pharmacy' || t.healthcare === 'pharmacy') return 'pharmacy';
  if (t.amenity === 'clinic' || t.amenity === 'doctors' || t.healthcare === 'clinic') return 'clinic';
  if (t.shop === 'weapons' || t.shop === 'hunting' || t.shop === 'outdoor') return 'weapons_shop';
  if (t.shop === 'hardware' || t.shop === 'doityourself') return 'hardware';
  if (t.shop === 'supermarket' || t.shop === 'wholesale' || t.shop === 'department_store') return 'supermarket';
  if (t.shop === 'convenience') return 'convenience';
  if (t.amenity === 'restaurant' || t.amenity === 'fast_food' || t.amenity === 'food_court') return 'restaurant';
  if (t.amenity === 'fuel') return 'fuel';
  if (t.amenity === 'shelter' || t.emergency === 'assembly_point' || t.building === 'bunker' || t.emergency === 'shelter') return 'shelter';
  if (t.station === 'subway' || (t.railway === 'station' && t.subway === 'yes')) return 'subway';
  if (t.amenity === 'place_of_worship') return 'church';
  if (t.amenity === 'university' || t.amenity === 'college') return 'university';
  if (t.amenity === 'school') return 'school';
  if (t.landuse === 'farmland' || t.landuse === 'farmyard' || t.landuse === 'orchard' || t.place === 'farm') return 'farm';
  if (t.building === 'apartments' || t.landuse === 'residential' && t.residential === 'apartments') return 'apartment';
  if (t.building === 'house' || t.building === 'detached' || t.building === 'semidetached_house') return 'house';
  if (t.leisure === 'park') return 'park';
  return null;
}
