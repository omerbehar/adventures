/// The deterministic Scene Linter (ADR-0005) — the line of defense that makes designer
/// "bulk-approve" real. Pure Dart, no I/O, no LLM: the same scene always yields the same
/// report. Implements rules L-01..L-15 from docs/architecture/scene-decomposition-spec.md §5.
library;

import '../../game/ontology.dart';
import '../../game/state_delta.dart';
import '../scene_model.dart';
import 'grounding_tables.dart';

enum LintSeverity { error, warning, promotionHint }

/// One lint finding. [where] is a human locator (e.g. `path[persuade].requirement`).
final class LintFinding {
  const LintFinding(this.ruleId, this.severity, this.where, this.message);
  final String ruleId;
  final LintSeverity severity;
  final String where;
  final String message;

  @override
  String toString() => '[$ruleId ${severity.name}] $where: $message';
}

/// Deterministic report. Passes iff there are no `error`-severity findings.
final class LintReport {
  const LintReport(this.findings);
  final List<LintFinding> findings;
  bool get passes => findings.every((f) => f.severity != LintSeverity.error);

  Iterable<LintFinding> get errors => findings.where((f) => f.severity == LintSeverity.error);
}

/// Deterministic linter. Construct once with the ontology + grounding tables; `lint` is pure.
final class SceneLinter {
  const SceneLinter({
    this.ontology = const Ontology(),
    this.grounding,
    this.maxThresholdDepth = 12,
  });

  final Ontology ontology;
  final GroundingTables? grounding;
  final int maxThresholdDepth;

