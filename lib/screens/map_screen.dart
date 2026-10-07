import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../app.dart';
import '../core/geo.dart';
import '../core/region_pack.dart';
import '../core/tokens.dart';
import '../services/location.dart';
import '../widgets/ui.dart';
import 'home_screen.dart' show distanceLine;

IconData placeIcon(PlaceType t) => switch (t) {
      PlaceType.shelter => Icons.shield_outlined,
      PlaceType.aid => Icons.inventory_2_outlined,
      PlaceType.water => Icons.water_drop_outlined,
      PlaceType.medical => Icons.local_hospital_outlined,
    };

LatLng _ll(LatLng2 p) => LatLng(p.lat, p.lng);

/// 목업 Map. 지도 그림(타일)은 지역팩으로 내려받는 구조이며, 서버에 위치를 묻지 않는다.
/// 타일이 없어도 장소·거리·방향은 오프라인으로 작동한다.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final map = MapController();
  LatLng2? me;
  Place? selected;

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
    final shell = context.watch<Shell>();
    final origin = me ?? pack.center;
    final places = pack.places.where((p) => p.type == shell.mapFilter).toList()
      ..sort((a, b) => distanceMeters(origin, a.pos).compareTo(distanceMeters(origin, b.pos)));
    final sel = selected != null && selected!.type == shell.mapFilter ? selected! : places.firstOrNull;
    final chips = {
      PlaceType.shelter: l.chipShelters,
      PlaceType.aid: l.chipAid,
      PlaceType.water: l.chipWater,
      PlaceType.medical: l.chipMedical,
    };

    return Scaffold(
      appBar: AppBar(title: Text(l.mapTitle)),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(T.pad, 0, T.pad, 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Muted(l.mapArea(tr(pack.area, lang), pack.savedDate), size: 13),
            Muted(l.mapNoTiles, size: 12),
          ]),
        ),
        SizedBox(
          height: T.minTouch,
          child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: T.pad), children: [
            for (final e in chips.entries)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: ChoiceChip(
                  avatar: Icon(placeIcon(e.key), size: 18, color: shell.mapFilter == e.key ? T.bg : T.text),
                  label: Text(e.value),
                  selected: shell.mapFilter == e.key,
                  showCheckmark: false,
                  selectedColor: T.text,
                  labelStyle: TextStyle(color: shell.mapFilter == e.key ? T.bg : T.text, fontWeight: FontWeight.w700),
                  onSelected: (_) => setState(() {
                    selected = null;
                    shell.go(Shell.map, filter: e.key);
                  }),
                ),
              ),
          ]),
        ),
        gap8,
        Expanded(
          child: Stack(children: [
            FlutterMap(
              mapController: map,
              options: MapOptions(
                initialCenter: _ll(origin),
                initialZoom: 15,
                backgroundColor: const Color(0xFF16191C),
                interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
              ),
              children: [
                // 오프라인 타일 레이어는 지역팩 타일이 준비되면 여기에 추가 (PMTiles 등). 온라인 타일은 쓰지 않는다.
                CircleLayer(circles: [
                  for (final z in pack.dangerZones)
                    CircleMarker(
                      point: _ll(z.center),
                      radius: z.radiusM,
                      useRadiusInMeter: true,
                      color: T.accent.withValues(alpha: .18),
                      borderColor: T.accent,
                      borderStrokeWidth: 2,
                    ),
                ]),
                MarkerLayer(markers: [
                  for (final z in pack.dangerZones)
                    Marker(
                      point: _ll(z.center),
                      width: 140,
                      height: 30,
                      child: Center(child: Pill(tr(z.label, lang), color: T.accent)),
                    ),
                  for (final p in places)
                    Marker(
                      point: _ll(p.pos),
                      width: 48,
                      height: 48,
                      child: Semantics(
                        button: true,
                        label: tr(p.name, lang),
                        child: GestureDetector(
                          onTap: () => setState(() => selected = p),
                          child: Container(
                            decoration: BoxDecoration(
                              color: p == sel ? T.info : T.card,
                              shape: BoxShape.circle,
                              border: Border.all(color: T.info, width: 2),
                            ),
                            child: Icon(placeIcon(p.type), color: p == sel ? T.bg : T.info, size: 22),
                          ),
                        ),
                      ),
                    ),
                  Marker(
                    point: _ll(origin),
                    width: 24,
                    height: 24,
                    child: Container(
                      decoration: BoxDecoration(
                        color: me == null ? T.muted : T.text,
                        shape: BoxShape.circle,
                        border: Border.all(color: T.bg, width: 4),
                      ),
                    ),
                  ),
                ]),
              ],
            ),
            PositionedDirectional(
              bottom: 12,
              end: 12,
              child: FloatingActionButton.small(
                heroTag: 'recenter',
                backgroundColor: T.card,
                tooltip: l.locationFromGps,
                onPressed: () async {
                  final p = await LocationService.current();
                  if (p != null) setState(() => me = p);
                  map.move(_ll(p ?? origin), 15);
                },
                child: const Icon(Icons.my_location, color: T.text),
              ),
            ),
          ]),
        ),
        if (sel != null) _PlaceCard(place: sel, origin: origin, sample: pack.sample, gps: me != null),
      ]),
    );
  }
}

