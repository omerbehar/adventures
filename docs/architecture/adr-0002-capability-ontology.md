# ADR-0002: Capability Ontology

## Status

Proposed

## Date

2026-06-21

## Last Verified

2026-06-21

## Decision Makers

technical-director, game-designer, flutter-specialist (authored via /architecture-decision, batch foundational set)

## Summary

Defines the two-tier vocabulary every action and requirement is expressed in: a closed,
canonical set of ~12 scalar dimensions (balanced axes) plus an open set of scene-local
keyed facets (booleans/flags). New scalar axes may only be added editorially via ADR,
never coined at runtime — this is what keeps the Compiler and the Translator speaking
the same language.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Flutter 3.44.0 / Dart 3.12 |
| **Domain** | Core |
| **Knowledge Risk** | LOW — pure-Dart enums + a typed key registry |
| **References Consulted** | `docs/engine-reference/flutter/current-best-practices.md` (Dart enums, sealed types) |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | None |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | None (root vocabulary) |
| **Enables** | ADR-0003 (Scene Model thresholds), ADR-0004 (Translator output), ADR-0005 (Compiler grounding), ADR-0006 (Resolver matching) |
| **Blocks** | MVP Translator and Scene Model epics |
| **Ordering Note** | Co-foundational with ADR-0001. Both must be Accepted before ADR-0003/0004. |

## Context

### Problem Statement

Infinite freeform surface actions must reduce onto a **finite, shared set of dimensions**
so that (a) the Resolver can match intent against authored thresholds deterministically,
and (b) the Compiler and the Translator are guaranteed to speak the same language. "All
possible outcomes" is a model of typed thresholds on a shared ontology — not an
enumerated input list. The ontology is the linchpin of that claim and must be fixed
before any scene or translator work.

### Current State

No code. The concept doc specifies the ontology's shape (two tiers, ~12 axes, Social
sub-vectored, a promotion path) but not its encoding.

### Constraints

- **Closed scalar tier**: balancing happens only on these axes; the Translator and Compiler must not invent new ones.
- **Open facet tier**: scene-local booleans/flags may proliferate freely with no cross-scene balancing.
- **No runtime axis coinage** (project forbidden pattern) — promotion is an editorial ADR act.
- Social is **sub-vectored** (persuasion / intimidation / deception / rapport).

### Requirements

- Enumerate the ~12 canonical scalar dimensions from the concept.
- Encode Social's sub-vectors as first-class addressable channels.
- Provide an open, typed registry for keyed facets that scenes declare locally.
- Make "coin a new axis at runtime" structurally impossible (closed enum), and document the promotion path.

## Decision

Two tiers, encoded separately:

1. **Scalar dimensions** — a **closed Dart `enum CapabilityDimension`** with ~12 members.
   Social is represented by four sub-vector members (or a `Social` dimension carrying a
   `SocialChannel` sub-enum). Magnitudes are integers on a shared scale (see ADR-0004 for
   how magnitude is computed). Because it is a closed enum, no runtime code can add an axis.
2. **Keyed facets** — open `String` keys (e.g. `knows_password`, `vault_fears_scandal`,
   `power_cut`), declared per-scene in the Scene Model. No global enum; validated against
   the active scene's declared facet set (ADR-0003).

**Promotion path**: a recurring scalar-behaving facet may be promoted to a `CapabilityDimension`
member by authoring an ADR that supersedes/extends this one — an editorial act, never runtime.

### Architecture

```
                 CAPABILITY ONTOLOGY
   ┌─────────────────────────────┬──────────────────────────────┐
   │  TIER 1: SCALAR (closed)     │  TIER 2: FACETS (open)        │
   │  enum CapabilityDimension    │  scene-local String keys      │
   │  • force                     │  • knows_password             │
   │  • sizeForm                  │  • vault_fears_scandal        │
   │  • mobility                  │  • power_cut                  │
   │  • energy                    │  • ...                        │
   │  • durability                │  declared per-scene (ADR-0003)│
   │  • stealth                   │  validated vs scene's set     │
   │  • insight                   │                               │
   │  • social {persuasion,       │   PROMOTION (editorial only): │
   │     intimidation,            │   recurring facet ──ADR──►    │
   │     deception, rapport}      │   new CapabilityDimension     │
   │  • loreArcane                │                               │
   │  • techCraft                 │                               │
   │  • wealthResources           │                               │
   └─────────────────────────────┴──────────────────────────────┘
```

### Key Interfaces

