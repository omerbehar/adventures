# Game Concept: Adventures

*Created: 2026-06-21*
*Status: Draft*

> **Creative Director Review (CD-PILLARS)**: CONCERNS resolved — Pillar 1 and Pillar 4 sharpened, locked 2026-06-21
> **Art Director Review (AD-CONCEPT-VISUAL)**: CONCEPTS — three directions proposed, selection deferred 2026-06-21
> **Technical Director Review (TD-FEASIBILITY)**: CONCERNS (VIABLE pending architecture lock) — guidance integrated 2026-06-21
> **Producer Review (PR-SCOPE)**: OPTIMISTIC — five adjustments integrated 2026-06-21

---

## Elevator Pitch

> It's a text-first RPG where you type **whatever you want to do** in your own
> words, and the world translates your intent into hand-authored, consequential
> events — every encounter won by the right **decisive move**, not by grinding.
> Like an AI dungeon master, *and also* every freeform action lands on real
> designed content with real stakes — and players and creators build with the
> same toolkit.

---

## Core Identity

| Aspect | Detail |
| ---- | ---- |
| **Genre** | Text-first RPG / interactive fiction with AI intent translation + UGC creator platform |
| **Platform** | Multi-platform — PC (Steam/Epic), Web/Browser, Mobile (iOS/Android), ideally one codebase |
| **Target Audience** | Explorers, storytellers/creators, and decisive-move tacticians (see Player Profile) |
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
consequence. It is the tabletop feeling of "I try something the designer didn't
put on a menu" — but the answer is consistent, designed, and fair, not improvised
prose. You are not picking from options; you are *expressing intent*, and the
world resolves it.

---

## Unique Hook

**Translate every player text to an authored event.** The single most important
sentence in the project.

The AI is not a novelist — it is a **semantic router** that maps freeform natural
language to the *nearest authored event* (a designer-written outcome with real
state changes). When there is a genuine gap with no authored match, a **bounded
AI fallback** resolves it — but even the fallback emits a validated state change,
never throwaway prose.

This passes the "and also" test cleanly:
- **Like AI Dungeon**, *and also* every action lands on authored content with real
  stakes and persistent state — consistent and balanced, not generative drift.
- **Like parser interactive fiction**, *and also* you are never limited to a fixed
  verb set — the blank line accepts anything.
- **Like Disco Elysium**, *and also* you write your own input instead of choosing
  from menus.
- **Like a tabletop RPG**, *and also* there is no human DM improvising — the world's
  responses are authored, fair, and repeatable.

The moat lives in three pillars: **authored translation** (P2), the **unified
player/creator primitive** (P4), and **class-colored resolution** (P5).

---

## Player Experience Analysis (MDA Framework)

### Target Aesthetics (What the player FEELS)

| Aesthetic | Priority | How We Deliver It |
| ---- | ---- | ---- |
| **Discovery** (exploration, secrets) | 1 | Probing the blank line to find what the world has authored a response for — "what happens if I try *this*?" |
| **Expression** (self-expression, creativity) | 2 | Acting in your own words; class identity coloring how your intent resolves; authoring adventures with the same toys |
| **Challenge** (mastery) | 3 | Finding the *decisive move* — the one signature action that wins an encounter |
| **Fantasy** (inhabiting a role) | 4 | Being a *specialist* (assassin, diplomat, etc.) whose worldview shapes what is possible |
| **Narrative** (drama, story) | 5 | Authored adventures with consequence carried forward through state |
| **Sensation** | 6 | Typography-forward presentation; the "decisive move" reveal as a visual beat |
| **Fellowship** | N/A | No co-op/PvP in the core loop (creator/player sharing is asynchronous) |
| **Submission** | N/A | The game rewards deliberate intent, not low-stress idle play |

### Key Dynamics (Emergent player behaviors we WANT)
- Players experiment with phrasings and approaches to probe the authored space.
- Players adopt a class "lens," reading each encounter for what *their* specialist
  could uniquely do.
- Players hunt for the decisive move rather than attempting to brute-force.
- Creators play an adventure, think "I could author that differently," and cross
  into authoring with the same primitives.

