import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'constants.dart';
import 'geo.dart';

class FoodItem {
  /// 콘텐츠의 식재료 키 (tuna, ramen …). 직접 입력한 식량은 null.
  final String? key;
  final String? customName;
  int meals;
  FoodItem({this.key, this.customName, required this.meals});
  Map<String, dynamic> toJson() => {'key': key, 'name': customName, 'meals': meals};
  factory FoodItem.fromJson(Map<String, dynamic> j) => FoodItem(key: j['key'], customName: j['name'], meals: j['meals']);
}

class Member {
  String name, contact, blood, allergy, meds;
  Member({this.name = '', this.contact = '', this.blood = '', this.allergy = '', this.meds = ''});
  Map<String, dynamic> toJson() => {'n': name, 'c': contact, 'b': blood, 'a': allergy, 'm': meds};
  factory Member.fromJson(Map<String, dynamic> j) =>
      Member(name: j['n'] ?? '', contact: j['c'] ?? '', blood: j['b'] ?? '', allergy: j['a'] ?? '', meds: j['m'] ?? '');
}

class MeetPoint {
  String name, how;
  MeetPoint({this.name = '', this.how = ''});
  Map<String, dynamic> toJson() => {'n': name, 'h': how};
  factory MeetPoint.fromJson(Map<String, dynamic>? j) => MeetPoint(name: j?['n'] ?? '', how: j?['h'] ?? '');
}

class SavedMed {
  final String id, medicineId, label;
  final String? expiry;
  SavedMed(this.id, this.medicineId, this.label, this.expiry);
  Map<String, dynamic> toJson() => {'id': id, 'med': medicineId, 'label': label, 'exp': expiry};
  factory SavedMed.fromJson(Map<String, dynamic> j) => SavedMed(j['id'], j['med'], j['label'], j['exp']);
}

/// 앱 상태. 모든 데이터는 이 기기에만 저장된다 (계정·서버 없음).
class AppState extends ChangeNotifier {
  static const _key = 'survivor.state.v1';
  final SharedPreferences _prefs;

  String? languageCode; // null이면 첫 실행 → 언어 선택 화면
  int people = 3;
  int waterLiters = 8;
  List<FoodItem> foods = [
    FoodItem(key: 'tuna', meals: 3),
    FoodItem(key: 'ramen', meals: 4),
    FoodItem(key: 'crackers', meals: 2),
    FoodItem(key: 'peanut_butter', meals: 4),
  ];
  Set<String> kitDone = {};
  MeetPoint meet1 = MeetPoint(), meet2 = MeetPoint();
  List<Member> members = [];
  List<SavedMed> savedMeds = [];

  AppState(this._prefs) {
    final raw = _prefs.getString(_key);
    if (raw != null) {
      try {
        _fromJson(jsonDecode(raw));
      } catch (_) {
        // 손상된 저장값은 무시하고 기본값으로 시작
      }
    }
  }

  static Future<AppState> open() async => AppState(await SharedPreferences.getInstance());

  void _fromJson(Map<String, dynamic> j) {
    languageCode = j['lang'];
    people = j['people'] ?? people;
    waterLiters = j['water'] ?? waterLiters;
    if (j['foods'] != null) foods = [for (final f in j['foods']) FoodItem.fromJson(f)];
    kitDone = Set<String>.from(j['kit'] ?? []);
    meet1 = MeetPoint.fromJson(j['meet1']);
    meet2 = MeetPoint.fromJson(j['meet2']);
    members = [for (final m in j['members'] ?? []) Member.fromJson(m)];
    savedMeds = [for (final m in j['meds'] ?? []) SavedMed.fromJson(m)];
  }

  Map<String, dynamic> toJson() => {
        'lang': languageCode,
        'people': people,
        'water': waterLiters,
        'foods': foods.map((f) => f.toJson()).toList(),
        'kit': kitDone.toList(),
        'meet1': meet1.toJson(),
        'meet2': meet2.toJson(),
        'members': members.map((m) => m.toJson()).toList(),
        'meds': savedMeds.map((m) => m.toJson()).toList(),
      };

  void changed() {
    _prefs.setString(_key, jsonEncode(toJson()));
    notifyListeners();
  }

  void setLanguage(String code) {
    languageCode = code;
    changed();
  }

  // ---------- 보유품 계산 ----------
  int get totalMeals => foods.fold(0, (a, f) => a + f.meals);
  double get waterDays => floor1(waterLiters / (people * Needs.waterLitersPerPersonPerDay));
  double get foodDays => floor1(totalMeals / (people * Needs.mealsPerPersonPerDay));
  bool get waterRunsOutFirst => waterDays <= foodDays;

  /// 식재료 키 중 지금 1끼 이상 가진 것
  Set<String> get availableFoodKeys => {for (final f in foods) if (f.key != null && f.meals > 0) f.key!};
}
