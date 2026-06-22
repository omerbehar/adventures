# ADR-0008: Feedback Loop (Fallback Proposal → Compiler Candidate)

## Status

Proposed

## Date

2026-06-21

## Last Verified

2026-06-21

## Decision Makers

technical-director, game-designer, flutter-specialist (authored via /architecture-decision, batch foundational set)

## Summary

Defines the offline-gated loop by which a Tier-3 bounded-fallback `StateDelta` that resolved
a real gap is captured and proposed back to the Scene Compiler as a candidate authored path —
reviewed, linted, and approved by a designer before it becomes canonical. Content improves
from play, but nothing the fallback invents is ever promoted to canonical at runtime.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Flutter 3.44.0 / Dart 3.12 |
| **Domain** | Core / Tooling (offline) |
| **Knowledge Risk** | LOW/MEDIUM — capture/serialization is pure-Dart (LOW); the offline Compiler step depends on an external model (MEDIUM, see ADR-0005) |
| **References Consulted** | `docs/engine-reference/flutter/current-best-practices.md`, ADR-0005, ADR-0007 |
| **Post-Cutoff APIs Used** | None in shipped Dart |
| **Verification Required** | None for capture; Compiler-side verification is covered by ADR-0005 |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0005 (Compiler + Linter — the review target), ADR-0007 (router cascade — source of proposals), ADR-0001 (StateDelta — the captured artifact) |
| **Enables** | Post-MVP content improvement; Alpha creator-toolkit feedback workflows |
| **Blocks** | None (last in the foundational set) |
| **Ordering Note** | Author last. Not required for MVP or the prototype. |

## Context

### Problem Statement

The bounded fallback (Tier 3) resolves genuine coverage gaps at runtime. Those gaps are
exactly the signal designers need to improve scenes. Without a loop, every gap is resolved
once and forgotten; with an *unguarded* loop, runtime AI output could silently mutate
canonical content — destroying determinism and editorial control. We need a way to harvest
fallback resolutions into authored content **safely**: offline, reviewed, and linted.

### Current State

No code. The concept specifies the loop and that it is "offline-gated" — fallback proposals
become Compiler candidate paths, not live content.

### Constraints

- **Offline-gated**: a captured proposal is a *candidate*, never canonical until a designer approves it through the Compiler/Linter pipeline (ADR-0005).
- **No runtime promotion**: the runtime never edits frozen scenes; it only *records* proposals.
- Captured artifact is a validated `StateDelta` + context (the intent, scene node, world state, class) — enough to author a real path.
- Privacy/telemetry: capturing player input must respect the project's data handling (decide what is stored, anonymization).

### Requirements

- Record each Tier-3 resolution with enough context to reconstruct an authored `SolutionPath`.
- Queue captured candidates for offline review (a designer-facing batch).
- Feed approved candidates through the Compiler → Linter → bulk-approve → freeze path (ADR-0005).
- Never alter canonical scenes at runtime; the loop is strictly capture-now, author-later.

## Decision

A **capture-and-propose** loop. At runtime, when Tier 3 produces a validated `StateDelta`
for a gap (ADR-0007), the cascade emits a `FallbackProposal` record (intent text, scene node
id, world-state snapshot, active class, the proposed delta) to an append-only **proposal sink**
(local queue, synced to the service when online). **Offline**, a batch tool turns clustered
proposals into candidate `SolutionPath`s, runs them through the Compiler/Linter (ADR-0005),
and presents them to a designer for bulk-approval. Approved paths are added to the scene and
re-frozen. Nothing in this loop touches canonical content without passing the same editorial
gate as any authored scene.

### Architecture

```
RUNTIME (online or offline)                          OFFLINE (gated)
──────────────────────────                           ─────────────────────────────
Tier 3 bounded fallback (ADR-0007)
  └─ validated StateDelta ──► FallbackProposal ──► proposal sink (append-only)
        {intent, nodeId, stateSnapshot,                      │ (sync when online)
         classId, delta}                                     ▼
                                            ┌─────────────────────────────────────┐
                                            │ cluster proposals → candidate paths   │
                                            │            ▼                          │
                                            │   Compiler/Linter (ADR-0005)          │
                                            │            ▼                          │
                                            │   designer bulk-approve               │
                                            └─────────────────┬────────────────────┘
                                                              ▼
                                            add SolutionPath → re-lint → freeze → canonical
                                                              │
                                                              ▼
                                            improved scene served to future players
```

### Key Interfaces

```dart
/// Captured at runtime when Tier 3 resolves a gap. Pure data; no canonical mutation.
final class FallbackProposal {
  const FallbackProposal({required this.intentText, required this.nodeId,
                          required this.stateSnapshot, required this.classId,
                          required this.proposedDelta, required this.capturedAt});
  final String intentText;
  final String nodeId;
  final WorldStateSnapshot stateSnapshot;
  final String classId;
  final StateDelta proposedDelta;       // ADR-0001, already validated within bounds
  final String capturedAt;              // logical beat/version stamp, not a wall clock for gameplay
}

/// Append-only sink; local queue synced to service when online. No canonical writes.
abstract interface class ProposalSink {
  Future<void> record(FallbackProposal proposal);
}

/// OFFLINE batch: cluster proposals → candidate SolutionPaths for the Compiler/Linter.
abstract interface class ProposalReviewBatch {
  Future<List<SolutionPath>> toCandidatePaths(List<FallbackProposal> proposals, SceneModel scene);
}
```

