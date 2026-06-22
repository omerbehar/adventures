# ADR-0007: Tiered Router Cascade + Bounded Fallback

## Status

Proposed

## Date

2026-06-21

## Last Verified

2026-06-21

## Decision Makers

technical-director, network-programmer, flutter-specialist (authored via /architecture-decision, batch foundational set)

## Summary

Defines the four-tier routing cascade that turns player text into a resolvable outcome at
the lowest possible cost: Tier 0 exact/cached match → Tier 1 embedding retrieval → Tier 2
Haiku disambiguation → Tier 3 Sonnet bounded fallback. Tiers 0–1 + the Resolver run
client/edge-side (offline-capable); Tiers 2–3 run service-side. The bounded fallback emits a
*validated* `StateDelta` within creator bounds — never prose — under a hard per-turn token
budget.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Flutter 3.44.0 / Dart 3.12 |
| **Domain** | Networking |
| **Knowledge Risk** | MEDIUM/HIGH — async Dart is LOW, but on-device embeddings (Tier 1) and the service model endpoints depend on packages/APIs that post-date training |
| **References Consulted** | `docs/engine-reference/flutter/current-best-practices.md` (async, DI services, Wasm interop caveats), `breaking-changes.md` |
| **Post-Cutoff APIs Used** | None confirmed in Dart yet. On-device embedding runtime (if used) must be verified for Flutter 3.44 / Wasm |
| **Verification Required** | Decide + verify on-device vs server embeddings (open question in concept); confirm any embedding package works under Skwasm/Wasm and mobile |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (fallback emits StateDelta), ADR-0004 (classifier is Tier 2/3), ADR-0006 (Resolver consumes routed vectors / reports NoMatch) |
| **Enables** | ADR-0008 (feedback loop captures Tier-3 proposals) |
| **Blocks** | MVP graceful-degradation + service-integration epics |
| **Ordering Note** | Author after ADR-0004 and ADR-0006. Tier 1 embedding-location decision may be deferred to the prototype. |

## Context

### Problem Statement

Per-beat LLM cost and latency on mobile/web is a real risk; the common case must be cheap
and offline-capable, while genuine gaps still resolve fairly. We need a routing policy that
escalates only as far as necessary and guarantees that even the deepest fallback produces a
validated state change within creator-declared bounds — never throwaway prose.

### Current State

No code. The concept specifies the tiers (0→1→2→3), where each runs, structured-output
discipline, a hard token budget, and that on-device vs server embeddings is an open question
to decide at `/setup-engine`/prototype.

### Constraints

- **Client/edge**: Tier 0 (exact/cached), Tier 1 (embedding retrieval), and the Resolver — no round-trip in the common case; degrade gracefully offline.
- **Service**: Tier 2 (Haiku disambiguation), Tier 3 (Sonnet bounded fallback) + the evaluative half of the Translator.
- **Bounded fallback**: Tier 3 output is a `StateDelta` validated against the scene within creator-declared bounds (ADR-0001/0003), never prose.
- **Hard per-turn generative-token budget**, instrumented from prototype #1.
- Structured-output discipline at every generative tier.

### Requirements

- Escalate tier-by-tier; stop at the first tier that resolves with sufficient confidence.
- Optimistic UI immediately; Tier 2/3 round-trip ≤2s (per performance budgets).
- Offline mode: Tiers 0–1 + Resolver still function; gracefully report when a gap needs service.
- Emit a validated StateDelta from Tier 3 (bounded), feedable to the Compiler (ADR-0008).

## Decision

A **cascade** orchestrated client-side. Each tier is an async resolver behind a DI interface;
the orchestrator tries them in order and stops at the first confident resolution. Tiers 0–1
are local and feed the Resolver directly; on `NoMatch` (or low confidence) it escalates to
Tier 2 (Haiku disambiguation → a `Classification` for the deterministic scorer, ADR-0004),
and finally Tier 3 (Sonnet bounded fallback) which **proposes a validated `StateDelta` within
creator bounds**. A per-turn token budget guards Tiers 2–3; exceeding it degrades to a
graceful authored "the world doesn't respond to that" outcome.

### Architecture

