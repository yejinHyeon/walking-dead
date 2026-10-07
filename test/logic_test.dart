import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:survivor/core/app_state.dart';
import 'package:survivor/core/content.dart';
import 'package:survivor/core/geo.dart';
import 'package:survivor/core/region_pack.dart';
import 'package:survivor/services/signals.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('보유품 계산', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('목업 기본값: 3명, 물 8L, 13끼 → 물 0.8일, 식량 1.4일, 물이 먼저', () async {
      final s = await AppState.open();
      expect(s.totalMeals, 13);
      expect(s.waterDays, 0.8);
      expect(s.foodDays, 1.4);
      expect(s.waterRunsOutFirst, isTrue);
    });

    test('일수는 반올림하지 않고 내림한다', () async {
      final s = await AppState.open();
      s
        ..people = 1
        ..waterLiters = 8; // 8/3 = 2.666…
      expect(s.waterDays, 2.6);
    });

    test('저장 후 다시 열면 그대로', () async {
      final s = await AppState.open();
      s
        ..people = 5
        ..languageCode = 'en'
        ..changed();
      final s2 = await AppState.open();
      expect(s2.people, 5);
      expect(s2.languageCode, 'en');
    });
  });

  group('약 찾기 (기기 안)', () {
    late List<Medicine> db;
    setUpAll(() async => db = (await Content.load('ko')).medicines);

    test('포장 글자에서 성분·용량·기한을 찾는다', () {
      final m = matchMedicines('타이레놀정 500mg\n아세트아미노펜\n사용기한 2027.03.31', db);
      expect(m.first.medicine.id, 'acetaminophen');
      expect(m.first.level, MatchLevel.high);
      expect(m.first.strength, '500mg');
      expect(m.first.expiry, '2027.03.31');
    });

    test('키워드 하나면 확신도 보통', () {
      final m = matchMedicines('Ibuprofen 200 mg tablets', db);
      expect(m.first.medicine.id, 'ibuprofen');
      expect(m.first.level, MatchLevel.medium);
    });

    test('모르는 글자는 결과 없음', () {
      expect(matchMedicines('비타민C 1000', db), isEmpty);
      expect(matchMedicines('', db), isEmpty);
    });
  });

  test('SOS 모스부호: 짧게 3 · 길게 3 · 짧게 3', () {
    final on = sosPattern().where((e) => e.$1).map((e) => e.$2).toList();
    expect(on, [1, 1, 1, 3, 3, 3, 1, 1, 1]);
    expect(sosPattern().last, (false, 7));
  });

  test('거리·방향', () {
    const a = LatLng2(37.5663, 126.9779);
    const b = LatLng2(37.5753, 126.9779); // 약 1km 북쪽
    expect(distanceMeters(a, b), closeTo(1000, 15));
    expect(compassIndex(bearingDegrees(a, b)), 0);
    expect(compassIndex(bearingDegrees(b, a)), 4);
    expect(formatDistance(450), '450 m');
    expect(formatDistance(1530), '1.5 km');
  });

  group('콘텐츠 파일', () {
    test('ko·en 콘텐츠가 같은 구조를 가진다', () async {
      final ko = await Content.load('ko'), en = await Content.load('en');
      expect(en.topics.map((t) => t.id), ko.topics.map((t) => t.id));
      for (var i = 0; i < ko.topics.length; i++) {
        expect(en.topics[i].steps.length, ko.topics[i].steps.length, reason: ko.topics[i].id);
        expect(en.topics[i].sources, ko.topics[i].sources);
      }
      expect(en.water.map((w) => w.id), ko.water.map((w) => w.id));
      expect(en.recipes.map((r) => r.id), ko.recipes.map((r) => r.id));
      expect(en.foods.keys, ko.foods.keys);
      expect(en.kit.map((k) => k.id), ko.kit.map((k) => k.id));
      expect(en.wounds.map((w) => w.id), ko.wounds.map((w) => w.id));
    });

    test('모든 출처 키가 정의되어 있고, 상처 목록은 실제 응급처치 주제로 연결된다', () async {
      for (final lang in ['ko', 'en']) {
        final c = await Content.load(lang);
        for (final t in c.topics) {
          for (final s in t.sources) {
            expect(c.aidSources.containsKey(s), isTrue, reason: '$lang ${t.id} $s');
          }
        }
        for (final w in c.wounds) {
          expect(c.topic(w.topic), isNotNull, reason: w.id);
        }
        for (final r in c.recipes) {
          for (final n in r.needs) {
            expect(c.foods.containsKey(n), isTrue, reason: '${r.id} $n');
          }
        }
      }
    });

    test('모든 콘텐츠 파일에 출처(meta.sources)가 기록되어 있다', () {
      for (final f in Directory('assets/content').listSync(recursive: true).whereType<File>()) {
        final j = jsonDecode(f.readAsStringSync());
        final meta = j['meta'] as Map;
        if (f.path.endsWith('wounds.json')) continue; // 사람이 고르는 목록 (안내 문구 없음)
        expect(meta['sources'], isNotEmpty, reason: f.path);
      }
    });

    test('물 정화 기준값 (CLAUDE.md)', () async {
      final ko = await Content.load('ko');
      final text = ko.water.expand((w) => w.steps).join(' ');
      expect(text, contains('1분'));
      expect(text, contains('3분'));
      expect(text, contains('2방울'));
      expect(text, contains('30분'));
      expect(text, contains('6시간'));
    });
  });

  test('지역팩: 샘플 표시, 응급 번호, 장소', () async {
    final p = await RegionPack.load('korea');
    expect(p.sample, isTrue);
    expect(p.numbers.map((n) => n.number), containsAll(['119', '112']));
    expect(p.places.where((x) => x.type == PlaceType.shelter), isNotEmpty);
    for (final x in p.places) {
      expect(tr(x.name, 'ko'), startsWith('[샘플]'));
    }
  });
}
