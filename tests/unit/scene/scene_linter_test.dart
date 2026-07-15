// scene_linter_test — verifies the deterministic Scene Linter (ADR-0005) against
// docs/architecture/scene-decomposition-spec.md §5 (rules L-01..L-15).
//
// Pure-Dart unit tests: no WidgetTester, no I/O, deterministic. The magistrate JSON is
// embedded (not read from disk) to honor the "unit tests do not do file I/O" standard.

import 'dart:convert';

import 'package:adventures/game/ontology.dart';
import 'package:adventures/game/state_delta.dart';
import 'package:adventures/scene/authoring/grounding_tables.dart';
import 'package:adventures/scene/authoring/scene_linter.dart';
import 'package:adventures/scene/scene_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// The canonical magistrate scene — must lint clean (spec §6).
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

SceneModel parse(String s) =>
    SceneModel.fromJson((jsonDecode(s) as Map).cast());

SceneLinter linterWithGrounding() =>
    SceneLinter(grounding: GroundingTables.defaults());

/// A minimal winnable scene builder for negative-case tests.
SceneModel scene({
  Set<FacetKey> facets = const {'f'},
  Map<String, MeterSpec> meters = const {},
  List<Entity> entities = const [],
  List<SolutionPath> paths = const [],
  List<ReactiveThreshold> reactives = const [],
  Set<String> narration = const {'n'},
  FallbackBounds? fallback,
}) => SceneModel(
  id: 't',
  schemaVersion: 1,
  entities: entities,
  paths: paths,
  declaredFacets: facets,
  localMeters: meters,
  reactiveThresholds: reactives,
  narrationKeys: narration,
  fallbackBounds:
      fallback ??
      const FallbackBounds(
        touchableFacets: {},
        touchableMeters: {},
        maxMeterDelta: 0,
        allowOutcome: false,
      ),
);

SolutionPath winPath({
  required ThresholdExpr req,
  String id = 'win',
  String target = 'self',
  PathKind kind = PathKind.progress,
  int priority = 10,
  Difficulty? difficulty,
}) => SolutionPath(
  id: id,
  requirement: req,
  target: target,
  effect: const StateDelta([Outcome(OutcomeResult.win)], narrationKey: 'n'),
  kind: kind,
  priority: priority,
  difficulty: difficulty,
);

CapabilityAxis axis(String s) => CapabilityAxis.parse(s);

bool hasError(LintReport r, String rule) =>
    r.findings.any((f) => f.ruleId == rule && f.severity == LintSeverity.error);
bool hasWarning(LintReport r, String rule) => r.findings.any(
  (f) => f.ruleId == rule && f.severity == LintSeverity.warning,
);