### Core Mechanics (Systems we build)
1. **The Blank Line + Intent Translation router** — freeform text → nearest authored event.
2. **Authored Events** — declarative designer-written outcomes with typed preconditions and a typed state change (`StateDelta`).
3. **Bounded AI Fallback** — resolves genuine gaps into a *validated* state change, never prose.
4. **Specialist Classes** — a filter/modifier over the shared event library; the same intent resolves differently per class.
5. **State & Consequence** — persistent world state that carries decisions forward and drives encounter win/lose.

---

## Player Motivation Profile

### Primary Psychological Needs Served (Self-Determination Theory)

| Need | How This Game Satisfies It | Strength |
| ---- | ---- | ---- |
| **Autonomy** | The blank line — total freedom of *input*; you act in your own words, never from a menu | Core |
| **Competence** | The decisive move — encounters reward finding the right signature action; freedom feels *skillful* because it lands on real authored content | Core |
| **Relatedness** | Connection to the authored world and its designers; the creator/player loop means you build for and play others' worlds | Supporting |

### Player Type Appeal (Bartle Taxonomy)
- [x] **Explorers** (primary) — the blank line is an invitation to probe the system and discover authored responses.
- [x] **Creators/Storytellers** (primary) — Pillar 4 makes authoring a first-class activity with the same primitives.
- [x] **Achievers** (secondary) — the decisive move gives mastery-seekers a clean target per encounter.
- [ ] **Killers/Competitors** — explicitly NOT served (no twitch, no PvP, no DPS race).

### Flow State Design
- **Onboarding curve**: The first encounter teaches that the blank line is real — a player's natural first phrasing resolves to a satisfying authored event, proving the promise.
- **Difficulty scaling**: Encounters escalate by demanding sharper *decisive moves* and rewarding class-aware reads, not by inflating numbers.
- **Feedback clarity**: Every resolution emits a visible state change — the player always sees that their words *did something* to the world.
- **Recovery from failure**: Failure is a consequence, not a wall; adventures are short (~15–30 min) so re-attempts and alternate approaches are cheap.

---

## Core Loop

### Moment-to-Moment (30 seconds)
The player reads the current situation, then **types freeform intent at the blank
line**. The Intent Translation router resolves it to an authored event; the world
responds with a concrete, visible state change. Repeat. The satisfaction is the
*translation moment* — "I said what I wanted, and the world took it seriously."

### Short-Term (5–15 minutes)
An **encounter**: a situation with one or more authored *decisive-move* solutions.
The player probes, reads their class's angle, and lands the signature action that
resolves it. "One more encounter" psychology lives here.

### Session-Level (15–30 minutes)
A complete **adventure**: a short authored sequence of encounters with state
carried forward, ending in a clear resolution. Natural stopping point; the hook to
return is the next adventure (or replaying with a different specialist).

### Long-Term Progression
Growth is in **player knowledge and options**, not stat inflation: learning how the
world reads intent, mastering each specialist's lens, and — for creators — building
and sharing adventures. The library of authored/community adventures is the
long-term content horizon.

### Retention Hooks
- **Curiosity**: What has the world authored a response for? What can *this* class do here?
- **Investment**: Adventures in progress; creators' own works-in-progress.
- **Social**: Playing others' authored adventures; sharing your own.
- **Mastery**: Finding cleaner decisive moves; replaying as different specialists.

---

## Game Pillars

*(Full detail in `design/gdd/game-pillars.md`. Summary below.)*

### Pillar 1: The Blank Line Is Sacred
Every situation accepts freeform player intent, and the world resolves it into
authored consequence.

*Design test*: If a feature would ever present a choice the player can't override
in their own words, we cut it or redesign it.

### Pillar 2: Translation, Not Improvisation
Player freedom resolves by mapping words to authored, meaningful outcomes — never
throwaway prose.

*Design test*: When freeform input resolves, it must connect to designed
consequence/state. If the best we can do is a flavor reply with no stakes, the
system failed. *(The AI fallback at a translation gap must still produce a state
change, never prose — so it lives inside this pillar.)*

### Pillar 3: The Decisive Move
Encounters are won by the right signature action at the right **game-state** moment
— not attrition or grind. *(State-based, never clock-based — protects the no-twitch
anti-pillar.)*

*Design test*: Debating depth vs. grind? Choose whatever makes one clever move feel
devastating.

### Pillar 4: Creators Play With The Same Toys
The primitives that resolve play are the same ones creators author with; authoring
is an extension of playing. **Primitive parity is the promise; experience parity
(UI depth/polish) is not.**

