import 'dart:convert';

import 'package:flutter/services.dart';

import 'geo.dart';

/// 지역팩: 국가별 데이터 (응급 번호, 대피소, 의료·구호 지점, 출처·기준일).
class RegionPack {
  final String id;
  final bool sample;
  final Map<String, String> name, area;
  final String savedDate;
  final LatLng2 center;
  final List<EmergencyNumber> numbers;
  final List<Place> places;
  final List<DangerZone> dangerZones;
  final List<Map<String, String>> sources;

  RegionPack(this.id, this.sample, this.name, this.area, this.savedDate, this.center, this.numbers, this.places,
      this.dangerZones, this.sources);

  static Future<RegionPack> load(String id, {AssetBundle? bundle}) async {
    final j = jsonDecode(await (bundle ?? rootBundle).loadString('assets/regions/$id/pack.json'));
    return RegionPack.fromJson(j);
  }

  factory RegionPack.fromJson(Map<String, dynamic> j) => RegionPack(
        j['id'],
        j['sample'] == true,
        Map<String, String>.from(j['name']),
        Map<String, String>.from(j['area']),
        j['savedDate'],
        LatLng2(j['center']['lat'], j['center']['lng']),
        [for (final n in j['emergencyNumbers']) EmergencyNumber(n['number'], Map<String, String>.from(n['label']))],
        [for (final p in j['places']) Place.fromJson(p)],
        [
          for (final d in j['dangerZones'] ?? [])
            DangerZone(d['id'], Map<String, String>.from(d['label']), LatLng2(d['center']['lat'], d['center']['lng']),
                (d['radiusM'] as num).toDouble())
        ],
        [for (final s in j['sources']) Map<String, String>.from(s)],
      );
}

/// 지역팩 문구: 현재 언어 → 영어 → 아무 값
String tr(Map<String, String> m, String lang) => m[lang] ?? m['en'] ?? m.values.first;

class EmergencyNumber {
  final String number;
  final Map<String, String> label;
  EmergencyNumber(this.number, this.label);
}

enum PlaceType { shelter, aid, water, medical }

class Place {
  final String id;
  final PlaceType type;
  final Map<String, String> name, kind, source;
  final LatLng2 pos;
  final String verified;
  Place(this.id, this.type, this.name, this.kind, this.source, this.pos, this.verified);
  factory Place.fromJson(Map<String, dynamic> j) => Place(
        j['id'],
        PlaceType.values.byName(j['type']),
        Map<String, String>.from(j['name']),
        Map<String, String>.from(j['kind']),
        Map<String, String>.from(j['source']),
        LatLng2(j['lat'], j['lng']),
        j['verified'],
      );
}

class DangerZone {
  final String id;
  final Map<String, String> label;
  final LatLng2 center;
  final double radiusM;
  DangerZone(this.id, this.label, this.center, this.radiusM);
}
