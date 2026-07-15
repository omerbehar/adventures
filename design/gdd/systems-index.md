# Systems Index: Adventures

> **Status**: Draft (lightweight map — per-system GDDs intentionally deferred)
> **Created**: 2026-06-22
> **Last Updated**: 2026-06-22
> **Source Concept**: design/gdd/game-concept.md

---

## Overview

Adventures is a text-first RPG whose mechanical scope is a **resolution pipeline**, not a
content tree: the player types freeform intent, a Translator classifies it into a typed
capability vector, and a deterministic Resolver matches that vector against an authored Scene
Model to emit a validated `StateDelta`. Every system below exists to make that pipeline
*deterministic, authored, and fair* (Pillars 1, 2, 6) while keeping the common case cheap and
offline (the tiered router). The systems map 1:1 onto the nine Accepted ADRs in
`docs/architecture/` — the **architecture is specified; this index records the system map and
defers the per-system design (GDD) layer until the core bet is validated by prototype** (the
concept's "Path B — Prototype-First").

> **Why GDDs are deferred (Option C):** the concept's central, unproven bet is run-to-run
> decisive-move threshold stability under classify-don't-score. The plan is to prove that with
> the magistrate prototype *before* spending on per-system design docs. This index gives an
> authoritative system map and dependency order now; `/design-system` per system runs only if
> the prototype PROCEEDS.

---

## Systems Enumeration

| # | System Name | Category | Priority | Governing ADR | Design Doc | Status | Depends On |
|---|-------------|----------|----------|---------------|------------|--------|------------|
| 1 | StateDelta Primitive | Core | MVP | ADR-0001 (Accepted) | — (deferred) | Arch Accepted · GDD deferred | — |
| 2 | Capability Ontology | Core | MVP | ADR-0002 (Accepted) | — (deferred) | Arch Accepted · GDD deferred | — |
| 3 | Scene Model | Core | MVP | ADR-0003 (Accepted) | — (deferred) | Arch Accepted · GDD deferred | StateDelta, Ontology |
| 4 | Capability Translator (classify-don't-score) | Gameplay | MVP | ADR-0004 (Accepted) | — (deferred) | Arch Accepted · GDD deferred | Ontology |
| 5 | Specialist Classes (lens) | Gameplay | MVP (one class) | ADR-0004 (Accepted) | — (deferred) | Arch Accepted · GDD deferred | Translator, Ontology |
| 6 | Resolver (per-beat rules engine) | Gameplay | MVP | ADR-0006 (Accepted) | — (deferred) | Arch Accepted · GDD deferred | StateDelta, Ontology, Scene Model, Translator |
| 7 | Tiered Router Cascade + Bounded Fallback | Gameplay / Networking | MVP (minimal: T0/1 + minimal T3) | ADR-0007 (Accepted) | — (deferred) | Arch Accepted · GDD deferred | StateDelta, Translator, Resolver |
| 8 | Client & UI | UI | MVP (bare text UI) | ADR-0009 (Accepted) | — (deferred) | Arch Accepted · GDD deferred | StateDelta, Resolver, Router |
| 9 | Eval Harness + Versioned Tables/Prompts *(inferred)* | Meta | MVP / Prototype | — (TR-cfg-001, no ADR) | — (deferred) | Not Started | Translator, Router |
| 10 | Scene Compiler + Grounding Tables + Linter | Meta (tooling, offline) | Vertical Slice | ADR-0005 (Accepted) | — (deferred) | Arch Accepted · GDD deferred | Ontology, Scene Model |
| 11 | Persistence / Save | Persistence | Vertical Slice | — (TR-persist-001, no ADR) | — (deferred) | Not Started | StateDelta, Scene Model |
| 12 | Feedback Loop (fallback → Compiler candidate) | Meta (tooling, offline) | Alpha (post-MVP) | ADR-0008 (Accepted) | — (deferred) | Arch Accepted · GDD deferred | Compiler, Router, StateDelta |

*System 9 (Eval Harness) and System 11 (Persistence) are **inferred** — referenced by the
concept (stack constraint #5; "StateDelta persistence between sessions") but not yet covered by
a dedicated ADR. They correspond to the open registry items TR-cfg-001 and TR-persist-001.*

---

## Categories

| Category | Description | Systems here |
|----------|-------------|--------------|
| **Core** | Foundation primitives everything depends on | StateDelta, Ontology, Scene Model |
| **Gameplay** | The systems that make the game work | Translator, Specialist Classes, Resolver, Router |
| **Persistence** | Save state and continuity | Persistence / Save |
| **UI** | Player-facing presentation | Client & UI |
| **Meta** | Outside the runtime hot loop (tooling, eval, offline) | Eval Harness, Scene Compiler, Feedback Loop |

*(Audio and Narrative are intentionally absent: audio is minimal/deferred per the concept, and
"narrative" here is authored `narrationKey` content inside the Scene Model, not a separate
delivery system.)*

---

## Priority Tiers

| Tier | Definition | Target Milestone |
|------|------------|------------------|
| **MVP** | Required for the core loop to be testable ("is the resolution loop fun + stable?") | First playable / prototype |
| **Vertical Slice** | One polished adventure; first rough Scene Compiler; basic save | Public demo |
| **Alpha** | All classes, content scale-up, internal creator toolkit | Alpha |
| **Full Vision** | Public creator tools + sharing | Release |

---

## Dependency Map

### Foundation Layer (no dependencies)
1. **StateDelta Primitive** — the single validated state-change record all resolution emits.
2. **Capability Ontology** — the closed scalar axes + open facets every action/threshold is expressed in.

### Core Layer (depends on foundation)
1. **Scene Model** — depends on: StateDelta, Ontology.
2. **Capability Translator** — depends on: Ontology.
3. **Specialist Classes** — depends on: Translator, Ontology (a lens over the Translator's class-colored tables).

### Feature Layer (depends on core)
1. **Resolver** — depends on: StateDelta, Ontology, Scene Model, Translator (most-dependent of the core four).
2. **Tiered Router Cascade** — depends on: StateDelta, Translator, Resolver.
3. **Eval Harness** — depends on: Translator, Router (validates threshold stability; gates the prototype).

### Presentation Layer (depends on features)
1. **Client & UI** — depends on: StateDelta (narrationKey lookup), Resolver, Router.

### Polish / Offline Layer (depends on everything / runs offline)
1. **Persistence / Save** — depends on: StateDelta, Scene Model.
2. **Scene Compiler + Linter** — depends on: Ontology, Scene Model (offline; Vertical Slice).
3. **Feedback Loop** — depends on: Compiler, Router, StateDelta (offline; post-MVP).

---

## Recommended Design Order

Per the concept's MVP build order (*Resolver/StateDelta → Translator → Scene Model → one
adventure*). **GDD authoring is deferred until the prototype PROCEEDS** — this is the order to
follow when/if those GDDs are written.

| Order | System | Priority | Layer | Agent(s) | Est. Effort |
|-------|--------|----------|-------|----------|-------------|
| 1 | StateDelta Primitive | MVP | Foundation | gameplay-programmer / game-designer | S |
| 2 | Capability Ontology | MVP | Foundation | game-designer / systems-designer | M |
| 3 | Scene Model | MVP | Core | game-designer | M |
| 4 | Capability Translator | MVP | Core | systems-designer + ai-programmer | L |
| 5 | Resolver | MVP | Feature | systems-designer | M |
| 6 | Specialist Classes | MVP (one) | Core | game-designer | S |
| 7 | Tiered Router Cascade | MVP (minimal) | Feature | network-programmer | M |
| 8 | Client & UI | MVP (bare) | Presentation | ux-designer / ui-programmer | M |

*Effort: S = 1 session, M = 2–3 sessions, L = 4+ sessions.*

---

## Circular Dependencies

- **None at the system level.** (Note: a code-level definitional cycle between StateDelta and
  Scene Model — `validateDelta` referencing `SceneModel` — was identified in the 2026-06-22
  architecture review and resolved by placing `validateDelta` in the scene/validation layer; see
  ADR-0001.)

---

## High-Risk Systems

| System | Risk Type | Risk Description | Mitigation |
|--------|-----------|-----------------|------------|
| Capability Translator | Technical / Design | Run-to-run magnitude variance would destabilize the decisive-move threshold — **the project's top risk and prototype kill-criterion** | classify-don't-score (ADR-0004); **prototype the magistrate scene FIRST**, measure stability before any content spend |
| Scene Compiler | Design / Scope | "Bulk-approve" could become a false economy (human re-checks every number) | Grounding tables + deterministic Scene Linter (ADR-0005); deferred to Vertical Slice |
| Tiered Router Cascade | Technical | Per-turn LLM cost/latency on mobile/web; on-device embeddings under Wasm | Cascade + hard token budget instrumented from prototype #1; decide embedding location at prototype (ADR-0007) |
| Eval Harness | Scope | Without it, threshold stability can't be measured — the prototype gate has no instrument | Build alongside the prototype; promote TR-cfg-001 to a tracked artifact |

---

## Progress Tracker

| Metric | Count |
|--------|-------|
| Total systems identified | 12 |
| Governed by an Accepted ADR | 9 |
| Systems with no ADR yet (inferred) | 3 (Eval Harness, Persistence, + class-lens shares ADR-0004) → 2 net gaps (TR-cfg-001, TR-persist-001) |
| Design docs (GDDs) started | 0 (intentionally deferred) |
| Design docs reviewed | 0 |
| MVP systems designed | 0 / 8 (deferred to post-prototype) |

---

## Next Steps

- [x] Record the authoritative system map and dependency order (this document)
- [ ] **Build the magistrate prototype** (`/prototype intent-translation`) — validate threshold stability (the kill-criterion) BEFORE writing per-system GDDs
- [ ] If the prototype PROCEEDS → author MVP-tier GDDs in design order (`/design-system [system]`), then `/review-all-gdds`
- [ ] Author the two missing ADRs when their systems are scheduled: Eval Harness (TR-cfg-001), Persistence/Save (TR-persist-001)
- [ ] If the prototype PIVOTS → return to `/brainstorm` with the learnings
