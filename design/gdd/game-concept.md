# Game Concept: Adventures

*Created: 2026-06-21*
*Status: Draft*

> **Creative Director Review (CD-PILLARS)**: CONCERNS resolved — Pillars 1 & 4 sharpened; 6th pillar added 2026-06-21
> **Art Director Review (AD-CONCEPT-VISUAL)**: CONCEPTS — three directions proposed, selection deferred 2026-06-21
> **Technical Director Review (TD-FEASIBILITY)**: CONCERNS (VIABLE pending architecture lock) — runtime router guidance integrated 2026-06-21
> **Technical Director Review (TD-PIPELINE)**: CONCERNS (VIABLE pending 3 mitigations) — authoring pipeline pressure-tested; mitigations + decisions integrated 2026-06-21
> **Producer Review (PR-SCOPE)**: OPTIMISTIC — five adjustments integrated; authoring engine moved early 2026-06-21

---

## Elevator Pitch

> It's a text-first RPG where you type **whatever you want to do** in your own
> words, and the world translates your intent into hand-authored, consequential
> events — every encounter won by the right **decisive move**, not by grinding.
> Like an AI dungeon master, *and also* every freeform action lands on real
> designed content with real stakes — and designers don't script every outcome,
> they write a *scene* and an authoring engine models the space of what's possible.

---

## Core Identity

| Aspect | Detail |
| ---- | ---- |
| **Genre** | Text-first RPG / interactive fiction with AI intent translation + UGC creator platform |
| **Platform** | Multi-platform — PC (Steam/Epic), Web/Browser, Mobile (iOS/Android), ideally one codebase |
| **Target Audience** | Explorers, storytellers/creators, and decisive-move tacticians |
| **Player Count** | Single-player, with creator-authored adventures shared between players |
| **Session Length** | ~15–30 minutes per adventure |
| **Monetization** | None yet (premium or platform model deferred) |
| **Estimated Scope** | Large (open-ended timeline, team of 2–4) |
| **Comparable Titles** | AI Dungeon, Disco Elysium, parser IF (Zork/Anchorhead), Slay the Spire (decisive-move combat) |

---

## Core Fantasy

**"You can say anything, and a world built by real designers takes it seriously.
Your cleverness — expressed in your own words — is the whole game."**

The fantasy is the *blank line*: an open invitation to act in your own voice,
backed by the promise that the world has been authored to answer you with real
consequence. You are not picking from options; you are *expressing intent*, and
the world resolves it.

---

## Unique Hook

**Translate every player text to an authored event** — and **model the scene
instead of scripting it.** Two translations, mirror images of each other:

- **Runtime**: translate the *player's words* → the nearest *authored outcome*.
- **Authoring**: translate the *designer's scene* → the *space of possible outcomes*.

The AI is never a novelist. At runtime it is a **semantic router** mapping freeform
language to authored consequence. At authoring time it is a **scene compiler** that
expands sparse prose into a model of typed possibilities. In both directions the AI
proposes; **deterministic, authored rules dispose** — every resolution emits a
validated state change, never throwaway prose.

This passes the "and also" test cleanly: *like AI Dungeon, and also* every action
lands on authored content with persistent state; *like parser IF, and also* the
blank line accepts anything; *like Disco Elysium, and also* you write your own
input; *like a tabletop RPG, and also* the DM's answers are authored, fair, and
repeatable.

The moat lives across six pillars — most critically **authored translation** (P2),
the **unified player/creator primitive** (P4), **class-colored resolution** (P5),
and **the scene-as-model** (P6).

---

## Player Experience Analysis (MDA Framework)

### Target Aesthetics (What the player FEELS)

