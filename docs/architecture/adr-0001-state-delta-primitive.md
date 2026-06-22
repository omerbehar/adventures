# ADR-0001: StateDelta Primitive

## Status

Proposed

## Date

2026-06-21

## Last Verified

2026-06-21

## Decision Makers

technical-director, lead-programmer, flutter-specialist (authored via /architecture-decision, batch foundational set)

## Summary

Defines the single typed, validated, immutable state-change record that every
resolution path emits — the Resolver, the bounded AI fallback, and discovery moves
all produce a `StateDelta`, never generative prose. This is the foundational primitive
all other engine systems depend on.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Flutter 3.44.0 / Dart 3.12 |
| **Domain** | Core |
| **Knowledge Risk** | LOW — pure-Dart core; `sealed` classes and pattern matching are stable since Dart 3.0 (within training data) |
| **References Consulted** | `docs/engine-reference/flutter/current-best-practices.md` (Dart 3.x idioms, pure-Dart-core discipline) |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | None — plain Dart, fully unit-testable |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | None (root primitive) |
| **Enables** | ADR-0003 (Scene Model), ADR-0006 (Resolver), ADR-0007 (Router/fallback), ADR-0008 (Feedback loop) |
| **Owns Types** | `StateDelta`, `StateDeltaOp` (sealed), `OutcomeResult`, **`WorldState` / `WorldStateSnapshot`** (the mutable runtime-state container — added per TD-ADR review B1) |
| **Blocks** | MVP Resolver/StateDelta epic — cannot start until Accepted |
| **Ordering Note** | Must be the first ADR Accepted. Co-foundational with ADR-0002 (Ontology), which it references for typing. |

## Context

### Problem Statement

Every resolution in Adventures must produce a **consequential, persistent state change**
(Pillar 1, Pillar 2). The anti-pillar is explicit: the game is NOT a freeform-prose
generator. We need a single, typed, validated representation of "what changed" that
every system emits and the world applies — so that resolution is always auditable,
testable, deterministic, and free of throwaway AI prose. This must be decided first
because the Scene Model, Resolver, Translator fallback, and feedback loop all depend
on the shape of this primitive.

### Current State

No code exists. The concept doc names "StateDelta" as the foundational primitive but
does not specify its schema.

### Constraints

- **Pure-Dart core**: zero `package:flutter` imports — must run client/edge-side and be unit-testable headlessly.
- **Determinism**: applying the same `StateDelta` to the same world state must always yield the same next state.
- **Validation**: a `StateDelta` must be validated against the active Scene Model and the Capability Ontology *before* it is applied. Invalid deltas are rejected, never partially applied.
- **No prose**: narration is referenced by an authored key, never generated free text.

### Requirements

- Represent: facet flips (boolean/keyed), scalar meter adjustments, entity-property changes, node/graph transitions, facet reveals (discovery), and terminal outcomes (win/lose).
- Composable: a single player action may emit multiple ops (e.g. hit the goal **and** raise Alertness — the loud/quiet tradeoff).
- Serializable for persistence and for transmission from the service-side fallback to the client.
- Immutable once constructed; application is a pure function `(WorldState, StateDelta) -> WorldState`.

## Decision

A `StateDelta` is an **immutable, ordered list of typed `StateDeltaOp` values** plus an
optional authored `narrationKey`. Each op is a variant of a `sealed` class hierarchy so
that application and validation are compile-time exhaustive. Application is a pure
function with no side effects beyond producing a new `WorldState`.

### Architecture

```
Player action
     │
     ▼
[Translator] ──► CapabilityVector
     │
     ▼
[Resolver] ──► matches path ──► path.effect : StateDelta
     │                                  │
     │                                  ▼
     │                         [StateDeltaValidator]  ◄── Scene Model + Ontology
     │                                  │ (reject if invalid)
     ▼                                  ▼
[applyDelta(WorldState, StateDelta)] ──► WorldState'
                                          │
                                          ▼
                                  authored narrationKey ──► UI lookup (no generated prose)
```

