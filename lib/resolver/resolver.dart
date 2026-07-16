/// Resolver (ADR-0006) — a pure-Dart, per-beat, deterministic rules engine. Given a
/// [WorldState] (frozen scene + mutable state) and a [CapabilityVector], it matches the
/// scene's conditional thresholds, fires the winning path's effect, advances the world one
/// beat, and evaluates reactive thresholds to a fixpoint. Zero Flutter imports; no clocks,
/// no unseeded randomness — same inputs always yield the same [ResolveResult].
library;

import '../game/capability_vector.dart';
import '../game/state_delta.dart';
import '../scene/scene_model.dart';
import 'world_state.dart';

/// Optional seeded RNG seam (review finding N6). Declared up front so adding
/// determinism-safe randomness later is not a breaking call-site change. The MVP Resolver
/// uses no randomness at all; any implementation supplied here MUST be seeded. This is a
/// deliberate named interface (injected, faked in tests), not a function typedef — hence the
/// `one_member_abstracts` ignore below.
// ignore: one_member_abstracts
abstract interface class SeededRng {
  /// A deterministic pseudo-random integer in `[0, max)`.
  int nextInt(int max);
}

/// The outcome of one beat of resolution.
sealed class ResolveResult {
  const ResolveResult();
}

/// A path matched: the world advanced. [firedDeltas] holds the path effect followed by any
/// reactive-cascade deltas, in the order they were applied. [outcome] is derived solely from
/// the last applied [Outcome] op (ADR-0001 single-source-of-truth); `advance` when none fired.
final class Resolved extends ResolveResult {
  const Resolved({
    required this.nextState,
    required this.firedDeltas,
    required this.outcome,
    required this.matchedPathId,
  });
  final WorldState nextState;
  final List<StateDelta> firedDeltas;
  final OutcomeResult outcome;

  /// The id of the winning [SolutionPath] — for narration lookup and feedback (ADR-0008).
  final String matchedPathId;
}

/// No path matched: handed to the router cascade / bounded fallback (ADR-0007). The Resolver
/// never invents an outcome for unhandled intent.
final class NoMatch extends ResolveResult {
  const NoMatch(this.vector, this.state);
  final CapabilityVector vector;
  final WorldState state;
}

/// Thrown when reactive thresholds fail to reach a fixpoint within the bound (a cycle the
/// Linter should have rejected, L-08). Defensive backstop only — authored content is acyclic.
class ReactiveFixpointException implements Exception {
  ReactiveFixpointException(this.message);
  final String message;
  @override
  String toString() => 'ReactiveFixpointException: $message';
}

/// A pure, deterministic, per-beat rules engine (ADR-0006).
final class Resolver {
  const Resolver({this.rng});

  /// Reserved seeded-randomness seam; unused by the MVP Resolver (see [SeededRng]).
  final SeededRng? rng;

  /// Resolve one beat. Selects the winning path by `(priority desc, declaration index asc)`,
  /// fires its effect, then evaluates reactive thresholds to a fixpoint. Returns [NoMatch]
  /// when no path's requirement holds.
  ResolveResult resolve(WorldState state, CapabilityVector vector) {
    final scene = state.scene;

    // 1–2. Select the winner: highest authored priority; ties broken by earliest declaration
    // index. Iterating in declaration order and replacing only on STRICTLY greater priority
    // keeps the earliest of any tie — a total order, never map/set iteration order.
    SolutionPath? winner;
    for (final path in scene.paths) {
      if (!_matches(path.requirement, vector, state)) continue;
      if (winner == null || path.priority > winner.priority) winner = path;
    }

    // 3. No path matched → hand off to the cascade.
    if (winner == null) return NoMatch(vector, state);

    // 4–6. Fire the winning effect and advance the world one beat.
    final firedDeltas = <StateDelta>[winner.effect];
    var next = applyDelta(state, winner.effect);

    // 7. Per-beat state machines (patrols/timers) advance here. The MVP Scene Model declares
    // no patrol schedules, so there is nothing to step yet; this is where authored per-beat
    // cursor advancement binds once schedules exist (kept explicit, never a wall clock).

    // 8. Evaluate reactive thresholds to a fixpoint. Each reactive fires at most once
    // (guaranteeing termination in ≤ N passes); declaration order keeps it deterministic.
    next = _runReactiveFixpoint(next, firedDeltas);

    // 9. Report. Outcome is the LAST applied Outcome op across every fired delta — so a
    // reactive terminal (e.g. lockdown → lose) correctly overrides an earlier path win.
    return Resolved(
      nextState: next,
      firedDeltas: List.unmodifiable(firedDeltas),
      outcome: _outcomeOf(firedDeltas),
      matchedPathId: winner.id,
    );
  }

  /// Evaluate the sealed [ThresholdExpr] tree to a bool against the vector + world facets.
  /// Exhaustive switch over all seven ADR-0003 R2 variants; recursion is authoring-bounded
  /// (Linter L-07). `Invokes` reads the vector's invoked facets — the stable decisive-move
  /// signal — while `WorldFacet`/`IfFacet` read world-state facet presence.
  bool _matches(
    ThresholdExpr expr,
    CapabilityVector vector,
    WorldState state,
  ) => switch (expr) {
    AxisAtLeast(:final axis, :final magnitude) =>
      vector.magnitudeOf(axis) >= magnitude,
    IfFacet(:final facet, :final thenExpr, :final elseExpr) =>
      state.hasFacet(facet)
          ? _matches(thenExpr, vector, state)
          : _matches(elseExpr, vector, state),
    WorldFacet(:final facet) => state.hasFacet(facet),
    Invokes(:final facet) => vector.invokedFacets.contains(facet),
    AllOf(:final parts) => parts.every((p) => _matches(p, vector, state)),
    AnyOf(:final parts) => parts.any((p) => _matches(p, vector, state)),
    Not(:final part) => !_matches(part, vector, state),
  };

  /// Fire every reactive whose meter is at/above its threshold, to a fixpoint. Appends each
  /// fired delta to [firedDeltas] in order and returns the settled state.
  WorldState _runReactiveFixpoint(
    WorldState state,
    List<StateDelta> firedDeltas,
  ) {
    final reactives = state.scene.reactiveThresholds;
    final fired = <String>{};
    var current = state;
    // Each reactive fires at most once, so the loop runs at most `reactives.length` times.
    for (var pass = 0; pass <= reactives.length; pass++) {
      var firedThisPass = false;
      for (final r in reactives) {
        if (fired.contains(r.id)) continue;
        if ((current.meters[r.meter] ?? 0) >= r.atLeast) {
          firedDeltas.add(r.effect);
          current = applyDelta(current, r.effect);
          fired.add(r.id);
          firedThisPass = true;
        }
      }
      if (!firedThisPass) return current;
    }
    throw ReactiveFixpointException(
      'reactive thresholds did not settle in ${reactives.length} passes '
      '(cyclic content should have been rejected by Linter L-08)',
    );
  }

  /// The beat's outcome: the last applied [Outcome] op across all fired deltas, or
  /// [OutcomeResult.advance] when none fired (ADR-0006 single-source-of-outcome-truth).
  OutcomeResult _outcomeOf(List<StateDelta> firedDeltas) {
    var outcome = OutcomeResult.advance;
    for (final delta in firedDeltas) {
      for (final op in delta.ops) {
        if (op is Outcome) outcome = op.result;
      }
    }
    return outcome;
  }
}
