# ADR-0005: Scene Compiler + Grounding Tables + Deterministic Scene Linter

## Status

Accepted

## Date

2026-06-21

## Last Verified

2026-06-21

## Decision Makers

technical-director, game-designer, flutter-specialist (authored via /architecture-decision, batch foundational set)

## Summary

Defines the offline authoring pipeline that expands a designer's sparse scene seed into a
full Scene Model: a constrained generative Compiler (Opus 4.8, offline) grounded in
canonical materials/archetype tables, whose output is checked by a deterministic Scene
Linter before bulk-approval and freezing. The constraint + linter are what make "bulk
approve" a real economy rather than secretly re-checking every number by hand.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Flutter 3.44.0 / Dart 3.12 (Linter is pure Dart; Compiler is an offline batch tool) |
| **Domain** | Core / Tooling (offline) |
| **Knowledge Risk** | MEDIUM — the Linter is LOW (pure Dart); the Compiler depends on an external offline model (Opus 4.8) |
| **References Consulted** | `docs/engine-reference/flutter/current-best-practices.md`, ADR-0002, ADR-0003 |
| **Post-Cutoff APIs Used** | None in shipped Dart. Offline: Opus 4.8 generation endpoint |
| **Verification Required** | Confirm Compiler output always validates against the ADR-0003 schema before any bulk-approve workflow is trusted |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0002 (Ontology — grounding vocabulary), ADR-0003 (Scene Model — the compile target) |
| **Enables** | ADR-0008 (feedback loop feeds candidate paths back here); content scale-up at Vertical Slice |
| **Blocks** | Vertical Slice content scale-up (NOT MVP — MVP hand-authors scenes) |
| **Ordering Note** | Author after ADR-0002 and ADR-0003. Explicitly NOT required for MVP; arrives at Vertical Slice. |

## Context

### Problem Statement

Content volume is driven by ontology richness + scene-model authoring, not input
enumeration. Hand-authoring full Scene Models is slow and the coverage risk (a reasonable
intent must catch on *some* axis) is the highest design risk. The Compiler is the lever
against that risk — but free-running generation would reintroduce the variance and
unbalanced thresholds the whole architecture exists to avoid. We must decide how the
Compiler is *constrained* and *verified* so a designer can bulk-approve its output safely.

### Current State

No code. The concept (TD-PIPELINE) specifies the mitigation: grounding tables + a
deterministic Scene Linter, and "build the Compiler constrained, not as free-running
generation." It is explicitly out of MVP scope.

### Constraints

- **Offline batch only** (Opus 4.8) — never in the runtime hot path.
- **Constrained generation**: the Compiler draws on canonical materials/archetype grounding tables; it may **not** coin new axes (ADR-0002).
- **Output must be a valid Scene Model** (ADR-0003) and pass the deterministic Linter before a human bulk-approves.
- Frozen → canonical → deterministic after approval (same freeze discipline as hand-authored scenes).

### Requirements

- Input: a sparse seed ("You wake up in a prison cell.").
- Output: a reviewable Scene Model grounded in canonical tables (materials, archetypes, threshold norms).
- A **deterministic Scene Linter** that flags inconsistent or unbalanced thresholds, undeclared facets, axis misuse, and orphaned paths — pure Dart, no LLM.
- A bulk-approve workflow: designer reviews linter report + diffs, approves, scene freezes.

## Decision

A three-part offline pipeline. **(1) Grounding tables** — canonical Dart/JSON data
(materials with default axis magnitudes, entity archetypes, threshold norms) that bound
what the Compiler may produce. **(2) Compiler** — an offline Opus 4.8 batch process that
expands a seed into an ADR-0003 `SceneModel`, constrained to the Ontology (ADR-0002) and
the grounding tables. **(3) Scene Linter** — a **deterministic, pure-Dart** validator that
runs on Compiler output (and on hand-authored scenes) and emits a structured report of
violations. A scene may only be frozen to canonical after it passes the Linter and a human
bulk-approves.

### Architecture

```
seed prose ──►  ┌─────────────────────────────┐
                │ COMPILER (Opus 4.8, OFFLINE) │ ◄── grounding tables (materials,
                │ expand seed → SceneModel     │     archetypes, threshold norms)
                └──────────────┬──────────────┘ ◄── Ontology (ADR-0002, closed axes)
                               │ candidate SceneModel (ADR-0003 JSON)
                               ▼
                ┌─────────────────────────────┐
                │ SCENE LINTER (deterministic) │  flags:
                │ pure Dart, no LLM            │   • undeclared facet refs
                └──────────────┬──────────────┘   • unbalanced/inconsistent thresholds
                               │ LintReport         • axis misuse / would-be new axis
                               ▼                     • orphaned/unreachable paths
                ┌─────────────────────────────┐      • scalar-behaving facet (promotion hint)
                │ DESIGNER BULK-APPROVE        │
                └──────────────┬──────────────┘
                               ▼
                   freeze → canonical → deterministic (runtime input to Resolver)
```

### Key Interfaces