### Key Interfaces

```dart
/// An immutable, validated description of how the world changes in one beat.
final class StateDelta {
  const StateDelta(this.ops, {this.narrationKey});
  final List<StateDeltaOp> ops;        // ordered; applied in sequence
  final String? narrationKey;          // authored narration reference, never generated text
}

/// Exhaustive, typed set of state-change operations.
sealed class StateDeltaOp { const StateDeltaOp(); }

final class SetFacet      extends StateDeltaOp { const SetFacet(this.key, this.value);     final String key; final bool value; }
final class AdjustMeter   extends StateDeltaOp { const AdjustMeter(this.meter, this.delta); final String meter; final int delta; }
final class SetEntityProp extends StateDeltaOp { const SetEntityProp(this.entityId, this.prop, this.value); final String entityId; final String prop; final Object value; }
final class TransitionNode extends StateDeltaOp { const TransitionNode(this.targetNodeId); final String targetNodeId; }
final class RevealFacet   extends StateDeltaOp { const RevealFacet(this.key);  final String key; }   // discovery move
final class Outcome       extends StateDeltaOp { const Outcome(this.result);   final OutcomeResult result; } // win / lose / continue

enum OutcomeResult { escape, win, lose, advance }

/// Pure application — no I/O, no clocks, no randomness.
WorldState applyDelta(WorldState state, StateDelta delta);

/// Validation against the active scene + ontology. Returns errors, empty = valid.
List<ValidationError> validateDelta(StateDelta delta, SceneModel scene, Ontology ontology);
```

### WorldState — the mutable runtime counterpart to the frozen SceneModel

`WorldState` is the **mutable, per-beat runtime state** that `applyDelta` transforms. It is
defined here because it is the codomain of `applyDelta` and the single value every system
threads through resolution. It is deliberately separate from `SceneModel` (ADR-0003), which
is frozen/immutable — `WorldState` holds only what changes during play.

```dart
/// All mutable runtime state for an in-progress adventure. Immutable value object —
/// applyDelta returns a NEW WorldState; nothing mutates in place.
final class WorldState {
  const WorldState({
    required this.currentNodeId,     // which SceneModel node is active
    required this.meters,            // current meter values (e.g. {alertness: 40})
    required this.facets,            // set facets (keyed booleans currently true)
    required this.revealedFacets,    // facets surfaced by discovery moves (RevealFacet)
    required this.entityProps,       // per-entity property overrides vs the frozen scene
    required this.beatCursors,       // per-beat state-machine positions (patrols/timers)
  });
  final String currentNodeId;
  final Map<String, int> meters;
  final Set<FacetKey> facets;
  final Set<FacetKey> revealedFacets;
  final Map<String, Map<String, Object>> entityProps;
  final Map<String, int> beatCursors;   // advanced per move, NEVER by a wall clock (ADR-0006)

  WorldStateSnapshot snapshot();        // immutable capture for feedback (ADR-0008)
}

/// A serializable, read-only capture of WorldState at a beat (used by ADR-0008).
typedef WorldStateSnapshot = WorldState; // snapshot is structurally a frozen WorldState
```

> **Single source of outcome truth**: `OutcomeResult` is defined here and is the *only*
> place an outcome is named. The Resolver (ADR-0006) must derive its reported outcome
> **from the applied `Outcome` op**, never compute a parallel one.

### Implementation Guidelines

- Place in `lib/game/state_delta.dart` (pure Dart). No Flutter imports.
- `applyDelta` must be a pure function: no `DateTime.now()`, no unseeded `Random`, no file/network I/O.
- Validate **before** apply at every call site; never apply an unvalidated delta.
- The bounded AI fallback (ADR-0007) must emit a `StateDelta` that passes `validateDelta` within creator-declared bounds — its output is structurally identical to an authored path's effect.
- Narration is resolved by `narrationKey` lookup in authored content; the core never holds generated prose.
- **`const` caveat**: the `const` constructors here are only usable as compile-time `const` when callers pass `const`/literal collections. Treat them as ordinary constructors for runtime-built deltas — do not assume `const StateDelta(someVariableList)` compiles.
- **`SetEntityProp.value` typing**: `Object` loses type info across JSON round-trip. Implementation should narrow to a discriminated `PropValue` (String | int | bool | double) so the round-trip validation criterion holds.

