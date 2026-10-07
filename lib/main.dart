import 'package:flutter/material.dart';

import 'app.dart';
import 'core/app_state.dart';
import 'core/region_pack.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = await AppState.open();
  final pack = await RegionPack.load('korea');
  runApp(SurvivorApp(state: state, pack: pack));
}
