import 'dart:convert';

import 'package:flutter/services.dart';

/// 오프라인 콘텐츠 (assets/content/{lang}/*.json). 번역이 없으면 영어 → 한국어 순으로 대체.
class Content {
  final String lang;
  final List<AidTopic> topics;
  final Map<String, String> aidSources;
  final List<WaterMethod> water;
  final Map<String, String> foods;
  final List<Recipe> recipes;
  final Map<String, dynamic> uxo;
  final List<KitItem> kit;
  final List<Medicine> medicines;
  final List<WoundType> wounds;

  Content({
    required this.lang,
    required this.topics,
    required this.aidSources,
    required this.water,
    required this.foods,
    required this.recipes,
    required this.uxo,
    required this.kit,
    required this.medicines,
    required this.wounds,
  });

  static const supported = ['ko', 'en'];

  static Future<Content> load(String lang, {AssetBundle? bundle}) async {
    final b = bundle ?? rootBundle;
    final l = supported.contains(lang) ? lang : 'en';
    Future<Map<String, dynamic>> j(String name) async => jsonDecode(await b.loadString('assets/content/$l/$name.json'));

    final fa = await j('first_aid');
    final w = await j('water');
    final r = await j('recipes');
    final u = await j('uxo');
    final k = await j('kit');
    final m = await j('medicines');
    final wo = await j('wounds');
    return Content(
      lang: l,
      topics: [for (final t in fa['topics']) AidTopic.fromJson(t)],
      aidSources: Map<String, String>.from(fa['meta']['sources']),
      water: [for (final x in w['methods']) WaterMethod.fromJson(x)],
      foods: Map<String, String>.from(r['foods']),
      recipes: [for (final x in r['recipes']) Recipe.fromJson(x)],
      uxo: u,
      kit: [for (final x in k['items']) KitItem(x['id'], x['t'], x['d'])],
      medicines: [for (final x in m['medicines']) Medicine.fromJson(x)],
      wounds: [for (final x in wo['types']) WoundType(x['id'], x['t'], x['d'], x['topic'])],
    );
  }

  AidTopic? topic(String id) => topics.where((t) => t.id == id).firstOrNull;
}

class AidStep {
  final String title, body;
  AidStep(this.title, this.body);
}

class AidTopic {
  final String id, title, summary, keywords;
  final List<String> sources, redFlags;
  final List<AidStep> steps;
  AidTopic(this.id, this.title, this.summary, this.keywords, this.sources, this.redFlags, this.steps);
  factory AidTopic.fromJson(Map<String, dynamic> j) => AidTopic(
        j['id'], j['title'], j['summary'], j['keywords'],
        List<String>.from(j['sources']), List<String>.from(j['redFlags']),
        [for (final s in j['steps']) AidStep(s['title'], s['body'])],
      );

  bool matches(String q) {
    final words = q.toLowerCase().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    final hay = '$title $summary $keywords'.toLowerCase();
    return words.every(hay.contains);
  }
}

class WaterMethod {
  final String id, label, intro;
  final List<String> steps;
  WaterMethod(this.id, this.label, this.intro, this.steps);
  factory WaterMethod.fromJson(Map<String, dynamic> j) => WaterMethod(j['id'], j['label'], j['intro'], List<String>.from(j['steps']));
}

class Recipe {
  final String id, title, ingredients;
  final List<String> needs, steps;
  final bool fire;
  final int waterMl, fireMin, serves;
  Recipe(this.id, this.title, this.ingredients, this.needs, this.steps, this.fire, this.waterMl, this.fireMin, this.serves);
  factory Recipe.fromJson(Map<String, dynamic> j) => Recipe(j['id'], j['title'], j['ingredients'], List<String>.from(j['needs']),
      List<String>.from(j['steps']), j['fire'], j['waterMl'], j['fireMin'], j['serves']);
}

class KitItem {
  final String id, t, d;
  KitItem(this.id, this.t, this.d);
}

class WoundType {
  final String id, t, d, topic;
  WoundType(this.id, this.t, this.d, this.topic);
}

class Medicine {
  final String id, name, category, what;
  final List<String> keywords, mustKnow;
  Medicine(this.id, this.name, this.category, this.what, this.keywords, this.mustKnow);
  factory Medicine.fromJson(Map<String, dynamic> j) => Medicine(j['id'], j['name'], j['category'], j['what'],
      List<String>.from(j['keywords']), List<String>.from(j['mustKnow']));
}

enum MatchLevel { high, medium, low }

class MedMatch {
  final Medicine medicine;
  final MatchLevel level;
  final String? strength; // 예: 500mg (사진 글자에서 읽은 경우)
  final String? expiry; // 예: 2027.03.31
  MedMatch(this.medicine, this.level, {this.strength, this.expiry});
}

String _norm(String s) => s.toLowerCase().replaceAll(RegExp(r'[\s\-·.,()\[\]]'), '');

/// 사진 글자(또는 직접 입력)에서 약을 찾는다. 기기 안에서만 동작.
/// 키워드가 2개 이상 겹치면 high, 1개면 medium.
List<MedMatch> matchMedicines(String text, List<Medicine> db) {
  final t = _norm(text);
  if (t.isEmpty) return [];
  final strength = RegExp(r'(\d{2,4})\s?(mg|밀리그램)', caseSensitive: false).firstMatch(text)?.group(0)?.replaceAll(' ', '');
  final exp = RegExp(r'(20\d{2})[.\-/년 ]\s?(\d{1,2})[.\-/월 ]\s?(\d{1,2})?').firstMatch(text);
  final expiry = exp == null ? null : [exp.group(1), exp.group(2)!.padLeft(2, '0'), if (exp.group(3) != null) exp.group(3)!.padLeft(2, '0')].join('.');
  final out = <MedMatch>[];
  for (final m in db) {
    final hits = m.keywords.where((k) => t.contains(_norm(k))).length;
    if (hits == 0) continue;
    out.add(MedMatch(m, hits >= 2 ? MatchLevel.high : MatchLevel.medium, strength: strength, expiry: expiry));
  }
  out.sort((a, b) => a.level.index.compareTo(b.level.index));
  return out;
}
