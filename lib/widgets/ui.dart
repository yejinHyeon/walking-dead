import 'package:flutter/material.dart';

import '../core/tokens.dart';
import '../l10n/app_localizations.dart';

extension Ctx on BuildContext {
  L get l => L.of(this);
  String get lang => Localizations.localeOf(this).languageCode;
}

/// 카드. [highlight]면 강조색 배경 (위 글자는 배경색).
class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool highlight;
  final Color? borderColor;
  final EdgeInsetsGeometry padding;
  const AppCard({super.key, required this.child, this.onTap, this.highlight = false, this.borderColor, this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(T.radius);
    return Material(
      color: highlight ? T.accent : T.card,
      shape: RoundedRectangleBorder(borderRadius: r, side: highlight ? BorderSide.none : BorderSide(color: borderColor ?? T.line)),
      child: InkWell(
        borderRadius: r,
        onTap: onTap,
        child: DefaultTextStyle.merge(
          style: TextStyle(color: highlight ? T.bg : T.text),
          child: IconTheme.merge(data: IconThemeData(color: highlight ? T.bg : T.text), child: Padding(padding: padding, child: child)),
        ),
      ),
    );
  }
}

class Muted extends StatelessWidget {
  final String text;
  final double size;
  const Muted(this.text, {super.key, this.size = 14});
  @override
  Widget build(BuildContext context) => Text(text, style: TextStyle(color: T.muted, fontSize: size, height: 1.5));
}

class SectionLabel extends StatelessWidget {
  final String text;
  final Color color;
  const SectionLabel(this.text, {super.key, this.color = T.muted});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        child: Text(text, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w700)),
      );
}

/// 번호 달린 단계 목록
class StepList extends StatelessWidget {
  final List<String> steps;
  const StepList(this.steps, {super.key});
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppCard(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(color: T.accent, shape: BoxShape.circle),
                    child: Text('${i + 1}', style: const TextStyle(color: T.bg, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(steps[i], style: const TextStyle(fontSize: 16, height: 1.5))),
                ]),
              ),
            ),
        ],
      );
}

/// 큰 주 버튼 (52~56px)
class BigButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool primary;
  const BigButton({super.key, required this.label, this.icon, this.onPressed, this.primary = true});
  @override
  Widget build(BuildContext context) {
    final label = Theme.of(context).textTheme.labelLarge!.copyWith(fontSize: 16, fontWeight: FontWeight.w700);
    final style = primary
        ? FilledButton.styleFrom(backgroundColor: T.accent, foregroundColor: T.bg, minimumSize: const Size.fromHeight(T.mainButton),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), textStyle: label)
        : FilledButton.styleFrom(backgroundColor: T.card, foregroundColor: T.text, minimumSize: const Size.fromHeight(T.mainButton),
            side: const BorderSide(color: T.line), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            textStyle: label);
    return icon == null
        ? FilledButton(style: style, onPressed: onPressed, child: Text(this.label, textAlign: TextAlign.center))
        : FilledButton.icon(style: style, onPressed: onPressed, icon: Icon(icon), label: Text(this.label));
  }
}

/// 둥근 세그먼트 선택 (목업의 탭 버튼)
class Segments<K> extends StatelessWidget {
  final Map<K, String> items;
  final K value;
  final ValueChanged<K> onChanged;
  const Segments({super.key, required this.items, required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: T.card, borderRadius: BorderRadius.circular(24), border: Border.all(color: T.line)),
        child: Row(children: [
          for (final e in items.entries)
            Expanded(
              child: Semantics(
                selected: e.key == value,
                button: true,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => onChanged(e.key),
                  child: Container(
                    height: T.minTouch,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: e.key == value ? T.text : Colors.transparent, borderRadius: BorderRadius.circular(20)),
                    child: Text(e.value,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: e.key == value ? T.bg : T.muted)),
                  ),
                ),
              ),
            ),
        ]),
      );
}

/// − 값 + 조절기
class Stepper2 extends StatelessWidget {
  final String value;
  final VoidCallback onMinus, onPlus;
  final String? label;
  const Stepper2({super.key, required this.value, required this.onMinus, required this.onPlus, this.label});
  @override
  Widget build(BuildContext context) {
    Widget btn(IconData i, VoidCallback f, String tip) => SizedBox(
          width: T.minTouch,
          height: T.minTouch,
          child: IconButton.outlined(
            tooltip: tip,
            onPressed: f,
            icon: Icon(i, size: 20),
            style: IconButton.styleFrom(side: const BorderSide(color: T.line)),
          ),
        );
    return Row(mainAxisSize: MainAxisSize.min, children: [
      btn(Icons.remove, onMinus, '−'),
      SizedBox(
          width: 64,
          child: Text(value, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
      btn(Icons.add, onPlus, '+'),
    ]);
  }
}

class Pill extends StatelessWidget {
  final String text;
  final Color color;
  const Pill(this.text, {super.key, this.color = T.muted});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(border: Border.all(color: color.withValues(alpha: .6)), borderRadius: BorderRadius.circular(999)),
        child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
      );
}

/// 경고 박스 (강조색 테두리)
class WarnBox extends StatelessWidget {
  final String title;
  final String body;
  final IconData icon;
  const WarnBox({super.key, required this.title, required this.body, this.icon = Icons.warning_amber_rounded});
  @override
  Widget build(BuildContext context) => AppCard(
        borderColor: T.accent,
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: T.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(color: T.accent, fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 4),
              Text(body, style: const TextStyle(height: 1.5)),
            ]),
          ),
        ]),
      );
}

/// 화면 공통 틀: 뒤로 + 제목 + 스크롤 본문
class AppPage extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final Widget? bottom;
  final List<Widget>? actions;
  const AppPage({super.key, required this.title, required this.children, this.bottom, this.actions});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title), actions: actions),
        body: SafeArea(
          top: false,
          child: ListView(padding: const EdgeInsets.fromLTRB(T.pad, 8, T.pad, 32), children: children),
        ),
        bottomNavigationBar: bottom == null ? null : SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(T.pad, 8, T.pad, 12), child: bottom)),
      );
}

const gap8 = SizedBox(height: 8);
const gap12 = SizedBox(height: 12);
const gap16 = SizedBox(height: 16);
const gap24 = SizedBox(height: 24);

/// 8방위 이름 (0=북)
String dirName(L l, int i) => [l.dirN, l.dirNE, l.dirE, l.dirSE, l.dirS, l.dirSW, l.dirW, l.dirNW][i % 8];
