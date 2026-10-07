import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';

import '../app.dart';
import '../core/content.dart';
import '../core/tokens.dart';
import '../widgets/ui.dart';

class FirstAidListScreen extends StatefulWidget {
  const FirstAidListScreen({super.key});
  @override
  State<FirstAidListScreen> createState() => _FirstAidListScreenState();
}

class _FirstAidListScreenState extends State<FirstAidListScreen> {
  String q = '';

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final c = context.watch<Content>();
    final list = c.topics.where((t) => q.isEmpty || t.matches(q)).toList();
    return Scaffold(
      appBar: AppBar(title: Text(l.faTitle)),
      body: ListView(padding: const EdgeInsets.fromLTRB(T.pad, 4, T.pad, 24), children: [
        TextField(
          decoration: InputDecoration(hintText: l.faSearch, prefixIcon: const Icon(Icons.search)),
          onChanged: (v) => setState(() => q = v.trim()),
        ),
        gap12,
        AppCard(
          onTap: () => context.read<Shell>().go(Shell.scan),
          child: Row(children: [
            const Icon(Icons.photo_camera_outlined, color: T.info),
            const SizedBox(width: 12),
            Expanded(child: Text(l.faCameraCheck, style: const TextStyle(color: T.info, fontWeight: FontWeight.w700))),
          ]),
        ),
        gap12,
        for (final t in list) ...[
          AppCard(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FirstAidScreen(topicId: t.id))),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(t.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                  Muted(t.summary),
                ]),
              ),
              const Icon(Icons.chevron_right, color: T.muted),
            ]),
          ),
          gap8,
        ],
      ]),
    );
  }
}

/// 한 화면에 한 단계씩 (목업 FirstAid)
class FirstAidScreen extends StatefulWidget {
  final String topicId;
  const FirstAidScreen({super.key, required this.topicId});
  @override
  State<FirstAidScreen> createState() => _FirstAidScreenState();
}

class _FirstAidScreenState extends State<FirstAidScreen> {
  int i = 0;
  final tts = FlutterTts();
  bool speaking = false;

  @override
  void dispose() {
    _stopTts();
    super.dispose();
  }

  // 음성 엔진이 없는 기기에서도 화면이 멈추지 않게 오류는 무시
  void _stopTts() => tts.stop().catchError((_) => null);

  Future<void> _speak(AidStep s) async {
    if (speaking) {
      _stopTts();
      setState(() => speaking = false);
      return;
    }
    try {
      // 기기에 설치된 음성 엔진 사용 (오프라인 음성이 없으면 소리가 나지 않을 수 있음)
      await tts.setLanguage(context.lang == 'ko' ? 'ko-KR' : 'en-US');
      tts.setCompletionHandler(() {
        if (mounted) setState(() => speaking = false);
      });
      setState(() => speaking = true);
      await tts.speak('${s.title}. ${s.body}');
    } catch (_) {
      if (mounted) setState(() => speaking = false);
    }
  }

  void _go(int to) {
    _stopTts();
    setState(() {
      speaking = false;
      i = to;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final c = context.watch<Content>();
    final t = c.topic(widget.topicId)!;
    final n = t.steps.length;
    final s = t.steps[i];
    return Scaffold(
      appBar: AppBar(title: Text(l.faTitle)),
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.fromLTRB(T.pad, 4, T.pad, 24), children: [
          Text(t.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
          gap12,
          Row(children: [
            for (var k = 0; k < n; k++)
              Expanded(
                child: Container(
                  height: 6,
                  margin: EdgeInsetsDirectional.only(end: k < n - 1 ? 4 : 0),
                  decoration: BoxDecoration(color: k <= i ? T.accent : T.line, borderRadius: BorderRadius.circular(3)),
                ),
              ),
          ]),
          gap8,
          Row(children: [
            Expanded(child: Muted(l.faStepCounter(i + 1, n))),
            TextButton.icon(
              onPressed: () => _speak(s),
              icon: Icon(speaking ? Icons.stop_circle_outlined : Icons.volume_up_outlined),
              label: Text(speaking ? l.faStop : l.faListen),
            ),
          ]),
          gap8,
          Text(s.title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, height: 1.3)),
          gap12,
          Text(s.body, style: const TextStyle(fontSize: 18, height: 1.6)),
          gap24,
          if (t.redFlags.isNotEmpty) WarnBox(title: l.woundGetHelp, body: t.redFlags.map((f) => '· $f').join('\n')),
          gap16,
          Muted(l.faSources(t.sources.map((k) => c.aidSources[k] ?? k).join(' / ')), size: 12),
          Muted(l.faReview, size: 12),
        ]),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(T.pad, 8, T.pad, 12),
          child: Row(children: [
            Expanded(child: BigButton(label: l.faPrev, primary: false, onPressed: i == 0 ? null : () => _go(i - 1))),
            const SizedBox(width: 12),
            Expanded(flex: 2, child: BigButton(label: i == n - 1 ? l.faRestart : l.faNext, onPressed: () => _go(i == n - 1 ? 0 : i + 1))),
          ]),
        ),
      ),
    );
  }
}
