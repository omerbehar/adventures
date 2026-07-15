// resolver_test — behavior of the deterministic Resolver (ADR-0006) against the canonical
// magistrate scene. Covers every ADR-0006 validation criterion plus applyDelta purity.
//
// Pure-Dart unit tests: no WidgetTester, no I/O, deterministic. The magistrate JSON is
// embedded (not read from disk) to honor the "unit tests do not do file I/O" standard.

import 'dart:convert';

import 'package:adventures/game/capability_vector.dart';
import 'package:adventures/game/ontology.dart';
import 'package:adventures/game/state_delta.dart';
import 'package:adventures/resolver/resolver.dart';
import 'package:adventures/resolver/world_state.dart';
import 'package:adventures/scene/scene_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// The canonical magistrate scene (matches assets/scenes/magistrate.json): discover reveals
/// `scandal`; persuade collapses from a hard brute (35) to easy (15) once scandal is both a
/// world facet and invoked; intimidate wins loudly (+30 suspicion); suspicion ≥ 60 → lockdown.
const String magistrateJson = r'''
{
  "schemaVersion": 1, "id": "magistrate",
  "declaredFacets": ["scandal"],
  "localMeters": { "suspicion": { "min": 0, "max": 100, "initial": 0 } },
  "narrationKeys": ["acquit", "acquitLoud", "reveal", "lockdown", "nudge"],
  "entities": [ { "id": "vorne", "type": "magistrate",
    "props": { "hostile": {"bool": true}, "persuadeBase": {"int": 35}, "intimidate": {"int": 40} } } ],
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

/// Build a CapabilityVector from `{'social.persuasion': 15, ...}`-style axis strings.
CapabilityVector vec({
  Map<String, int> axes = const {},
  Set<FacetKey> invokes = const {},
  String target = 'vorne',
  String classId = 'diplomat',
}) => CapabilityVector(
  magnitudes: {
    for (final e in axes.entries) CapabilityAxis.parse(e.key).key!: e.value,
  },
  invokedFacets: invokes,
  target: target,
  classId: classId,
);

void main() {
  const resolver = Resolver();

  group('path selection & the decisive move', () {
    test('test_resolver_persuade_collapses_when_scandal_revealed_and_invoked', () {
      // Arrange: scandal already discovered; a weak (15) persuasion that invokes scandal.
      final state = applyDelta(
        WorldState.initial(magistrate()),
        const StateDelta([RevealFacet('scandal')]),
      );
      // Act.
      final result = resolver.resolve(
        state,
        vec(axes: {'social.persuasion': 15}, invokes: {'scandal'}),
      );
      // Assert: the collapsed branch fires — a win the brute 35 threshold would have denied.
      expect(result, isA<Resolved>());
      final resolved = result as Resolved;
      expect(resolved.matchedPathId, 'persuade');
      expect(resolved.outcome, OutcomeResult.win);
    });

    test('test_resolver_weak_persuasion_without_leverage_no_match', () {
      // Same magnitude, but scandal is neither revealed nor invoked → no path holds.
      final result = resolver.resolve(
        WorldState.initial(magistrate()),
        vec(axes: {'social.persuasion': 15}),
      );
      expect(result, isA<NoMatch>());
    });

    test('test_resolver_brute_persuasion_wins_without_leverage', () {
      // The un-collapsed brute path (35) is still a valid, harder route to the same win.
      final result = resolver.resolve(
        WorldState.initial(magistrate()),
        vec(axes: {'social.persuasion': 35}),
      );
      expect((result as Resolved).matchedPathId, 'persuade');
      expect(result.outcome, OutcomeResult.win);
    });

    test('test_resolver_discovery_then_collapse_across_two_beats', () {
      // Beat 1: an insightful read discovers the scandal (highest-priority discovery path).
      final beat1 = resolver.resolve(
        WorldState.initial(magistrate()),
        vec(axes: {'insight': 25}),
      );
      final r1 = beat1 as Resolved;
      expect(r1.matchedPathId, 'discover');
      expect(r1.outcome, OutcomeResult.advance); // discovery is non-terminal
      expect(r1.nextState.hasFacet('scandal'), isTrue);

      // Beat 2: from the revealed state, weak persuasion now collapses to a win.
      final beat2 = resolver.resolve(
        r1.nextState,
        vec(axes: {'social.persuasion': 15}, invokes: {'scandal'}),
      );
      expect((beat2 as Resolved).matchedPathId, 'persuade');
      expect(beat2.outcome, OutcomeResult.win);
    });
  });

  group('side effects & reactive thresholds', () {
    test('test_resolver_intimidate_moves_meter_in_the_win_beat', () {
      // Loud/quiet tradeoff: the win and its +30 suspicion land in the same beat.
      final result = resolver.resolve(
        WorldState.initial(magistrate()),
        vec(axes: {'social.intimidation': 40}),
      );
      final resolved = result as Resolved;
      expect(resolved.outcome, OutcomeResult.win);
      expect(resolved.nextState.meters['suspicion'], 30);
    });

    test('test_resolver_reactive_lockdown_overrides_win_as_lose', () {
      // Preload suspicion to 40 so a loud +30 win crosses the 60 lockdown line.
      final primed = applyDelta(
        WorldState.initial(magistrate()),
        const StateDelta([AdjustMeter('suspicion', 40)]),
      );
      final result = resolver.resolve(
        primed,
        vec(axes: {'social.intimidation': 40}),
      );
      final resolved = result as Resolved;
      // The path effect wins, then the reactive fires — last applied Outcome wins.
      expect(resolved.matchedPathId, 'intimidate');
      expect(resolved.nextState.meters['suspicion'], 70);
      expect(resolved.outcome, OutcomeResult.lose);
      // Fired order is [path effect, lockdown effect].
      expect(resolved.firedDeltas.map((d) => d.narrationKey).toList(), [
        'acquitLoud',
        'lockdown',
      ]);
    });
  });

  group('no-match & outcome truth', () {
    test('test_resolver_empty_intent_returns_no_match', () {
      final result = resolver.resolve(WorldState.initial(magistrate()), vec());
      expect(result, isA<NoMatch>());
      expect((result as NoMatch).vector.invokedFacets, isEmpty);
    });

    test('test_resolver_outcome_is_advance_when_no_outcome_op_fires', () {
      final result = resolver.resolve(
        WorldState.initial(magistrate()),
        vec(axes: {'insight': 25}),
      );
      expect((result as Resolved).outcome, OutcomeResult.advance);
    });
  });

  group('applyDelta purity (ADR-0001, finding N3)', () {
    test('test_applyDelta_does_not_mutate_the_input_state', () {
      final before = WorldState.initial(magistrate());
      final after = applyDelta(
        before,
        const StateDelta([
          AdjustMeter('suspicion', 25),
          SetFacet('scandal', true),
        ]),
      );
      // The successor changed; the input is untouched.
      expect(after.meters['suspicion'], 25);
      expect(after.facets.contains('scandal'), isTrue);
      expect(before.meters['suspicion'], 0);
      expect(before.facets.contains('scandal'), isFalse);
    });

    test('test_world_state_collections_are_unmodifiable', () {
      final state = WorldState.initial(magistrate());
      expect(() => state.meters['suspicion'] = 99, throwsUnsupportedError);
      expect(() => state.facets.add('x'), throwsUnsupportedError);
    });

    test('test_meter_writes_clamp_to_declared_bounds', () {
      // suspicion max is 100 — a huge delta clamps rather than overflowing.
      final state = applyDelta(
        WorldState.initial(magistrate()),
        const StateDelta([AdjustMeter('suspicion', 500)]),
      );
      expect(state.meters['suspicion'], 100);
    });
  });
}