| Aesthetic | Priority | How We Deliver It |
| ---- | ---- | ---- |
| **Discovery** | 1 | Probing the blank line; *discovery moves* that reveal hidden facets of a scene |
| **Expression** | 2 | Acting in your own words; class coloring resolution; authoring with the same toys |
| **Challenge** | 3 | Finding the *decisive move* — the action that flips the highest-leverage facet |
| **Fantasy** | 4 | Being a *specialist* whose worldview shapes what is possible |
| **Narrative** | 5 | Authored adventures with consequence carried through state |
| **Sensation** | 6 | Typography-forward presentation; the translation moment as a visual beat |

### Key Dynamics (Emergent behaviors we WANT)
- Players experiment with phrasings to probe the authored space.
- Players read each scene for the **facet that breaks it open** (the decisive move).
- Players adopt a class "lens," reading encounters for what *their* specialist can uniquely do.
- Creators play, think "I'd model that scene differently," and cross into authoring with the same primitives.

### Core Mechanics (Systems we build)
1. **The Blank Line + Capability Translator** — freeform text → a typed capability vector `{dimension, magnitude, target}`.
2. **The Resolver** — a deterministic per-beat rules engine matching capability vectors against a scene's typed thresholds.
3. **The Scene Model** — entities with typed properties, solution paths as conditional thresholds, scalar meters, and scene-graph composition.
4. **The Authoring Engine (Scene Compiler)** — expands a designer's sparse scene prose into a reviewable Scene Model.
5. **Bounded AI Fallback** — resolves genuine gaps into a *validated* state change, never prose; its proposals can feed back to the Compiler.
6. **Specialist Classes** — a lens over the shared model; the same intent resolves differently per class.

---

## Player Motivation Profile

### Psychological Needs (Self-Determination Theory)
| Need | How This Game Satisfies It | Strength |
| ---- | ---- | ---- |
| **Autonomy** | The blank line — total freedom of *input* | Core |
| **Competence** | The decisive move — finding the leverage facet feels skillful *because* it lands on real authored content | Core |
| **Relatedness** | Connection to the authored world and its designers; the creator/player loop | Supporting |

### Player Type Appeal (Bartle)
- [x] **Explorers** (primary) — the blank line + discovery moves reward probing.
- [x] **Creators/Storytellers** (primary) — authoring is first-class (P4), and the Compiler lowers its cost.
- [x] **Achievers** (secondary) — the decisive move gives a clean mastery target.
- [ ] **Killers/Competitors** — explicitly NOT served (no twitch, no PvP).

### Flow State Design
- **Onboarding**: the first encounter proves the blank line is real — a natural first phrasing resolves to a satisfying authored event.
- **Difficulty**: scenes escalate by demanding sharper decisive moves and class-aware reads, never by inflating numbers.
- **Feedback**: every resolution emits a visible state change — your words always *did something*.
- **Recovery**: failure is a consequence, not a wall; ~15–30 min adventures make re-approaches cheap.

---

## The Authoring Engine & Resolution Pipeline

This is the spine of the game — the mechanism behind both the hook and Pillar 6.
"All possible outcomes" is **not** an enumerated list of inputs; it is a **scene
model of typed thresholds on a shared capability ontology.** Infinite surface
actions reduce onto a finite set of dimensions.

### The pipeline (author time → run time)