  /// Lint one scene node. `globalFacets`/`globalMeters` come from the enclosing SceneGraph.
  /// Findings are emitted in a stable order (rule id, then declaration order).
  LintReport lint(
    SceneModel scene, {
    Set<FacetKey> globalFacets = const <FacetKey>{},
    Map<String, MeterSpec> globalMeters = const <String, MeterSpec>{},
  }) {
    final f = <LintFinding>[];
    final allFacets = {...scene.declaredFacets, ...globalFacets};
    final allMeters = {...scene.localMeters.keys, ...globalMeters.keys};
    final entityIds = {for (final e in scene.entities) e.id, 'self'};
    final norms = grounding?.thresholdNorms;

    void add(String rule, LintSeverity sev, String where, String msg) =>
        f.add(LintFinding(rule, sev, where, msg));

    // ---- per-path checks (L-01,02,04,05,06,07,15) ----
    for (final p in scene.paths) {
      final loc = 'path[${p.id}]';

      // L-07 — depth bound (recursion / stack-overflow guard).
      final depth = _depth(p.requirement);
      if (depth > maxThresholdDepth) {
        add('L-07', LintSeverity.error, '$loc.requirement',
            'ThresholdExpr depth $depth exceeds max $maxThresholdDepth');
      }

      // L-01 — facet references in the requirement must be declared.
      final reqFacets = <String>{};
      _facetsInExpr(p.requirement, reqFacets);
      for (final key in reqFacets) {
        if (!allFacets.contains(key)) {
          add('L-01', LintSeverity.error, '$loc.requirement', 'Undeclared facet "$key"');
        }
      }

      // Axis leaves drive L-02, L-04, L-05.
      _axisLeaves(p.requirement, false, (axis, mag, guarded) {
        if (!axis.isCanonical) {
          add('L-02', LintSeverity.error, '$loc.requirement',
              'Non-canonical / would-be-new axis "${axis.raw}"');
          return;
        }
        final key = axis.key!;
        // L-05 — impossible threshold (unreachable leaf).
        if (mag > ontology.magnitudeMax) {
          add('L-05', LintSeverity.error, '$loc.requirement',
              'AxisAtLeast(${axis.raw}, $mag) exceeds ontology max ${ontology.magnitudeMax} — unreachable');
        } else if (mag < ontology.magnitudeMin) {
          add('L-05', LintSeverity.warning, '$loc.requirement',
              'AxisAtLeast(${axis.raw}, $mag) below ontology min ${ontology.magnitudeMin} — always true');
        }
        // L-04 — magnitude outside the grounding band for the path's declared difficulty.
        if (p.difficulty != null && norms != null) {
          final ok = norms.inBand(key, p.difficulty!, mag);
          if (ok == false) {
            add('L-04', LintSeverity.warning, '$loc.requirement',
                'Magnitude $mag on ${axis.raw} is outside the ${p.difficulty!.name} band');
          }
        }
      });

      // L-05 — orphaned path: target entity must exist.
      if (!entityIds.contains(p.target)) {
        add('L-05', LintSeverity.error, '$loc.target', 'Unknown target "${p.target}"');
      }

      // L-06 — a discovery path must not emit a terminal Outcome.
      if (p.kind == PathKind.discovery) {
        for (final op in p.effect.ops) {
          if (op is Outcome && op.result != OutcomeResult.advance) {
            add('L-06', LintSeverity.error, '$loc.effect',
                'Discovery path emits a terminal Outcome (${op.result.name})');
          }
        }
      }

      // L-15 — a decisive-move collapse must land a difficulty band below its brute path.
      if (norms != null) _lintLeverage(p, norms, add);
    }

    // ---- effect-level checks across paths + reactives (L-01,09,10) ----
    for (final p in scene.paths) {
      _lintEffect('path[${p.id}].effect', p.effect, allFacets, allMeters, entityIds,
          scene.narrationKeys, add);
    }
    for (final r in scene.reactiveThresholds) {
      final loc = 'reactive[${r.id}]';
      // L-09 — reactive must watch a declared meter.
      if (!allMeters.contains(r.meter)) {
        add('L-09', LintSeverity.error, loc, 'Reactive watches undeclared meter "${r.meter}"');
      }
      _lintEffect('$loc.effect', r.effect, allFacets, allMeters, entityIds,
          scene.narrationKeys, add);
    }

    // L-08 — reactive thresholds must not form a cycle (Resolver fixpoint must terminate).
    for (final cyc in _reactiveCycles(scene)) {
      add('L-08', LintSeverity.error, 'reactiveThresholds', 'Reactive cycle: ${cyc.join(" -> ")}');
    }

    // L-11 — FallbackBounds sanity.
    final fb = scene.fallbackBounds;
    for (final key in fb.touchableFacets) {
      if (!allFacets.contains(key)) {
        add('L-11', LintSeverity.error, 'fallbackBounds', 'touchableFacets contains undeclared "$key"');
      }
    }
    for (final m in fb.touchableMeters) {
      if (!allMeters.contains(m)) {
        add('L-11', LintSeverity.error, 'fallbackBounds', 'touchableMeters contains undeclared "$m"');
      }
    }
    if (fb.maxMeterDelta < 0) {
      add('L-11', LintSeverity.error, 'fallbackBounds', 'maxMeterDelta must be >= 0');
    }
    if (fb.allowOutcome) {
      add('L-11', LintSeverity.warning, 'fallbackBounds',
          'allowOutcome=true lets a Tier-3 fallback declare a terminal outcome — usually unsafe');
    }

    // L-12 — duplicate authored priorities (tie relies on declaration index).
    final byPriority = <int, List<String>>{};
    for (final p in scene.paths) {
      byPriority.putIfAbsent(p.priority, () => []).add(p.id);
    }
    for (final e in byPriority.entries) {
      if (e.value.length > 1) {
        add('L-12', LintSeverity.warning, 'paths',
            'Paths share priority ${e.key}: ${e.value.join(", ")} (tiebreak = declaration index)');
      }
    }

    // L-13 — at least one progress path must reach a terminal Outcome.
    final winnable = scene.paths.any((p) =>
        p.kind == PathKind.progress &&
        p.effect.ops.any((op) => op is Outcome && op.result != OutcomeResult.advance));
    if (!winnable) {
      add('L-13', LintSeverity.error, 'paths',
          'No progress path reaches a terminal Outcome — scene is unwinnable');
    }

    // L-03 (PropValue) and L-14 (cross-scene promotion) are enforced by construction /
    // out of scope for a single-node lint — see spec §5. Not emitted here.

    // Canonical total order (insertion-independent) → the report is deterministic.
    final ordered = [...f]
      ..sort((a, b) {
        final r = a.ruleId.compareTo(b.ruleId);
        if (r != 0) return r;
        final w = a.where.compareTo(b.where);
        if (w != 0) return w;
        return a.message.compareTo(b.message);
      });
    return LintReport(List.unmodifiable(ordered));
  }

  // -- effect-level rules (shared by paths + reactives) --
  void _lintEffect(
    String loc,
    StateDelta effect,
    Set<String> allFacets,
    Set<String> allMeters,
    Set<String> entityIds,
    Set<String> narrationKeys,
    void Function(String, LintSeverity, String, String) add,
  ) {
    for (final op in effect.ops) {
      switch (op) {
        case SetFacet(:final key):
          if (!allFacets.contains(key)) {
            add('L-01', LintSeverity.error, loc, 'SetFacet on undeclared facet "$key"');
          }
        case RevealFacet(:final key):
          if (!allFacets.contains(key)) {
            add('L-01', LintSeverity.error, loc, 'RevealFacet on undeclared facet "$key"');
          }
        case AdjustMeter(:final meter):
          if (!allMeters.contains(meter)) {
            add('L-09', LintSeverity.error, loc, 'AdjustMeter on undeclared meter "$meter"');
          }
        case SetEntityProp(:final entityId):
          if (!entityIds.contains(entityId)) {
            add('L-05', LintSeverity.error, loc, 'SetEntityProp on unknown entity "$entityId"');
          }
        case TransitionNode() || Outcome():
          break;
      }
    }
    // L-10 — narration must resolve to an authored key.
    final nk = effect.narrationKey;
    if (nk != null && !narrationKeys.contains(nk)) {
      add('L-10', LintSeverity.error, loc, 'narrationKey "$nk" not in declared narrationKeys');
    }
  }

