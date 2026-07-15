# Scene Decomposition Spec

> **Status:** Draft v0.1 · **Date:** 2026-06-22
> **Owns:** the authoring-direction contract — how a scene is dismantled into a typed Scene Model,
> what a valid Scene Model *is*, and what the deterministic Linter checks.
> **Elaborates:** ADR-0003 (Scene Model schema), ADR-0005 (Compiler + grounding tables + Linter).
> **Consumes/affects:** ADR-0001 (StateDelta/PropValue), ADR-0002 (Ontology), ADR-0004
> (CapabilityVector — see §7 refinement), ADR-0006 (Resolver evaluation order).
>
> ⚠️ **ADR impact:** §3 extends `ThresholdExpr` beyond ADR-0003's two accepted variants
> (`AxisAtLeast`, `IfFacet`). Adding variants is a schema change — before this spec is
> ratified, ADR-0003 must be updated/superseded to record the extended form set. Flagged
> inline as **[ADR-0003 EXT]**.

---

## 1. Scope

This is the **authoring pipeline** (Pillar 6): the mirror of the runtime Translator. The
Translator maps *player words → nearest authored outcome*; decomposition maps *a designer's
scene → the space of possible outcomes*.

```
seed prose ─▶ COMPILER ─▶ candidate Scene Model ─▶ LINTER ─▶ bulk-approve ─▶ FREEZE ─▶ canonical
 (human)      (Opus, offline,     (this spec, §2-3)  (§4-5,        (designer)   (immutable)   (Resolver
              grounded §4)                            deterministic)                            input)
```

- The **Compiler** (ADR-0005) is deferred to Vertical Slice; MVP hand-authors the Scene Model JSON.
- The **Linter** (§5) is MVP: pure Dart, deterministic, hardens hand-authored scenes in CI now.
- "Dismantling a scene" = producing a Scene Model (§2) that passes the Linter (§5). The Compiler
  is an optional generative front-end that targets the *same* schema — nothing downstream knows
  whether a human or the Compiler emitted it.

The output is **data, not code** (Pillar 4): the same JSON is engine-consumable, creator-authorable,
and LLM-emittable.

---

## 2. The Scene Model schema (exact)

Pure Dart, `lib/scene/`, zero Flutter imports. JSON is the source of truth
(`assets/scenes/*.json`). Frozen/immutable at runtime; world *state* lives separately in
`WorldState` (ADR-0001). `schemaVersion` gates migration.

### 2.1 Graph and node

```dart
final class SceneGraph {              // an adventure
  const SceneGraph({required this.id, required this.schemaVersion, required this.nodes,
                    required this.globalMeters, required this.globalFacets, required this.entryNodeId});
  final String id;
  final int schemaVersion;
  final Map<String, SceneModel> nodes;
  final Map<String, MeterSpec> globalMeters;   // shared across nodes
  final Set<FacetKey> globalFacets;            // shared across nodes
  final String entryNodeId;
}

final class SceneModel {              // an encounter / node
  const SceneModel({required this.id, required this.entities, required this.paths,
                    required this.declaredFacets, required this.localMeters,
                    required this.reactiveThresholds, required this.fallbackBounds,
                    required this.narrationKeys});
  final String id;
  final List<Entity> entities;
  final List<SolutionPath> paths;
  final Set<FacetKey> declaredFacets;          // scene owns its facet namespace (ADR-0002)
  final Map<String, MeterSpec> localMeters;
  final List<ReactiveThreshold> reactiveThresholds;
  final FallbackBounds fallbackBounds;         // Tier-3 envelope (ADR-0003/0007)
  final Set<String> narrationKeys;             // every authored key this scene may emit
}
```

### 2.2 Leaf types

```dart
typedef FacetKey = String;                     // snake_case, scene-local (ADR-0002)

final class MeterSpec { const MeterSpec({required this.min, required this.max, required this.initial}); final int min, max, initial; }

final class Entity {
  const Entity({required this.id, required this.type, required this.props});
  final String id; final String type;
  final Map<String, PropValue> props;          // PropValue (ADR-0001), NEVER Object
}

// PropValue — first-class sealed union (ADR-0001, review finding N4). Survives JSON round-trip.
sealed class PropValue { const PropValue(); }
final class PropString extends PropValue { const PropString(this.v); final String v; }
final class PropInt    extends PropValue { const PropInt(this.v);    final int v; }
final class PropBool   extends PropValue { const PropBool(this.v);   final bool v; }
final class PropDouble extends PropValue { const PropDouble(this.v); final double v; }
```

### 2.3 Solution paths

