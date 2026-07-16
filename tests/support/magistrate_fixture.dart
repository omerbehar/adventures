// Shared test fixture: the canonical magistrate scene + its narration table. Not a test file
// (no `_test` suffix), so `flutter test` never executes it directly — it is imported by the
// service and UI tests that need a real, winnable scene.

import 'dart:convert';

import 'package:adventures/scene/scene_model.dart';

const String magistrateJson = r'''
{
  "schemaVersion": 1, "id": "magistrate",
  "declaredFacets": ["scandal"],
  "localMeters": { "suspicion": { "min": 0, "max": 100, "initial": 0 } },
  "narrationKeys": ["acquit", "acquitLoud", "reveal", "lockdown"],
  "entities": [ { "id": "vorne", "type": "magistrate", "props": { "hostile": {"bool": true} } } ],
  "paths": [
    { "id": "discover", "kind": "discovery", "target": "vorne", "priority": 30,
      "requirement": { "AllOf": [ {"Not": {"WorldFacet": "scandal"}}, {"AxisAtLeast": ["insight", 25]} ] },
      "effect": { "ops": [ {"RevealFacet": "scandal"} ], "narrationKey": "reveal" } },
    { "id": "persuade", "kind": "progress", "target": "vorne", "priority": 20,
      "requirement": { "AnyOf": [
        { "AllOf": [ {"WorldFacet": "scandal"}, {"Invokes": "scandal"}, {"AxisAtLeast": ["social.persuasion", 15]} ] },
        { "AxisAtLeast": ["social.persuasion", 35] } ] },
      "effect": { "ops": [ {"Outcome": "win"} ], "narrationKey": "acquit" } },
    { "id": "intimidate", "kind": "progress", "target": "vorne", "priority": 10,
      "requirement": { "AxisAtLeast": ["social.intimidation", 40] },
      "effect": { "ops": [ {"AdjustMeter": ["suspicion", 30]}, {"Outcome": "win"} ], "narrationKey": "acquitLoud" } }
  ],
  "reactiveThresholds": [
    { "id": "lockdown", "meter": "suspicion", "atLeast": 60,
      "effect": { "ops": [ {"Outcome": "lose"} ], "narrationKey": "lockdown" } } ],
  "fallbackBounds": { "touchableFacets": [], "touchableMeters": ["suspicion"], "maxMeterDelta": 10, "allowOutcome": false }
}
''';

SceneModel magistrateScene() =>
    SceneModel.fromJson((jsonDecode(magistrateJson) as Map).cast());

/// Narration table matching the fixture's keys, plus the UI's `_noMatch` line.
const Map<String, String> magistrateNarration = {
  'reveal': 'You catch it — a name the magistrate would rather stayed buried.',
  'acquit':
      'Magistrate Vorne hesitates, then signs the release. You walk free.',
  'acquitLoud':
      'Vorne flinches and signs — but the guards have noted your threat.',
  'lockdown': 'Alarms. The doors seal. There will be no walking out now.',
  '_noMatch': 'Vorne watches you, unmoved. Nothing you did lands.',
};
