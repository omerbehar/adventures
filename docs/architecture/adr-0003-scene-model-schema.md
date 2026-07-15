# ADR-0003: Scene Model Schema

## Status

Accepted

## Date

2026-06-21

## Last Verified

2026-06-22

## Revision History

- **R1 (2026-06-22)** — engine-review refinements: `Entity.props` uses `PropValue` (not `Object`);
  `ThresholdExpr` acyclicity/depth gate (finding N7); macro-JSON demoted to aspirational (N1).
- **R2 (2026-06-22)** — extended the `ThresholdExpr` form set (added `WorldFacet`, `Invokes`,
  `AllOf`, `AnyOf`, `Not` alongside `AxisAtLeast`, `IfFacet`) so the decisive-move collapse keys
  on the reliably-classified facet, not a noisy scalar axis. Adds the `vector.invokedFacets`
  dependency on ADR-0004. Ratifies `docs/architecture/scene-decomposition-spec.md` §3/§7; the
  Scene Linter (ADR-0005) enforces the corresponding rules.

## Decision Makers

technical-director, game-designer, flutter-specialist (authored via /architecture-decision, batch foundational set)

## Summary

Defines the data schema for a scene: entities with typed properties, solution paths as
conditional thresholds over the Capability Ontology, scalar meters, reactive thresholds,
and scene-graph composition. This JSON-serializable schema IS the creator-facing primitive
(Pillar 4) — the same format players' authored adventures use, even though the Compiler
and toolkit ship later.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Flutter 3.44.0 / Dart 3.12 |
| **Domain** | Core |
| **Knowledge Risk** | LOW — pure-Dart immutable models + JSON (de)serialization |
| **References Consulted** | `docs/engine-reference/flutter/current-best-practices.md` (sealed types, records, pure-Dart-core), `deprecated-apis.md` |
| **Post-Cutoff APIs Used** | None (manual JSON or codegen decided at implementation time) |
| **Verification Required** | **MVP uses hand-rolled `fromJson`/`toJson`** (zero codegen, zero package risk). Macro-based JSON is **aspirational only**: Dart 3.12 stabilized the *macros language feature*, but a production-ready `@JsonSerializable`-via-macros *package* is not confirmed available — adopting one requires explicit technical-director package approval first (review finding N1). Confirm null-safety + 3.12 compatibility either way |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (StateDelta — path effects), ADR-0002 (Ontology — threshold axes + facet keys) |
| **Enables** | ADR-0005 (Compiler target), ADR-0006 (Resolver input), ADR-0008 (Compiler candidate paths) |
| **Blocks** | MVP Scene Model epic; the magistrate prototype scene authoring |
| **Ordering Note** | Author after ADR-0001 and ADR-0002 are Accepted. |

## Context

### Problem Statement

A scene must be authored as a **model of possibility**, not an enumerated decision tree
(Pillar 6, anti-pillar "NOT an enumerated branching script"). We need a concrete schema
that expresses conditional thresholds, scalar world-state meters, reactive transitions,
discovery moves, and graph composition — and that is frozen → canonical → deterministic
after authoring. Because this format is *also* the creator-facing primitive (Pillar 4),
it must be decided before any scene (including the prototype) is authored.

### Current State

No code. The concept's "Core resolution mechanics" section enumerates the required
features with a worked example (the prison cell) but no schema.

### Constraints

- **Format = creator primitive** (Pillar 4): must be authorable by humans (JSON), not a code-only structure.
- **Frozen after authoring**: once approved, a scene is canonical, immutable, deterministic at runtime.
- **Threshold vocabulary** must be exactly the Capability Ontology (ADR-0002); path effects must be `StateDelta`s (ADR-0001).
- Must support the worked example (prison cell) and the social example (magistrate) without new axes.

### Requirements

- **Entities** with typed properties (`stone_wall {breach: Force ≥ 20}`, `window {aperture 30×30 → passable_if Size ≤ 30}`).
- **Solution paths** as conditional thresholds whose required magnitude changes with facets (Social-persuasion ≥ 35, reduced to 20 if `knows_vault_fears_scandal`).
- **Scalar meters** (e.g. `Alertness 0–100`), not just booleans.
- **Reactive thresholds** — world-state crossing a line fires an authored autonomous transition.
- **Discovery moves** — paths that reveal facets rather than progress (emit `RevealFacet`).
- **Side-effect effects** — a path can hit the goal *and* move a meter.
- **Scene-graph composition** — an adventure is a graph of nodes sharing global meters/facets; an encounter is one node.

