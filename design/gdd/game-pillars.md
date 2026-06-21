# Game Pillars: Adventures

## Document Status
- **Version**: 2.0
- **Last Updated**: 2026-06-21
- **Approved By**: creative-director (CD-PILLARS); pipeline pressure-tested by technical-director (TD-PIPELINE)
- **Status**: Approved
- **Changes in 2.0**: Added Pillar 6 (The Scene Is a Model, Not a Script); rewrote Pillar 3 (The Decisive Move) around facet-leverage; added the "enumerated branching script" anti-pillar.

---

## Core Fantasy

**"You can say anything, and a world built by real designers takes it seriously.
Your cleverness — expressed in your own words — is the whole game."**

---

## Target MDA Aesthetics

| Rank | Aesthetic | How Our Game Delivers It |
| ---- | ---- | ---- |
| 1 | Discovery | Probing the blank line; *discovery moves* that reveal hidden scene facets |
| 2 | Expression | Acting in your own words; class coloring resolution; authoring with the same toys |
| 3 | Challenge | Finding the decisive move — the facet that breaks an encounter open |
| 4 | Fantasy | Being a specialist whose worldview shapes what's possible |
| 5 | Narrative | Authored adventures with consequence carried through state |

---

## The Pillars

### Pillar 1: The Blank Line Is Sacred

**Definition**: Every situation accepts freeform player intent, and the world
resolves it into authored consequence.

**Aesthetics Served**: Expression, Discovery.

**Design Test**: If a feature would ever present a choice the player can't override
in their own words, we cut it or redesign it.

| Department | This Pillar Says... |
| ---- | ---- |
| Game Design | No mechanic may foreclose freeform input |
| Art | The input line is the hero of the screen |
| Audio | A satisfying "commit" cue on submit |
| Narrative | Situations framed to invite open intent, not set answers |
| Engineering | The text input is never modal-locked out |

**Serving it**: a blank line in every encounter; suggested verbs that *seed* without *limiting*.
**Violating it**: a pure multiple-choice node with no way to type your own action.

---

### Pillar 2: Translation, Not Improvisation

**Definition**: Player freedom resolves by mapping words to authored, meaningful
outcomes — never throwaway prose.

**Aesthetics Served**: Discovery, Challenge, Narrative.

**Design Test**: When freeform input resolves, it must connect to designed
consequence/state. If the best we can do is a flavor reply with no stakes, the
system failed. *(The AI fallback at a translation gap must still produce a validated
state change, never prose — so it lives inside this pillar.)*

| Department | This Pillar Says... |
| ---- | ---- |
| Game Design | Every resolution emits a typed, validated `StateDelta` |
| Art | Make the *translation moment* visible (the gold "illuminated word") |
| Audio | Consequence has a sonic signature |
| Narrative | Authored outcomes carry the drama, not improv prose |
| Engineering | All resolution paths return the same `StateDelta`, validated before applying; on failure, safe default — never raw text |

**Serving it**: classify-don't-score translation onto authored thresholds; a bounded fallback that emits a validated state change.
**Violating it**: the AI writing narrative prose *as* the resolution; a flavor reply with no stakes.

---

### Pillar 3: The Decisive Move

**Definition**: Encounters are won by the **right signature action at the right
game-state moment** — specifically, by the action that flips the **highest-leverage
facet**, collapsing a hard threshold to a trivial one. Not attrition, not grind, not
the highest-magnitude action — the highest-*leverage* one. State-based, never
clock-based.

**Aesthetics Served**: Challenge, Fantasy.

**Design Test**: Debating depth vs. grind? Choose whatever makes one clever move feel
devastating. And: every encounter must have at least one **leverage facet** a player
can discover and flip to break it open — if the only path is brute magnitude, the
encounter is under-designed.

