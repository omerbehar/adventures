// resolver_determinism_test — the core MVP property (ADR-0006 validation criterion #1):
// the same (WorldState, CapabilityVector) resolves to an identical ResolveResult every run.
// No clocks, no unseeded randomness (ADR-0006). Pure-Dart, no I/O.
library;

import 'dart:convert';

import 'package:adventures/game/capability_vector.dart';
import 'package:adventures/game/ontology.dart';
import 'package:adventures/game/state_delta.dart';
import 'package:adventures/resolver/resolver.dart';
import 'package:adventures/resolver/world_state.dart';
import 'package:adventures/scene/scene_model.dart';
import 'package:flutter_test/flutter_test.dart';

const String magistrateJson = r'''
{
  "schemaVersion": 1, "id": "magistrate",
  "declaredFacets": ["scandal"],
  "localMeters": { "suspicion": { "min": 0, "max": 100, "initial": 0 } },
  "narrationKeys": ["acquit", "acquitLoud", "reveal", "lockdown", "nudge"],
  "entities": [ { "id": "vorne", "type": "magistrate",
    "props": { "hostile": {"bool": true} } } ],
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

SceneModel magistrate() =>
    SceneModel.fromJson((jsonDecode(magistrateJson) as Map).cast());

/// A total, order-independent projection of a ResolveResult — enough to detect any
/// nondeterminism (outcome, matched path, fired narration, and settled state).
String project(ResolveResult r) {
  switch (r) {
    case NoMatch():
      return 'NoMatch';
    case Resolved(
      :final outcome,
      :final matchedPathId,
      :final firedDeltas,
      :final nextState,
    ):
      final meters =
          (nextState.meters.entries.toList()
                ..sort((a, b) => a.key.compareTo(b.key)))
              .map((e) => '${e.key}=${e.value}')
              .join(',');
      final facets = (nextState.facets.toList()..sort()).join(',');
      final revealed = (nextState.revealedFacets.toList()..sort()).join(',');
      final narration = firedDeltas.map((d) => d.narrationKey).join('>');
      return 'Resolved|${outcome.name}|$matchedPathId|[$narration]|'
          'meters{$meters}|facets{$facets}|revealed{$revealed}';
  }
}

void main() {
  const resolver = Resolver();

  CapabilityVector vec({
    Map<String, int> axes = const {},
    Set<FacetKey> invokes = const {},
  }) => CapabilityVector(
    magnitudes: {
      for (final e in axes.entries) CapabilityAxis.parse(e.key).key!: e.value,
    },
    invokedFacets: invokes,
    target: 'vorne',
    classId: 'diplomat',
  );

  group('Resolver Determinism', () {
    test('test_resolver_same_input_produces_same_output_across_1000_runs', () {
      // A rich beat that exercises a path effect + a side-effect meter + a reactive cascade:
      // suspicion primed to 40, a loud +30 win crosses 60, lockdown flips it to a loss.
      final state = applyDelta(
        WorldState.initial(magistrate()),
        const StateDelta([AdjustMeter('suspicion', 40)]),
      );
      final vector = vec(axes: {'social.intimidation': 40});

      final first = project(resolver.resolve(state, vector));
      // Sanity: the scenario really does traverse the interesting path.
      expect(
        first,
        'Resolved|lose|intimidate|[acquitLoud>lockdown]|'
        'meters{suspicion=70}|facets{}|revealed{}',
      );
      for (var i = 0; i < 1000; i++) {
        expect(project(resolver.resolve(state, vector)), equals(first));
      }
    });

    test('test_resolver_decisive_move_beat_is_deterministic', () {
      final state = applyDelta(
        WorldState.initial(magistrate()),
        const StateDelta([RevealFacet('scandal')]),
      );
      final vector = vec(axes: {'social.persuasion': 15}, invokes: {'scandal'});
      final first = project(resolver.resolve(state, vector));
      for (var i = 0; i < 1000; i++) {
        expect(project(resolver.resolve(state, vector)), equals(first));
      }
    });
  });
}
