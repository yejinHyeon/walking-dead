import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../core/app_state.dart';
import '../core/content.dart';
import '../core/tokens.dart';
import '../services/ocr.dart';
import '../widgets/ui.dart';
import 'first_aid_screens.dart';

enum ScanMode { med, plant, wound }

/// 목업 Scan. 카메라는 진단하지 않는다: 약은 글자를 읽어 저장된 목록과 비교, 상처는 사람이 고르게 돕고,
/// 식물은 언제나 "먹지 마세요"로만 안내한다. 사진은 기기 밖으로 나가지 않는다.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});
  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  ScanMode mode = ScanMode.med;

  Future<void> _pick(ImageSource src) async {
    final XFile? f;
    try {
      f = await ImagePicker().pickImage(source: src, maxWidth: 1600, imageQuality: 85);
    } catch (_) {
      return;
    }
    if (f == null || !mounted) return;
    final bytes = await f.readAsBytes();
    if (!mounted) return;
    final Widget next = switch (mode) {
      ScanMode.med => MedResultScreen(photo: bytes, path: f.path),
      ScanMode.plant => PlantResultScreen(photo: bytes),
      ScanMode.wound => WoundResultScreen(photo: bytes),
    };
    Navigator.push(context, MaterialPageRoute(builder: (_) => next));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final s = context.watch<AppState>();
    final hint = switch (mode) { ScanMode.med => l.scanHintMed, ScanMode.plant => l.scanHintPlant, ScanMode.wound => l.scanHintWound };
    return Scaffold(
      appBar: AppBar(title: Text(l.scanTitle)),
      body: ListView(padding: const EdgeInsets.fromLTRB(T.pad, 4, T.pad, 24), children: [
        Segments<ScanMode>(
          items: {ScanMode.med: l.scanMed, ScanMode.plant: l.scanPlant, ScanMode.wound: l.scanWound},
          value: mode,
          onChanged: (m) => setState(() => mode = m),
        ),
        gap16,
        AspectRatio(
          aspectRatio: 1,
          child: AppCard(
            onTap: () => _pick(ImageSource.camera),
            child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.photo_camera_outlined, size: 56, color: T.muted),
                gap12,
                Text(hint, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, height: 1.5)),
              ]),
            ),
          ),
        ),
        gap12,
        BigButton(label: l.scanTakePhoto, icon: Icons.photo_camera_outlined, onPressed: () => _pick(ImageSource.camera)),
        gap8,
        BigButton(label: l.scanFromGallery, icon: Icons.photo_library_outlined, primary: false, onPressed: () => _pick(ImageSource.gallery)),
        gap12,
        Row(children: [
          const Icon(Icons.lock_outline, size: 16, color: T.muted),
          const SizedBox(width: 6),
          Expanded(child: Muted(l.scanPrivacy, size: 13)),
        ]),
        if (mode == ScanMode.med && s.savedMeds.isNotEmpty) ...[
          gap16,
          SectionLabel(l.medSavedBox),
          for (final m in s.savedMeds)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppCard(
                child: Row(children: [
                  const Icon(Icons.medication_outlined, color: T.info),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(m.label, style: const TextStyle(fontWeight: FontWeight.w700)),
                      if (m.expiry != null) Muted('${l.medExpiry} ${m.expiry}', size: 13),
                    ]),
                  ),
                  IconButton(
                    tooltip: l.delete,
                    icon: const Icon(Icons.close, color: T.muted),
                    onPressed: () => (s..savedMeds.remove(m)).changed(),
                  ),
                ]),
              ),
            ),
        ],
      ]),
    );
  }
}

class _Photo extends StatelessWidget {
  final Uint8List bytes;
  const _Photo(this.bytes);
  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(T.radius),
        child: Image.memory(bytes, height: 180, width: double.infinity, fit: BoxFit.cover),
      );
}

/// 목업 MedResult
class MedResultScreen extends StatefulWidget {
  final Uint8List photo;
  final String path;
  final String? presetText; // 테스트·직접 입력용
  const MedResultScreen({super.key, required this.photo, required this.path, this.presetText});
  @override
  State<MedResultScreen> createState() => _MedResultScreenState();
}

