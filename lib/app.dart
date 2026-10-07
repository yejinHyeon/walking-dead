import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/app_state.dart';
import 'core/content.dart';
import 'core/region_pack.dart';
import 'core/tokens.dart';
import 'l10n/app_localizations.dart';
import 'screens/first_aid_screens.dart';
import 'screens/home_screen.dart';
import 'screens/language_screen.dart';
import 'screens/map_screen.dart';
import 'screens/scan_screens.dart';
import 'screens/supplies_screens.dart';

/// 탭 이동과 지도 필터를 화면끼리 주고받기 위한 작은 컨트롤러
class Shell extends ChangeNotifier {
  int tab = 0;
  PlaceType mapFilter = PlaceType.shelter;
  void go(int i, {PlaceType? filter}) {
    tab = i;
    if (filter != null) mapFilter = filter;
    notifyListeners();
  }

  static const home = 0, map = 1, scan = 2, supplies = 3, firstAid = 4;
}

class SurvivorApp extends StatelessWidget {
  final AppState state;
  final RegionPack pack;
  final AssetBundle? bundle; // 테스트용
  final String? fontFamily; // 화면 캡처 도구용 (앱은 시스템 글꼴)
  const SurvivorApp({super.key, required this.state, required this.pack, this.bundle, this.fontFamily});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: state),
        Provider.value(value: pack),
        ChangeNotifierProvider(create: (_) => Shell()),
      ],
      child: Consumer<AppState>(
        builder: (context, s, _) => MaterialApp(
          title: 'SURVIVOR',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(fontFamily: fontFamily),
          locale: Locale(s.languageCode ?? 'ko'),
          supportedLocales: L.supportedLocales,
          localizationsDelegates: const [
            L.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          // 콘텐츠는 Navigator 위에 두어 모든 화면(push된 화면 포함)에서 쓸 수 있게 한다
          builder: (context, child) => _ContentLoader(lang: s.languageCode ?? 'ko', bundle: bundle, child: child!),
          home: s.languageCode == null ? const LanguageScreen(firstRun: true) : const HomeShell(),
        ),
      ),
    );
  }
}

/// 언어가 바뀌면 해당 언어의 오프라인 콘텐츠를 다시 읽는다.
class _ContentLoader extends StatefulWidget {
  final String lang;
  final AssetBundle? bundle;
  final Widget child;
  const _ContentLoader({required this.lang, required this.child, this.bundle});
  @override
  State<_ContentLoader> createState() => _ContentLoaderState();
}

class _ContentLoaderState extends State<_ContentLoader> {
  Content? content;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(_ContentLoader old) {
    super.didUpdateWidget(old);
    if (old.lang != widget.lang) _load();
  }

  Future<void> _load() async {
    final c = await Content.load(widget.lang, bundle: widget.bundle);
    if (mounted) setState(() => content = c);
  }

  @override
  Widget build(BuildContext context) {
    final c = content;
    if (c == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Provider.value(value: c, child: widget.child);
  }
}

class HomeShell extends StatelessWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context) {
    final shell = context.watch<Shell>();
    final l = L.of(context);
    return Scaffold(
      body: IndexedStack(index: shell.tab, children: const [
        HomeScreen(),
        MapScreen(),
        ScanScreen(),
        SuppliesScreen(),
        FirstAidListScreen(),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.tab,
        onDestinationSelected: shell.go,
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home), label: l.navHome),
          NavigationDestination(icon: const Icon(Icons.map_outlined), selectedIcon: const Icon(Icons.map), label: l.navMap),
          NavigationDestination(
              icon: const Icon(Icons.photo_camera_outlined), selectedIcon: const Icon(Icons.photo_camera), label: l.navScan),
          NavigationDestination(
              icon: const Icon(Icons.inventory_2_outlined), selectedIcon: const Icon(Icons.inventory_2), label: l.navSupplies),
          NavigationDestination(
              icon: const Icon(Icons.medical_services_outlined), selectedIcon: const Icon(Icons.medical_services), label: l.navFirstAid),
        ],
      ),
    );
  }
}