```dart
enum PathKind { progress, discovery }

final class SolutionPath {
  const SolutionPath({required this.id, required this.requirement, required this.target,
                      required this.effect, required this.kind, required this.priority});
  final String id;
  final ThresholdExpr requirement;             // §3 — evaluated to bool by the Resolver
  final String target;                         // entityId or 'self'
  final StateDelta effect;                     // ADR-0001 (may include Outcome + side-effect meters)
  final PathKind kind;                         // progress | discovery
  final int priority;                          // authored total order (ADR-0006); stable tiebreak = declaration index
}

final class ReactiveThreshold {                // meter-watcher: e.g. suspicion >= 60 -> lockdown
  const ReactiveThreshold({required this.id, required this.meter, required this.atLeast, required this.effect});
  final String id; final String meter; final int atLeast; final StateDelta effect;
}

// The creator-declared envelope a Tier-3 fallback may not exceed (ADR-0003/0007).
final class FallbackBounds {
  const FallbackBounds({required this.touchableFacets, required this.touchableMeters,
                        required this.maxMeterDelta, required this.allowOutcome});
  final Set<FacetKey> touchableFacets;
  final Set<String> touchableMeters;
  final int maxMeterDelta;
  final bool allowOutcome;                      // usually false: fallback may nudge, not declare win/lose
}
```

---

## 3. The `ThresholdExpr` form set  **[ADR-0003 EXT]**

A `ThresholdExpr` is a `sealed` tree evaluated to `bool` against the `CapabilityVector` and the
current `WorldState.facets`. The **decisive move** (Pillar 3) is mechanically the point where a
facet flips the tree from a hard requirement to a trivial one.

> **PIVOT-driven change.** The prototype showed the LLM reliably identifies *which leverage a
> player invokes* (`invokesScandalFacet` was 25/25 stable) but is noisy about *which scalar axis*
> the action is. So the collapse must key on **facet invocation**, not on a specific axis
> magnitude. That requires (a) the `CapabilityVector` to carry `invokedFacets` (see §7), and
> (b) an `Invokes(...)` predicate below.

### 3.1 Forms

| Form | Evaluates true when | Status |
|---|---|---|
| `AxisAtLeast(axis, mag)` | `vector.magnitudes[axis.key] >= mag` | ADR-0003 (accepted) |
| `IfFacet(facet, thenE, elseE)` | if `world.facets` has `facet` → eval `thenE`, else `elseE` | ADR-0003 (accepted) |
| `WorldFacet(facet)` | `world.facets` contains `facet` (a gate) | **EXT** |
| `Invokes(facet)` | `vector.invokedFacets` contains `facet` (Stage A named it) | **EXT** — the PIVOT fix |
| `AllOf([...])` | every child is true (conjunction) | **EXT** |
| `AnyOf([...])` | at least one child is true (disjunction) | **EXT** |
| `Not(expr)` | child is false | **EXT** |

```dart
sealed class ThresholdExpr { const ThresholdExpr(); }
final class AxisAtLeast extends ThresholdExpr { const AxisAtLeast(this.axis, this.magnitude); final CapabilityAxis axis; final int magnitude; }
final class IfFacet     extends ThresholdExpr { const IfFacet(this.facet, this.thenExpr, this.elseExpr); final FacetKey facet; final ThresholdExpr thenExpr, elseExpr; }
final class WorldFacet  extends ThresholdExpr { const WorldFacet(this.facet); final FacetKey facet; }
final class Invokes     extends ThresholdExpr { const Invokes(this.facet); final FacetKey facet; }
final class AllOf       extends ThresholdExpr { const AllOf(this.parts); final List<ThresholdExpr> parts; }
final class AnyOf       extends ThresholdExpr { const AnyOf(this.parts); final List<ThresholdExpr> parts; }
final class Not         extends ThresholdExpr { const Not(this.part); final ThresholdExpr part; }
```

### 3.2 The decisive move, expressed two ways

The magistrate's persuade path — the collapse fires when the scandal is **known** AND the
action **invokes** it:

```
// Readable IfFacet form (collapse gated on a compound predicate):
requirement = AnyOf([
  AllOf([ WorldFacet(scandal_known), Invokes(scandal), AxisAtLeast(social.persuasion, 15) ]),  // decisive: trivial
  AxisAtLeast(social.persuasion, 35),                                                           // brute: hard
])
```

This keys the collapse on the **stably-detected facet**, not on the noisy axis label — the
whole point of the PIVOT. `Invokes(scandal)` is true whenever Stage A tagged the action with the
scandal facet, regardless of whether it also (mis)labelled the axis as intimidation vs persuasion.

### 3.3 Evaluation rules (Resolver, ADR-0006)

