import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_state.dart';
import '../core/content.dart';
import '../core/geo.dart';
import '../core/region_pack.dart';
import '../core/tokens.dart';
import '../services/location.dart';
import '../services/signals.dart';
import '../widgets/ui.dart';

// ---------------------------------------------------------------- SOS
enum Sig { torch, alarm, screen, vibrate }

/// 목업 Sos. 위치는 화면에만 보여주고 어디에도 보내지 않는다.
class SosScreen extends StatefulWidget {
  const SosScreen({super.key});
  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> {
  LatLng2? me;
  bool locating = true;
  Sig? on;
  bool torchOk = true;

  @override
  void initState() {
    super.initState();
    LocationService.current().then((p) {
      if (mounted) {
        setState(() {
          me = p;
          locating = false;
        });
      }
    });
    Signals.torchAvailable().then((ok) {
      if (mounted) setState(() => torchOk = ok);
    });
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  void _stop() {
    Signals.stopTorch();
    Signals.stopAlarm();
    Signals.stopVibration();
  }

  Future<void> _toggle(Sig s) async {
    final wasOn = on == s;
    _stop();
    setState(() => on = wasOn ? null : s);
    if (wasOn) return;
    switch (s) {
      case Sig.torch:
        Signals.startTorch();
      case Sig.alarm:
        Signals.startAlarm();
      case Sig.vibrate:
        Signals.startVibration();
      case Sig.screen:
        await Navigator.push(context, MaterialPageRoute(fullscreenDialog: true, builder: (_) => const _FlashScreen()));
        if (mounted) setState(() => on = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l, lang = context.lang;
    final pack = context.read<RegionPack>();
    final labels = {Sig.torch: l.sosTorch, Sig.alarm: l.sosAlarm, Sig.screen: l.sosScreen, Sig.vibrate: l.sosVibrate};
    final icons = {Sig.torch: Icons.flashlight_on_outlined, Sig.alarm: Icons.campaign_outlined, Sig.screen: Icons.light_mode_outlined, Sig.vibrate: Icons.vibration};
    return AppPage(title: l.sosTitle, children: [
      AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Muted(l.sosMyLocation, size: 13),
          gap8,
          if (me == null)
            Text(locating ? l.sosNoFix : l.locationFallback, style: const TextStyle(fontSize: 16))
          else
            SelectableText('${me!.lat.toStringAsFixed(5)}, ${me!.lng.toStringAsFixed(5)}',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, fontFeatures: [FontFeature.tabularFigures()])),
          gap8,
          Muted(l.sosReadOut, size: 13),
        ]),
      ),
      gap16,
      SectionLabel(l.sosSignals),
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.25,
        children: [
          for (final s in Sig.values)
            Opacity(
              opacity: s == Sig.torch && !torchOk ? .5 : 1,
              child: AppCard(
                highlight: on == s,
                onTap: s == Sig.torch && !torchOk ? null : () => _toggle(s),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Icon(icons[s]),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(labels[s]!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    Text(s == Sig.torch && !torchOk ? l.torchUnavailable : (on == s ? l.sosOn : l.sosOff),
                        maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: on == s ? T.bg : T.muted)),
                  ]),
                ]),
              ),
            ),
        ],
      ),
      gap12,
      Muted(l.sosPattern, size: 13),
      gap16,
      WarnBox(title: l.sosCheckFirst, body: l.sosCheckFirstBody),
      gap16,
      SectionLabel(l.emergencyNumbers),
      for (final n in pack.numbers)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: AppCard(
            onTap: () => launchUrl(Uri(scheme: 'tel', path: n.number)),
            child: Row(children: [
              Text(n.number, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(width: 12),
              Expanded(child: Muted(tr(n.label, lang))),
              const Icon(Icons.call_outlined, color: T.info),
            ]),
          ),
        ),
    ]);
  }
}

class _FlashScreen extends StatefulWidget {
  const _FlashScreen();
  @override
  State<_FlashScreen> createState() => _FlashScreenState();
}

class _FlashScreenState extends State<_FlashScreen> {
  bool lit = false;
  late final MorseRunner runner = MorseRunner((v) {
    if (mounted) setState(() => lit = v);
  });

  @override
  void initState() {
    super.initState();
    runner.start();
  }

  @override
  void dispose() {
    runner.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          color: lit ? Colors.white : Colors.black,
          alignment: Alignment.bottomCenter,
          padding: const EdgeInsets.all(32),
          child: SafeArea(
            child: Text(context.l.sosOn, style: TextStyle(color: lit ? Colors.black54 : Colors.white54, fontSize: 16, decoration: TextDecoration.none)),
          ),
        ),
      );
}

// ---------------------------------------------------------------- 가족
/// 목업 Family. QR은 기기끼리 화면으로만 전달 (인터넷 불필요).
class FamilyScreen extends StatefulWidget {
  const FamilyScreen({super.key});
  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  bool showQr = false;