*Design test*: If a content feature can't be expressed in the creator toolkit, it
doesn't belong in the base game either.

### Pillar 5: Specialists, Not Everymen
Your class fantasy shapes which intents are powerful; the same words resolve
differently per specialist.

*Design test*: "Kick the brazier" should mean something different for an assassin
than a diplomat — if class doesn't color the blank line, we've flattened it.

### Anti-Pillars (What This Game Is NOT)
- **NOT a freeform-prose generator**: we will not make the AI's *narrative writing*
  the resolution — it would compromise Pillar 2 (kills consistency and earned competence).
- **NOT real-time / twitch combat**: it would compromise Pillar 3 and the text-first identity.
- **NOT a creator-only "dev mode"** players can't reach: it would compromise Pillar 4.
- **NOT a do-everything generalist hero**: it would compromise Pillar 5.

---

## Visual Identity Anchor

**Status: DEFERRED — three candidate directions retained; Art Director recommends Direction 2.**

This is a **text-first** game: the blank input line is the emotional and visual
center, and the visual identity must make *text itself* feel powerful, tactile, and
consequential. Three named directions were proposed at gate AD-CONCEPT-VISUAL:

### Direction 1 — The Oracle Terminal
- **Visual rule**: *Every word typed is a command the world is obligated to obey.*
- **Mood**: Cold authority; CRT glow; the weight of a sent message you can't unsend.
- **Shape language**: Hard orthogonal grids; monospace as architecture; bottom-anchored command-prompt input.
- **Color philosophy**: Near-black base; aged phosphor green = world speaking; white = player speaking; a single red flash = consequence landing.

### Direction 2 — The Illuminated Word ⭐ (AD recommendation)
- **Visual rule**: *Language is sacred matter; every sentence the player writes becomes scripture.*
- **Mood**: Warm, ceremonial, weighty — a manuscript that has seen wars.
- **Shape language**: Organic geometry; humanist serif; the input line as a ruled manuscript line with a pen-nib cursor.
- **Color philosophy**: Dark-vellum primary; deep ink = the authored world; cobalt = the player's voice; **gold = the moment of translation** (Pillar 2 made visible — the player's decisive word illuminates).
- **Why recommended**: The only direction where the visual language *encodes Pillar 2* (gold = "your words became the world's words") and best serves Pillar 1 (the blank line as ritual, not command prompt).
- **Caveat**: Use the dark-vellum variant with modern type rigor so it reads "text is sacred," not "ye olde RPG."

### Direction 3 — The Struck Match
- **Visual rule**: *Every word lands like a struck match — the world ignites, then settles into ash.*
- **Mood**: Kinetic, high-contrast noir/woodblock; barely-contained energy.
- **Shape language**: Bold silhouettes; slab/compressed display type; comic-panel zone divisions.
- **Color philosophy**: Charcoal base; grey = world; white = player agency; a single "danger color" appears ONLY at consequence moments.
- **Risk**: The kinetic energy can fight the deliberate, weighty feeling of the decisive move.

*Decision to be finalized before `/art-bible`.*

---

## Inspiration and References

| Reference | What We Take From It | What We Do Differently | Why It Matters |
| ---- | ---- | ---- | ---- |
| AI Dungeon | Freeform-text agency; the thrill of typing anything | Resolve to authored events with persistent state, not generative prose | Validates appetite for the blank line; we fix its consistency problem (P2) |
| Disco Elysium | Text as the world; skills/identity coloring perception | Player writes input instead of choosing menu options | Proves text-first can be a critical/commercial hit; informs P5 |
| Parser IF (Zork, Anchorhead) | The authored, consequential text world | No fixed verb set — the blank line accepts anything | Lineage for authored consequence; we remove the parser wall (P1) |
| Slay the Spire | The "decisive move" / perfect-solution feel | Expressed through freeform intent, not a card hand | Validates the decisive-move tactical audience (P3) |
| Tabletop RPGs | "Try anything," specialist classes, a world that answers | Authored & repeatable instead of human-DM improv | Source of the core fantasy; we make the DM authored, not improvised |

**Non-game inspirations**: illuminated manuscripts and marginalia; the typewriter
and the terminal; the ritual weight of the written word.

---

## Target Player Profile