### Implementation Guidelines

- `FallbackProposal` + `ProposalSink` are simple and live near the cascade (`lib/services/router/feedback/`); recording must be **fire-and-forget** and must never block or alter the resolved turn.
- The runtime side ONLY records. The `ProposalReviewBatch`, clustering, and Compiler/Linter run in `tools/` offline — never in shipped client hot paths.
- `capturedAt` is a logical/version stamp for ordering and dedup, not a gameplay clock (gameplay stays per-beat, ADR-0006). Encode it as `"<sceneId>:<beat>@<sceneVersion>"` (e.g. `"prisonCell:42@v3"`) so dedup and "which scene version produced this" are both derivable. `WorldStateSnapshot` is the type defined in ADR-0001.
- Decide and document the **data-handling policy** (what player text is stored, retention, anonymization) before enabling capture in any build that ships to players; coordinate with security-engineer.
- Candidate paths re-enter the *same* freeze discipline as authored scenes — no shortcut to canonical.

## Alternatives Considered

### Alternative 1: Auto-promote fallback resolutions to canonical at runtime

- **Description**: When the fallback resolves a gap, write it into the scene live.
- **Pros**: Zero authoring effort; content "self-heals" instantly.
- **Cons**: Runtime AI silently mutates canonical content — destroys determinism, balancing, and editorial control.
- **Estimated Effort**: Lower.
- **Rejection Reason**: Violates the offline-gated requirement and every determinism/editorial guarantee.

### Alternative 2: No feedback loop (discard fallback resolutions)

- **Description**: Resolve gaps and forget them.
- **Pros**: Simplest; no telemetry/privacy surface.
- **Cons**: Wastes the single best signal for closing the coverage risk; scenes never improve from play.
- **Estimated Effort**: Lowest.
- **Rejection Reason**: Leaves the highest design risk (coverage) without its most natural data source. Acceptable to defer (post-MVP) but not to abandon.

## Consequences

### Positive

- Scenes measurably improve from real play, directly attacking the coverage risk.
- The editorial gate (Compiler/Linter/approve) is preserved end-to-end — no determinism loss.
- Proposals are a rich corpus for tuning grounding tables (ADR-0005) and classify tables (ADR-0004).

### Negative

- Introduces a telemetry/privacy surface that must be governed deliberately.
- Adds an offline review workload (mitigated by clustering + the Compiler/Linter).

### Neutral

- Value scales with play volume; near-zero benefit until there is a player base (hence post-MVP).

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| Player input capture raises privacy concerns | Medium | High | Define retention/anonymization policy with security-engineer before shipping capture |
| Proposal volume overwhelms review | Medium | Medium | Cluster/dedup proposals; Linter pre-filters; review by impact |
| Recording impacts the resolved turn | Low | Medium | Fire-and-forget sink; never on the critical path |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| CPU (runtime capture) | n/a | negligible, async fire-and-forget | 16.6ms frame (must not block) |
| CPU (offline review) | n/a | batch clustering + lint | offline only |
| Network | n/a | small proposal sync when online | within turn budget; deferred/batched |
| Storage | n/a | append-only proposal log | governed by retention policy |

## Migration Plan

Deferred to post-MVP. Capture can be wired in once Tier 3 and the Compiler/Linter exist; until then the cascade simply resolves gaps without recording.

**Rollback plan**: disable the proposal sink via config; runtime resolution is unaffected (capture is fire-and-forget and optional).

## Validation Criteria

- [ ] A Tier-3 resolution produces a `FallbackProposal` without altering canonical content
- [ ] Recording is fire-and-forget and never blocks or changes the resolved turn
- [ ] Offline review turns clustered proposals into candidate paths that pass the Linter
- [ ] Approved candidates re-enter the freeze pipeline; canonical changes only via approval
- [ ] A documented data-handling policy exists before capture ships in a player build

## GDD Requirements Addressed

Foundational — no GDD requirement (no system GDDs yet). Sourced from
`design/gdd/game-concept.md` → "When no path matches… fed back (offline-gated) to the Compiler", "Foundational ADRs" #8.

| Source | Pillar / Concept | How This ADR Satisfies It |
|--------|------------------|--------------------------|
| `design/gdd/game-concept.md` | Hook ("its proposals can feed back to the Compiler") | Capture → candidate path, offline-gated |
| `design/gdd/game-concept.md` | Coverage risk (highest) | Harvests real gaps into authored content |
| `design/gdd/game-concept.md` | Pillar 2 / determinism | No runtime promotion; editorial gate preserved |

**Enables**: post-MVP content improvement; creator-toolkit feedback workflows (Alpha-B).

## Related

- ADR-0005 (Compiler + Linter) — the review/approve target for candidates
- ADR-0007 (Router cascade) — source of Tier-3 proposals
- ADR-0001 (StateDelta) — the captured, validated artifact