  Widget _field(String label, String value, ValueChanged<String> onChanged) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: TextFormField(initialValue: value, decoration: InputDecoration(labelText: label), onChanged: onChanged),
      );

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final s = context.watch<AppState>();
    final qrData = jsonEncode({'v': 1, 'm1': s.meet1.toJson(), 'm2': s.meet2.toJson(), 'f': s.members.map((m) => m.toJson()).toList()});
    return AppPage(title: l.familyTitle, children: [
      SectionLabel(l.meet1, color: T.accent),
      _field(l.placeName, s.meet1.name, (v) => (s..meet1.name = v).changed()),
      _field(l.placeHow, s.meet1.how, (v) => (s..meet1.how = v).changed()),
      gap8,
      SectionLabel(l.meet2),
      _field(l.placeName, s.meet2.name, (v) => (s..meet2.name = v).changed()),
      _field(l.placeHow, s.meet2.how, (v) => (s..meet2.how = v).changed()),
      gap8,
      SectionLabel(l.familyMembers),
      for (var i = 0; i < s.members.length; i++) ...[
        AppCard(
          // 삭제 후에도 입력 칸이 다른 사람과 섞이지 않게 사람마다 고정 키
          key: ObjectKey(s.members[i]),
          child: Column(children: [
            Row(children: [
              CircleAvatar(radius: 14, backgroundColor: T.line, child: Text('${i + 1}', style: const TextStyle(fontSize: 13, color: T.text))),
              const Spacer(),
              IconButton(tooltip: l.delete, icon: const Icon(Icons.close, color: T.muted), onPressed: () => (s..members.removeAt(i)).changed()),
            ]),
            _field(l.memberName, s.members[i].name, (v) => (s..members[i].name = v).changed()),
            _field(l.memberContact, s.members[i].contact, (v) => (s..members[i].contact = v).changed()),
            Row(children: [
              Expanded(child: _field(l.memberBlood, s.members[i].blood, (v) => (s..members[i].blood = v).changed())),
              const SizedBox(width: 8),
              Expanded(child: _field(l.memberAllergy, s.members[i].allergy, (v) => (s..members[i].allergy = v).changed())),
            ]),
            _field(l.memberMeds, s.members[i].meds, (v) => (s..members[i].meds = v).changed()),
          ]),
        ),
        gap8,
      ],
      BigButton(label: l.addMember, icon: Icons.person_add_alt, primary: false, onPressed: () => (s..members.add(Member())).changed()),
      gap16,
      BigButton(label: l.familyQr, icon: Icons.qr_code_2, onPressed: () => setState(() => showQr = !showQr)),
      if (showQr) ...[
        gap12,
        Center(
          child: Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: QrImageView(data: qrData, size: 240, backgroundColor: Colors.white),
          ),
        ),
        gap8,
        Muted(l.familyQrHelp, size: 13),
      ],
      gap16,
      TextButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KitScreen())),
        child: Text(l.prepareKit),
      ),
    ]);
  }
}

// ---------------------------------------------------------------- 비상 배낭
class KitScreen extends StatelessWidget {
  const KitScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final s = context.watch<AppState>();
    final items = context.watch<Content>().kit;
    final done = items.where((x) => s.kitDone.contains(x.id)).length;
    return AppPage(title: l.kitTitle, children: [
      Text(l.kitProgress(done, items.length), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      gap8,
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(value: items.isEmpty ? 0 : done / items.length, minHeight: 8, color: T.accent, backgroundColor: T.line),
      ),
      gap16,
      for (final x in items) ...[
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: T.accent,
            checkColor: T.bg,
            value: s.kitDone.contains(x.id),
            onChanged: (v) {
              v == true ? s.kitDone.add(x.id) : s.kitDone.remove(x.id);
              s.changed();
            },
            title: Text(x.t, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: x.d.isEmpty ? null : Text(x.d, style: const TextStyle(color: T.muted)),
          ),
        ),
        gap8,
      ],
    ]);
  }
}

// ---------------------------------------------------------------- 불발탄
class UxoScreen extends StatelessWidget {
  const UxoScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final u = context.watch<Content>().uxo;
    final rules = List<Map<String, dynamic>>.from(u['rules']);
    final src = Map<String, String>.from(u['meta']['sources']).values.join(' / ');
    return AppPage(title: l.uxoTitle, children: [
      Muted(u['head']),
      gap8,
      AppCard(
        highlight: true,
        child: Row(children: [
          const Icon(Icons.do_not_touch_outlined, size: 36),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(u['big'], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
            Text(u['sub'], style: const TextStyle(height: 1.5)),
          ])),
        ]),
      ),
      gap16,
      for (var i = 0; i < rules.length; i++) ...[
        AppCard(
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: T.accent, shape: BoxShape.circle),
              child: Text('${i + 1}', style: const TextStyle(color: T.bg, fontWeight: FontWeight.w700, fontSize: 16)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(rules[i]['t'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              Text(rules[i]['d'], style: const TextStyle(height: 1.5)),
            ])),
          ]),
        ),
        gap8,
      ],
      gap8,
      SectionLabel(l.uxoWatch, color: T.accent),
      for (final w in List<String>.from(u['watch']))
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: AppCard(child: Row(children: [
            const Icon(Icons.warning_amber_rounded, color: T.accent),
            const SizedBox(width: 12),
            Expanded(child: Text(w, style: const TextStyle(fontSize: 16))),
          ])),
        ),
      for (final e in List<String>.from(u['extra'])) Padding(padding: const EdgeInsets.only(top: 4), child: Muted('· $e')),
      gap16,
      Muted(l.faSources(src), size: 12),
      Muted(l.faReview, size: 12),
    ]);
  }
}