| Attribute | Detail |
| ---- | ---- |
| **Age range** | ~18–40 |
| **Gaming experience** | Mid-core to hardcore; comfortable reading and typing |
| **Time availability** | 15–30 minute sessions; longer for creators |
| **Platform preference** | Cross-platform; keyboard-forward on PC/web, but mobile-considered |
| **Current games they play** | AI Dungeon, Disco Elysium, interactive fiction, narrative roguelikes |
| **What they're looking for** | Real agency in their own words, answered by a world that was actually designed |
| **What would turn them away** | Inconsistent/incoherent AI responses; menus that fake freedom; twitch demands; numbers-grind |

---

## Technical Considerations

| Consideration | Assessment |
| ---- | ---- |
| **Recommended Engine** | UNDECIDED — run `/setup-engine`. For Adventures the real question is "thin cross-platform text client + AI translation service backend," favoring a portable UI layer over a heavy native game engine |
| **Key Technical Challenges** | The Intent Translation router; the bounded state-change-only fallback; the shared player/creator primitive schema |
| **Art Style** | Text-first / typography-forward (see Visual Identity Anchor — decision deferred) |
| **Art Pipeline Complexity** | Low (typography, layout, restrained motion — not asset-heavy) |
| **Audio Needs** | Minimal to moderate (atmospheric; the "decisive move" beat) |
| **Networking** | Client → AI translation service for Tier 2/3; asynchronous sharing of authored adventures |
| **Content Volume** | Driven by **intents-per-encounter coverage density** (the real sink), not raw encounter count |
| **Procedural Systems** | None in the generative sense — resolution is *authored*, routed by retrieval, with bounded AI only at gaps |

### Intent Translation Router — recommended architecture (from TD-FEASIBILITY)

A **tiered cascade**, cheapest and most deterministic first. Do NOT route every
input through an LLM.

| Tier | Mechanism | When it runs | Model |
| ---- | ---- | ---- | ---- |
| **0** | Deterministic normalize + exact/alias/verb-object match | Common inputs ("attack", "open door") | none |
| **1** | **Embedding retrieval** vs. authored-event index, scoped to current encounter + class; threshold on similarity | **Primary path** | embeddings |
| **2** | Constrained-choice disambiguation: pick event ID from top-K or NO_MATCH (structured output) | Only when Tier 1 is ambiguous | Haiku 4.5 |
| **3** | Bounded fallback: emit a validated `StateDelta` within creator-set bounds | Only on genuine gap (NO_MATCH) | Sonnet 4.6 |

**Foundational invariants (write as ADRs at `/setup-engine`):**
1. **All four tiers return the same typed `StateDelta`.** The fallback's output is
   schema-validated and bound-checked by deterministic code *before* it touches game
   state; on validation failure, apply a safe default — never raw text. *(This is what
   keeps the game testable, balanced, and save-safe — and is what makes the AI
   fallback live inside Pillar 2.)*
2. **The shared event/`StateDelta` schema is the project's spine** — simultaneously
   engine-consumable, creator-authorable, and LLM-emittable. Design it once,
   deliberately, as a small declarative format (trigger phrasings + typed precondition
   + typed `StateDelta` + bounds) with a validator.
3. **Class is a filter/modifier over a shared event library**, not duplicated event
   sets — author the event once, vary the consequence per class.
4. **Cost discipline**: set a hard cap on average generative-tokens-per-player-turn
   and instrument it from prototype #1. The cascade keeps generative calls rare.
5. **Offline/latency**: Tier 0/1 can run client-side or edge-cached (small local
   embedding model) so the common case needs no round-trip; degrade gracefully to a
   safe authored default when the service is unreachable, surfaced honestly.

Opus is reserved for **offline authoring tools** (e.g., generating candidate trigger
phrasings for the embedding index), not the runtime hot path.

---

## Risks and Open Questions

### Design Risks
- **Coverage density** (highest): if a player's reasonable first phrasings hit the
  fallback or a near-miss event, the core promise breaks. Coverage-per-encounter is
  a protected, non-cuttable acceptance bar.
- The decisive move could feel like "guess the authored solution" if encounters
  don't telegraph multiple legitimate signature actions.

### Technical Risks
- **The router itself** — accuracy/latency/cost of mapping freeform text to authored
  events. Mitigation: the tiered cascade + an **eval harness** (50–100 input→event
  pairs per encounter) as the cheapest prove-or-kill prototype.