  // -- L-15 leverage heuristic --
  void _lintLeverage(
    SolutionPath p,
    ThresholdNorms norms,
    void Function(String, LintSeverity, String, String) add,
  ) {
    final guardedMin = <CapabilityAxisKey, int>{};
    final bruteMin = <CapabilityAxisKey, int>{};
    _axisLeaves(p.requirement, false, (axis, mag, guarded) {
      if (!axis.isCanonical) return;
      final key = axis.key!;
      final target = guarded ? guardedMin : bruteMin;
      target[key] = target.containsKey(key) ? (mag < target[key]! ? mag : target[key]!) : mag;
    });
    for (final key in guardedMin.keys) {
      if (!bruteMin.containsKey(key)) continue;
      final gb = norms.bandOf(key, guardedMin[key]!);
      final bb = norms.bandOf(key, bruteMin[key]!);
      if (gb != null && bb != null && gb.index >= bb.index) {
        add('L-15', LintSeverity.warning, 'path[${p.id}].requirement',
            'Decisive-move collapse (${guardedMin[key]} = ${gb.name}) is not a lower difficulty '
            'band than the brute path (${bruteMin[key]} = ${bb.name}) — no real leverage');
      }
    }
  }
}

// ======== pure tree helpers (top-level, deterministic) ========

void _facetsInExpr(ThresholdExpr e, Set<String> out) {
  switch (e) {
    case AxisAtLeast():
      break;
    case IfFacet(:final facet, :final thenExpr, :final elseExpr):
      out.add(facet);
      _facetsInExpr(thenExpr, out);
      _facetsInExpr(elseExpr, out);
    case WorldFacet(:final facet):
      out.add(facet);
    case Invokes(:final facet):
      out.add(facet);
    case AllOf(:final parts) || AnyOf(:final parts):
      for (final p in parts) {
        _facetsInExpr(p, out);
      }
    case Not(:final part):
      _facetsInExpr(part, out);
  }
}

int _depth(ThresholdExpr e) {
  switch (e) {
    case AxisAtLeast() || WorldFacet() || Invokes():
      return 1;
    case IfFacet(:final thenExpr, :final elseExpr):
      return 1 + _max(_depth(thenExpr), _depth(elseExpr));
    case AllOf(:final parts) || AnyOf(:final parts):
      var m = 0;
      for (final p in parts) {
        m = _max(m, _depth(p));
      }
      return 1 + m;
    case Not(:final part):
      return 1 + _depth(part);
  }
}

/// Collect axis leaves, tracking whether each is under a facet guard (an `AllOf` containing
/// a facet predicate, or an `IfFacet.thenExpr`). Used by L-15.
void _axisLeaves(
    ThresholdExpr e, bool guarded, void Function(CapabilityAxis, int, bool) sink) {
  switch (e) {
    case AxisAtLeast(:final axis, :final magnitude):
      sink(axis, magnitude, guarded);
    case IfFacet(:final thenExpr, :final elseExpr):
      _axisLeaves(thenExpr, true, sink); // then-branch fires when the facet IS set (the collapse)
      _axisLeaves(elseExpr, guarded, sink); // else-branch is the brute path
    case AllOf(:final parts):
      final hasFacet = parts.any((p) => p is Invokes || p is WorldFacet);
      for (final p in parts) {
        _axisLeaves(p, guarded || hasFacet, sink);
      }
    case AnyOf(:final parts):
      for (final p in parts) {
        _axisLeaves(p, guarded, sink);
      }
    case Not(:final part):
      _axisLeaves(part, guarded, sink);
    case WorldFacet() || Invokes():
      break;
  }
}

/// Detect cycles among meters induced by reactive thresholds: an edge `watched -> adjusted`
/// for each `AdjustMeter` a reactive's effect performs. Returns each cycle found (meter names).
List<List<String>> _reactiveCycles(SceneModel scene) {
  final edges = <String, Set<String>>{};
  for (final r in scene.reactiveThresholds) {
    for (final op in r.effect.ops) {
      if (op is AdjustMeter) {
        edges.putIfAbsent(r.meter, () => {}).add(op.meter);
      }
    }
  }
  final cycles = <List<String>>[];
  final visiting = <String>{};
  final done = <String>{};
  final stack = <String>[];

  bool dfs(String n) {
    visiting.add(n);
    stack.add(n);
    for (final m in (edges[n] ?? const <String>{})) {
      if (visiting.contains(m)) {
        final i = stack.indexOf(m);
        cycles.add([...stack.sublist(i), m]);
        continue;
      }
      if (!done.contains(m) && dfs(m)) return true;
    }
    visiting.remove(n);
    stack.removeLast();
    done.add(n);
    return false;
  }

  for (final n in edges.keys) {
    if (!done.contains(n)) dfs(n);
  }
  return cycles;
}

int _max(int a, int b) => a > b ? a : b;