- Exhaustive `switch` over the sealed tree; **recursion is bounded** — see lint rule L-07.
- Total order on paths: `(priority, declaration index)`; never rely on map/set iteration order.
- Derive the reported outcome **only** from the applied `Outcome` op (ADR-0001); no parallel outcome.

---

## 4. Grounding-table shape (ADR-0005)

Canonical bounds that (a) constrain what the Compiler may produce and (b) give the Linter its
"expected band" reference. Versioned artifact; bumping it re-lints affected scenes.

```dart
final class GroundingTables {
  const GroundingTables(this.version, this.materials, this.archetypes, this.thresholdNorms);
  final String version;
  final Map<String, MaterialSpec> materials;     // stone_wall -> default Force-to-breach band
  final Map<String, EntityArchetype> archetypes; // guard -> default props
  final ThresholdNorms thresholdNorms;           // expected magnitude bands per axis/difficulty
}

final class MaterialSpec  { const MaterialSpec({required this.axis, required this.band}); final CapabilityAxis axis; final (int lo, int hi) band; }
final class EntityArchetype { const EntityArchetype({required this.type, required this.defaultProps}); final String type; final Map<String, PropValue> defaultProps; }
final class ThresholdNorms {
  const ThresholdNorms(this.bands);
  // (axisKey, difficulty) -> allowed [lo, hi] magnitude band. Difficulty is an authored enum.
  final Map<(CapabilityAxisKey axis, Difficulty diff), (int lo, int hi)> bands;
}
enum Difficulty { trivial, easy, standard, hard, extreme }
```

Example rows (illustrative, tune later):

| axis / channel | trivial | easy | standard | hard | extreme |
|---|---|---|---|---|---|
| force | ≤10 | 11–20 | 21–35 | 36–55 | 56–80 |
| social.persuasion | ≤12 | 13–20 | 21–35 | 36–50 | 51–75 |

The **collapsed** decisive-move threshold should land in *trivial/easy*; the **brute** threshold
in *hard/extreme*. That gap is what makes the decisive move feel decisive — and the Linter can
check it (L-04).

---

## 5. Lint rules (deterministic, pure Dart)

`SceneLinter.lint(scene) -> LintReport` — same scene → identical report, always. `passes` iff no
`error`-severity findings. The Linter is the line of defense that makes "bulk-approve" real.

| ID | Severity | Catches | Rationale |
|---|---|---|---|
| **L-01** | error | Path/reactive references a facet not in `declaredFacets ∪ globalFacets` | Undeclared facet → runtime miss (ADR-0002) |
| **L-02** | error | Threshold references a non-canonical axis (would-be new axis) | No runtime axis coinage (ADR-0002 forbidden pattern) |
| **L-03** | error | `PropValue`/prop type mismatch, or any `Object`-typed value | JSON round-trip type safety (N4) |
| **L-04** | warning | Threshold magnitude outside the grounding band for its declared difficulty | Unbalanced threshold; the false-economy guard (ADR-0005) |
| **L-05** | error | Orphaned/unreachable path: `target` entity missing, or no vector in-range could satisfy `requirement` | Dead content |
| **L-06** | error | Discovery path emits an `Outcome`, OR progress path never can | `PathKind` contract (ADR-0003) |
| **L-07** | error | `ThresholdExpr` exceeds max depth or is non-finite | No unbounded Resolver recursion (N7) |
| **L-08** | error | Reactive thresholds form a cycle (delta → meter → reactive → …) | Resolver fixpoint must terminate (ADR-0006) |
| **L-09** | error | Reactive watches an undeclared meter, or meter delta exits `[min,max]` unhandled | Meter integrity |
| **L-10** | error | `effect` references a `narrationKey` not in `SceneModel.narrationKeys` | UI lookup must resolve; never generated prose (Pillar 2) |
| **L-11** | error | `FallbackBounds` touchable facets/meters ⊄ declared; `maxMeterDelta` out of meter range; `allowOutcome` on a scene with no non-terminal fallback | Tier-3 envelope sanity (ADR-0007) |
| **L-12** | warning | Two paths share `priority` (tie relies on declaration index) | Determinism clarity (ADR-0006) |
| **L-13** | error | No progress path can reach a terminal `Outcome` | Scene is unwinnable |
| **L-14** | promotionHint | A facet behaves like a scalar axis across scenes | Ontology promotion candidate (ADR-0002) |
| **L-15** | warning | A decisive-move collapse and its brute path are in the *same* difficulty band | Decisive move has no leverage (Pillar 3 — "if the only path is brute magnitude, the encounter is under-designed") |

```dart
final class LintReport { const LintReport(this.findings); final List<LintFinding> findings;
  bool get passes => findings.every((f) => f.severity != LintSeverity.error); }
final class LintFinding { const LintFinding(this.ruleId, this.severity, this.where, this.message);
  final String ruleId; final LintSeverity severity; final String where; final String message; }
enum LintSeverity { error, warning, promotionHint }
```

