# Game Pillars: Adventures

## Document Status
- **Version**: 1.0
- **Last Updated**: 2026-06-21
- **Approved By**: creative-director (CD-PILLARS — CONCERNS resolved, locked)
- **Status**: Approved

---

## Core Fantasy

**"You can say anything, and a world built by real designers takes it seriously.
Your cleverness — expressed in your own words — is the whole game."**

The core fantasy is the *blank line*: total freedom of input, backed by the promise
that the world has been authored to answer with real, consistent consequence.

---

## Target MDA Aesthetics

| Rank | Aesthetic | How Our Game Delivers It |
| ---- | ---- | ---- |
| 1 | Discovery | Probing the blank line to find what the world has authored a response for |
| 2 | Expression | Acting in your own words; class identity coloring resolution; authoring with the same toys |
| 3 | Challenge | Finding the *decisive move* that wins an encounter |
| 4 | Fantasy | Being a *specialist* whose worldview shapes what's possible |
| 5 | Narrative | Authored adventures with consequence carried through state |
| N/A | Fellowship, Submission | No co-op/PvP core; the game rewards deliberate intent, not idle play |

---

## The Pillars

### Pillar 1: The Blank Line Is Sacred

**One-Sentence Definition**: Every situation accepts freeform player intent, and the
world resolves it into authored consequence.

**Target Aesthetics Served**: Expression, Discovery (this pillar owns the *input
surface*; Pillar 2 owns *resolution*).

**Design Test**: If a feature would ever present a choice the player can't override
in their own words, we cut it or redesign it.

#### What This Means for Each Department
| Department | This Pillar Says... | Example |
| ---- | ---- | ---- |
| **Game Design** | No mechanic may foreclose freeform input | No dialogue tree without a blank-line escape |
| **Art** | The input line is the hero of the screen | The cursor/input is the visual focal point |
| **Audio** | Acknowledge the act of input | A subtle, satisfying "commit" cue on submit |
| **Narrative** | Situations are framed to invite open intent | Scene text ends on an open beat, not a question with set answers |
| **Engineering** | Always-available freeform input pipeline | The text input is never modal-locked out |

#### Serving This Pillar
- A blank line present in every encounter, even scripted ones.
- Suggested verbs/autocomplete that *seed* without *limiting* input.

#### Violating This Pillar
- A pure multiple-choice node with no way to type your own action.
- A "cutscene" the player cannot act into.

---

### Pillar 2: Translation, Not Improvisation

**One-Sentence Definition**: Player freedom resolves by mapping words to authored,
meaningful outcomes — never throwaway prose.

**Target Aesthetics Served**: Discovery, Challenge, Narrative.

**Design Test**: When freeform input resolves, it must connect to designed
consequence/state. If the best we can do is a flavor reply with no stakes, the system
failed. *(The AI fallback at a translation gap must still produce a state change,
never prose — so it lives inside this pillar.)*

#### What This Means for Each Department
| Department | This Pillar Says... | Example |
| ---- | ---- | ---- |
| **Game Design** | Every resolution emits a typed state change | No "nothing happens" outcomes without state meaning |
| **Art** | Make the *translation moment* visible | The gold "illuminated word" reveal (Direction 2) |
| **Audio** | Consequence has a sonic signature | A distinct cue when an authored event fires |
| **Narrative** | Authored outcomes carry the drama, not improv prose | Designers write the consequence, not the model |
| **Engineering** | All router tiers return the same `StateDelta`, validated before applying | Fallback output schema-checked; safe default on failure |

#### Serving This Pillar
- Embedding-retrieval router that lands input on authored events.
- A bounded fallback that emits a validated state change within creator-set bounds.

#### Violating This Pillar
- The AI writing narrative prose *as* the resolution.
- A "flavor reply" with no stakes standing in for a real outcome.

---

### Pillar 3: The Decisive Move

**One-Sentence Definition**: Encounters are won by the right signature action at the
right **game-state** moment — not attrition or grind. *(State-based, never
clock-based.)*