| Stage | Time | Nature | What it does |
| ---- | ---- | ---- | ---- |
| **1. Scene Seed** | author | human | Designer writes sparse prose ("you wake in a prison cell") |
| **2. Scene Compiler** | author | generative (Opus 4.8, offline) | Expands the seed into a **Scene Model**, grounded in canonical tables; output is **linted**, then **bulk-approved** by the designer and **frozen → canonical → deterministic** |
| **3. Capability Ontology** | shared | data | The two-tier vocabulary every requirement and action is expressed in (below) |
| **4. Capability Translator** | runtime | semantic (classify-don't-score) | Freeform intent → `{dimension(s), magnitude, target}`, class-colored (P5) |
| **5. Resolver** | runtime | deterministic rules engine | Per beat: match vector vs. the scene's conditional thresholds → fire the path's `StateDelta` + narration; advance world state; evaluate reactive thresholds |

When no path matches, the **bounded AI fallback** (Tier 3) proposes a *validated*
`StateDelta` within creator bounds; that proposal can be fed back (offline-gated) to
the Compiler as a candidate path — content improves from play.

### Worked example (the prison cell)
Seed: *"You wake up in a prison cell."* → Compiler produces: 3× `stone_wall`
{breach: **Force ≥ 20**}, 1× `bar_wall` {Force ≥ 35, gap: too_narrow}, `window`
{aperture 30×30 → passable_if **Size ≤ 30**}, 2× `guard` {Force 25, hostile}. Paths:
**P1** Force≥20 on stone → ESCAPE · **P2** Size≤30 → window → ESCAPE · **P3** subdue
guards → key. *"I blast the wall with force magic"* (Mage) → `{Force: 30, stone_wall}`
→ Force 30 ≥ 20 → **wall breaches, ESCAPE.**

### The Capability Ontology — two tiers
- **Scalar dimensions: closed / canonical (~12).** Force, Size/Form, Mobility,
  Energy, Durability, Stealth, Insight, **Social *(sub-vectored: persuasion /
  intimidation / deception / rapport)*,** Lore/Arcane, Tech/Craft, Wealth/Resources.
  The Compiler may **not** coin new axes — this is what keeps Compiler and Translator
  speaking the same language. Balancing happens on these axes.
- **Keyed facets: scene-local / open.** `knows_password`, `vault_fears_scandal`,
  `power_cut`. Booleans/flags, free to proliferate, no cross-scene balancing.
- **Promotion path:** a recurring scalar-behaving facet may be promoted to a core
  axis via ADR — an editorial act, **never** at runtime.

### Core resolution mechanics (validated on prison / magistrate / heist)
- **Conditional thresholds** — a path's required magnitude changes with facets
  (Social-persuasion ≥ 35, *reduced to 20 if `knows_vault_fears_scandal`*). **The
  decisive move (P3) = the action that flips the highest-leverage facet, collapsing
  a hard threshold to a trivial one** — not the highest-magnitude action.
- **Discovery moves** — some actions reveal facets rather than progress to a win;
  both progress and discovery are `StateDelta`s. Discovery is the mechanical payoff
  for the Discovery aesthetic.
- **Scalar world-state meters** (e.g., `Alertness 0–100`), not just booleans.
- **Per-beat advancement** — the world steps once per player action; patrols/timers
  are **state machines advanced by moves, never a real-time clock** (honors the
  no-twitch anti-pillar — pressure is beat-economy, like chess, not reflexes).
- **Reactive thresholds** — world-state crossing a line fires an *authored*
  autonomous transition (`Alertness ≥ 60` → lockdown raises thresholds).
- **Scene-graph composition** — an adventure is a graph of nodes sharing global
  meters/facets; an encounter is one node. The same conditional-threshold machinery
  runs at both scales. The decisive move scales to a global facet that cascades
  thresholds across the graph ("cut the power and the whole job opens up").
- **Side-effect StateDeltas** — a path can hit the goal *and* move a meter
  (Force≥50 cracks the vault *and* +40 Alertness = the loud/quiet tradeoff).

### Determinism discipline (the three TD mitigations)
1. **Classify-don't-score.** The Translator's LLM names *which* facets/tactics an
   action invokes plus a coarse ordinal; **deterministic tables compute the
   magnitude.** This keeps the *same* argument scored consistently run-to-run —
   protecting Pillars 2 & 3 against LLM variance. (Physical translation is near-
   deterministic/lookup; social is evaluative — classify-don't-score tames the latter.)
2. **Grounding tables + a deterministic Scene Linter** make bulk-approve *real*: a
   constrained Compiler (drawing on canonical materials/archetype tables) plus a
   linter that flags inconsistent or unbalanced thresholds — so the reviewer isn't
   secretly re-checking every number by hand.
3. **Prototype the magistrate (social) scene first,** with run-to-run decisive-move
   threshold stability as the explicit kill criterion — before any Compiler, tooling,
   or content spend.

---

## Core Loop

### Moment-to-Moment (30s)
Read the situation → **type freeform intent** → the Translator forms a capability
vector → the Resolver fires a visible state change. The payoff is the *translation
moment*: "I said what I wanted, and the world took it seriously."

### Short-Term (5–15 min)
An **encounter** (one scene node): probe for the leverage facet, read your class's
angle, land the decisive move.

### Session-Level (15–30 min)
A complete **adventure** (a scene-graph) with state carried forward to a clear
resolution. The hook to return: the next adventure, or a replay as a different specialist.

### Long-Term Progression
Growth is in **player knowledge and options** (learning how the world reads intent,
mastering each class's lens) and — for creators — building and sharing adventures.

---

## Game Pillars

*(Full detail in `design/gdd/game-pillars.md`. Summary below — now six.)*

1. **The Blank Line Is Sacred** — every situation accepts freeform intent, resolved into authored consequence.
2. **Translation, Not Improvisation** — freedom resolves by mapping words to authored outcomes; even the AI fallback emits a validated state change, never prose.
3. **The Decisive Move** — encounters are won by flipping the highest-leverage facet to collapse a threshold, at the right *game-state* moment (state-based, never clock-based).
4. **Creators Play With The Same Toys** — players and creators share the same authoring primitives; primitive parity is the promise (experience-parity is not).
5. **Specialists, Not Everymen** — your class shapes which intents are powerful; the same words resolve differently per specialist.
6. **The Scene Is a Model, Not a Script** — designers author a *model of possibility* (typed thresholds on a shared ontology), not enumerated outcomes; the engine resolves against the model.

### Anti-Pillars
NOT a freeform-prose generator · NOT real-time/twitch · NOT a creator-only "dev
mode" players can't reach · NOT a do-everything generalist hero · **NOT an
enumerated branching script** (the scene is a model, not a decision tree).

---

## Visual Identity Anchor

**Status: DEFERRED — three candidate directions retained; AD recommends Direction 2
(*The Illuminated Word*).** This is a text-first game; the blank line is the visual
center. Direction 2 is recommended because its visual language *encodes Pillar 2*
(gold = the moment a player's word becomes the world's word). Directions 1 (*The
Oracle Terminal*) and 3 (*The Struck Match*) retained as alternatives. Decision
finalized before `/art-bible`.

---

## Inspiration and References

| Reference | What We Take | What We Do Differently |
| ---- | ---- | ---- |
| AI Dungeon | Freeform-text agency | Authored events + persistent state, not generative prose |
| Disco Elysium | Text as the world; identity colors perception | Player writes input instead of choosing menus |
| Parser IF (Zork) | The authored, consequential text world | No fixed verb set — the blank line accepts anything |
| Slay the Spire | The decisive-move / perfect-solution feel | Expressed via freeform intent against a scene model |
| Tabletop RPGs | "Try anything"; specialist classes; a world that answers | Authored & repeatable, not human-DM improv |

**Non-game inspirations**: illuminated manuscripts; the typewriter and the terminal;
the ritual weight of the written word.

---

## Target Player Profile

| Attribute | Detail |
| ---- | ---- |
| **Age / experience** | ~18–40; mid-core to hardcore; comfortable reading and typing |
| **Time availability** | 15–30 min sessions; longer for creators |
| **Platform** | Cross-platform; keyboard-forward, mobile-considered |
| **Currently plays** | AI Dungeon, Disco Elysium, interactive fiction, narrative roguelikes |
| **Wants** | Real agency in their own words, answered by a world that was actually designed |
| **Turn-offs** | Inconsistent AI; menus faking freedom; twitch demands; numbers-grind |

---

## Technical Considerations

| Consideration | Assessment |
| ---- | ---- |
| **Engine** | UNDECIDED — run `/setup-engine`. Shape: thin cross-platform text client + AI translation/compiler service, favoring a portable UI layer over a heavy native engine |
| **Key challenges** | Translator reliability (classify-don't-score); Compiler determinism + Scene Linter; the Capability Ontology; the shared StateDelta/Scene-Model schema |
| **Art** | Text-first / typography-forward (direction deferred) |
| **Audio** | Minimal–moderate; a sonic beat on the decisive move |
| **Networking** | Client → service for Tier 2/3 + Compiler; async sharing of authored adventures |
| **Content volume** | Driven by **ontology richness + scene-model authoring**, not raw input enumeration — the authoring engine is the lever |
| **Procedural systems** | None generative at runtime — resolution is *authored*, routed by retrieval/classification, bounded AI only at gaps |

### Where each piece runs (input to `/setup-engine`)
- **Client / edge (deterministic hot path):** text I/O, Tier 0 match, Tier 1
  embedding retrieval, and the **Resolver** (per-beat rules engine) — so the common
  case needs no round-trip and degrades gracefully offline.
- **Service:** Tier 2 (Haiku disambiguation) and Tier 3 (Sonnet bounded fallback);
  the evaluative half of the Translator.
- **Offline batch:** the **Scene Compiler** (Opus 4.8) and the eval harness.

### Foundational ADRs (to author at `/setup-engine` → `/create-architecture`)
1. **StateDelta primitive** — the single typed, validated state-change schema all resolution emits.
2. **Capability Ontology** — closed scalar axes (Social sub-vectored) + open keyed facets + promotion process.
3. **Scene Model schema** — entities, conditional thresholds, scalar meters, reactive thresholds, scene-graph.
4. **Classify-don't-score Translator** — LLM names facets/tactics; deterministic tables compute magnitude.
5. **Scene Compiler + grounding tables + deterministic Scene Linter** — what makes bulk-approve safe.
6. **Resolver as a per-beat deterministic rules engine** — advancement rules + threshold evaluation order.
7. **Tiered router cascade + bounded fallback** — Tier 0→1→2→3, structured-output discipline.
8. **Feedback loop** — offline-gated fallback-proposal → Compiler candidate path.

### Stack-shaping constraints
1. Deterministic hot path (Tier 0/1 + Resolver) must run client/edge-side.
2. The service hosts generative Tier 2/3 + hosts/queues the offline Compiler.
3. One portable cross-platform UI layer over a heavy native engine.
4. A hard per-turn generative-token budget, instrumented from prototype #1.
5. Versioned embedding index + classify tables + prompts, with eval re-runs on any model/table change.

---

## Risks and Open Questions

### Design Risks
- **Coverage / ontology richness** (highest): a reasonable intent must catch on *some*
  axis. Mitigation: rich ontology + the protected playtest coverage bar (below).
- The decisive move could feel like "guess the solution" if scenes don't telegraph their leverage facets.

### Technical Risks (from TD-PIPELINE — CONCERNS, three mitigations)
- **Social-magnitude variance** → *classify-don't-score* (resolved).
- **Compiler bulk-approve as false economy** → *grounding tables + Scene Linter* (resolved).
- **Building in the wrong order** → *prototype the social scene first* (resolved).
- Per-beat LLM cost/latency on mobile/web → cascade + caching + token budget.

### Scope Risks
- The creator toolkit is a **second product**, not a polish pass.
- The authoring engine is now early — guard against it ballooning before the core loop is proven.

### Open Questions
- Compound/sequential intent ("cut power, then crack vault") — resolve one beat at a time, or decompose the plan? *(Translator design call, deferred to prototype.)*
- Minimum ontology size / when to promote a facet to an axis.
- On-device vs. server embeddings — decided at `/setup-engine`.
- Visual identity direction — decided before `/art-bible`.

---

## MVP Definition

**Core hypothesis (the loop is fun — class-divergence is a Vertical-Slice claim, not an MVP one):**
"Players find typing freeform intent — and watching it resolve into an authored,
consequential outcome — satisfying enough to want the next encounter."

**The MVP is anchored by the prototype, which comes first:**
- **Prototype (gate before MVP):** ONE hand-authored **social scene (the magistrate)**,
  the classify-don't-score Translator, and the Resolver. **Kill criterion: run-to-run
  stability of the decisive-move threshold.** No Compiler, no tooling, no content spend
  until this passes. This is the cheapest prove-or-kill of the core bet.

**MVP proper** *(build order: Resolver/StateDelta → Translator → Scene Model → one adventure)*:
1. The blank line + classify-don't-score **Translator** for one specialist class.
2. The deterministic **Resolver** + `StateDelta` persistence + per-encounter win/lose.
3. A small **Scene Model** vocabulary (a handful of axes incl. Social sub-vector, conditional thresholds, one meter).
4. One short (~15-min) **authored adventure** (hand-authored Scene Models — the Compiler is not required for MVP content).

Bare text UI (no chosen visual identity yet).

**Protected, non-cuttable acceptance bar:** for each encounter, a cold playtester's
~5 most-likely first phrasings each resolve to a *satisfying authored event*, not the
fallback. (The cut that looks graceful but silently breaks the product.)

**Authoring-format rule:** the MVP's Scene Model format must already be the
**creator-facing primitive** (P4), even though the Compiler and toolkit ship later.

**Explicitly NOT in MVP:** the Scene Compiler's full generation, creator toolkit,
multiple classes, accounts/cloud, marketplace, visual polish.

### Scope Tiers

| Tier | Content | Features | Shippable if work stops here? |
| ---- | ---- | ---- | ---- |
| **Prototype** | One hand-authored social scene | Translator + Resolver | Internal only — a go/no-go gate |
| **MVP** | One class, one ~15-min adventure | Translator + Resolver + Scene Model + state; bare UI | Testable (friends), not shippable |
| **Vertical Slice** | 2–3 classes (P5 visible), one polished adventure | Chosen visual identity, basic save, **first Scene Compiler (rough)** | **Shippable as a public demo** |
| **Alpha-A** | All core classes, several adventures | Content scale-up via the Compiler | Yes |
| **Alpha-B** | Internal creator toolkit | Authoring on the shared primitive | Yes |
| **Full Vision** | Public creator tools + sharing, content library, full roster | Cross-platform polish | Yes (terminal vision) |

*(The Scene Compiler arrives early — at Vertical Slice — because it defines the
content-production model and is the answer to the coverage risk. Per TD-PIPELINE it
is built **constrained** (grounding tables + linter), not as free-running generation.)*

---

## Next Steps

**Path B — Prototype-First** (the core router/translator bet is unproven):
1. **`/setup-engine`** — configure the stack (client/service split, where embeddings run) and author the 8 foundational ADRs above (respecting the 5 stack-shaping constraints).
2. **`/prototype intent-translation`** — build the eval harness + the **magistrate social scene**; kill criterion = run-to-run decisive-move threshold stability under classify-don't-score.
3. If it **PROCEEDS** → finalize the visual direction, `/art-bible`, then `/map-systems` → `/design-system` per system → `/create-architecture` → ADRs → `/architecture-review` → `/gate-check`.
4. If it **PIVOTS** → back to `/brainstorm` with the learnings.
5. After full design + architecture, build the `/vertical-slice` (incl. the first rough Compiler) to validate production readiness.

- [ ] Concept approval (CD-PILLARS resolved ✓; TD-PIPELINE CONCERNS resolved via 3 mitigations ✓)
- [ ] `/setup-engine` — stack + 8 foundational ADRs
- [ ] `/prototype` — magistrate scene, classify-don't-score, stability kill-criterion
- [ ] Finalize Visual Identity Anchor → `/art-bible`
- [ ] `/map-systems` → `/design-system` per system
- [ ] `/create-architecture` → ADRs → `/architecture-review` → `/gate-check`