### Requirements (performance)

- Deserialization + validation of one scene node must be well under one frame's worth of work on first load; no per-beat allocation of the schema.

## Decision

A **`SceneModel`** is an immutable, JSON-serializable graph node containing: declared
facets, declared meters, entities, and solution paths. An **adventure** is a `SceneGraph`
of `SceneModel` nodes sharing global meters/facets. Each path carries a **conditional
threshold expression** over the Ontology and an **effect `StateDelta`**; reactive
thresholds are meter-watchers that fire authored `StateDelta`s when crossed.

### Architecture

```
SceneGraph (an adventure)
 ├── globalMeters:  { alertness: 0..100, ... }      shared across nodes
 ├── globalFacets:  { power_cut, ... }              shared across nodes
 └── nodes: [ SceneModel, SceneModel, ... ]
                 │
                 ▼
            SceneModel (an encounter / node)
             ├── declaredFacets:  [ knows_password, vault_fears_scandal, ... ]
             ├── localMeters:     { ... }
             ├── entities:        [ Entity{id, type, props{Force:25, hostile:true}}, ... ]
             ├── paths:           [ SolutionPath, ... ]
             └── reactiveThresholds: [ MeterWatcher{ alertness >= 60 -> StateDelta }, ... ]

            SolutionPath
             ├── requirement:  ThresholdExpr   (conditional on facets; over Ontology axes)
             ├── target:       entityId | self
             ├── effect:       StateDelta       (may include Outcome + side-effect meters)
             └── kind:         progress | discovery
```

### Key Interfaces

```dart
final class SceneGraph {
  const SceneGraph({required this.id, required this.nodes, required this.globalMeters, required this.globalFacets, required this.entryNodeId});
  final String id;
  final Map<String, SceneModel> nodes;
  final Map<String, MeterSpec> globalMeters;
  final Set<FacetKey> globalFacets;
  final String entryNodeId;
}

final class SceneModel {
  const SceneModel({required this.id, required this.entities, required this.paths,
                    required this.declaredFacets, required this.localMeters,
                    required this.reactiveThresholds, required this.fallbackBounds});
  final String id;
  final List<Entity> entities;
  final List<SolutionPath> paths;
  final Set<FacetKey> declaredFacets;      // ADR-0002: scene owns its facet namespace
  final Map<String, MeterSpec> localMeters;
  final List<ReactiveThreshold> reactiveThresholds;
  final FallbackBounds fallbackBounds;     // creator-declared envelope for Tier-3 (ADR-0007)

  factory SceneModel.fromJson(Map<String, Object?> json);  // creator-facing format (P4)
  Map<String, Object?> toJson();
}

/// The "creator bounds" referenced by ADR-0001/0007/0008: the declared envelope a
/// bounded AI fallback (Tier 3) may not exceed. A fallback StateDelta is valid only if
/// every op stays within these bounds (e.g. may only touch declared facets/meters,
/// may only move a meter by <= maxMeterDelta, may not emit a terminal Outcome unless
/// allowOutcome is set). This gives validateDelta(...) a concrete contract for "bounds".
final class FallbackBounds {
  const FallbackBounds({required this.touchableFacets, required this.touchableMeters,
                        required this.maxMeterDelta, required this.allowOutcome});
  final Set<FacetKey> touchableFacets;
  final Set<String> touchableMeters;
  final int maxMeterDelta;
  final bool allowOutcome;
}

final class Entity {
  const Entity({required this.id, required this.type, required this.props});
  // PropValue (sealed union, ADR-0001), NOT Object — keeps JSON round-trip type-safe (N4).
  final String id; final String type; final Map<String, PropValue> props;
}

final class SolutionPath {
  const SolutionPath({required this.requirement, required this.target, required this.effect, required this.kind});
  final ThresholdExpr requirement;   // conditional on facets
  final String target;               // entityId or 'self'
  final StateDelta effect;           // ADR-0001
  final PathKind kind;               // progress | discovery
}

enum PathKind { progress, discovery }

/// Conditional threshold: a sealed tree evaluated to bool against the CapabilityVector
/// (ADR-0004) + the current WorldState.facets (ADR-0001). The decisive move (Pillar 3) is
/// the point where a facet flips the tree from a hard requirement to a trivial one.
/// Extended 2026-06-22 (Revision 2) per docs/architecture/scene-decomposition-spec.md §3 —
/// the two original variants proved insufficient once the intent-translation prototype showed
/// the classifier reliably names WHICH LEVERAGE is invoked but is noisy about WHICH AXIS.
/// The collapse must therefore key on a facet, not a specific axis magnitude — hence `Invokes`.
sealed class ThresholdExpr { const ThresholdExpr(); }
final class AxisAtLeast extends ThresholdExpr {            // vector magnitude on an axis >= mag
  const AxisAtLeast(this.axis, this.magnitude); final CapabilityAxis axis; final int magnitude; }
final class IfFacet extends ThresholdExpr {               // if world facet set -> thenExpr else elseExpr
  const IfFacet(this.facet, this.thenExpr, this.elseExpr); final FacetKey facet; final ThresholdExpr thenExpr; final ThresholdExpr elseExpr; }
final class WorldFacet extends ThresholdExpr {            // world facet is currently set (a gate)
  const WorldFacet(this.facet); final FacetKey facet; }
final class Invokes extends ThresholdExpr {               // action invoked this facet (vector.invokedFacets, ADR-0004)
  const Invokes(this.facet); final FacetKey facet; }      // THE decisive-move key — stable classifier signal
final class AllOf extends ThresholdExpr { const AllOf(this.parts); final List<ThresholdExpr> parts; } // conjunction
final class AnyOf extends ThresholdExpr { const AnyOf(this.parts); final List<ThresholdExpr> parts; } // disjunction
final class Not   extends ThresholdExpr { const Not(this.part);    final ThresholdExpr part; }

final class ReactiveThreshold {                            // Alertness >= 60 -> lockdown
  const ReactiveThreshold({required this.meter, required this.atLeast, required this.effect});
  final String meter; final int atLeast; final StateDelta effect;
}

final class MeterSpec { const MeterSpec({required this.min, required this.max, required this.initial}); final int min, max, initial; }
```