class _MedResultScreenState extends State<MedResultScreen> {
  String? text;
  bool reading = true;
  final query = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.presetText != null) {
      text = widget.presetText;
      reading = false;
    } else {
      Ocr.read(widget.path).then((t) {
        if (mounted) {
          setState(() {
            text = t;
            reading = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final c = context.watch<Content>();
    final source = [text ?? '', query.text].join(' ');
    final matches = matchMedicines(source, c.medicines);
    final best = matches.firstOrNull;
    return AppPage(title: l.medTitle, children: [
      _Photo(widget.photo),
      gap16,
      if (reading)
        Row(children: [const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)), const SizedBox(width: 12), Text(l.scanReading)])
      else if (best == null) ...[
        Text(l.medNotFound, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        gap8,
        Muted(l.medNotFoundHelp),
        gap12,
        TextField(
          controller: query,
          decoration: InputDecoration(hintText: l.medSearchHint, prefixIcon: const Icon(Icons.search)),
          onChanged: (_) => setState(() {}),
        ),
        if ((text ?? '').trim().isNotEmpty) ...[gap16, SectionLabel(l.medRecognized), AppCard(child: Text(text!.trim()))],
        gap16,
        Muted(l.medSampleDb, size: 12),
      ] else
        ..._result(context, best),
    ]);
  }

  List<Widget> _result(BuildContext context, MedMatch m) {
    final l = context.l;
    final conf = switch (m.level) { MatchLevel.high => l.confHigh, MatchLevel.medium => l.confMedium, MatchLevel.low => l.confLow };
    final label = [m.medicine.name, if (m.strength != null) m.strength].join(' ');
    return [
      Text(label, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
      Muted(m.medicine.category),
      gap8,
      Row(children: [
        Icon(Icons.info_outline, size: 16, color: m.level == MatchLevel.high ? T.info : T.accent),
        const SizedBox(width: 6),
        Expanded(child: Text(l.medConfidence(conf), style: TextStyle(fontSize: 13, color: m.level == MatchLevel.high ? T.info : T.accent))),
      ]),
      gap16,
      SectionLabel(l.medWhatFor),
      AppCard(child: Text(m.medicine.what, style: const TextStyle(fontSize: 16, height: 1.5))),
      gap12,
      SectionLabel(l.medMustKnow, color: T.accent),
      AppCard(
        borderColor: T.accent.withValues(alpha: .5),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (final x in m.medicine.mustKnow) Padding(padding: const EdgeInsets.only(bottom: 6), child: Text('· $x', style: const TextStyle(height: 1.5))),
        ]),
      ),
      gap12,
      SectionLabel(l.medExpiry),
      AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (m.expiry != null) Text(m.expiry!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          Muted(l.medExpiryNote, size: 13),
        ]),
      ),
      gap16,
      BigButton(
        label: l.medSaveToBox,
        icon: Icons.add_box_outlined,
        onPressed: () {
          final s = context.read<AppState>();
          s.savedMeds.add(SavedMed(DateTime.now().millisecondsSinceEpoch.toString(), m.medicine.id, label, m.expiry));
          s.changed();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.saved)));
        },
      ),
      gap12,
      Muted(l.medUnsure),
      gap8,
      Muted(l.medSampleDb, size: 12),
    ];
  }
}

/// 목업 PlantResult — 식물 결과는 언제나 "먹지 마세요"
class PlantResultScreen extends StatelessWidget {
  final Uint8List photo;
  const PlantResultScreen({super.key, required this.photo});
  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return AppPage(title: l.plantTitle, children: [
      AppCard(
        highlight: true,
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.block, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.plantDontEat, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(l.plantDontEatBody, style: const TextStyle(height: 1.5)),
            ]),
          ),
        ]),
      ),
      gap16,
      _Photo(photo),
      gap16,
      AppCard(
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.wifi_off, color: T.muted),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Pill(l.needsInternet), const SizedBox(width: 6), Pill(l.comingSoon)]),
            gap8,
            Text(l.plantIdOnline, style: const TextStyle(height: 1.5)),
          ])),
        ]),
      ),
      gap16,
      WarnBox(title: l.plantIfEaten, body: l.plantIfEatenBody),
    ]);
  }
}

/// 목업 WoundResult — 사람이 상처 종류를 고르고 확인한다
class WoundResultScreen extends StatefulWidget {
  final Uint8List photo;
  const WoundResultScreen({super.key, required this.photo});
  @override
  State<WoundResultScreen> createState() => _WoundResultScreenState();
}

class _WoundResultScreenState extends State<WoundResultScreen> {
  String? picked;
  bool confirmed = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final c = context.watch<Content>();
    final w = c.wounds.where((x) => x.id == picked).firstOrNull;
    final topic = w == null ? null : c.topic(w.topic);
    return AppPage(title: l.woundTitle, children: [
      _Photo(widget.photo),
      gap16,
      if (!confirmed) ...[
        Row(children: [Pill(l.notSure, color: T.accent)]),
        gap8,
        Text(l.woundPick, style: const TextStyle(fontSize: 16, height: 1.5)),
        gap12,
        for (final x in c.wounds) ...[
          AppCard(
            borderColor: x.id == picked ? T.accent : null,
            onTap: () => setState(() => picked = x.id),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(x.t, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                  Muted(x.d, size: 13),
                ]),
              ),
              Icon(x.id == picked ? Icons.radio_button_checked : Icons.radio_button_off, color: x.id == picked ? T.accent : T.muted),
            ]),
          ),
          gap8,
        ],
        gap8,
        BigButton(label: l.woundConfirm, onPressed: picked == null ? null : () => setState(() => confirmed = true)),
      ] else if (w != null && topic != null) ...[
        Row(children: [
          Expanded(child: Text(w.t, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700))),
          TextButton(onPressed: () => setState(() => confirmed = false), child: Text(l.woundOther)),
        ]),
        gap12,
        WarnBox(title: l.woundGetHelp, body: topic.redFlags.map((f) => '· $f').join('\n')),
        gap16,
        SectionLabel(l.woundDoNow),
        StepList([for (final s in topic.steps) '${s.title}\n${s.body}']),
        BigButton(
          label: l.woundOpenGuide,
          primary: false,
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FirstAidScreen(topicId: topic.id))),
        ),
        gap12,
        Muted(l.faReview, size: 12),
      ],
    ]);
  }
}