## Alternatives Considered

### Alternative 1: Free-form event objects / prose + structured patch

- **Description**: Let resolution emit a prose string plus a loosely-structured JSON patch.
- **Pros**: Flexible; easy for an LLM to produce.
- **Cons**: Violates the anti-pillar (prose generator); non-deterministic; unvalidatable; untestable.
- **Estimated Effort**: Lower upfront.
- **Rejection Reason**: Directly contradicts Pillars 1 & 2 and the "never raw prose from the Resolver" forbidden pattern.

### Alternative 2: Direct mutation of WorldState by each system

- **Description**: Systems mutate shared world state in place rather than emitting a delta.
- **Pros**: Simple, fewer allocations.
- **Cons**: No audit trail; impossible to validate-before-apply; breaks determinism testing; the fallback could write anything.
- **Estimated Effort**: Similar.
- **Rejection Reason**: Loses the single validated choke point that makes resolution provable and the fallback safe.

## Consequences

### Positive

- One validated choke point for all state change — auditable, testable, deterministic.
- The bounded AI fallback is structurally constrained to the same primitive as authored content.
- Trivially serializable for persistence and service→client transmission.

### Negative

- Every new kind of state change requires a new `StateDeltaOp` variant (and updates to apply/validate switches).
- Slight allocation overhead vs. in-place mutation (negligible for a text game).

### Neutral

- Narration indirection (keys, not strings) requires an authored-content lookup layer in the UI.

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| Op set proves too coarse for a future mechanic | Medium | Low | `sealed` hierarchy makes adding a variant safe and exhaustive-checked at compile time |
| Validation drifts from apply semantics | Low | High | Co-locate apply + validate; property-test that valid deltas always apply cleanly |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| CPU (per beat) | n/a | <0.1ms (list of small ops) | 16.6ms frame |
| Memory | n/a | negligible per delta | 150MB ceiling |
| Network | n/a | tiny JSON when fallback transmits a delta | n/a |

## Migration Plan

Greenfield — no migration. This is the first primitive implemented.

**Rollback plan**: N/A (foundational). If the op model proves wrong, supersede with a new ADR before the Resolver is built on it.

## Validation Criteria

- [ ] `applyDelta` is a pure function (property test: same inputs → identical output, 1000 runs)
- [ ] `validateDelta` rejects deltas referencing unknown facets/meters/entities
- [ ] A round-trip serialize→deserialize→apply equals apply on the original
- [ ] A bounded-fallback-shaped delta passes validation only within declared bounds

## GDD Requirements Addressed

Foundational — no GDD requirement (no system GDDs authored yet). Sourced from
`design/gdd/game-concept.md` → "Foundational ADRs" #1 and the Pillars.

| Source | Pillar / Concept | How This ADR Satisfies It |
|--------|------------------|--------------------------|
| `design/gdd/game-concept.md` | Pillar 2 ("even the AI fallback emits a validated state change, never prose") | Defines that single validated primitive |
| `design/gdd/game-concept.md` | "Side-effect StateDeltas" (loud/quiet tradeoff) | Ops are a composable list — one action can move multiple facets/meters |

**Enables**: Scene Model (ADR-0003), Resolver (ADR-0006), bounded fallback (ADR-0007), feedback loop (ADR-0008).

## Related

- ADR-0002 (Capability Ontology) — supplies the typed vocabulary deltas are validated against
- ADR-0003 (Scene Model) — defines the facets/meters/entities a delta may reference
- ADR-0006 (Resolver) — the primary producer of StateDeltas