```dart
/// Canonical bounds the Compiler must stay within (also informs the Linter).
final class GroundingTables {
  const GroundingTables(this.version, this.materials, this.archetypes, this.thresholdNorms);
  final String version;
  final Map<String, MaterialSpec> materials;     // e.g. stone_wall → default Force-to-breach band
  final Map<String, EntityArchetype> archetypes; // e.g. guard → default props
  final ThresholdNorms thresholdNorms;           // expected magnitude bands per axis/difficulty
}

/// Offline batch compiler — NOT runtime. Behind an interface for testability/mocking.
abstract interface class SceneCompiler {
  Future<SceneModel> compile(String seedProse, GroundingTables tables);
}

/// Deterministic linter — pure Dart, no I/O, no LLM. Runs on any SceneModel.
final class SceneLinter {
  const SceneLinter(this.tables, this.ontology);
  final GroundingTables tables;
  final Ontology ontology;
  LintReport lint(SceneModel scene);   // same scene → same report, always
}

final class LintReport {
  const LintReport(this.findings);
  final List<LintFinding> findings;    // severity: error | warning | promotionHint
  bool get passes => findings.every((f) => f.severity != LintSeverity.error);
}
```

### Implementation Guidelines

- `SceneLinter` and `GroundingTables` live in `lib/scene/authoring/` (pure Dart, unit-tested for determinism). The Linter must run headlessly in CI on every authored/compiled scene.
- The Compiler is an offline tool under `tools/` (not in `lib/` shipped client code); it produces JSON that is then linted and reviewed.
- Grounding tables and the Compiler prompt are versioned artifacts; bumping them re-lints all affected scenes.
- The Linter, not the human, is the line of defense against unbalanced thresholds — design lint rules so that passing genuinely means "safe to bulk-approve."
- MVP does NOT use the Compiler; MVP scenes are hand-authored JSON that still must pass the Linter.

## Alternatives Considered

### Alternative 1: Free-running generative Compiler (no grounding, no linter)

- **Description**: Let the model freely generate scenes; designer reads them.
- **Pros**: Fastest to build; most flexible output.
- **Cons**: Reintroduces variance/unbalanced thresholds; "bulk-approve" becomes a lie (human re-checks everything); can coin pseudo-axes.
- **Estimated Effort**: Lower.
- **Rejection Reason**: Defeats the determinism architecture; TD-PIPELINE explicitly rejects this.

### Alternative 2: No Compiler — hand-author everything forever

- **Description**: Skip generative authoring entirely.
- **Pros**: Fully deterministic; no model dependency.
- **Cons**: Doesn't scale; leaves the coverage risk unmitigated past MVP.
- **Estimated Effort**: High ongoing.
- **Rejection Reason**: The Compiler is the answer to the coverage risk and the content-production model; needed by Vertical Slice. (It IS the right approach *for MVP*, hence Compiler is deferred, not cancelled.)

## Consequences

### Positive

- Scales content without abandoning determinism — the Linter makes bulk-approve real.
- The same Linter hardens hand-authored MVP scenes immediately, before the Compiler exists.
- Grounding tables double as the balancing surface for authored difficulty.

### Negative

- Two versioned artifact sets (grounding tables, Compiler prompt) to maintain and eval.
- Linter rule quality is load-bearing; weak rules silently undermine bulk-approve.

### Neutral

- Compiler output quality scales with grounding-table richness — an ongoing editorial investment.

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| Bulk-approve becomes a false economy | Medium | High | Strong deterministic Linter; measure reviewer re-check rate; TD-PIPELINE mitigation |
| Compiler output drifts off-schema | Medium | Medium | Validate against ADR-0003 schema before lint; reject non-conforming output |
| Grounding tables too sparse → bland scenes | Medium | Low | Iterate tables from real authored scenes; start from the prototype |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| CPU (runtime) | n/a | ZERO — Compiler is offline | n/a (not in hot path) |
| CPU (Linter, CI) | n/a | fast pure-Dart pass per scene | CI time only |
| Offline cost | n/a | Opus 4.8 batch per seed | offline budget, not per-turn |

## Migration Plan

Deferred to Vertical Slice. The Linter ships earlier (MVP) to harden hand-authored scenes; the Compiler is added without changing the Scene Model schema (ADR-0003).

**Rollback plan**: disable the Compiler and fall back to hand-authoring + Linter; runtime is unaffected (Compiler never runs at runtime).

## Validation Criteria

- [ ] `SceneLinter.lint` is deterministic (same scene → identical report)
- [ ] Linter catches: undeclared facet refs, out-of-band thresholds, would-be new axes, orphaned paths
- [ ] Compiler output always validates against the ADR-0003 schema before lint
- [ ] A designer can bulk-approve a linted scene without manually re-checking every magnitude
- [ ] Hand-authored MVP scenes pass the same Linter in CI

## GDD Requirements Addressed

Foundational — no GDD requirement (no system GDDs yet). Sourced from
`design/gdd/game-concept.md` → "Determinism discipline" #2, "The Authoring Engine", TD-PIPELINE mitigations, "Foundational ADRs" #5.

| Source | Pillar / Concept | How This ADR Satisfies It |
|--------|------------------|--------------------------|
| `design/gdd/game-concept.md` | Hook ("scene compiler expands sparse prose") | Defines that compiler, constrained |
| `design/gdd/game-concept.md` | Coverage risk (highest) | Compiler is the scaling lever |
| `design/gdd/game-concept.md` | TD-PIPELINE mitigation #2 | Grounding tables + deterministic Linter |

**Enables**: feedback loop (ADR-0008); Vertical Slice content scale-up.

## Related

- ADR-0002 (Ontology) — the Compiler may not coin axes; grounding tables bound magnitudes
- ADR-0003 (Scene Model) — the compile target and lint subject
- ADR-0008 (Feedback loop) — fallback proposals become candidate paths reviewed here
