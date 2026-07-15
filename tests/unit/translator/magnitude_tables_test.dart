// magnitude_tables_test — Stage B scoring (ADR-0004): deterministic, class-colored, and
// wired end-to-end through a fake Stage A classifier into the Resolver. Pure-Dart, no I/O.

import 'dart:convert';

import 'package:adventures/game/capability_vector.dart';
import 'package:adventures/game/ontology.dart';
import 'package:adventures/game/state_delta.dart';
import 'package:adventures/game/translator/classification.dart';
import 'package:adventures/game/translator/magnitude_tables.dart';
import 'package:adventures/resolver/resolver.dart';
import 'package:adventures/resolver/world_state.dart';
import 'package:adventures/scene/scene_model.dart';
import 'package:adventures/services/intent_classifier.dart';
import 'package:flutter_test/flutter_test.dart';

CapabilityAxis axis(String s) => CapabilityAxis.parse(s);
CapabilityAxisKey ax(String s) => CapabilityAxis.parse(s).key!;

Classification classify({
  Map<String, CoarseOrdinal> axes = const {},
  String target = 'vorne',
  List<FacetKey> invokes = const [],
}) => Classification(
  axisOrdinals: {for (final e in axes.entries) ax(e.key): e.value},
  target: target,
  tactics: const [],
  facetsInvoked: invokes,
);

/// A canned Stage A — returns a fixed [Classification], never calls a model (ADR-0004: unit
/// tests use a fake classifier).
final class FakeClassifier implements IntentClassifier {
  FakeClassifier(this._result);
  final Classification _result;
  @override
  Future<Classification> classify(String text, ClassifyContext ctx) async =>
      _result;
}

/// Order-independent projection of a vector — enough to detect any nondeterminism.
String project(CapabilityVector v) {
  final mags =
      (v.magnitudes.entries.toList()
            ..sort((a, b) => a.key.toString().compareTo(b.key.toString())))
          .map((e) => '${e.key}=${e.value}')
          .join(',');
  final facets = (v.invokedFacets.toList()..sort()).join(',');
  return '{$mags}|facets{$facets}|target=${v.target}|class=${v.classId}';
}

const String magistrateJson = r'''
{
  "schemaVersion": 1, "id": "magistrate",
  "declaredFacets": ["scandal"],
  "localMeters": { "suspicion": { "min": 0, "max": 100, "initial": 0 } },
  "narrationKeys": ["acquit", "acquitLoud", "reveal", "lockdown"],
  "entities": [ { "id": "vorne", "type": "magistrate", "props": { "hostile": {"bool": true} } } ],
  "paths": [
    { "id": "persuade", "kind": "progress", "target": "vorne", "priority": 20,
      "requirement": { "AnyOf": [
        { "AllOf": [ {"WorldFacet": "scandal"}, {"Invokes": "scandal"}, {"AxisAtLeast": ["social.persuasion", 15]} ] },
        { "AxisAtLeast": ["social.persuasion", 35] } ] },
      "effect": { "ops": [ {"Outcome": "win"} ], "narrationKey": "acquit" } }
  ],
  "reactiveThresholds": [],
  "fallbackBounds": { "touchableFacets": [], "touchableMeters": ["suspicion"], "maxMeterDelta": 10, "allowOutcome": false }
}
''';

SceneModel magistrate() =>
    SceneModel.fromJson((jsonDecode(magistrateJson) as Map).cast());

