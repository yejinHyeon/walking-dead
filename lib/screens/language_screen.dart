import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_state.dart';
import '../core/tokens.dart';
import '../widgets/ui.dart';

class _Lang {
  final String id, native;
  final bool rtl, ready, rtlPreview;
  const _Lang(this.id, this.native, {this.rtl = false, this.ready = false, this.rtlPreview = false});
}

// ready: 번역과 오프라인 콘텐츠가 모두 있음. rtlPreview: 번역 없이 RTL 레이아웃만 확인용 (영어 문구).
const _langs = [
  _Lang('ko', '한국어', ready: true),
  _Lang('en', 'English', ready: true),
  _Lang('uk', 'Українська'),
  _Lang('ru', 'Русский'),
  _Lang('ar', 'العربية', rtl: true, rtlPreview: true),
  _Lang('fa', 'فارسی', rtl: true),
  _Lang('he', 'עברית', rtl: true),
];

class LanguageScreen extends StatefulWidget {
  final bool firstRun;
  const LanguageScreen({super.key, this.firstRun = false});
  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  late String picked = context.read<AppState>().languageCode ?? Localizations.localeOf(context).languageCode;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return Scaffold(
      appBar: widget.firstRun ? null : AppBar(),
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.fromLTRB(T.pad, 32, T.pad, 24), children: [
          const Text('언어를 선택하세요', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
          const Muted('Choose your language'),
          gap16,
          for (final x in _langs) ...[
            _tile(x, l.langReady, l.langPending, l.langRtlPreview),
            gap8,
          ],
        ]),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(T.pad, 8, T.pad, 12),
          child: BigButton(
            label: picked == 'ko' ? '계속하기' : 'Continue',
            onPressed: () {
              context.read<AppState>().setLanguage(picked);
              if (!widget.firstRun) Navigator.pop(context);
            },
          ),
        ),
      ),
    );
  }

  Widget _tile(_Lang x, String ready, String pending, String rtlPreview) {
    final on = x.id == picked;
    final enabled = x.ready || x.rtlPreview;
    final status = x.ready ? ready : (x.rtlPreview ? rtlPreview : pending);
    return Opacity(
      opacity: enabled ? 1 : .5,
      child: AppCard(
        borderColor: on ? T.accent : null,
        onTap: enabled ? () => setState(() => picked = x.id) : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(x.native, textDirection: x.rtl ? TextDirection.rtl : TextDirection.ltr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              Muted(status, size: 12),
            ]),
          ),
          Icon(on ? Icons.radio_button_checked : Icons.radio_button_off, color: on ? T.accent : T.muted),
        ]),
      ),
    );
  }
}
