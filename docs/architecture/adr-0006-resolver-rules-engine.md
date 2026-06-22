# ADR-0006: Resolver as a Per-Beat Deterministic Rules Engine

## Status

Accepted

## Date

2026-06-21

## Last Verified

2026-06-21

## Decision Makers

technical-director, gameplay-programmer, flutter-specialist (authored via /architecture-decision, batch foundational set)

## Summary

Defines the Resolver: a pure-Dart, client/edge-side deterministic rules engine that, once
per beat, matches a `CapabilityVector` against the active scene's conditional thresholds,
fires the winning path's `StateDelta` + authored narration, advances world state, and
evaluates reactive thresholds. All advancement is per-beat (state-machine), never driven by
a real-time clock.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Flutter 3.44.0 / Dart 3.12 |
| **Domain** | Core |
| **Knowledge Risk** | LOW — pure-Dart core; pattern matching / sealed types stable since Dart 3.0 |
| **References Consulted** | `docs/engine-reference/flutter/current-best-practices.md` (patterns + switch expressions for Resolver matching, pure-Dart-core, determinism) |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | None — fully unit-testable headlessly |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (StateDelta), ADR-0002 (Ontology), ADR-0003 (Scene Model), ADR-0004 (Translator → CapabilityVector) |
| **Enables** | ADR-0007 (cascade falls back only when the Resolver finds no path), ADR-0008 (feedback observes Resolver gaps) |
| **Blocks** | MVP Resolver epic; the magistrate prototype |
| **Ordering Note** | The most-dependent of the core four; author after ADR-0001/0002/0003/0004. |

## Context

### Problem Statement

The translation moment ("I said what I wanted, and the world took it seriously") requires a
component that turns a typed `CapabilityVector` into a visible, authored, consequential
state change — fairly and identically every run. Pressure must be beat-economy (like chess),
not reflexes (anti-pillar: no twitch). This engine is the deterministic heart of Pillars 1,
2, and 3 and must run client/edge-side so the common case needs no round-trip and degrades
gracefully offline.

### Current State

No code. The concept's pipeline table (stage 5) and "Core resolution mechanics" specify the
behavior; no evaluation order or interface exists.

### Constraints

- **Pure Dart**, client/edge-side, zero Flutter imports.
- **Deterministic**: same `CapabilityVector` + same `WorldState` → same `StateDelta`, every run. No `DateTime.now()`, no unseeded `Random`, no real-time clock.
- **Per-beat**: the world steps exactly once per player action; patrols/timers are state machines advanced by moves.
- Emits only validated `StateDelta`s (ADR-0001) + authored narration keys — never prose.

### Requirements

- Evaluate conditional thresholds (ADR-0003 `ThresholdExpr`), including facet-collapse (the decisive move).
- Fire the matched path's effect; apply side-effect meters; advance world state by one beat.
- Evaluate reactive thresholds after application; cascade authored transitions deterministically.
- Report "no path matched" so the router cascade (ADR-0007) can invoke the bounded fallback.
- Support both progress and discovery paths.

## Decision

A pure function-style engine, `Resolver.resolve(WorldState, CapabilityVector) -> ResolveResult`,
with a **fixed, documented evaluation order**. It selects among matching paths
deterministically (authored priority, then stable order), fires the effect via `applyDelta`,
advances per-beat state machines, then evaluates reactive thresholds to a fixpoint — all
without any nondeterministic input. If no path matches, it returns a `NoMatch` result for the
cascade to handle.

### Architecture

```
CapabilityVector  +  WorldState (frozen SceneModel + mutable state)
        │
        ▼
┌────────────────────────────────────────────────────────────┐
│ RESOLVER.resolve  (pure, deterministic, per-beat)            │
│                                                              │
│ 1. Evaluate each candidate path's ThresholdExpr against the  │
│    vector + current facets  (IfFacet collapse = decisive move)│
│ 2. Select winner: authored priority → stable tiebreak        │
│ 3. If none → return NoMatch  ─────────────────────────────►  │ → cascade (ADR-0007)
│ 4. effect = winner.effect : StateDelta                       │
│ 5. validateDelta(effect)  (ADR-0001)                         │
│ 6. state' = applyDelta(state, effect)   (incl. side-effects) │
│ 7. advance per-beat state machines (patrols/timers by move)  │
│ 8. evaluate reactiveThresholds on state' to a fixpoint       │
│    (e.g. Alertness ≥ 60 → lockdown StateDelta), deterministic │
│ 9. return Resolved(state'', narrationKeys, outcome)          │
└────────────────────────────────────────────────────────────┘
        │
        ▼
  ResolveResult  →  UI renders authored narration + visible state change
```

### Key Interfaces

```dart
sealed class ResolveResult { const ResolveResult(); }

final class Resolved extends ResolveResult {
  const Resolved({required this.nextState, required this.firedDeltas, required this.outcome});
  final WorldState nextState;
  final List<StateDelta> firedDeltas;     // path effect + any reactive cascade, in order
  final OutcomeResult outcome;            // advance | escape | win | lose
}

final class NoMatch extends ResolveResult {
  const NoMatch(this.vector, this.state); // hand-off to the cascade / bounded fallback
  final CapabilityVector vector; final WorldState state;
}

/// Pure, deterministic, per-beat. No I/O, no clocks, no unseeded randomness.
final class Resolver {
  // Optional SEEDED RNG declared up front (review finding N6) so adding determinism-
  // safe randomness later is not a breaking call-site change. MVP passes nothing and
  // the Resolver uses no randomness at all. `rng`, when supplied, MUST be seeded.
  const Resolver({this.rng});
  final SeededRng? rng;
  ResolveResult resolve(WorldState state, CapabilityVector vector);
}
```

