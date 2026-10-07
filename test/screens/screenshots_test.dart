// 화면 캡처 도구 (CI 테스트 아님). 한국어 글꼴 경로를 주면 PNG를 만든다:
//   SCREENSHOT_FONT_DIR=/path/to/ttf SCREENSHOT_OUT=/tmp/shots flutter test test/screens/screenshots_test.dart
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:survivor/app.dart';
import 'package:survivor/core/app_state.dart';
import 'package:survivor/core/region_pack.dart';
import 'package:survivor/screens/first_aid_screens.dart';
import 'package:survivor/screens/home_screen.dart';
import 'package:survivor/screens/language_screen.dart';
import 'package:survivor/screens/map_screen.dart';
import 'package:survivor/screens/plan_screens.dart';
import 'package:survivor/screens/scan_screens.dart';
import 'package:survivor/screens/supplies_screens.dart';

final fontDir = Platform.environment['SCREENSHOT_FONT_DIR'];
final outDir = Platform.environment['SCREENSHOT_OUT'] ?? '/tmp/shots';

Future<void> _fonts() async {
  // 테스트 엔진의 기본 글꼴(FlutterTest)과 Roboto 이름 모두에 한국어 글꼴을 등록
  for (final family in ['NotoSansKR']) {
    final f = FontLoader(family);
    for (final w in ['400Regular/NotoSansKR_400Regular.ttf', '700Bold/NotoSansKR_700Bold.ttf']) {
      f.addFont(Future.value(ByteData.sublistView(File('$fontDir/$w').readAsBytesSync())));
    }
    await f.load();
  }
  final root = Platform.environment['FLUTTER_ROOT'] ?? '/opt/flutter';
  final icons = FontLoader('MaterialIcons')
    ..addFont(Future.value(ByteData.sublistView(File('$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf').readAsBytesSync())));
  await icons.load();
}

Future<void> _shot(WidgetTester t, String name) async {
  for (var i = 0; i < 30; i++) {
    await t.runAsync(() => Future.delayed(const Duration(milliseconds: 20)));
    await t.pump(const Duration(milliseconds: 50));
  }
  final boundary = t.renderObject<RenderRepaintBoundary>(find.byType(RepaintBoundary).first);
  late ui.Image img;
  await t.runAsync(() async {
    img = await boundary.toImage(pixelRatio: 2);
    final png = await img.toByteData(format: ui.ImageByteFormat.png);
    File('$outDir/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
  });
}

Uint8List _fakePhoto() {
  // 회색 사각형 PNG (사진 자리)
  return base64.decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVR4nGNoaGgAAAMEAYFL09IQAAAAAElFTkSuQmCC');
}


void main() {
  testWidgets('screenshots', (t) async {
    if (fontDir == null) return; // 글꼴이 없으면 건너뜀
    Directory(outDir).createSync(recursive: true);
    await t.runAsync(_fonts);
    t.view.physicalSize = const Size(390 * 2, 844 * 2);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);

    for (final lang in ['ko', 'ar']) {
      SharedPreferences.setMockInitialValues({'survivor.state.v1': '{"lang":"$lang"}'});
      late AppState state;
      late RegionPack pack;
      await t.runAsync(() async {
        state = await AppState.open();
        pack = await RegionPack.load('korea');
      });
      await t.pumpWidget(RepaintBoundary(child: SurvivorApp(state: state, pack: pack, bundle: PlatformAssetBundle(), fontFamily: 'NotoSansKR')));
      await _shot(t, '$lang-01-home');
      if (lang == 'ar') break;

      final nav = t.state<NavigatorState>(find.byType(Navigator).first);
      final shell = Provider.of<Shell>(t.element(find.byType(HomeScreen)), listen: false);
      Future<void> push(Widget w, String name) async {
        nav.push(MaterialPageRoute(builder: (_) => w));
        await _shot(t, name);
        nav.pop();
        await t.pump(const Duration(milliseconds: 400));
      }

      for (final (i, name) in [(Shell.map, '02-map'), (Shell.scan, '03-scan'), (Shell.supplies, '04-supplies'), (Shell.firstAid, '05-firstaid-list')]) {
        shell.go(i);
        await _shot(t, 'ko-$name');
      }
      shell.go(Shell.home);
      await push(const FirstAidScreen(topicId: 'bleeding'), 'ko-06-firstaid-step');
      await push(MedResultScreen(photo: _fakePhoto(), path: '', presetText: '타이레놀정 500mg 아세트아미노펜 사용기한 2027.03.31'), 'ko-07-med');
      await push(PlantResultScreen(photo: _fakePhoto()), 'ko-08-plant');
      await push(WoundResultScreen(photo: _fakePhoto()), 'ko-09-wound');
      await push(const SosScreen(), 'ko-10-sos');
      state.members.add(Member(name: '엄마', contact: '010-0000-0000', blood: 'A+'));
      state.meet1.name = '○○초등학교 정문';
      await push(const FamilyScreen(), 'ko-11-family');
      await push(const KitScreen(), 'ko-12-kit');
      await push(const UxoScreen(), 'ko-13-uxo');
      await push(const WaterScreen(), 'ko-14-water');
      await push(const RecipesScreen(), 'ko-15-recipes');
      await push(const LanguageScreen(), 'ko-16-language');
      await push(CompassScreen(target: pack.places.first), 'ko-17-compass');
    }
  });
}