class _PlaceCard extends StatelessWidget {
  final Place place;
  final LatLng2 origin;
  final bool sample, gps;
  const _PlaceCard({required this.place, required this.origin, required this.sample, required this.gps});

  @override
  Widget build(BuildContext context) {
    final l = context.l, lang = context.lang;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(T.pad, 14, T.pad, 12),
      decoration: const BoxDecoration(color: T.bg, border: Border(top: BorderSide(color: T.line))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          Expanded(child: Text(tr(place.kind, lang), style: const TextStyle(color: T.info, fontSize: 13, fontWeight: FontWeight.w700))),
          if (sample) Pill(l.sampleData, color: T.accent),
        ]),
        const SizedBox(height: 2),
        Text(tr(place.name, lang), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        Muted(distanceLine(context, origin, place.pos)),
        Muted('${l.source}: ${tr(place.source, lang)} · ${l.verified(place.verified)}', size: 12),
        if (!gps) Muted(l.locationFallback, size: 12),
        gap8,
        BigButton(
          label: l.compassGuide,
          icon: Icons.explore_outlined,
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CompassScreen(target: place))),
        ),
      ]),
    );
  }
}

/// 나침반 길 안내: 기기 나침반 + GPS만 사용 (인터넷·지도 불필요)
class CompassScreen extends StatefulWidget {
  final Place target;
  const CompassScreen({super.key, required this.target});
  @override
  State<CompassScreen> createState() => _CompassScreenState();
}

class _CompassScreenState extends State<CompassScreen> {
  double? heading;
  LatLng2? me;
  StreamSubscription? _c;
  Timer? _gps;

  @override
  void initState() {
    super.initState();
    try {
      _c = FlutterCompass.events?.listen((e) {
        if (mounted) setState(() => heading = e.heading);
      }, onError: (_) {}); // 센서·플러그인이 없으면 방향 글자 안내로 대체
    } catch (_) {
      // 나침반 센서 없음
    }
    _poll();
    _gps = Timer.periodic(const Duration(seconds: 5), (_) => _poll());
  }

  Future<void> _poll() async {
    final p = await LocationService.current();
    if (mounted && p != null) setState(() => me = p);
  }

  @override
  void dispose() {
    _c?.cancel();
    _gps?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l, lang = context.lang;
    final pack = context.read<RegionPack>();
    final from = me ?? pack.center;
    final bearing = bearingDegrees(from, widget.target.pos);
    final dist = distanceMeters(from, widget.target.pos);
    final dir = dirName(l, compassIndex(bearing));
    final h = heading;
    return AppPage(title: l.compassTitle, children: [
      Text(tr(widget.target.name, lang), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
      Muted(distanceLine(context, from, widget.target.pos)),
      if (me == null) Muted(l.locationFallback, size: 12),
      gap24,
      Center(
        child: SizedBox(
          width: 240,
          height: 240,
          child: Container(
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: T.line, width: 2)),
            child: h == null
                ? Center(child: Icon(Icons.explore_off_outlined, size: 64, color: T.muted))
                : Transform.rotate(
                    angle: (bearing - h) * pi / 180,
                    child: const Icon(Icons.navigation, size: 140, color: T.accent),
                  ),
          ),
        ),
      ),
      gap24,
      if (dist < 30)
        Center(child: Text(l.compassArrived, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: T.info)))
      else
        Center(child: Text(h == null ? l.compassUnavailable(dir) : l.compassHint, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16))),
    ]);
  }
}