void main() {
  final linter = linterWithGrounding();

  group('happy path', () {
    test('test_magistrate_lints_clean', () {
      final report = linter.lint(parse(magistrateJson));
      expect(report.passes, isTrue, reason: report.findings.join('\n'));
      expect(report.errors, isEmpty);
      // The clean fixture also raises no warnings.
      expect(report.findings, isEmpty, reason: report.findings.join('\n'));
    });

    test('test_lint_is_deterministic', () {
      final s = parse(magistrateJson);
      final a = linter.lint(s).findings.map((f) => f.toString()).toList();
      // Same scene, 100 runs -> identical report.
      for (var i = 0; i < 100; i++) {
        final b = linter.lint(s).findings.map((f) => f.toString()).toList();
        expect(b, equals(a));
      }
    });
  });

  group('rules', () {
    test('test_L01_undeclared_facet_in_requirement_errors', () {
      final s = scene(
        facets: {},
        paths: [winPath(req: const Invokes('ghost'))],
      );
      expect(hasError(linter.lint(s), 'L-01'), isTrue);
    });

    test('test_L02_noncanonical_axis_errors', () {
      final s = scene(
        paths: [winPath(req: AxisAtLeast(axis('bogusAxis'), 10))],
      );
      expect(hasError(linter.lint(s), 'L-02'), isTrue);
    });

    test('test_L02_social_without_channel_errors', () {
      final s = scene(paths: [winPath(req: AxisAtLeast(axis('social'), 10))]);
      expect(hasError(linter.lint(s), 'L-02'), isTrue);
    });

    test('test_L05_unknown_target_errors', () {
      final s = scene(
        paths: [winPath(req: AxisAtLeast(axis('force'), 10), target: 'ghost')],
      );
      expect(hasError(linter.lint(s), 'L-05'), isTrue);
    });

    test('test_L05_impossible_magnitude_errors', () {
      final s = scene(paths: [winPath(req: AxisAtLeast(axis('force'), 999))]);
      expect(hasError(linter.lint(s), 'L-05'), isTrue);
    });

    test('test_L06_discovery_with_outcome_errors', () {
      final discovery = SolutionPath(
        id: 'd',
        requirement: AxisAtLeast(axis('insight'), 10),
        target: 'self',
        effect: const StateDelta([
          Outcome(OutcomeResult.win),
        ], narrationKey: 'n'),
        kind: PathKind.discovery,
        priority: 5,
      );
      // Also include a winnable progress path so L-13 doesn't mask the check.
      final s = scene(
        paths: [
          discovery,
          winPath(req: AxisAtLeast(axis('force'), 10)),
        ],
      );
      expect(hasError(linter.lint(s), 'L-06'), isTrue);
    });

    test('test_L07_excessive_depth_errors', () {
      ThresholdExpr deep = AxisAtLeast(axis('force'), 10);
      for (var i = 0; i < 30; i++) {
        deep = Not(deep);
      }
      final s = scene(paths: [winPath(req: deep)]);
      expect(hasError(linter.lint(s), 'L-07'), isTrue);
    });

    test('test_L08_reactive_cycle_errors', () {
      final meters = {
        'x': const MeterSpec(min: 0, max: 100, initial: 0),
        'y': const MeterSpec(min: 0, max: 100, initial: 0),
      };
      final reactives = [
        const ReactiveThreshold(
          id: 'rx',
          meter: 'x',
          atLeast: 10,
          effect: StateDelta([AdjustMeter('y', 5)]),
        ),
        const ReactiveThreshold(
          id: 'ry',
          meter: 'y',
          atLeast: 10,
          effect: StateDelta([AdjustMeter('x', 5)]),
        ),
      ];
      final s = scene(
        meters: meters,
        reactives: reactives,
        paths: [winPath(req: AxisAtLeast(axis('force'), 10))],
      );
      expect(hasError(linter.lint(s), 'L-08'), isTrue);
    });

    test('test_L09_adjust_undeclared_meter_errors', () {
      final p = SolutionPath(
        id: 'w',
        requirement: AxisAtLeast(axis('force'), 10),
        target: 'self',
        effect: const StateDelta([
          AdjustMeter('nope', 5),
          Outcome(OutcomeResult.win),
        ], narrationKey: 'n'),
        kind: PathKind.progress,
        priority: 1,
      );
      expect(hasError(linter.lint(scene(paths: [p])), 'L-09'), isTrue);
    });

    test('test_L10_unknown_narration_key_errors', () {
      final p = SolutionPath(
        id: 'w',
        requirement: AxisAtLeast(axis('force'), 10),
        target: 'self',
        effect: const StateDelta([
          Outcome(OutcomeResult.win),
        ], narrationKey: 'missing'),
        kind: PathKind.progress,
        priority: 1,
      );
      expect(
        hasError(linter.lint(scene(paths: [p], narration: {'n'})), 'L-10'),
        isTrue,
      );
    });

    test(
      'test_L11_touchable_undeclared_meter_errors_and_allowOutcome_warns',
      () {
        final s = scene(
          paths: [winPath(req: AxisAtLeast(axis('force'), 10))],
          fallback: const FallbackBounds(
            touchableFacets: {},
            touchableMeters: {'ghostMeter'},
            maxMeterDelta: 5,
            allowOutcome: true,
          ),
        );
        final r = linter.lint(s);
        expect(hasError(r, 'L-11'), isTrue);
        expect(hasWarning(r, 'L-11'), isTrue); // allowOutcome=true
      },
    );

    test('test_L12_duplicate_priority_warns', () {
      final s = scene(
        paths: [
          winPath(req: AxisAtLeast(axis('force'), 10), id: 'a', priority: 5),
          winPath(req: AxisAtLeast(axis('insight'), 10), id: 'b', priority: 5),
        ],
      );
      expect(hasWarning(linter.lint(s), 'L-12'), isTrue);
    });

    test('test_L13_unwinnable_scene_errors', () {
      final onlyDiscovery = SolutionPath(
        id: 'd',
        requirement: AxisAtLeast(axis('insight'), 10),
        target: 'self',
        effect: const StateDelta([RevealFacet('f')], narrationKey: 'n'),
        kind: PathKind.discovery,
        priority: 1,
      );
      expect(
        hasError(linter.lint(scene(paths: [onlyDiscovery])), 'L-13'),
        isTrue,
      );
    });

    test('test_L15_collapse_without_leverage_warns', () {
      // Guarded (facet) branch at 30 and brute branch at 34 — both fall in the SAME
      // persuasion "standard" band (21..35), so the decisive move has no real leverage.
      final req = AnyOf([
        AllOf([
          const WorldFacet('f'),
          const Invokes('f'),
          AxisAtLeast(axis('social.persuasion'), 30),
        ]),
        AxisAtLeast(axis('social.persuasion'), 34),
      ]);
      final s = scene(paths: [winPath(req: req)]);
      expect(hasWarning(linter.lint(s), 'L-15'), isTrue);
    });

    test('test_L15_real_leverage_does_not_warn', () {
      // Magistrate-style: collapsed 15 (easy) vs brute 35 (standard) — real leverage.
      final req = AnyOf([
        AllOf([
          const WorldFacet('f'),
          const Invokes('f'),
          AxisAtLeast(axis('social.persuasion'), 15),
        ]),
        AxisAtLeast(axis('social.persuasion'), 35),
      ]);
      final s = scene(paths: [winPath(req: req)]);
      expect(hasWarning(linter.lint(s), 'L-15'), isFalse);
    });
  });
}