**Target Aesthetics Served**: Challenge, Fantasy.

**Design Test**: Debating depth vs. grind? Choose whatever makes one clever move feel
devastating.

#### What This Means for Each Department
| Department | This Pillar Says... | Example |
| ---- | ---- | ---- |
| **Game Design** | Encounters have signature solutions, not HP races | No damage-sponge enemies; no resource attrition wins |
| **Art** | The decisive move gets a visual climax | The consequence reveal beat |
| **Audio** | Punctuate the winning move | A sharp, singular sting at resolution |
| **Narrative** | The right action is dramatically *earned* | The encounter telegraphs its vulnerabilities |
| **Engineering** | Turn/state-based resolution, no real-time pressure | "Moment" = game-state moment, never reaction time |

#### Serving This Pillar
- Encounters that telegraph multiple legitimate signature actions.
- A single clever move that visibly ends the encounter.

#### Violating This Pillar
- HP-sponge enemies / DPS races.
- Any real-time/reaction-time pressure (also an anti-pillar).

---

### Pillar 4: Creators Play With The Same Toys

**One-Sentence Definition**: The primitives that resolve play are the same ones
creators author with; authoring is an extension of playing. **Primitive parity is the
promise; experience parity (UI depth/polish) is not.**

**Target Aesthetics Served**: Expression.

**Design Test**: If a content feature can't be expressed in the creator toolkit, it
doesn't belong in the base game either.

#### What This Means for Each Department
| Department | This Pillar Says... | Example |
| ---- | ---- | ---- |
| **Game Design** | Base-game content uses only authorable primitives | No hard-coded special-case events outside the schema |
| **Art** | Authoring surfaces share the game's visual language | The toolkit feels like the game, not a spreadsheet |
| **Audio** | Authored events can declare their own cues | Creators pick from a shared cue palette |
| **Narrative** | The authored-event format is humane to write | Trigger phrasings + typed consequence, not raw JSON archaeology |
| **Engineering** | One shared event/`StateDelta` schema: engine-consumable, creator-authorable, LLM-emittable | Designed once as a foundational ADR |

#### Serving This Pillar
- The MVP authored-event format *is* the creator-facing primitive.
- Creators get more affordances/depth, but never different primitives.

#### Violating This Pillar
- A hidden, creator-inaccessible "dev mode" for base-game content (anti-pillar).
- Base content that uses powers the toolkit can't express.

---

### Pillar 5: Specialists, Not Everymen

**One-Sentence Definition**: Your class fantasy shapes which intents are powerful; the
same words resolve differently per specialist.

**Target Aesthetics Served**: Fantasy, Expression.

**Design Test**: "Kick the brazier" should mean something different for an assassin
than a diplomat — if class doesn't color the blank line, we've flattened it.

#### What This Means for Each Department
| Department | This Pillar Says... | Example |
| ---- | ---- | ---- |
| **Game Design** | Class is a filter/modifier over shared events | Same event, per-class outcome variants/eligibility |
| **Art** | Each specialist has a distinct identity cue | Class-tinted framing of the blank line |
| **Audio** | Class can color resolution feedback | Subtle per-class motif on signature actions |
| **Narrative** | The world reads intent through the class lens | The assassin's "approach" reads as a kill angle |
| **Engineering** | Router scopes candidate events by class | Class tag filters the retrieval candidate set |

#### Serving This Pillar
- The same intent resolving into class-specific consequences.
- Encounters with class-specific decisive moves.

#### Violating This Pillar
- A generalist hero for whom class never changes resolution (anti-pillar).
- Identical outcomes regardless of specialist.

---

## Anti-Pillars (What This Game Is NOT)

- **NOT a freeform-prose generator**: we will not make the AI's narrative *writing*
  the resolution — it compromises Pillar 2 (kills consistency and earned competence),
  and would cost us the entire authored-consequence moat.
- **NOT real-time / twitch combat**: it compromises Pillar 3 and the text-first
  identity; "moment" is game-state, never reaction time.