### Implementation Guidelines

- Place in `lib/scene/` (pure Dart). No Flutter imports.
- JSON is the source-of-truth authoring format (`assets/scenes/*.json`); validate against a schema on load and reject malformed scenes (do not silently coerce).
- A scene is loaded and validated once, then treated as immutable/frozen at runtime — no per-beat mutation of the model (world *state* lives separately in `WorldState`, defined in ADR-0001).
- `ThresholdExpr` is a `sealed` tree so the Resolver's evaluation (ADR-0006) is exhaustive. The decisive move (Pillar 3) is mechanically a facet flip that collapses a hard requirement to a trivial one. **Prefer keying the collapse on `Invokes(facet)` (and/or `WorldFacet(facet)`) rather than on a specific axis magnitude** — the classifier reliably names the invoked leverage but is noisy about the scalar axis (intent-translation prototype, 2026-06-22). The canonical form is `AnyOf([ AllOf([WorldFacet(x), Invokes(x), AxisAtLeast(axis, trivialMag)]), AxisAtLeast(axis, bruteMag) ])`.
- **`Invokes` requires `vector.invokedFacets`**: the Resolver reads which facets Stage A tagged from the `CapabilityVector` (ADR-0004 surfaces `Classification.facetsInvoked` as `invokedFacets`). `WorldFacet` reads `WorldState.facets` (ADR-0001).
- **`ThresholdExpr` acyclicity / depth bound (review finding N7)**: the tree is recursive (`IfFacet.thenExpr`/`elseExpr`, `AllOf`/`AnyOf.parts`, `Not.part` are themselves `ThresholdExpr`). Schema validation on load MUST enforce a maximum tree depth and reject any structure that cannot be built as a finite acyclic tree, so a malformed scene cannot drive the Resolver into unbounded recursion / stack overflow. The Scene Linter (ADR-0005, rule L-07) carries the same rule for compiled scenes. (This mirrors the acyclicity guarantee ADR-0006 already requires for reactive thresholds.)
- **JSON (de)serialization**: MVP hand-rolls `fromJson`/`toJson` — no codegen, no package dependency. Macro-based codegen is aspirational and gated on technical-director package approval (see Engine Compatibility, finding N1).

