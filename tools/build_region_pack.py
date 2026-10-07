#!/usr/bin/env python3
"""공공데이터포털 '민방위대피시설' CSV → SURVIVOR 지역팩(pack.json) 변환.

앱에는 API 키를 넣지 않는다 (CLAUDE.md). 이 스크립트는 개발자 PC나 작은 서버에서 실행해
지역팩 파일을 만들고, 앱은 그 파일만 받는다.

사용 예:
  python3 tools/build_region_pack.py shelters.csv \
      --area-ko "서울 중구" --area-en "Jung-gu, Seoul" \
      --agency-ko "행정안전부 민방위대피시설 (공공데이터포털)" \
      --verified 2026-10-01 --out assets/regions/korea/pack.json

CSV 열 이름은 내려받은 파일마다 다를 수 있다. 실제 파일의 머리글을 확인하고
--col-name/--col-lat/--col-lng/--col-kind 로 맞출 것. TODO(검토 필요): 최신 데이터셋 열 이름 확인.
"""
import argparse
import csv
import json
import sys


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('csv')
    ap.add_argument('--encoding', default='utf-8-sig', help='공공데이터 CSV는 cp949인 경우가 많음')
    ap.add_argument('--col-name', default='시설명')
    ap.add_argument('--col-lat', default='위도')
    ap.add_argument('--col-lng', default='경도')
    ap.add_argument('--col-kind', default='시설구분')
    ap.add_argument('--col-floor', default='시설위치')
    ap.add_argument('--area-ko', required=True)
    ap.add_argument('--area-en', required=True)
    ap.add_argument('--agency-ko', required=True)
    ap.add_argument('--agency-en', default='Ministry of the Interior and Safety (data.go.kr)')
    ap.add_argument('--verified', required=True, help='자료 기준일 YYYY-MM-DD')
    ap.add_argument('--out', required=True)
    a = ap.parse_args()

    places = []
    with open(a.csv, encoding=a.encoding, newline='') as f:
        for i, row in enumerate(csv.DictReader(f)):
            try:
                lat, lng = float(row[a.col_lat]), float(row[a.col_lng])
            except (KeyError, ValueError):
                continue
            if not (33 <= lat <= 39 and 124 <= lng <= 132):  # 한국 범위 밖 좌표 제외
                continue
            name = (row.get(a.col_name) or '').strip() or f'대피소 {i + 1}'
            kind = ' · '.join(x for x in [(row.get(a.col_kind) or '').strip(), (row.get(a.col_floor) or '').strip()] if x)
            places.append({
                'id': f's{i}', 'type': 'shelter',
                'name': {'ko': name, 'en': name},
                'kind': {'ko': kind or '민방위 대피소', 'en': 'Public shelter'},
                'lat': round(lat, 6), 'lng': round(lng, 6),
                'source': {'ko': a.agency_ko, 'en': a.agency_en},
                'verified': a.verified,
            })
    if not places:
        sys.exit('좌표가 있는 행을 찾지 못했습니다. 열 이름(--col-*)과 인코딩(--encoding)을 확인하세요.')

    lat = sum(p['lat'] for p in places) / len(places)
    lng = sum(p['lng'] for p in places) / len(places)
    pack = {
        'id': 'korea', 'sample': False,
        'name': {'ko': '한국', 'en': 'Korea'},
        'area': {'ko': a.area_ko, 'en': a.area_en},
        'savedDate': a.verified,
        'center': {'lat': round(lat, 6), 'lng': round(lng, 6)},
        'languages': ['ko', 'en'],
        'emergencyNumbers': [
            {'number': '119', 'label': {'ko': '화재 · 구조 · 구급', 'en': 'Fire · Rescue · Ambulance'}},
            {'number': '112', 'label': {'ko': '경찰', 'en': 'Police'}},
            {'number': '1339', 'label': {'ko': '질병관리청 (감염병)', 'en': 'KDCA (infectious disease)'}},
            {'number': '122', 'label': {'ko': '해양 긴급신고', 'en': 'Maritime emergency'}},
        ],
        'places': places,
        'dangerZones': [],
        'sources': [{'ko': f'{a.agency_ko} · {a.verified} 기준', 'en': f'{a.agency_en} · as of {a.verified}'}],
        'tiles': None,
    }
    with open(a.out, 'w', encoding='utf-8') as f:
        json.dump(pack, f, ensure_ascii=False, indent=2)
        f.write('\n')
    print(f'{len(places)}곳 → {a.out}')


if __name__ == '__main__':
    main()
