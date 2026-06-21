# ADR-0004: Classify-Don't-Score Translator

## Status

Proposed

## Date

2026-06-21

## Last Verified

2026-06-21

## Decision Makers

technical-director, game-designer, network-programmer, flutter-specialist (authored via /architecture-decision, batch foundational set)

## Summary

Defines how freeform player text becomes a typed `CapabilityVector`: the LLM **names**
which axes/facets/tactics an action invokes plus a coarse ordinal, and **deterministic
tables compute the magnitude** — the LLM never emits the final number. This "classify,
don't score" discipline keeps the same argument scored consistently run-to-run, which is
the prototype's explicit kill-criterion.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Flutter 3.44.0 / Dart 3.12 |
| **Domain** | Scripting / Networking (the deterministic mapping is pure-Dart core; the classifier call is a service) |
| **Knowledge Risk** | MEDIUM — the Dart mapping is LOW; the LLM structured-output contract depends on external model APIs that post-date training |
| **References Consulted** | `docs/engine-reference/flutter/current-best-practices.md` (pure-Dart-core, DI for services), `breaking-changes.md` |
| **Post-Cutoff APIs Used** | None in Dart. External: a structured-output LLM endpoint (versioned per concept stack-shaping constraint #5) |
| **Verification Required** | Confirm the chosen classifier model reliably honors the structured-output schema; run the eval harness before relying on it |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0002 (Ontology — the classification vocabulary) |
| **Enables** | ADR-0006 (Resolver consumes the CapabilityVector), ADR-0007 (router tiers invoke the classifier) |
| **Blocks** | The magistrate prototype; MVP Translator epic |
| **Ordering Note** | Author after ADR-0002. Independent of ADR-0003 but consumed alongside it by the Resolver. |

## Context

### Problem Statement

The blank line accepts anything (Pillar 1); resolution must be deterministic and fair
(Pillar 2). LLM free scoring varies run-to-run, which would make the decisive-move
threshold unstable — the single biggest technical risk in the concept. We must convert
freeform intent into a typed `{axis(es), magnitude, target}` vector in a way that is
**stable** for the same argument, while still allowing the LLM to do the part it is good
at (recognizing *what* an action is).

### Current State

No code. The concept specifies the mitigation ("classify-don't-score") and that physical
translation is near-deterministic/lookup while social is evaluative.

### Constraints

- The LLM may classify (name axes/facets/tactics + coarse ordinal) but must **not** produce the final magnitude.
- Deterministic tables (pure Dart, versioned) compute magnitude from the classification.
- Output is class-colored (Pillar 5) — the same words resolve differently per specialist.
- The classifier call lives service-side (Tier 2/3) behind a DI interface; the mapping is client/edge-side pure Dart.
- Hard per-turn generative-token budget (concept stack-shaping constraint #4).

### Requirements

- Produce a `CapabilityVector { axes: {CapabilityAxis: magnitude}, target, classColoring }`.
- Same argument → same vector (run-to-run stability) — the prototype kill-criterion.
- Structured output (JSON schema) from the classifier; reject/repair off-schema responses.
- Versioned classify tables + prompts; eval re-run on any model/table change (constraint #5).

## Decision

A two-stage Translator. **Stage A (classify, evaluative, service-side LLM)**: given player
text + scene context + active class, the model returns a **structured classification** —
which `CapabilityAxis`(es) and tactics/facets the action invokes, a coarse ordinal per axis
(e.g. `none | minor | moderate | major | extreme`), and the `target`. **Stage B (score,
deterministic, pure-Dart tables)**: a versioned lookup maps `(axis, ordinal, class, scene
modifiers)` → an integer magnitude, producing the `CapabilityVector`. The LLM never sees or
emits the final number.

### Architecture

```
player text + scene context + active class
            │
            ▼  (service-side, Tier 2/3 — ADR-0007)
   ┌──────────────────────────────┐
   │ STAGE A: CLASSIFY (LLM)       │  structured output ONLY:
   │ "names axes/tactics/facets    │   { axes:[{axis, ordinal}], target, tactics:[...] }
   │  + coarse ordinal"            │
   └──────────────┬───────────────┘
                  │ (validated against JSON schema; repair/reject off-schema)
                  ▼  (client/edge, pure Dart — deterministic)
   ┌──────────────────────────────┐
   │ STAGE B: SCORE (tables)       │  magnitude = table[axis][ordinal] (class-colored)
   │ versioned classify tables     │  + scene modifiers
   └──────────────┬───────────────┘
                  ▼
        CapabilityVector { {axis: magnitude}, target, classColoring }
                  ▼
             [Resolver] (ADR-0006)
```

### Key Interfaces

```dart
/// The deterministic output consumed by the Resolver.
final class CapabilityVector {
  const CapabilityVector({required this.magnitudes, required this.target, required this.classId});
  // Keyed on CapabilityAxisKey (a record) for value-equality — see ADR-0002.
  // A plain-class key would miss on every lookup and break Resolver determinism.
  final Map<CapabilityAxisKey, int> magnitudes;   // computed by Stage B, never by the LLM
  final String target;                            // entityId or 'self'
  final String classId;                           // active specialist (Pillar 5)
}

enum CoarseOrdinal { none, minor, moderate, major, extreme }

/// Stage A result — what the LLM is allowed to emit (no magnitudes).
final class Classification {
  const Classification({required this.axisOrdinals, required this.target, required this.tactics, required this.facetsInvoked});
  final Map<CapabilityAxisKey, CoarseOrdinal> axisOrdinals;  // record-keyed, see ADR-0002
  final String target;
  final List<String> tactics;
  final List<FacetKey> facetsInvoked;
}

/// Stage A — evaluative, service-side, behind DI for testability.
abstract interface class IntentClassifier {
  Future<Classification> classify(String text, ClassifyContext ctx);
}

/// Stage B — deterministic, pure-Dart, versioned tables. No LLM, no I/O.
final class MagnitudeTables {
  const MagnitudeTables(this.version, this._table);
  final String version;
  CapabilityVector score(Classification c, String classId, SceneModifiers mods);
}
```

### Implementation Guidelines

- Stage B (`lib/game/translator/magnitude_tables.dart`) is pure Dart, fully unit-tested, deterministic — the same `Classification` + class + modifiers always yields the same `CapabilityVector`.
- Stage A lives in `lib/services/` behind `IntentClassifier`; unit tests use a fake returning canned `Classification`s — never the live model.
- Class coloring is applied in Stage B (table selection per `classId`), keeping Pillar 5 deterministic.
- **Client/service split (the determinism boundary)**: Stage A (`IntentClassifier`) runs service-side (Tier 2/3, ADR-0007) and returns ONLY a `Classification`. **Stage B (`MagnitudeTables.score`) runs client/edge-side** so the magnitude — and thus the decisive-move threshold — is computed by deterministic local tables, never on the server, never by the model. The cascade carries the `Classification` back across this boundary (see ADR-0007's `Classified` outcome) before scoring.
- Classify tables and prompts are versioned artifacts (`assets/translator/tables.vN.json`, prompt files); any change re-runs the eval harness (constraint #5).
- Off-schema LLM output is repaired or rejected, never passed downstream raw.
- The **decisive move** is not the highest magnitude — Stage B may surface which facets an action *invokes* (Stage A `facetsInvoked`) so the Resolver can apply conditional-threshold collapses (ADR-0003).

## Alternatives Considered

### Alternative 1: LLM scores the magnitude directly

- **Description**: Ask the model for the final number on each axis.
- **Pros**: Simplest pipeline; one call.
- **Cons**: Run-to-run variance destabilizes the decisive-move threshold — the named top risk.
- **Estimated Effort**: Lower.
- **Rejection Reason**: Fails the prototype kill-criterion (threshold stability); violates Pillar 2's fairness/repeatability.

### Alternative 2: Pure embedding/classifier (no generative model)

- **Description**: Classify intent with embeddings + a trained classifier only.
- **Pros**: Fully deterministic; cheap; offline-capable.
- **Cons**: Weaker at novel/social phrasings; the evaluative half (social) needs more nuance than a fixed classifier gives early on.
- **Estimated Effort**: Higher (training data needed).
- **Rejection Reason**: Kept as Tier 0/1 of the cascade (ADR-0007), but insufficient alone for the evaluative social case; classify-don't-score complements it.

## Consequences

### Positive

- Run-to-run stability for the same argument — directly protects Pillars 2 & 3.
- Separates "what is this action" (LLM strength) from "how strong is it" (deterministic, balanceable).
- Magnitude tables are a clean balancing surface, versioned and testable.

### Negative

- Two-stage pipeline is more moving parts than one call.
- Quality depends on the classifier reliably honoring the structured-output schema.

### Neutral

- Coarse ordinals must be granular enough to drive meaningful magnitudes but coarse enough to be stable (a tuning concern).

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| Classifier returns off-schema output | Medium | Medium | JSON-schema validation + repair/reject; eval harness gate |
| Ordinal granularity too coarse/fine | Medium | Medium | Prototype the magistrate; tune ordinal→magnitude tables against stability |
| Social classification still varies | Medium | High | Stability is the explicit prototype kill-criterion — measured before content spend |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| CPU (Stage B) | n/a | table lookups, <0.1ms | 16.6ms frame |
| Network (Stage A) | n/a | one bounded structured call when cascade escalates | Tier 2/3 ≤2s round-trip; hard token budget |
| Memory | n/a | versioned tables in memory | 150MB ceiling |

## Migration Plan

Greenfield. Tables and prompts are versioned from day one so model/table changes are deliberate, eval-gated migrations.

**Rollback plan**: pin to a previous table/prompt version; eval harness compares versions.

## Validation Criteria

- [ ] Stage B is deterministic (same Classification+class+mods → identical vector, 1000 runs)
- [ ] The magistrate scene's decisive-move threshold is stable run-to-run under live Stage A (kill-criterion)
- [ ] Off-schema classifier output is never passed to the Resolver
- [ ] Class coloring changes the vector for the same text across two specialists (Pillar 5)
- [ ] Token usage per turn stays within the configured budget

## GDD Requirements Addressed

Foundational — no GDD requirement (no system GDDs yet). Sourced from
`design/gdd/game-concept.md` → "Determinism discipline" #1, "Capability Translator", "Foundational ADRs" #4.

| Source | Pillar / Concept | How This ADR Satisfies It |
|--------|------------------|--------------------------|
| `design/gdd/game-concept.md` | Pillar 2 (translation, not improvisation) | LLM classifies; deterministic tables score |
| `design/gdd/game-concept.md` | Pillar 5 (specialists) | Class-colored magnitude tables |
| `design/gdd/game-concept.md` | Prototype kill-criterion | Stability is the measured gate |

**Enables**: Resolver (ADR-0006), router cascade (ADR-0007).

## Related

- ADR-0002 (Ontology) — the classification vocabulary
- ADR-0006 (Resolver) — consumes the CapabilityVector
- ADR-0007 (Router cascade) — where Stage A is invoked (Tier 2/3)
