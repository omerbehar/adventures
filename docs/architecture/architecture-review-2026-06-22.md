# Architecture Review Report

> **Date:** 2026-06-22
> **Engine:** Flutter 3.44.0 / Dart 3.12
> **Mode:** `/architecture-review` (full)
> **Inputs:** 2 design docs (`game-concept.md`, `game-pillars.md` — no per-system GDDs yet), 8 ADRs (all `Proposed`), 4 engine-reference docs.
> **Verdict:** **CONCERNS**

---

## Context

This is a *Pre-Production / Concept-Complete* project. There are no per-system GDDs and
no `systems-index.md`, `architecture.md`, or (prior to this review) `tr-registry.yaml`.
The requirements baseline is extracted from `game-concept.md` (master design doc) and
`game-pillars.md`. The 8 ADRs map 1:1 to the 8 "Foundational ADRs" the concept enumerates.

Loaded: 2 design docs, 8 ADRs, engine reference = Flutter 3.44.0 / Dart 3.12.

---

## Traceability Matrix

| TR-ID | Source | Requirement | ADR | Status |
|---|---|---|---|---|
| TR-state-001 | concept §Mechanics, P2 | Every resolution emits a typed, validated, immutable `StateDelta`, never prose | ADR-0001 | ✅ |
| TR-state-002 | concept "side-effect StateDeltas" | One action composes multiple ops (goal + meter move) | ADR-0001 | ✅ |
| TR-state-003 | concept §Mechanics | Mutable runtime `WorldState`; pure `applyDelta` | ADR-0001 | ✅ |
| TR-ont-001 | concept §Ontology | Closed ~12 scalar axes; Social sub-vectored | ADR-0002 | ✅ |
| TR-ont-002 | concept §Ontology | Open scene-local keyed facets | ADR-0002 | ✅ |
| TR-ont-003 | concept, forbidden pattern | No runtime axis coinage; promotion via ADR only | ADR-0002 | ✅ |
| TR-ont-004 | concept §Determinism | Single canonical magnitude scale shared by thresholds + tables | ADR-0002 | ✅ |
| TR-scene-001 | concept §Scene Model, P6 | Entities w/ typed props; paths as conditional thresholds | ADR-0003 | ✅ |
| TR-scene-002 | concept "conditional thresholds" | Required magnitude changes with facets (`IfFacet`) = decisive move | ADR-0003 | ✅ |
| TR-scene-003 | concept "discovery moves" | Paths that reveal facets, not progress | ADR-0001/0003 | ✅ |
| TR-scene-004 | concept "scalar meters" | Scalar world-state meters (Alertness 0–100) | ADR-0003 | ✅ |
| TR-scene-005 | concept "reactive thresholds" | Meter crossing fires authored autonomous transition | ADR-0003/0006 | ✅ |
| TR-scene-006 | concept "scene-graph" | Adventure = graph of nodes sharing global meters/facets | ADR-0003 | ✅ |
| TR-p4-001 | Pillar 4 | Scene Model JSON format IS the creator-facing primitive | ADR-0003 | ✅ |
| TR-trans-001 | concept §Translator, P1 | Freeform text → typed `{axes, magnitude, target}` vector | ADR-0004 | ✅ |
| TR-trans-002 | concept §Determinism #1 | Classify-don't-score: LLM names; deterministic tables score | ADR-0004 | ✅ |
| TR-trans-003 | Pillar 5 | Class-colored resolution (same words differ per specialist) | ADR-0004 | ✅ |
| TR-trans-004 | concept kill-criterion | Run-to-run threshold stability for same argument | ADR-0004 | ✅ |
| TR-comp-001 | concept §Authoring, P6 | Compiler expands sparse seed → reviewable Scene Model | ADR-0005 | ✅ |
| TR-comp-002 | concept §Determinism #2 | Grounding tables + deterministic Scene Linter make bulk-approve real | ADR-0005 | ✅ |
| TR-res-001 | concept pipeline stage 5 | Per-beat deterministic rules engine, client/edge-side | ADR-0006 | ✅ |
| TR-res-002 | concept, anti-pillar | Per-beat advancement; state machines, never a wall clock | ADR-0006 | ✅ |
| TR-res-003 | concept §Mechanics | Outcome single source of truth | ADR-0001/0006 | ✅ |
| TR-route-001 | concept §Where it runs | Tier 0→1→2→3 cascade; escalate only as needed | ADR-0007 | ✅ |
| TR-route-002 | Pillar 2 | Bounded fallback emits validated `StateDelta` within creator bounds | ADR-0007/0003 | ✅ |
| TR-route-003 | stack constraint #1 | Deterministic hot path (T0/1 + Resolver) offline-capable | ADR-0006/0007 | ✅ |
| TR-route-004 | stack constraint #4 | Hard per-turn token budget, instrumented | ADR-0007 | ✅ |
| TR-fb-001 | concept §Feedback, hook | Offline-gated fallback proposal → Compiler candidate path | ADR-0008 | ✅ |
| TR-fb-002 | concept risks | Player-input capture data-handling/privacy policy | ADR-0008 | ⚠️ Partial (policy deferred, owner named) |
| TR-cfg-001 | coding-standards | Versioned tables/prompts/index; eval re-run on change | ADR-0004/0007 | ⚠️ Partial (eval harness not its own ADR) |
| TR-client-001 | concept "one portable UI layer"; tech-prefs platforms | Cross-platform thin client architecture (PC/Web/Mobile), UI/state-mgmt, navigation, translation-moment beat, soft-keyboard, <5MB Wasm bundle | — | ❌ **GAP** |
| TR-persist-001 | MVP "StateDelta persistence … between sessions" | Save/persistence architecture (beyond StateDelta serialization) | — | ❌ Gap (deferred-acceptable) |