```
                         player text
                              │
        ┌─────────────────────┴───────── CLIENT / EDGE (offline-capable) ──────────┐
        │  TIER 0  exact / cached match ──hit──► CapabilityVector ─┐                │
        │     │ miss                                               │                │
        │  TIER 1  embedding retrieval ──hit──► CapabilityVector ──┤                │
        │     │ miss / low-confidence                              ▼                │
        │     │                                          [Resolver] (ADR-0006)      │
        │     │                                            │ Resolved → render      │
        │     │                                            │ NoMatch ↓              │
        └─────┼────────────────────────────────────────────┼───────────────────────┘
              ▼ escalate (token budget gate)                │
        ┌──── SERVICE ────────────────────────────────────┐ │
        │  TIER 2  Haiku disambiguation → Classification ──┼─┘ (→ deterministic score, ADR-0004)
        │     │ still unresolved                           │
        │  TIER 3  Sonnet bounded fallback                 │
        │          → validated StateDelta within bounds ───┼──► [validateDelta] ──► apply
        │            (never prose)                         │         │
        └──────────────────────────────────────────────────┘         ▼
                                                          candidate for feedback (ADR-0008)
        budget exceeded / offline gap ──► graceful authored non-response (no invented prose)
```

### Key Interfaces

```dart
/// One tier of the cascade. Ordered; orchestrator stops at first confident result.
abstract interface class RouterTier {
  int get tier;                         // 0..3
  bool get requiresNetwork;             // 0,1 = false; 2,3 = true
  Future<RouteOutcome> attempt(String text, RouteContext ctx);
}

sealed class RouteOutcome { const RouteOutcome(); }
final class Routed     extends RouteOutcome { const Routed(this.vector, this.confidence); final CapabilityVector vector; final double confidence; } // Tier 0/1 local
final class Classified extends RouteOutcome { const Classified(this.classification); final Classification classification; }                           // Tier 2 — needs client-side Stage B scoring (ADR-0004)
final class Proposed   extends RouteOutcome { const Proposed(this.delta); final StateDelta delta; }   // Tier 3 bounded fallback
final class Pass       extends RouteOutcome { const Pass(); }                                          // try next tier

/// Orchestrates the cascade under a per-turn token/latency budget.
final class RouterCascade {
  RouterCascade(this.tiers, this.budget, this.resolver);
  final List<RouterTier> tiers;         // sorted by tier
  final TurnBudget budget;              // hard token + latency ceiling, instrumented
  final Resolver resolver;

  Future<ResolveResult> route(String text, WorldState state);
}
```

### Implementation Guidelines

- Orchestrator in `lib/services/router/`; Tier 0/1 implementations are local (no network), Tier 2/3 are service clients behind DI interfaces — unit tests inject fakes, never hit the live service.
- **Tier 2 → Stage B seam**: a `Classified` outcome from Tier 2 carries only a `Classification`; the orchestrator then runs the **client-side** deterministic `MagnitudeTables.score` (ADR-0004) to produce the `CapabilityVector` before handing it to the Resolver. Scoring never happens server-side — this preserves run-to-run threshold stability.
- **"Creator bounds" = `SceneModel.fallbackBounds`** (ADR-0003). A Tier-3 `Proposed` delta is applied only if every op stays within `fallbackBounds` (touchable facets/meters, `maxMeterDelta`, `allowOutcome`); `validateDelta` checks this. Out-of-bounds ⇒ graceful authored non-response.
- **Optimistic UI**: render an immediate acknowledgment; reconcile when an escalated tier returns (≤2s budget).
- **Token budget** is a first-class object, instrumented from the first prototype; on breach, return the authored graceful non-response (a real, validated, do-nothing-but-acknowledge StateDelta), never a generated apology.
- Tier 3's `StateDelta` must pass `validateDelta` against the active scene's creator bounds before apply; reject (→ graceful non-response) if it doesn't.
- **Offline**: if `requiresNetwork` tiers are unreachable, the cascade resolves with Tiers 0–1 + Resolver and clearly signals when a gap needs connectivity.
- The **embedding location** (on-device vs server) for Tier 1 is an open decision — prototype both; if on-device, verify the embedding runtime works under Skwasm/Wasm and on mobile (flutter-specialist + network-programmer).
- **Wasm interop constraint (concrete)**: under the Skwasm/WebAssembly production web build, `dart:js` and legacy `dart:html` interop do **not** work. Any on-device embedding runtime chosen for Tier 1 must expose a Wasm-compatible surface via `dart:js_interop` + `package:web`; packages still relying on `dart:js`/`dart:html` are incompatible with the web target and would force server-side embeddings there.

