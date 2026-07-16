/// Composition root (ADR-0009). Loads the frozen scene + narration table from bundled assets,
/// wires the three layers (core → service → UI), and runs the app. This is the only place the
/// asset I/O and concrete service implementations are chosen; every layer below receives its
/// collaborators by injection.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'game/translator/magnitude_tables.dart';
import 'resolver/world_state.dart';
import 'scene/scene_model.dart';
import 'screens/adventure_screen.dart';
import 'services/local_resolver_cascade.dart';
import 'services/narration_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final sceneJson = await rootBundle.loadString(
    'assets/scenes/magistrate.json',
  );
  final scene = SceneModel.fromJson((jsonDecode(sceneJson) as Map).cast());

  final narrationJson = await rootBundle.loadString('assets/narration/en.json');
  final narrationTable = (jsonDecode(narrationJson) as Map).map(
    (key, value) => MapEntry(key as String, value as String),
  );

  runApp(AdventuresApp(scene: scene, narrationTable: narrationTable));
}

/// The root widget. Builds the MVP single-encounter experience; a `go_router` navigator with
/// shareable `/play/:id` URLs is added after sign-off (ADR-0009 Decision Point 3).
class AdventuresApp extends StatelessWidget {
  const AdventuresApp({
    super.key,
    required this.scene,
    required this.narrationTable,
  });

  final SceneModel scene;
  final Map<String, String> narrationTable;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Adventures',
    theme: ThemeData(brightness: Brightness.dark, useMaterial3: true),
    home: AdventureScreen(
      cascade: LocalResolverCascade(
        tables: MagnitudeTables.defaults(),
        classId: 'default',
      ),
      narration: InMemoryNarrationRepository(narrationTable),
      initialState: WorldState.initial(scene),
      intro:
          'You stand before Magistrate Vorne. A word could free you — or damn you. '
          'What do you do?',
    ),
  );
}