L-15 is the design-teeth rule the prototype motivated: it fails a scene whose "decisive move"
doesn't actually collapse a hard threshold to an easy one.

---

## 6. Worked dismantling — the magistrate (canonical JSON)

```jsonc
{
  "schemaVersion": 1,
  "id": "magistrate",
  "declaredFacets": ["scandal_known"],
  "localMeters": { "suspicion": { "min": 0, "max": 100, "initial": 0 } },
  "narrationKeys": ["acquit", "acquitLoud", "reveal", "lockdown", "nudge"],
  "entities": [
    { "id": "vorne", "type": "magistrate",
      "props": { "hostile": {"bool": true}, "persuadeBase": {"int": 35}, "intimidate": {"int": 40} } }
  ],
  "paths": [
    { "id": "discover", "kind": "discovery", "target": "vorne", "priority": 30,
      "requirement": { "AllOf": [ {"Not": {"WorldFacet": "scandal_known"}},
                                  {"AxisAtLeast": ["insight", 25]} ] },
      "effect": { "ops": [ {"RevealFacet": "scandal_known"} ], "narrationKey": "reveal" } },

    { "id": "persuade", "kind": "progress", "target": "vorne", "priority": 20,
      "requirement": { "AnyOf": [
        { "AllOf": [ {"WorldFacet": "scandal_known"}, {"Invokes": "scandal"},
                     {"AxisAtLeast": ["social.persuasion", 15]} ] },     // decisive: trivial
        { "AxisAtLeast": ["social.persuasion", 35] } ] },                // brute: hard
      "effect": { "ops": [ {"Outcome": "win"} ], "narrationKey": "acquit" } },

    { "id": "intimidate", "kind": "progress", "target": "vorne", "priority": 10,
      "requirement": { "AxisAtLeast": ["social.intimidation", 40] },
      "effect": { "ops": [ {"AdjustMeter": ["suspicion", 30]}, {"Outcome": "win"} ],
                  "narrationKey": "acquitLoud" } }
  ],
  "reactiveThresholds": [
    { "id": "lockdown", "meter": "suspicion", "atLeast": 60,
      "effect": { "ops": [ {"Outcome": "lose"} ], "narrationKey": "lockdown" } }
  ],
  "fallbackBounds": { "touchableFacets": [], "touchableMeters": ["suspicion"],
                      "maxMeterDelta": 10, "allowOutcome": false }
}
```

Lint pass over this scene: L-01✓ (facet declared), L-02✓ (all axes canonical), L-06✓ (discovery
emits RevealFacet only), L-13✓ (persuade/intimidate reach Outcome), L-15✓ (collapse=trivial band
15 vs brute=hard band 35 — real leverage).

---

## 7. Cross-cutting refinement — `CapabilityVector.invokedFacets`

The `Invokes(facet)` predicate requires the runtime vector to carry which facets the action
invoked. This threads through:

- **ADR-0004:** `Classification.facetsInvoked` already exists; `CapabilityVector` must **surface**
  it (add `Set<FacetKey> invokedFacets`) so Stage B passes it through unmodified.
- **ADR-0006:** the Resolver reads `vector.invokedFacets` when evaluating `Invokes`.
- Net effect: the decisive-move collapse keys on the *reliably-classified* facet, not the noisy
  axis — directly closing the prototype's PIVOT.

This is a small, additive change to two Accepted ADRs — record it when ADR-0003 is updated for §3.

---

## 8. Open questions

1. **Compound/sequential intent** ("cut power, then crack vault") — one beat at a time, or a
   decomposed plan? (Concept open question; affects whether a path can require an *ordered* facet
   history.) Deferred to prototype.
2. **Difficulty tagging** — is `Difficulty` authored per threshold, or inferred by the Linter from
   the grounding band? Leaning authored (explicit intent) + Linter cross-check (L-04).
3. **Multi-target actions** — one action hitting two entities. Out of scope for v0.1.
4. **Promotion workflow** — how L-14 promotion hints feed the ADR-0002 axis-promotion process.

---

## 9. Next steps

- Ratify §3 by updating/superseding **ADR-0003** with the extended `ThresholdExpr` form set and
  the §7 `invokedFacets` addition.
- Build the **Scene Linter** (§5) as the first implementable piece — pure Dart, unit-tested for
  determinism, runs headlessly in CI on every authored/compiled scene.
- Re-run the intent-translation prototype's PIVOT with `Invokes(scandal)` keying the collapse, to
  confirm the decisive move now lands stably.