## Alternatives Considered

### Alternative 1: Always call the top model (no cascade)

- **Description**: Send every turn to Sonnet.
- **Pros**: Simplest; best single-shot quality.
- **Cons**: Per-beat cost/latency unacceptable on mobile/web; no offline; blows the token budget.
- **Estimated Effort**: Lower.
- **Rejection Reason**: Violates the latency/cost budgets and offline requirement.

### Alternative 2: Local-only (no service tiers)

- **Description**: Tiers 0–1 + Resolver only; gaps just fail.
- **Pros**: Fully offline, cheapest.
- **Cons**: Genuine gaps never resolve; coverage risk unmitigated; no bounded fallback.
- **Estimated Effort**: Lower.
- **Rejection Reason**: The bounded fallback is needed for fairness at gaps; cascade keeps it rare and cheap instead of removing it.

## Consequences

### Positive

- Common case is local, instant, and offline-capable; cost concentrates only on real gaps.
- Even the deepest fallback is bounded and validated — no prose, no unfairness.
- Token budget is explicit and instrumented, protecting mobile/web viability.

### Negative

- Four tiers + an orchestrator is the most operationally complex subsystem.
- Confidence thresholds between tiers are a tuning surface that needs eval support.

### Neutral

- Tier 1 embedding location (device vs server) is an explicit, deferred decision.

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| Per-turn cost/latency exceeds budget | Medium | High | Hard token budget object; cascade stops early; cache Tier 0; instrument from prototype #1 |
| Tier 3 proposes an out-of-bounds delta | Medium | High | `validateDelta` against creator bounds before apply; reject → graceful non-response |
| On-device embeddings don't work under Wasm/mobile | Medium | Medium | Prototype both locations; fall back to server embeddings if needed (verify per ADR engine notes) |
| Confidence tuning between tiers is fragile | Medium | Medium | Versioned thresholds + eval harness (constraint #5) |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| CPU (Tier 0/1) | n/a | hash/lookup + vector search, low ms | 16.6ms frame |
| Network (Tier 2/3) | n/a | one bounded structured call when escalated | ≤2s round-trip; hard token budget |
| Memory | n/a | embedding index + caches | 150MB ceiling (watch index size) |
| Offline | n/a | Tiers 0/1 + Resolver functional | graceful degradation required |

## Migration Plan

Greenfield. MVP can ship with Tiers 0/1 + Resolver + a minimal Tier 3 bounded fallback; Tier 2 disambiguation can be added as escalation tuning matures.

**Rollback plan**: disable upper tiers via config to fall back to local-only resolution; the Resolver still functions.

## Validation Criteria

- [ ] Cascade stops at the lowest sufficient tier (measured tier-hit distribution)
- [ ] Tier 3 output always passes `validateDelta` within creator bounds, or degrades gracefully
- [ ] Per-turn token budget is enforced; breach yields a validated graceful non-response, not prose
- [ ] Offline: Tiers 0/1 + Resolver resolve known intents; gaps are clearly signaled
- [ ] Tier 2/3 round-trip within the ≤2s budget under optimistic UI

## GDD Requirements Addressed

Foundational — no GDD requirement (no system GDDs yet). Sourced from
`design/gdd/game-concept.md` → "Where each piece runs", stack-shaping constraints, "Foundational ADRs" #7.

| Source | Pillar / Concept | How This ADR Satisfies It |
|--------|------------------|--------------------------|
| `design/gdd/game-concept.md` | Pillar 2 (bounded AI emits validated state change) | Tier 3 emits a validated StateDelta within bounds |
| `design/gdd/game-concept.md` | Stack constraint #1 (deterministic hot path client-side) | Tiers 0/1 + Resolver are local |
| `design/gdd/game-concept.md` | Stack constraint #4 (hard token budget) | TurnBudget enforced from prototype #1 |

**Enables**: feedback loop (ADR-0008).

## Related

- ADR-0001 (StateDelta) — Tier 3 proposes one
- ADR-0004 (Translator) — Tier 2/3 perform Stage A classification
- ADR-0006 (Resolver) — consumes routed vectors; reports NoMatch to trigger escalation
- ADR-0008 (Feedback loop) — captures Tier-3 proposals as Compiler candidates
