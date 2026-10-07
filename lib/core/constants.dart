/// 계산 기준값. 바꿀 때는 출처를 함께 갱신할 것.
class Needs {
  /// 1인 하루 물 3L (마시는 물·조리).
  /// 출처: Sphere Handbook 2018, Water supply standard 2.1 (생존용 최소 2.5~3L/인/일).
  static const waterLitersPerPersonPerDay = 3.0;

  /// 하루 3끼 기준, 단위는 "끼니 분량". (CLAUDE.md 계산 기준)
  static const mealsPerPersonPerDay = 3.0;
}

/// 도보 속도 (지도 거리 → 시간). 위기 상황의 보수적 보행 속도.
const walkingMetersPerMinute = 70.0;