- **The bounded state-change-only fallback** — the novel, make-or-break piece;
  prototype first as a spike.
- **Per-input recurring LLM cost** — structural margin risk; mitigated by cascade +
  caching + a token budget set before code.
- **The shared primitive schema** — get it wrong and everything downstream churns.

### Market Risks
- Some AI-Dungeon fans may read *bounded* freedom as a limitation rather than a feature.
- Text-first + no character-art presentation narrows mass-market appeal.

### Scope Risks
- The **creator toolkit is a second product** (its UX, validation, authoring model),
  not a polish pass — must not be underestimated.
- Class-divergence (P5) multiplies authored content if not modeled as a filter.

### Open Questions
- What is the minimum coverage density that makes an encounter feel "understood"?
  *(Answered by the eval-harness prototype.)*
- On-device vs. server-side embeddings — decided at `/setup-engine`.
- Which visual identity direction — decided before `/art-bible`.

---

## MVP Definition

**Core hypothesis (the loop is fun — class-divergence is explicitly NOT claimed here):**
"Players find typing freeform intent — and watching it resolve into an authored,
consequential outcome — satisfying enough to want the next encounter."

**Required for MVP** *(build order 3 → 4 → 1 → 2, per PR-SCOPE)*:
1. **Bounded AI fallback** that produces a validated state change, never prose *(spike first — make-or-break)*.
2. **State/consequence persistence** + per-encounter win/lose.
3. **The blank line + Intent Translation router** for **one** specialist class.
4. **One short (~15-min) authored adventure** — a handful of encounters, each with an authored decisive-move solution.

Bare text UI (no chosen visual identity yet).

**Protected, non-cuttable acceptance bar**: for each encounter, a cold playtester's
~5 most-likely first phrasings each resolve to a *satisfying authored event*, not the
fallback. (This is the cut that looks graceful but silently breaks the product.)

**Authoring-format rule**: the MVP's authored-event data format must already be the
**creator-facing primitive** (Pillar 4) — even though the toolkit ships at Alpha.

**Explicitly NOT in MVP**: creator toolkit, multiple classes, accounts/cloud,
marketplace, visual polish.

### Scope Tiers

| Tier | Content | Features | Shippable if work stops here? |
| ---- | ---- | ---- | ---- |
| **MVP** | One class, one ~15-min adventure | Router + bounded fallback + state; bare text UI | Testable (internal/friends), not shippable |
| **Vertical Slice** | 2–3 classes (P5 divergence visible), one polished adventure | Chosen visual identity, basic save | **Shippable as a public demo** (e.g., itch.io) |
| **Alpha-A** | All core classes, several adventures | Content scale-up, rough | Yes (content-rich build) |
| **Alpha-B** | Internal creator toolkit | Authoring on the shared primitive | Yes (creators onboard) |
| **Full Vision** | Public creator tools + sharing, content library, full roster | Cross-platform polish | Yes (terminal vision) |

*(Alpha split into A/B per PR-SCOPE so the content sink and the toolkit-as-second-product
don't land simultaneously.)*

---

## Next Steps

**Path B — Prototype-First** (recommended — the core router/fallback mechanic is unproven):
1. Run `/setup-engine` to configure the stack (client/server split, where the AI
   service lives, on-device vs. server embeddings) and write the two foundational
   ADRs (shared `StateDelta` primitive; fallback-emits-validated-state).
2. Run `/prototype intent-translation` — build the **eval harness** + bounded
   state-change-only fallback spike on a single encounter. Cheapest prove-or-kill of
   the core bet.
3. If the prototype PROCEEDS: run `/art-bible` (finalize the visual direction first),
   then `/map-systems`, then `/design-system` per system, `/create-architecture`,
   the ADRs, `/architecture-review`, and `/gate-check`.
4. If it PIVOTS: return to `/brainstorm` with the learnings.
5. After full design + architecture, build the `/vertical-slice` to validate
   production readiness.

- [ ] Concept approval from creative-director (CD-PILLARS resolved ✓)
- [ ] `/setup-engine` — stack + foundational ADRs
- [ ] `/prototype intent-translation` — eval harness + fallback spike
- [ ] Finalize Visual Identity Anchor → `/art-bible`
- [ ] `/map-systems` → `/design-system` per system
- [ ] `/create-architecture` → ADRs → `/architecture-review` → `/gate-check`