### Implementation Guidelines

- Place in `lib/resolver/` (pure Dart). No Flutter imports; no service calls (the cascade calls the Resolver, not vice-versa).
- Use Dart **switch expressions with object patterns over the `sealed ThresholdExpr`** for exhaustive, readable matching (e.g. `case AxisAtLeast(:final axis, :final magnitude)`). These are type/object patterns against a sealed class — not record patterns.
- **Axis matching** compares `vector.magnitudes[axis.key]` against `AxisAtLeast.magnitude` using the record `CapabilityAxisKey` (ADR-0002) — value-equality is required for deterministic lookup.
- **Outcome single source of truth**: derive `Resolved.outcome` *from* the applied `Outcome` op in the fired `StateDelta` (ADR-0001), never compute a parallel outcome. If no `Outcome` op fired, the outcome is `advance`.
- Make path selection a **total order**: authored `priority` then a stable secondary key (e.g. declaration index). Never rely on map/set iteration order.
- Reactive-threshold evaluation runs to a **fixpoint** with a guard against cycles (authored thresholds must be acyclic; detect and error in the Linter, ADR-0005).
- If any randomness is ever needed (it should not be for MVP), use the pre-declared optional seeded `rng` constructor parameter (above) — never `Random()` unseeded, and never add the parameter later as a breaking change (finding N6).
- Return `NoMatch` rather than inventing an outcome; the bounded fallback (ADR-0007) owns gaps.

## Alternatives Considered

### Alternative 1: LLM-driven resolution (model decides the outcome)

- **Description**: Let the model resolve intent → outcome directly.
- **Pros**: Maximum flexibility; less authored structure.
- **Cons**: Non-deterministic; unfair/unrepeatable; emits prose — every core anti-pattern.
- **Estimated Effort**: Lower.
- **Rejection Reason**: Violates Pillars 2 & 3 and the "never raw prose from the Resolver" rule.

### Alternative 2: Real-time tick-based world advancement

- **Description**: Advance patrols/timers on a wall clock.
- **Pros**: Familiar action-game model; emergent pressure.
- **Cons**: Introduces twitch pressure (anti-pillar); breaks determinism and per-beat replayability.
- **Estimated Effort**: Higher.
- **Rejection Reason**: The concept mandates state-machine, per-beat advancement (chess, not reflexes).

## Consequences

### Positive

- Deterministic, replayable, unit-testable heart of the game.
- Runs offline client/edge-side — the common case needs no round-trip.
- The decisive move is a first-class outcome of conditional-threshold evaluation.

### Negative

- All advancement logic must be expressible as per-beat state machines (no convenient timers).
- Reactive-threshold fixpoint requires acyclicity discipline (enforced by the Linter).

### Neutral

- World state and frozen scene are separate; the Resolver reads the scene, writes only new state.

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| Hidden nondeterminism (iteration order, clock) creeps in | Medium | High | Determinism property tests in CI; forbidden-pattern lint for `DateTime.now()`/`Random()` in `lib/resolver/` |
| Reactive thresholds form a cycle → infinite loop | Low | High | Linter rejects cyclic reactive thresholds; runtime fixpoint guard with max-iterations error |
| Tie-break ambiguity between paths | Medium | Medium | Total order on (priority, declaration index); covered by tests |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| CPU (per beat) | n/a | path eval + apply + reactive fixpoint, <1ms typical | 16.6ms frame |
| Memory | n/a | one new WorldState per beat (small) | 150MB ceiling |
| Network | n/a | ZERO on the hot path (offline-capable) | — |

## Migration Plan

Greenfield. Built first in the MVP (build order: Resolver/StateDelta → Translator → Scene Model → adventure).

**Rollback plan**: N/A foundational. Engine changes are made by superseding this ADR.

## Validation Criteria

- [ ] Determinism: same (WorldState, CapabilityVector) → identical ResolveResult across 1000 runs
- [ ] Conditional threshold collapse fires when the gating facet is set (decisive move)
- [ ] Reactive threshold (Alertness ≥ 60 → lockdown) fires deterministically after crossing
- [ ] Side-effect effects move meters in the same beat as the outcome (loud/quiet tradeoff)
- [ ] `NoMatch` is returned for unhandled intent (no invented outcome)
- [ ] No `DateTime.now()` / unseeded `Random` anywhere in `lib/resolver/`

## GDD Requirements Addressed

Foundational — no GDD requirement (no system GDDs yet). Sourced from
`design/gdd/game-concept.md` → pipeline stage 5, "Core resolution mechanics", "Foundational ADRs" #6.

| Source | Pillar / Concept | How This ADR Satisfies It |
|--------|------------------|--------------------------|
| `design/gdd/game-concept.md` | Pillar 1/2 (translation moment, authored consequence) | Deterministic match → StateDelta + authored narration |
| `design/gdd/game-concept.md` | Pillar 3 (decisive move, state-based) | Conditional-threshold collapse; per-beat advancement |
| `design/gdd/game-concept.md` | Anti-pillar (no twitch) | State-machine advancement, never a real-time clock |

**Enables**: router cascade fallback (ADR-0007), feedback loop gap observation (ADR-0008).

## Related

- ADR-0001 (StateDelta) — what the Resolver emits
- ADR-0003 (Scene Model) — what the Resolver evaluates
- ADR-0004 (Translator) — produces the CapabilityVector input
- ADR-0007 (Router cascade) — handles `NoMatch`