| Department | This Pillar Says... |
| ---- | ---- |
| Game Design | Encounters resolve via leverage facets + conditional thresholds, not HP races; scale the idea to global facets in scene-graphs ("cut the power") |
| Art | The decisive move gets a visual climax |
| Audio | Punctuate the winning move with a singular sting |
| Narrative | The leverage facet is *discoverable* and dramatically earned |
| Engineering | Turn/state-based resolution; per-beat advancement; NO real-time pressure |

**Serving it**: scenes that telegraph a leverage facet; a single clever move that collapses a threshold and ends the encounter.
**Violating it**: HP-sponge enemies / magnitude races; any real-time/reaction-time pressure (also an anti-pillar).

---

### Pillar 4: Creators Play With The Same Toys

**Definition**: The primitives that resolve play are the same ones creators author
with; authoring is an extension of playing. **Primitive parity is the promise;
experience parity (UI depth/polish) is not.**

**Aesthetics Served**: Expression.

**Design Test**: If a content feature can't be expressed in the creator toolkit, it
doesn't belong in the base game either.

| Department | This Pillar Says... |
| ---- | ---- |
| Game Design | Base-game content uses only authorable primitives (the Scene Model) |
| Art | Authoring surfaces share the game's visual language |
| Audio | Authored events declare cues from a shared palette |
| Narrative | The Scene Model format is humane to write |
| Engineering | One shared Scene Model / `StateDelta` schema: engine-consumable, creator-authorable, LLM-emittable; designers and creators share the Compiler (tiered access) |

**Serving it**: the MVP Scene Model format *is* the creator-facing primitive; the Scene Compiler serves designers and community creators alike (tiered access).
**Violating it**: a hidden, creator-inaccessible "dev mode" for base-game content (anti-pillar).

---

### Pillar 5: Specialists, Not Everymen

**Definition**: Your class fantasy shapes which intents are powerful; the same words
resolve differently per specialist.

**Aesthetics Served**: Fantasy, Expression.

**Design Test**: "Kick the brazier" should mean something different for an assassin
than a diplomat — if class doesn't color the blank line, we've flattened it.

| Department | This Pillar Says... |
| ---- | ---- |
| Game Design | Class is a lens over a shared model — same event, per-class capability vector |
| Art | Each specialist has a distinct identity cue |
| Audio | Class colors resolution feedback |
| Narrative | The world reads intent through the class lens |
| Engineering | The Translator colors which axes are strong + the magnitude per class; resolution scopes by class |

**Serving it**: the same sentence routing to different axes per class (Diplomat→Social, Scholar→Insight, Assassin→intimidation facet).
**Violating it**: a generalist hero for whom class never changes resolution (anti-pillar).

---

### Pillar 6: The Scene Is a Model, Not a Script

**Definition**: Designers author a **model of possibility** — typed thresholds on a
shared capability ontology — not an enumerated list of outcomes. The engine resolves
freeform intent against the model. This is the authoring counterpart to Pillar 2:
P2 translates *the player's words* to authored outcomes; P6 translates *the
designer's scene* to the space of possibilities.

**Aesthetics Served**: Discovery (for players), Expression (for creators).

**Design Test**: If authoring a scene means writing one outcome per anticipated
player action, we've built a branching script and failed. A scene must be expressible
as entities + typed thresholds + facets, so that *unanticipated* intents still
resolve sensibly.

| Department | This Pillar Says... |
| ---- | ---- |
| Game Design | Design encounters as scene models (entities, conditional thresholds, meters, facets), not decision trees |
| Art | Visualize state/consequence, since outcomes are computed not pre-written |
| Audio | Cues attach to dimensions/outcomes, not to scripted lines |
| Narrative | Author the *situation and its leverage*, and let resolution compose the beats |
| Engineering | The Scene Compiler expands sparse prose into a linted, frozen, deterministic Scene Model; the Resolver is a per-beat deterministic rules engine; classify-don't-score keeps it stable |