```dart
/// Closed, canonical scalar axes. Adding a member is an editorial ADR act.
enum CapabilityDimension {
  force, sizeForm, mobility, energy, durability, stealth, insight,
  social, loreArcane, techCraft, wealthResources,
}

/// Social is evaluative and sub-vectored (concept §Capability Ontology).
enum SocialChannel { persuasion, intimidation, deception, rapport }

/// Canonical map/threshold key for an axis: a (dimension, channel?) record.
/// Records give STRUCTURAL value-equality for free, so this is the correct type
/// to use as a `Map<CapabilityAxisKey, int>` key and in threshold matching.
/// (Added per review: a plain class key would use identity equality and every
/// axis lookup would miss at runtime — silently breaking Resolver determinism.)
typedef CapabilityAxisKey = (CapabilityDimension dimension, SocialChannel? channel);

/// A typed capability axis reference for documentation/ergonomics. MUST expose a
/// `key` for use in maps/thresholds; do NOT use the object itself as a map key
/// unless it overrides `==`/`hashCode`.
final class CapabilityAxis {
  const CapabilityAxis(this.dimension, {this.socialChannel})
      : assert(dimension != CapabilityDimension.social || socialChannel != null,
               'Social axes must name a channel');
  final CapabilityDimension dimension;
  final SocialChannel? socialChannel; // required iff dimension == social
  CapabilityAxisKey get key => (dimension, socialChannel);
}

/// Open, scene-local facets. No global enum — declared by the Scene Model.
typedef FacetKey = String;

/// Aggregate ontology value passed to validators (ADR-0001) and the Linter (ADR-0005).
/// Names the concrete `Ontology` type those consumers depend on.
final class Ontology {
  const Ontology({this.magnitudeMin = 0, this.magnitudeMax = 100});
  /// ADR-0002 OWNS the canonical magnitude scale. Thresholds (ADR-0003) and the
  /// Translator's magnitude tables (ADR-0004) must agree with this range.
  final int magnitudeMin;
  final int magnitudeMax;
  Set<CapabilityDimension> get dimensions => CapabilityDimension.values.toSet();
}

/// Validated against the active scene's declared facets (see ADR-0003).
bool isFacetDeclared(FacetKey key, SceneModel scene);
```

### Implementation Guidelines

- Place in `lib/game/ontology.dart` (pure Dart).
- `CapabilityDimension` is the *only* place axes are defined. A lint/forbidden-pattern check (per `technical-preferences.md`) must reject any runtime attempt to extend the axis set.
- **Magnitude scale ownership**: ADR-0002 (the `Ontology` object) is the single owner of the canonical magnitude range (0–100 default, consistent with `Alertness 0–100` meters). Thresholds (ADR-0003 `AxisAtLeast`) and the Translator's magnitude tables (ADR-0004) must agree with it; the exact range is a tuning knob, the *closed set* is not.
- **Axis equality**: use `CapabilityAxisKey` (a record) wherever an axis keys a map or is matched in a threshold — never the `CapabilityAxis` object directly, unless it overrides `==`/`hashCode`. This is load-bearing for Resolver determinism.
- Facet keys use `snake_case`; scenes own their facet namespace.

## Alternatives Considered

### Alternative 1: Fully open/dynamic axis set (data-driven dimensions)

- **Description**: Let scenes/Compiler define new scalar axes as data.
- **Pros**: Maximum flexibility; designers never blocked on an ADR.
- **Cons**: Translator and Compiler could drift apart; cross-scene balancing becomes impossible; the determinism guarantee collapses.
- **Estimated Effort**: Similar.
- **Rejection Reason**: Directly violates the "never coin new scalar axes at runtime" forbidden pattern and the concept's core mitigation.

### Alternative 2: Single flat tier (everything is a keyed value)

- **Description**: No distinction between balanced axes and scene flags.
- **Pros**: Simplest model.
- **Cons**: Loses the balancing surface; no shared language guarantee between Compiler and Translator.
- **Estimated Effort**: Lower.
- **Rejection Reason**: The two-tier split is the concept's mechanism for taming infinite input onto a finite balanced surface.

## Consequences

### Positive

- A guaranteed shared language between Translator and Compiler (closed axis set).
- Free local expressiveness via open facets without polluting the balanced surface.
- Balancing is confined to ~12 axes — tractable.

### Negative

- Adding a genuinely new axis requires an ADR (deliberate friction).
- The promotion decision (when a facet "deserves" axis status) is a recurring editorial judgment.

### Neutral

- Social needs special-case handling (sub-channels) everywhere a plain dimension is used.

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| Initial 12 axes prove insufficient for coverage | Medium | Medium | Promotion path exists; prototype the magistrate scene to stress the axis set early |
| Designers route around the closed set via facet abuse | Medium | Low | Scene Linter (ADR-0005) flags scalar-behaving facets as promotion candidates |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| CPU | n/a | enum compares — negligible | 16.6ms frame |
| Memory | n/a | negligible | 150MB ceiling |

## Migration Plan

Greenfield. **Rollback/extension**: axis changes are made by superseding this ADR, never by editing the enum without one.

## Validation Criteria

- [ ] `CapabilityDimension` contains exactly the concept's canonical set; no runtime path adds members
- [ ] Social sub-channels are addressable everywhere a dimension is used
- [ ] Facet keys validate against the active scene's declared set; unknown keys are rejected
- [ ] A documented promotion example (facet → axis) round-trips through an ADR

## GDD Requirements Addressed

Foundational — no GDD requirement (no system GDDs yet). Sourced from
`design/gdd/game-concept.md` → "The Capability Ontology — two tiers" and "Foundational ADRs" #2.

| Source | Pillar / Concept | How This ADR Satisfies It |
|--------|------------------|--------------------------|
| `design/gdd/game-concept.md` | Pillar 6 ("typed thresholds on a shared ontology") | Defines that shared ontology |
| `design/gdd/game-concept.md` | Determinism mitigation #1 (classify-don't-score) | Closed axis set is the precondition for consistent scoring |

**Enables**: Scene Model thresholds (ADR-0003), Translator output (ADR-0004), Compiler grounding (ADR-0005), Resolver matching (ADR-0006).

## Related

- ADR-0001 (StateDelta) — deltas reference these axes/facets
- ADR-0003 (Scene Model) — declares scene-local facets and thresholds over these axes
- ADR-0004 (Translator) — emits magnitudes on these axes (classify-don't-score)
