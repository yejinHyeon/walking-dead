import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app.dart';
import '../core/constants.dart';
import '../core/geo.dart';
import '../core/region_pack.dart';
import '../core/tokens.dart';
import '../services/location.dart';
import '../widgets/ui.dart';
import 'language_screen.dart';
import 'plan_screens.dart';
import 'supplies_screens.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  LatLng2? me;

  @override
  void initState() {
    super.initState();
    LocationService.current().then((p) {
      if (mounted && p != null) setState(() => me = p);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l, lang = context.lang;
    final pack = context.read<RegionPack>();
    final shell = context.read<Shell>();
    final origin = me ?? pack.center;
    final shelters = pack.places.where((p) => p.type == PlaceType.shelter).toList()
      ..sort((a, b) => distanceMeters(origin, a.pos).compareTo(distanceMeters(origin, b.pos)));
    final nearest = shelters.firstOrNull;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(T.pad, 16, T.pad, 24),
        children: [
          Row(children: [
            Container(width: 8, height: 8, decoration: const BoxDecoration(color: T.info, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Expanded(child: Muted(l.homeStatus(tr(pack.name, lang)), size: 13)),
            _PillButton(
              label: 'SOS',
              semantics: l.sosAria,
              accent: true,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SosScreen())),
            ),
            const SizedBox(width: 8),
            _PillButton(
              icon: Icons.language,
              label: lang.toUpperCase(),
              semantics: l.langAria,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LanguageScreen())),
            ),
          ]),
          gap16,
          Text(l.homeTitle, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, height: 1.3)),
          const SizedBox(height: 4),
          Muted(l.homeSub),
          gap16,
          AppCard(
            highlight: true,
            padding: const EdgeInsets.all(20),
            onTap: () => shell.go(Shell.firstAid),
            child: Row(children: [
              const Icon(Icons.medical_services_outlined, size: 40),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(l.navFirstAid, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                  Text(l.homeFirstAidSub, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                ]),
              ),
            ]),
          ),
          gap12,
          AppCard(
            borderColor: T.info.withValues(alpha: .5),
            onTap: () => shell.go(Shell.map, filter: PlaceType.shelter),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.shield_outlined, color: T.info, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(l.homeNearestShelter, style: const TextStyle(color: T.info, fontWeight: FontWeight.w700))),
                Text(l.homeOpenMap, style: const TextStyle(color: T.info, fontSize: 14)),
              ]),
              gap8,
              if (nearest == null)
                Muted(l.homeNoShelter)
              else ...[
                Text(tr(nearest.name, lang), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Muted(_distText(context, origin, nearest.pos)),
                if (pack.sample) ...[gap8, Pill(l.sampleData, color: T.accent)],
              ],
              const SizedBox(height: 4),
              Muted(me == null ? l.locationFallback : l.locationFromGps, size: 12),
            ]),
          ),
          gap12,
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: [
              _Tile(Icons.water_drop_outlined, l.homeAidTitle, l.homeAidSub, () => shell.go(Shell.map, filter: PlaceType.aid)),
              _Tile(Icons.dangerous_outlined, l.homeUxoTitle, l.homeUxoSub, () => _push(context, const UxoScreen()), warn: true),
              _Tile(Icons.local_hospital_outlined, l.homeMedTitle, l.homeMedSub, () => shell.go(Shell.map, filter: PlaceType.medical)),
              _Tile(Icons.groups_outlined, l.homeFamilyTitle, l.homeFamilySub, () => _push(context, const FamilyScreen())),
              _Tile(Icons.local_drink_outlined, l.homeWaterTitle, l.homeWaterSub, () => _push(context, const WaterScreen())),
              _Tile(Icons.backpack_outlined, l.homeKitTitle, l.homeKitSub, () => _push(context, const KitScreen())),
            ],
          ),
        ],
      ),
    );
  }

  static void _push(BuildContext c, Widget w) => Navigator.push(c, MaterialPageRoute(builder: (_) => w));
}

String _distText(BuildContext context, LatLng2 from, LatLng2 to) {
  final d = distanceMeters(from, to);
  final l = context.l;
  return '${l.walkDistance((d / walkingMetersPerMinute).ceil(), formatDistance(d))} · ${dirName(l, compassIndex(bearingDegrees(from, to)))}';
}

String distanceLine(BuildContext context, LatLng2 from, LatLng2 to) => _distText(context, from, to);

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title, sub;
  final VoidCallback onTap;
  final bool warn;
  const _Tile(this.icon, this.title, this.sub, this.onTap, {this.warn = false});
  @override
  Widget build(BuildContext context) => AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Icon(icon, color: warn ? T.accent : T.text),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, height: 1.3)),
            Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: T.muted)),
          ]),
        ]),
      );
}

class _PillButton extends StatelessWidget {
  final String label, semantics;
  final IconData? icon;
  final bool accent;
  final VoidCallback onTap;
  const _PillButton({required this.label, required this.semantics, required this.onTap, this.icon, this.accent = false});
  @override
  Widget build(BuildContext context) => Semantics(
        label: semantics,
        button: true,
        child: Material(
          color: accent ? T.accentDark : T.card,
          shape: StadiumBorder(side: BorderSide(color: accent ? T.accent : T.line)),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onTap,
            child: Container(
              height: T.minTouch,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                if (icon != null) ...[Icon(icon, size: 18, color: T.text), const SizedBox(width: 6)],
                Text(label, style: TextStyle(color: accent ? T.accent : T.text, fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
        ),
      );
}