**Serving it**: a sparse seed ("you wake in a prison cell") compiling to typed paths any reasonable intent can satisfy; the same machinery composing into scene-graphs.
**Violating it**: an enumerated `if input == X then Y` table; LLM-improvised outcomes with no model behind them; the Compiler emitting un-linted, un-grounded thresholds.

---

## Anti-Pillars (What This Game Is NOT)

- **NOT a freeform-prose generator** — would compromise Pillar 2 (kills consistency and earned competence).
- **NOT real-time / twitch** — would compromise Pillar 3 and the text-first identity; "moment" is game-state, never reaction time.
- **NOT a creator-only "dev mode"** players can't reach — would compromise Pillar 4.
- **NOT a do-everything generalist hero** — would compromise Pillar 5.
- **NOT an enumerated branching script** — would compromise Pillar 6; the scene is a model, not a decision tree.

---

## Pillar Conflict Resolution

| Priority | Pillar | Rationale |
| ---- | ---- | ---- |
| 1 | Pillar 2 (Translation) | The authored-consequence thesis is the moat |
| 2 | Pillar 6 (Scene Is a Model) | The authoring mechanism that makes P2 affordable at scale; defines the content-production model |
| 3 | Pillar 4 (Same Toys) | The unified primitive; the scope governor on everything else |
| 4 | Pillar 1 (Blank Line) | Total input freedom — but it must land on authored consequence (defers to P2) |
| 5 | Pillar 5 (Specialists) | Class divergence is core but multiplies P2×P6 cost; modeled as a lens |
| 6 | Pillar 3 (Decisive Move) | The encounter shape; non-negotiable in feel but most locally scoped |

**Key tensions** (intentional): P1 (infinite input) vs P2 (authored resolution) is
the central productive friction. P4 and P6 together govern ambition and cost. The
hardest production cost lives at the **P2 × P5 × P6 intersection** (per-class
resolution against a shared, creator-authorable scene model). The **classify-don't-
score** discipline and the **Scene Linter** are what keep that intersection
deterministic and testable.

---

## Player Motivation Alignment

| Need | Pillar | How |
| ---- | ---- | ---- |
| **Autonomy** | Pillar 1 | Total freedom of input |
| **Competence** | Pillar 3 (+ P2) | The decisive move rewards finding leverage; freedom feels skillful because it lands on authored content |
| **Relatedness** | Pillar 4 | The creator/player loop: build for, and play, others' worlds |

All three SDT needs served. ✓

---

## Reference Games

| Reference | What We Take | What We Do Differently | Validates |
| ---- | ---- | ---- | ---- |
| AI Dungeon | Freeform-text agency | Authored events + persistent state | P1, P2 |
| Disco Elysium | Text as the world; identity colors perception | Player writes input | P5 |
| Parser IF (Zork) | Authored, consequential text world | No fixed verb set | P1, P2 |
| Slay the Spire | The decisive-move feel | Freeform intent against a scene model | P3 |
| Tabletop RPGs | "Try anything"; specialist classes | Authored & repeatable | P2, P5, P6 |

---

## Pillar Validation Checklist
- [x] **Count**: 6 pillars
- [x] **Falsifiable**: each could fail a real decision
- [x] **Constraining**: each forces a "no" to plausible features
- [x] **Cross-departmental**: each has design/art/audio/narrative/engineering implications
- [x] **Design-tested**: each has a concrete design test
- [x] **Anti-pillars defined**: 5 explicit "this game is NOT" statements
- [x] **Priority-ranked**: conflict order established
- [x] **MDA-aligned**: pillars deliver Discovery/Expression/Challenge
- [x] **SDT coverage**: Autonomy (P1), Competence (P3), Relatedness (P4)
- [x] **Memorable**: six sharp, nameable pillars
- [x] **Core fantasy served**: every pillar traces to the blank line

---

*This document is the creative north star for Adventures. It lives in
`design/gdd/game-pillars.md` and is referenced by every design, art, audio, and
narrative document in the project.*