void main() {
  final tables = MagnitudeTables.defaults();

  group('Stage B scoring', () {
    test('test_score_is_deterministic_across_1000_runs', () {
      final c = classify(
        axes: {
          'social.persuasion': CoarseOrdinal.major,
          'insight': CoarseOrdinal.minor,
        },
        invokes: ['scandal'],
      );
      final first = project(tables.score(c, 'diplomat'));
      for (var i = 0; i < 1000; i++) {
        expect(project(tables.score(c, 'diplomat')), equals(first));
      }
    });

    test('test_class_coloring_diverges_for_same_classification', () {
      // Pillar 5: the same "major persuasion" scores differently per specialist.
      final c = classify(axes: {'social.persuasion': CoarseOrdinal.major});
      final diplomat = tables
          .score(c, 'diplomat')
          .magnitudeOf(axis('social.persuasion'));
      final enforcer = tables
          .score(c, 'enforcer')
          .magnitudeOf(axis('social.persuasion'));
      expect(diplomat, 48);
      expect(enforcer, 28);
      expect(diplomat, isNot(equals(enforcer)));
    });

    test('test_unknown_class_falls_back_to_default_table', () {
      final c = classify(axes: {'force': CoarseOrdinal.moderate});
      final v = tables.score(c, 'no-such-class');
      expect(v.magnitudeOf(axis('force')), 22); // the 'default' class value
    });

    test('test_scene_modifiers_shift_magnitude', () {
      final c = classify(axes: {'force': CoarseOrdinal.moderate});
      final base = tables.score(c, 'default').magnitudeOf(axis('force'));
      final modified = tables
          .score(c, 'default', mods: SceneModifiers({ax('force'): 10}))
          .magnitudeOf(axis('force'));
      expect(modified, base + 10);
    });

    test('test_score_passes_through_facets_and_target', () {
      final c = classify(
        axes: {'social.persuasion': CoarseOrdinal.minor},
        target: 'vorne',
        invokes: ['scandal'],
      );
      final v = tables.score(c, 'diplomat');
      expect(v.invokedFacets, {'scandal'});
      expect(v.target, 'vorne');
      expect(v.classId, 'diplomat');
    });

    test('test_magnitude_clamps_to_ontology_scale', () {
      // A large scene modifier cannot push a magnitude past the ontology max (100).
      final c = classify(axes: {'force': CoarseOrdinal.extreme});
      final v = tables.score(
        c,
        'default',
        mods: SceneModifiers({ax('force'): 500}),
      );
      expect(v.magnitudeOf(axis('force')), 100);
    });
  });

  group('fromJson', () {
    test('test_fromJson_round_trips_and_rejects_noncanonical_axis', () {
      final t = MagnitudeTables.fromJson(const {
        'version': 'v1',
        'classes': {
          'default': {
            'force': {
              'none': 0,
              'minor': 9,
              'moderate': 20,
              'major': 41,
              'extreme': 66,
            },
          },
        },
      });
      final v = t.score(
        classify(axes: {'force': CoarseOrdinal.major}),
        'default',
      );
      expect(v.magnitudeOf(axis('force')), 41);

      expect(
        () => MagnitudeTables.fromJson(const {
          'version': 'v1',
          'classes': {
            'default': {
              'social': {'minor': 10},
            },
          },
        }),
        throwsA(isA<TranslatorException>()),
      );
    });
  });

  group('pipeline: classifier -> Stage B -> Resolver', () {
    test('test_pipeline_decisive_move_wins_via_facet_collapse', () async {
      // Scandal already discovered; a weak (minor) persuasion that invokes scandal.
      final state = applyDelta(
        WorldState.initial(magistrate()),
        const StateDelta([RevealFacet('scandal')]),
      );
      final classifier = FakeClassifier(
        classify(
          axes: {'social.persuasion': CoarseOrdinal.minor},
          invokes: ['scandal'],
        ),
      );

      final classification = await classifier.classify(
        'remind the magistrate his own scandal would surface',
        const ClassifyContext(
          sceneId: 'magistrate',
          classId: 'diplomat',
          availableFacets: {'scandal'},
        ),
      );
      final vector = tables.score(classification, 'diplomat');
      // diplomat minor persuasion = 16, above the collapsed 15 threshold.
      expect(vector.magnitudeOf(axis('social.persuasion')), 16);

      final result = const Resolver().resolve(state, vector);
      expect((result as Resolved).matchedPathId, 'persuade');
      expect(result.outcome, OutcomeResult.win);
    });

    test('test_pipeline_same_intent_without_class_color_falls_short', () async {
      // The enforcer's minor persuasion (8) is below the collapsed 15 threshold, so the same
      // words that win for a diplomat find no path here — class coloring is decisive.
      final state = applyDelta(
        WorldState.initial(magistrate()),
        const StateDelta([RevealFacet('scandal')]),
      );
      final classifier = FakeClassifier(
        classify(
          axes: {'social.persuasion': CoarseOrdinal.minor},
          invokes: ['scandal'],
        ),
      );
      final classification = await classifier.classify(
        'remind the magistrate his own scandal would surface',
        const ClassifyContext(sceneId: 'magistrate', classId: 'enforcer'),
      );
      final vector = tables.score(classification, 'enforcer');
      expect(vector.magnitudeOf(axis('social.persuasion')), 8);
      expect(const Resolver().resolve(state, vector), isA<NoMatch>());
    });
  });
}