**Totals:** 31 requirements — ✅ 27 covered · ⚠️ 2 partial · ❌ 2 gaps.

---

## Coverage Gaps

❌ **TR-client-001 — Client / UI architecture** *(confirmed real gap by user)*
- Domain: UI / Cross-platform · Engine Risk: MEDIUM
- No ADR governs the thin cross-platform client: layering (pure-Dart core vs. widget layer
  vs. service layer), UI/state-management choice (best-practices flags Riverpod to *evaluate*),
  Navigation 2.0 / router for shareable adventure URLs, the typography-forward
  translation-moment visual beat (`CustomPainter`/animation), soft-keyboard handling, and the
  <5MB initial Wasm bundle budget.
- Suggested ADR: `/architecture-decision client-and-ui-architecture`

❌ **TR-persist-001 — Save / persistence** *(deferred-acceptable)*
- Domain: Core · Engine Risk: LOW
- StateDelta is serializable (ADR-0001) but no ADR covers session/adventure persistence.
  Concept places "basic save" at Vertical Slice; deferral is reasonable. Track, don't block.

---

## Cross-ADR Conflicts

No blocking conflicts. Ownership is explicitly assigned and deferred-to across documents
(Outcome→ADR-0001, magnitude scale→ADR-0002, `FallbackBounds`→ADR-0003, client-side Stage-B
scoring agreed by ADR-0004 & 0007). Three **non-blocking integration seams** to tighten
before the ADRs are Accepted:

### ① Layering inversion — `validateDelta` placement (ADR-0001 ↔ ADR-0003)
Type: Pattern / Dependency.
ADR-0001 declares `validateDelta(StateDelta, SceneModel, Ontology)` and places it in
`lib/game/state_delta.dart`. But `SceneModel` (ADR-0003) depends on `StateDelta`, so this
creates a definitional cycle 0001→0003→0001. ADR-0001's "Depends On: None" doesn't acknowledge it.
**Resolution:** put `validateDelta` in the scene/validation layer (may depend on both 0001+0003);
keep the `StateDelta` *data class* dependency-free. One-line note in ADR-0001.

### ② Bounds-enforcement seam — `validateDelta` has no provenance (ADR-0001 ↔ 0007 ↔ 0003)
Type: Integration contract.
ADR-0007/0003 require `FallbackBounds` enforced **only for Tier-3 proposals** (authored path
effects may legitimately exceed `maxMeterDelta` or emit `Outcome`). ADR-0001's signature carries
no provenance/bounds flag and describes only unknown-reference checks.
**Resolution:** add a bounds/provenance parameter (e.g. `validateDelta(..., {FallbackBounds? enforce})`);
reconcile across 0001/0003/0007.