- **NOT a creator-only "dev mode"** players can't reach: it compromises Pillar 4 — the
  "primitive parity vs experience parity" line must never quietly become a dev mode.
- **NOT a do-everything generalist hero**: it compromises Pillar 5 and flattens the
  blank line into class-agnostic verbs.

---

## Pillar Conflict Resolution

| Priority | Pillar | Rationale |
| ---- | ---- | ---- |
| 1 | Pillar 2 (Translation) | The authored-consequence thesis is the moat; without it the game is "a chatbot with HP bars" |
| 2 | Pillar 4 (Same Toys) | The unified primitive is the second differentiator and the scope governor on everything else |
| 3 | Pillar 1 (Blank Line) | Total input freedom — but it must land on authored consequence (defers to P2) |
| 4 | Pillar 5 (Specialists) | Class divergence is core to the pitch but multiplies P2×P4 cost; model as a filter |
| 5 | Pillar 3 (Decisive Move) | The combat/encounter shape; non-negotiable in feel but most locally scoped |

**Resolution Process**: identify the tension → consult priority → serve the lower
pillar partially if it doesn't compromise the higher → otherwise the higher wins →
document the decision → escalate fundamental conflicts to the creative-director.

**Key known tensions** (intentional): P1 (infinite input) vs P2 (authored
resolution) is the central productive friction. P4 caps the ambition of P1/P2/P5
(scope governor). The hardest production cost lives at the **P2 × P4 × P5
intersection** (per-class authored resolution on a shared, creator-authorable
primitive) — enter with eyes open.

---

## Player Motivation Alignment

| Need | Which Pillar Serves It | How |
| ---- | ---- | ---- |
| **Autonomy** | Pillar 1 | Total freedom of input — act in your own words, never a menu |
| **Competence** | Pillar 3 (+ Pillar 2) | The decisive move rewards skill; freedom feels skillful because it lands on real authored content |
| **Relatedness** | Pillar 4 | The creator/player loop: you build for, and play, others' worlds |

All three SDT needs are served. ✓

---

## Reference Games

| Reference | What We Take From It | What We Do Differently | Which Pillar It Validates |
| ---- | ---- | ---- | ---- |
| AI Dungeon | Freeform-text agency | Authored events + persistent state, not generative prose | Pillar 1, Pillar 2 |
| Disco Elysium | Text as the world; identity colors perception | Player writes input instead of choosing menus | Pillar 5 |
| Parser IF (Zork) | Authored, consequential text world | No fixed verb set — blank line accepts anything | Pillar 1, Pillar 2 |
| Slay the Spire | The decisive-move / perfect-solution feel | Expressed via freeform intent, not a card hand | Pillar 3 |
| Tabletop RPGs | "Try anything"; specialist classes | Authored & repeatable, not human-DM improv | Pillar 2, Pillar 5 |

**Non-game inspirations**: illuminated manuscripts and marginalia; the typewriter and
the terminal; the ritual weight of the written word.

---

## Pillar Validation Checklist
- [x] **Count**: 5 pillars
- [x] **Falsifiable**: each makes a claim that could fail a real decision
- [x] **Constraining**: each forces a "no" to plausible features
- [x] **Cross-departmental**: each has design/art/audio/narrative/engineering implications
- [x] **Design-tested**: each has a concrete design test
- [x] **Anti-pillars defined**: 4 explicit "this game is NOT" statements
- [x] **Priority-ranked**: conflict order established
- [x] **MDA-aligned**: pillars deliver Discovery/Expression/Challenge
- [x] **SDT coverage**: Autonomy (P1), Competence (P3), Relatedness (P4)
- [x] **Memorable**: five sharp, nameable pillars
- [x] **Core fantasy served**: every pillar traces to the blank line

---

*This document is the creative north star for Adventures. It lives in
`design/gdd/game-pillars.md` and is referenced by every design, art, audio, and
narrative document in the project.*
