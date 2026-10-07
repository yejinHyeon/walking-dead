import 'package:flutter/material.dart';

/// 디자인 토큰 (docs/mockups 기준). 색·크기는 여기서만 정의한다.
class T {
  static const bg = Color(0xFF111315);
  static const card = Color(0xFF1B1E22);
  static const line = Color(0xFF2A2E34);
  static const text = Color(0xFFF1F0EC);
  static const muted = Color(0xFFA9ADB3);
  static const accent = Color(0xFFFF8A3D); // 위험/강조 — 위 글자는 bg 색
  static const accentDark = Color(0xFF3A1D12);
  static const info = Color(0xFF7FB2FF); // 정보/대피소

  static const radius = 18.0;
  static const minTouch = 44.0;
  static const mainButton = 54.0;
  static const pad = 20.0;
}

/// [fontFamily]는 비워두면 기기 시스템 글꼴(한국어 포함)을 쓴다. 앱 용량을 위해 글꼴 파일은 넣지 않는다.
ThemeData buildTheme({String? fontFamily}) {
  final base = ThemeData(brightness: Brightness.dark, useMaterial3: true, fontFamily: fontFamily);
  return base.copyWith(
    scaffoldBackgroundColor: T.bg,
    colorScheme: const ColorScheme.dark(
      surface: T.bg,
      primary: T.accent,
      onPrimary: T.bg,
      secondary: T.info,
      onSurface: T.text,
      outline: T.line,
    ),
    textTheme: base.textTheme.apply(bodyColor: T.text, displayColor: T.text).copyWith(
          bodyMedium: base.textTheme.bodyMedium!.copyWith(fontSize: 15, height: 1.5, color: T.text),
          bodyLarge: base.textTheme.bodyLarge!.copyWith(fontSize: 17, height: 1.5, color: T.text),
        ),
    appBarTheme: AppBarTheme(
      backgroundColor: T.bg,
      foregroundColor: T.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: T.text, fontFamily: fontFamily),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: T.bg,
      indicatorColor: T.card,
      height: 68,
      labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
            fontFamily: fontFamily,
            fontSize: 12,
            fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w400,
            color: s.contains(WidgetState.selected) ? T.accent : T.muted,
          )),
      iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(color: s.contains(WidgetState.selected) ? T.accent : T.muted)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: T.card,
      hintStyle: const TextStyle(color: T.muted),
      labelStyle: const TextStyle(color: T.muted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: T.line)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: T.line)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: T.accent)),
    ),
    dividerColor: T.line,
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      // 저사양 기기: 화면 전환 애니메이션 최소화
      TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
    }),
  );
}
