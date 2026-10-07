import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:survivor/app.dart';
import 'package:survivor/core/app_state.dart';
import 'package:survivor/core/region_pack.dart';

Future<AppState> _boot(WidgetTester t, {String? lang}) async {
  SharedPreferences.setMockInitialValues(lang == null ? {} : {'survivor.state.v1': '{"lang":"$lang"}'});
  t.view.physicalSize = const Size(390 * 3, 844 * 3);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  late AppState state;
  late RegionPack pack;
  await t.runAsync(() async {
    state = await AppState.open();
    pack = await RegionPack.load('korea');
  });
  // 테스트마다 새 애셋 번들: rootBundle 캐시는 이전 테스트의 Zone에 묶여 끝나지 않을 수 있다
  await t.pumpWidget(SurvivorApp(state: state, pack: pack, bundle: PlatformAssetBundle()));
  await _settleContent(t);
  return state;
}

/// 오프라인 콘텐츠(애셋) 비동기 로딩이 끝날 때까지 기다린다
Future<void> _settleContent(WidgetTester t) async {
  for (var i = 0; i < 100; i++) {
    await t.runAsync(() => Future.delayed(const Duration(milliseconds: 20)));
    await t.pump();
    if (find.byType(CircularProgressIndicator).evaluate().isEmpty) break;
  }
  await t.pump();
}

void main() {
  testWidgets('첫 실행: 언어 선택 → 한국어 홈', (t) async {
    final s = await _boot(t);
    expect(find.text('언어를 선택하세요'), findsOneWidget);
    await t.tap(find.text('한국어'));
    await t.tap(find.text('계속하기'));
    await _settleContent(t);
    expect(s.languageCode, 'ko');
    expect(find.text('지금 무엇이 필요하세요?'), findsOneWidget);
    expect(find.text('가장 가까운 대피소'), findsOneWidget);
    expect(find.textContaining('[샘플] 대피소'), findsWidgets);
  });

  testWidgets('응급처치: 단계 넘기기', (t) async {
    await _boot(t, lang: 'ko');
    await t.tap(find.text('응급처치').last);
    await t.pumpAndSettle();
    await t.tap(find.text('심한 출혈'));
    await t.pumpAndSettle();
    expect(find.text('1 / 6단계'), findsOneWidget);
    expect(find.text('상처를 세게 누르세요'), findsOneWidget);
    await t.tap(find.text('다음 단계'));
    await t.pumpAndSettle();
    expect(find.text('2 / 6단계'), findsOneWidget);
    expect(find.text('떼지 말고 계속 누르세요'), findsOneWidget);
  });

  testWidgets('보유품: 사람 수를 늘리면 일수가 줄어든다', (t) async {
    final s = await _boot(t, lang: 'ko');
    await t.tap(find.text('보유품').last);
    await t.pumpAndSettle();
    expect(find.text('0.8일'), findsOneWidget); // 물 8L / (3명 × 3L)
    await t.tap(find.byIcon(Icons.add).first);
    await t.pumpAndSettle();
    expect(s.people, 4);
    expect(find.text('0.6일'), findsOneWidget);
    expect(find.textContaining('물이 먼저 떨어져요'), findsOneWidget);
  });

  testWidgets('영어로 바꾸면 영어 콘텐츠', (t) async {
    await _boot(t, lang: 'en');
    expect(find.text('What do you need right now?'), findsOneWidget);
    await t.tap(find.text('First aid').last);
    await t.pumpAndSettle();
    expect(find.text('Severe bleeding'), findsOneWidget);
  });

  testWidgets('RTL 미리보기 (ar): 오른쪽에서 왼쪽 레이아웃', (t) async {
    await _boot(t, lang: 'ar');
    final dir = Directionality.of(t.element(find.text('What do you need right now?')));
    expect(dir, TextDirection.rtl);
  });
}