### ③ Recursive `ThresholdExpr` has no acyclicity/depth gate (ADR-0003 ↔ 0005 ↔ 0006)
Type: Integration / Safety.
`IfFacet` is a recursive `sealed ThresholdExpr`. ADR-0006 mandates a Linter cycle-check for
*reactive thresholds* but none exists for the `ThresholdExpr` tree itself — malformed JSON could
produce a deep/cyclic tree → stack overflow during Resolver evaluation.
**Resolution:** add a depth-limit / acyclicity rule to ADR-0003 schema validation and the
ADR-0005 Linter.

### ADR Dependency Order (topological — declared `Depends On` graph is acyclic)
```
Foundation (no deps):     ADR-0001 (StateDelta) · ADR-0002 (Ontology)   ← co-foundational
Depends on Foundation:    ADR-0003 (Scene Model ← 0001,0002) · ADR-0004 (Translator ← 0002)
Core engine:              ADR-0006 (Resolver ← 0001,0002,0003,0004)
Authoring (deferrable):   ADR-0005 (Compiler+Linter ← 0002,0003)
Service layer:            ADR-0007 (Router cascade ← 0001,0004,0006)
Feature (last):           ADR-0008 (Feedback ← 0001,0005,0007)
```
**Unresolved-dependency flag:** all 8 ADRs are `Proposed`; every ADR depends on `Proposed`
predecessors. Expected for a batch-authored set, but **all 8 must move to `Accepted` before
implementation begins.** Note: the *type cycle* (① above) exists at code level even though the
declared `Depends On` graph is acyclic.

---

## Engine Compatibility

Version: all 8 ADRs declare Flutter 3.44.0 / Dart 3.12 — consistent. Engine Compatibility
section present: **8/8**. No deprecated-API references (core ADRs are pure-Dart, avoid
Material/widget APIs). Post-Cutoff API discipline correct (all "None" in shipped Dart;
external LLM/embedding risk properly scoped).

### Engine Specialist Findings (flutter-specialist)
Confirmed all five audit findings. Added:

| # | Finding | Severity |
|---|---------|----------|
| N1 | **ADR-0003 macro-based JSON is understated risk.** Dart 3.12 stabilized the macros *language feature* — not a production-ready `@JsonSerializable`-via-macros *package*. Preferring it for the core data model risks immature codegen. Demote to "aspirational, requires technical-director package approval"; hand-rolled `fromJson`/`toJson` is the correct MVP choice (ADR-0003's closing line already allows this). | HIGH |
| N4 | **`Object`-typed values are a blocking design gap.** `SetEntityProp.value` (ADR-0001) and `Entity.props` (ADR-0003) typed as `Object` break the JSON round-trip Validation Criterion. Promote `PropValue` (sealed String\|int\|bool\|double) to a first-class ADR type. | MED |
| N3 | **`WorldState` immutable-set copy discipline unspecified.** Mutable `Set`/`Map` into the "immutable" `WorldState` without defensive copy → silent determinism break. Mandate `UnmodifiableSetView`/unmodifiable maps. | MED |
| N2 | **`FacetKey`/`CapabilityAxisKey` value-equality unverified.** Safe only if `FacetKey` (String typedef — OK) and `CapabilityAxisKey` (record — OK) keep structural equality; verify at implementation. | MED |
| N7 | **Recursive `ThresholdExpr` needs a schema acyclicity/depth gate** (= conflict ③). | MED |
| N5 | **`RouterCascade` should sit behind a DI interface** (testability + boundary hygiene vs. widget tree). | LOW-MED |
| N8 | **`typedef WorldStateSnapshot = WorldState` gives zero type safety** — a live mutable state can be passed where a frozen snapshot is expected (matters for ADR-0008 capture). Consider a distinct wrapper type. | LOW-MED |
| N6 | **`const Resolver()` vs future seeded-RNG injection** — pre-declare `Resolver({Rng? rng})` now to avoid a breaking call-site change later. | LOW |

These are refinements to apply before the ADRs are Accepted, not coverage gaps.

---

## GDD Revision Flags (Architecture → Design Feedback)

**None.** The design docs make no engine-API assumptions that contradict verified Flutter 3.44 /
Dart 3.12 behaviour — the concept is deliberately engine-agnostic, and the HIGH-risk macro finding
is an architecture/implementation concern, not a design-rule conflict. No systems-index updates
required (and none exists yet).

---

## Architecture Document Coverage

- ❌ `docs/architecture/architecture.md` does not exist — no master blueprint stitching the 8
  ADRs into layers/data-flow. Run `/create-architecture` (the 8 ADRs are strong inputs).
- ❌ `design/gdd/systems-index.md` does not exist — no authoritative systems list. Expected
  pre-`/map-systems`.

---

## Verdict: CONCERNS

Not a FAIL — every Foundation/Core-layer requirement is covered by a thorough, internally
consistent ADR set, and there are no blocking cross-ADR conflicts. Held back from PASS by:
**(1)** one genuine coverage gap (no client/UI architecture ADR — `TR-client-001`); **(2)** all
8 ADRs still `Proposed`, not `Accepted`; **(3)** one HIGH engine refinement (macro JSON) plus
several MED data-typing/determinism refinements to fold in before acceptance.

### Items to resolve toward PASS
1. **Author a client/UI-architecture ADR** (`TR-client-001`): cross-platform thin-client
   layering, UI/state-management choice, navigation/routing for shareable adventure URLs, the
   translation-moment visual beat, soft-keyboard handling, <5MB Wasm bundle budget. *(Highest-impact.)*
2. **Fold the engine-specialist refinements into ADR-0001/0003** before Accepting: demote macro
   JSON to aspirational; promote `PropValue` to a first-class type; mandate `WorldState`
   immutable-collection discipline; add the `ThresholdExpr` acyclicity gate.
3. **Reconcile the three integration seams** (validateDelta placement + provenance/bounds param;
   ThresholdExpr guard).
4. **Move all 8 ADRs `Proposed → Accepted`** once 2–3 are addressed.
5. *(Lower priority / deferred-acceptable)* persistence ADR (`TR-persist-001`); promote the
   eval-harness + privacy policy from referenced-but-deferred to tracked artifacts.

### Required ADRs (prioritised)
1. `client-and-ui-architecture` (Foundation for the presentation/platform layer) — **highest impact**
2. *(optional, lower priority)* `persistence-and-save`
3. *(optional)* `eval-harness` — promote the cross-cutting eval/versioning discipline to a tracked decision

---

## Resolution Addendum — 2026-06-22 (same day)

All blocking and refinement items from this review were actioned the same day:

- **ADR-0009 `client-and-ui-architecture` authored** — closes `TR-client-001` (the only confirmed
  coverage gap). Registry updated: gap → covered. Also resolves finding **N5** (`RouterCascade`
  behind a DI interface).
- **Engine-specialist refinements folded into ADR-0001 / ADR-0003 / ADR-0006 / ADR-0007:**
  - N1 — ADR-0003 macro-JSON **demoted** to aspirational (technical-director package approval
    required); MVP hand-rolls `fromJson`/`toJson`.
  - N4 — `PropValue` (sealed String|int|bool|double) **promoted to a first-class type** in ADR-0001;
    ADR-0003 `Entity.props` and ADR-0001 `WorldState.entityProps`/`SetEntityProp.value` now use it.
  - N3 — ADR-0001 mandates **immutable-collection discipline** for `WorldState` (unmodifiable views,
    defensive copies).
  - N7 — ADR-0003 adds a **`ThresholdExpr` acyclicity / depth gate** at schema-load and in the
    ADR-0005 Linter, with matching validation criteria.
  - N8 — ADR-0001 `WorldStateSnapshot` is now a **distinct type**, not a `typedef`.
  - N6 — ADR-0006 `Resolver` pre-declares an optional **seeded-RNG** constructor parameter.
- **Integration seams reconciled:** ① `validateDelta` placement documented (scene/validation layer,
  not `state_delta.dart`) to break the 0001↔0003 type cycle; ② `validateDelta` gains an
  `enforceBounds` parameter (Tier-3 deltas only) reconciled across ADR-0001/0003/0007;
  ③ covered by N7.
- **All 9 ADRs moved `Proposed → Accepted`.**

**Remaining (non-blocking, deferred-acceptable):** `TR-persist-001` (save/persistence ADR — concept
places basic save at Vertical Slice); `TR-fb-002` (capture privacy policy — owner named in ADR-0008);
`TR-cfg-001` (eval-harness as a tracked artifact). A human must run `flutter create .` + `flutter pub get`
once the SDK is available (the scaffold has no platform folders yet).

**Effective post-addendum status: PASS-ready** for `/gate-check pre-production`, subject to the three
deferred items above being acknowledged as out-of-scope for the gate.