## Alternatives Considered

### Alternative 1: Branching decision tree / node-link graph of explicit choices

- **Description**: Author each outcome as an explicit branch.
- **Pros**: Easy to reason about for small scenes; familiar IF tooling.
- **Cons**: Enumerates outcomes — directly the anti-pillar; cannot answer arbitrary intent.
- **Estimated Effort**: Lower for tiny scenes, explodes combinatorially.
- **Rejection Reason**: Violates Pillar 6 / the "NOT an enumerated branching script" anti-pillar.

### Alternative 2: Pure rules-as-code (scenes authored in Dart)

- **Description**: Express scenes as Dart classes/functions.
- **Pros**: Maximum expressiveness; no schema limits.
- **Cons**: Not a creator-facing primitive (P4 broken); not safely user-authored; not data-frozen.
- **Estimated Effort**: Lower initially.
- **Rejection Reason**: The format must be the shared player/creator primitive — data, not code.

## Consequences

### Positive

- One schema serves runtime, the Compiler target, and the creator toolkit (P4 parity).
- Conditional thresholds give the decisive move a precise mechanical definition.
- Scene-graph composition reuses the same threshold machinery at encounter and adventure scale.

### Negative

- A JSON schema is more verbose for authors than code; mitigated later by the Compiler (ADR-0005).
- `ThresholdExpr` expressiveness is bounded by the sealed variant set (deliberate).

### Neutral

- World state (mutable) and Scene Model (frozen) are separate concerns and must be kept distinct.

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| Schema can't express a needed mechanic | Medium | Medium | Validate against prison + magistrate + heist examples before freezing the schema |
| Hand-authoring JSON is error-prone | High | Low | Deterministic Scene Linter (ADR-0005) + schema validation on load |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| CPU (scene load) | n/a | one-time parse+validate, <few ms | 16.6ms frame (not per-beat) |
| CPU (per beat) | n/a | read-only traversal, <0.5ms | 16.6ms frame |
| Memory | n/a | one frozen model per active node | 150MB ceiling |

## Migration Plan

Greenfield. The MVP hand-authors Scene Models in this exact format; the Compiler (ADR-0005) later *targets* this schema without changing it.

**Rollback plan**: schema changes are versioned; bump a `schemaVersion` field and migrate authored scenes deliberately.

## Validation Criteria

- [ ] The prison-cell and magistrate examples from the concept serialize to valid `SceneModel` JSON and load
- [ ] A conditional threshold (`IfFacet`) correctly collapses a hard requirement when its facet is set
- [ ] Reactive thresholds fire their `StateDelta` exactly once when a meter crosses
- [ ] Loading malformed JSON is rejected with actionable errors, never silently coerced
- [ ] A `ThresholdExpr` exceeding the max depth (or otherwise non-finite) is rejected on load (N7)
- [ ] `Entity.props` round-trips through JSON with type preserved via `PropValue` (no `Object`) (N4)
- [ ] Discovery paths emit `RevealFacet` and do not advance to an outcome

## GDD Requirements Addressed

Foundational — no GDD requirement (no system GDDs yet). Sourced from
`design/gdd/game-concept.md` → "The Scene Model", "Core resolution mechanics", "Foundational ADRs" #3.

| Source | Pillar / Concept | How This ADR Satisfies It |
|--------|------------------|--------------------------|
| `design/gdd/game-concept.md` | Pillar 6 (model, not script) | Conditional-threshold schema, not a branch tree |
| `design/gdd/game-concept.md` | Pillar 4 (creator parity) | JSON format IS the creator primitive |
| `design/gdd/game-concept.md` | Pillar 3 (decisive move) | `IfFacet` collapse is the decisive move's mechanical form |

**Enables**: Compiler target (ADR-0005), Resolver input (ADR-0006), feedback candidate paths (ADR-0008).

## Related

- ADR-0001 (StateDelta) — path effects and reactive effects are StateDeltas
- ADR-0002 (Ontology) — thresholds reference axes; scenes declare facets
- ADR-0006 (Resolver) — consumes this schema each beat
