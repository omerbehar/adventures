# Interaction Patterns: Adventures

*Created: 2026-06-22*
*Status: Draft — UX Foundation*
*Scope: All platforms — PC (Steam/Epic), Web (Wasm/Skwasm), Mobile (iOS/Android)*

Cross-reference: `design/accessibility-requirements.md` (cited inline as **[A-x.x]**)

---

## Overview

This document defines the reusable interaction patterns for Adventures. A pattern
specifies: the situation it addresses, the exact behavior, platform variations, and
accessibility requirements. Patterns are grounded in the game's six pillars; each
pattern cites the pillar(s) it serves.

The central object in every pattern is the blank line. All other patterns exist in
relation to it.

---

## Pattern 1: The Blank-Line Input

**Pillars**: 1 (Blank Line Is Sacred), 5 (Specialists)

### When to Use

In every encounter state where the player can act. This is the primary, always-visible
control in active gameplay. There is no game state during active play where the blank
line is hidden, collapsed, or replaced by a menu.

### Behavior

**Structure**: A single-line `TextField` (expanding to multi-line only if the player
types past the line width; the visual design keeps it as a single prominent line by
default) placed at a fixed, consistent position in the screen layout. The Art Director
designates this as "the hero of the screen" (Pillar 1, Art note).

**Focus on scene entry**: When a new scene node becomes active, focus moves to the
blank-line input automatically. The cursor is placed and blinking. No player tap or
click is required to begin typing.

**Placeholder / hint text**: A low-contrast placeholder string is visible when the
field is empty. The placeholder serves a seeding function: it must invite intent without
constraining it (Pillar 1: "suggested verbs that seed without limiting"). Examples:
- "What do you do?" (generic)
- "How does the [class name] approach this?" (specialist-colored variant)

The placeholder is never a list of options. It never implies there is a correct answer.
It must be empty enough to invite any phrasing.

**Commit affordance**: The primary submission action is Enter / Return on PC and Web;
the soft-keyboard action button on mobile (configured as `TextInputAction.send`). A
secondary visible "Send" affordance (an icon button flush with the input field) is
provided for mobile users and mouse-users who prefer clicking. Both affordances submit
the same action.

**On submit**: The input text is immediately captured and the translation-moment
sequence begins (Pattern 2). The input field clears. Focus remains in the input field
throughout the translation and feedback sequence, so the player can type the next
action immediately.

**Commit audio cue**: Audio fires on submit — the "satisfying commit cue" (Pillar 1,
Audio note). This is a non-optional audio event paired with a visual indicator
(see Pattern 3 for the pending state) so the player receives confirmation that input
was registered even with audio off. See **[A-6.1]**.

**Input history / scrollback**: The player can press the Up arrow key (PC/Web) or a
visible history control (Mobile) to recall the previous input. A session-local history
of the last 20 submitted actions is kept in-memory and presented as a scrollable list
on explicit request. History is not persisted across sessions (MVP scope). The history
panel is dismissed by pressing Escape or tapping outside.

**Field constraints**: Maximum input length is 500 characters. If the player types
past 500, additional characters are ignored and a character-count indicator appears
near the field (e.g., "497/500"). This is a technical safeguard against runaway
Translator input; it must not feel punitive. The indicator appears only when within
50 characters of the limit.

### Platform Variations

**PC/Web**: The field receives keyboard focus on scene entry. Tab can navigate away to
other elements (history, settings) and Tab-back or clicking returns focus to the field.
Enter submits. The secondary send button is present but de-emphasized since keyboard
submission is primary. See **[A-4.1]**.

**Mobile**: The field is tap-to-focus. On focus, the soft keyboard raises and the
layout resizes so the field remains above the keyboard (`resizeToAvoidBottomInset: true`).
The soft keyboard's action button is labeled "Send" (`TextInputAction.send`). The
secondary send icon is present and prominent since some mobile users avoid the action
button. See **[A-4.4]**.

**Web (touch)**: Follows mobile behavior. The WebAssembly (Skwasm) build is the
production web target; input handling must work under Wasm with no `dart:html` or
legacy `dart:js` interop.

### Suggested Verb Chips

A horizontal row of 3–5 short verb phrases (e.g., "Examine", "Persuade the guard",
"Search for tools") appears below or above the input field as dismissible chips.

**Purpose**: The chips are a seeding mechanism, not a menu. They lower the blank-page
barrier for new players and provide entry points into the scene's designed possibility
space. Tapping or clicking a chip populates the input field with that text (it does not
submit immediately), allowing the player to edit the phrase before committing.

**Content**: Chips are authored per scene node and reflect the scene's prominent
capability dimensions and any surfaced facets. They must not enumerate all solutions or
give away the decisive move. They are removed or refreshed when the scene state changes
significantly (e.g., after a meter crosses a reactive threshold).

**Specialist coloring**: Chips are colored or labeled by the player's class where
relevant (Pillar 5). A chip that the player's class has a strong advantage on may carry
the specialist identity cue (Pattern 6) alongside it.

**Accessibility**: Each chip is a focusable widget with a semantic label. See **[A-4.1]**
for keyboard operability. See **[A-2.1]** for screen-reader labels. Touch targets are
≥ 48×48dp per **[A-4.3]**.

---

## Pattern 2: The Translation-Moment Beat

**Pillars**: 2 (Translation, Not Improvisation), 3 (Decisive Move)

### When to Use

Immediately after every action submission, without exception. This pattern covers the
full sequence from input submission to the display of the resolved `StateDelta`.

### Behavior

The translation moment is a three-phase sequence:

**Phase 1 — Optimistic acknowledgment (immediate, 0ms delay)**
As soon as the player submits, display an optimistic acknowledgment. The input text
appears in the scrollback log in a visually distinct "pending" style (e.g., italicized
or de-saturated — visual identity decision deferred to Art Director). A pending
indicator activates (Pattern 3). This phase executes with no waiting; it is purely
client-side state.

**Phase 2 — Translation (variable duration, ≤ 2s)**
The router cascade processes the input (ADR-0007). Tiers 0 and 1 run client-side and
return within one frame budget in the common case — for these tiers, Phase 2 is
imperceptibly short and the pending indicator may not render at all (it has a minimum
display time threshold to prevent flicker; see Pattern 3). If the cascade escalates to
Tier 2 or Tier 3 (service call), the pending indicator is visible for the duration of
the service round-trip, with a hard ceiling of 2 seconds (per ADR-0007 latency budget).

**Phase 3 — Resolution climax**
The `StateDelta` is applied and the narration key is looked up in authored content.
The resolution renders in two sub-steps:

1. The authored narration text appears in the narration feed. For the common resolution
   path, the player's submitted words (or a key phrase from them) are presented
   typographically as "the illuminated word" — the visual moment where the player's
   expression becomes the world's event. This is the translation-moment climax. The
   exact visual treatment (gold highlight, animation) is determined by the Art Director
   in the art bible. The UX requirement is: a distinct, non-trivial visual event occurs
   here that marks the transition from player-intent to authored-world-response.

2. State-delta readouts appear (Pattern 4). The pending indicator resolves.

**Decisive-move climax**: When the `StateDelta` includes a terminal `Outcome` (win,
escape, advance) triggered by flipping a high-leverage facet, the resolution climax is
amplified: the visual event is larger, and the audio "singular sting" fires (Pillar 3,
Audio note). This is authored per scene (the scene model declares which `OutcomeResult`
values qualify for the climax treatment). The amplification must be perceivable without
audio — it must be visually distinct from a standard resolution. See **[A-6.1]**.

**Narration content**: The narration text is resolved from the `narrationKey` in the
`StateDelta` via a lookup in authored content. The UI layer never displays raw
generated prose. The narration output widget is the semantic live region. See **[A-2.2]**.

**Reduce-motion variant**: When the player has enabled "Reduce motion" (**[A-5.1]**),
all animation in the translation moment is replaced with an immediate state change:
the illuminated word appears instantaneously with its final visual state, and no
kinetic or glow effects play. The visual distinction between pending and resolved states
remains.

### Platform Variations

**PC/Web**: The full animation sequence plays. The pending indicator is a subtle
typographic or icon-level treatment near the input field, not a blocking spinner.

**Mobile**: Identical behavior. The soft keyboard may still be visible during the
translation moment — this is acceptable, as the player may be composing the next
action. The narration feed scrolls to show the new narration without requiring a swipe.

### Accessibility

- Narration output is a `SemanticsProperties.liveRegion` live region (**[A-2.2]**).
- The illuminated word effect is accompanied by a narration update that a screen
  reader will announce — color is not the sole signal (**[A-3.2]**).
- The decisive-move climax is distinct from a standard resolution both visually and in
  the narration text (the authored narration key for a decisive outcome carries
  different content).
- Reduce-motion compliance: **[A-5.1]**.

---

## Pattern 3: Latency and Offline States

**Pillars**: 2 (Translation, Not Improvisation)

### When to Use

Whenever the router cascade has not yet returned a resolution. This pattern governs
four distinct sub-states.

### Sub-State 3A: Local resolution (Tiers 0/1)

**Behavior**: Tiers 0 and 1 are client-side and resolve within a single frame in the
common case. A pending indicator is not shown unless resolution takes longer than 100ms
(a deliberate minimum threshold to prevent the indicator flashing briefly and
disappearing). If resolution is instant, the UI moves directly from Phase 1 to Phase 3
of the translation-moment beat.

**Pass criterion**: For a Tier-0 cache hit, QA measures elapsed time from submission to
narration display. If under 100ms, no spinner or pending indicator is visible. Verified
with Flutter's performance overlay.

### Sub-State 3B: Service escalation (Tiers 2/3) — pending indicator

**Behavior**: When the cascade escalates to Tier 2 or Tier 3, the pending indicator
becomes visible after 100ms of unresolved state. The pending indicator design (deferred
to Art Director) must:
- Be positioned near the narration feed or below the most recent entry, not blocking
  the blank-line input
- Not be a full-screen blocking overlay
- Communicate "the world is processing your action" without implying uncertainty about
  the game's designed quality (it must not look like an error state)
- Have a text label accessible to screen readers: "Resolving action…"

The indicator remains until the service returns or the 2-second hard ceiling is
reached (ADR-0007). The blank-line input remains operable during this time — the player
can type the next action. If submitted, the new action queues and resolves after the
current one completes.

**Pass criterion**: QA uses network throttling (Chrome DevTools for web, or a proxy)
to simulate a 1.5-second Tier 2/3 response. The pending indicator appears within 200ms
of submission, the input field accepts text during the wait, and the indicator resolves
to the narration display within 2 seconds of submission.

### Sub-State 3C: Budget exceeded — graceful non-response

**Behavior**: When the per-turn token budget is exceeded (ADR-0007) or Tier 3's
proposed delta fails `validateDelta` against creator bounds, the cascade returns a
graceful authored non-response: a real, validated `StateDelta` whose authored
narration communicates that the world did not respond to this action. This is not an
error state. It is a designed game outcome: some intents fall outside what the current
scene can resolve.

The narration for a graceful non-response must be authored content — it must not be
generated text, it must not be a generic "I don't understand" message, and it must
not be an apology. The tone is the world declining to react, not the game apologizing
for a failure. Example authored text in the narration key: "The guard does not respond
to that. The cell door remains closed." or "The magistrate looks past you."

The input field is immediately available for the player's next attempt.

**Pass criterion**: QA injects a budget-exceeded condition (via a test route in the
service or a debug flag on the cascade) and submits an action. The result is a
narration-feed entry with authored content — no spinner remains, no error UI appears,
no generated apology text is visible.

### Sub-State 3D: Offline — service tiers unavailable

**Behavior**: When the device is offline, the cascade resolves using only Tiers 0 and 1
plus the Resolver (ADR-0007). If a match is found locally, the game resolves normally
with no indication of offline status (the player need not know the service was skipped).
If no local match is found (the cascade returns `NoMatch` from Tiers 0/1 and cannot
escalate), the game must clearly signal the connectivity gap.

The offline gap signal must:
- Appear in or near the narration feed (not only as a system-level notification)
- State that this action requires a connection in plain language ("This action needs a
  connection to resolve. You can try a different approach, or reconnect and try again.")
- Not be styled as a system error dialog
- Leave the blank-line input fully operable so the player can try a locally-resolvable
  action

An offline-mode indicator (a small persistent icon or label) may appear in the UI
chrome to signal the offline state proactively.

**Pass criterion**: QA disables network access, launches the game, and submits an
action that is known to be in the Tier-0 cache. It resolves normally. Then submits an
action known to require Tier 2/3. The in-feed offline message appears. The input
remains operable.

### Accessibility

- Pending indicator has a text label in the semantic tree: **[A-2.1]**.
- The graceful non-response and offline signal are narration-feed entries, so they are
  announced by the screen-reader live region: **[A-2.2]**.
- The offline indicator in UI chrome has a semantic label (**[A-2.1]**) and does not
  rely on color alone to communicate status (**[A-3.2]**).

---

## Pattern 4: State-Change Feedback

**Pillars**: 2 (Translation, Not Improvisation), 3 (Decisive Move), 6 (Scene Is a Model)

### When to Use

Whenever a `StateDelta` is applied and the resulting `WorldState` differs from the
previous one. Every resolution must show a visible state change — the player must
always know what happened and why (the MDA Discovery and Challenge aesthetics depend
on this legibility).

### Behavior

State changes produced by the `StateDelta` are rendered in two zones:

**Zone A — The narration feed (authored prose)**
The `narrationKey` in the `StateDelta` resolves to an authored text entry that appears
in the scrollable narration log. This text describes what happened narratively. It is
the primary delivery mechanism for story consequence. The text is never generated
prose; it is authored content looked up by key (ADR-0001). The narration feed scrolls
automatically to the new entry.

**Zone B — Meter and facet readouts (structured state display)**
Below or alongside the narration entry, structured state changes are displayed:
- Scalar meter changes: "Alertness +40 → 60" (or a meter bar delta). The direction
  and magnitude of change are shown, not only the current value, so the player
  understands consequence.
- Facet reveals (discovery moves): a new facet label appears with a distinct "revealed"
  visual treatment (e.g., the facet name appearing for the first time with a subtle
  differentiation from known facets). This is the mechanical payoff for the Discovery
  aesthetic.
- Facet flips (set/clear): if a previously known facet changes state, it is shown in
  the readout.

The Zone B readout appears simultaneously with or immediately after Zone A. It must
not be a separate screen or require a tap to view. The player should be able to read
the consequence of their action in a single glance at the narration feed region.

**Discovery vs. progress distinction**: A discovery move (`RevealFacet` op) and a
progress move (threshold met, path advanced) must be visually distinct. Discovery
reveals information; progress changes the world's possibility space. Both are
consequential. The distinction communicates to the player which kind of feedback they
received: "I learned something" vs. "I changed something." The exact visual treatment
is a coordination point with the Art Director; the UX requirement is that the two
types are distinguishable without requiring the player to read fine print.

**Reduce-motion compliance**: Meter animations (bar fills, number counters) must be
bypassed when "Reduce motion" is enabled. State jumps to its new value instantaneously.
See **[A-5.1]**.

### Platform Variations

Same on all platforms. On mobile, the narration feed must auto-scroll to the new entry
even if the soft keyboard is raised; the scroll must not be obscured by the keyboard.

### Accessibility

- Zone B readouts are included in or immediately follow the live-region narration
  update, so screen readers announce them. See **[A-2.4]**.
- Discovery vs. progress distinction uses shape or label, not color alone: **[A-3.2]**.
- Meter change direction (increase vs. decrease) must be communicated in the semantic
  label, not only via bar-fill animation color (**[A-3.1]**, **[A-3.2]**).

---

## Pattern 5: Specialist Identity Cue

**Pillar**: 5 (Specialists, Not Everymen)

### When to Use

Persistently during active gameplay. The player's specialist class shapes which intents
are powerful; the UI must make that identity legible at a glance.

### Behavior

A persistent specialist identity indicator appears in a consistent, non-intrusive
position in the active gameplay layout (exact placement deferred to Art Director and
UI-programmer layout pass). The indicator must communicate:
- The player's class name or icon
- A class-associated visual accent that is applied consistently across the blank-line
  input area and the resolution readout

When a `StateDelta` resolves in a way that engaged the player's class capabilities
(i.e., the class coloring on the Translator shifted the capability vector), the
resolution readout (Zone B, Pattern 4) includes a class-resonance signal: a brief
indicator that this outcome was shaped by the player's specialist identity. This is the
"same words resolve differently per specialist" (Pillar 5) made legible to the player.

**Contrast**: Class-resonance signals are an addition on top of the standard resolution
feedback, not a replacement. A non-class-resonant outcome must still produce full
Pattern 4 feedback.

### Platform Variations

The class indicator scales with the layout — it may be more prominent on a large
desktop viewport and more compact on mobile. The minimum requirement on all platforms
is that the class name is legible without scrolling.

### Accessibility

- The class identity indicator has a semantic label: "Playing as [class name]":
  **[A-2.1]**.
- Class-resonance signals must not rely on color alone: **[A-3.2]** and **[A-3.3]**
  (colorblind mode provides a text or icon alternative).
- Touch target for any interactive class indicator is ≥ 48dp: **[A-4.3]**.

---

## Pattern 6: Error, Empty, and Edge States

**Pillars**: 1 (Blank Line Is Sacred), 2 (Translation, Not Improvisation)

### When to Use

When the player's input is empty, when intent is unrecognized within any tier, when a
network failure occurs, or when an unhandled edge case is reached.

### Behavior

**6A — Empty input submission**: If the player presses Enter with no text in the
blank-line field, nothing is submitted and no error is shown. The cursor remains in the
field. No negative feedback. This is consistent with Pillar 1 (the blank line is an
invitation, not a mandatory form field).

**Pass criterion**: Press Enter with empty field. The field does not clear, no error
message appears, no toast or snackbar fires, and the narration feed is unchanged.

**6B — Unrecognized intent / graceful non-response**: When the cascade returns a
graceful non-response (Pattern 3C), the authored narration text communicates the world's
non-reaction. This is Pattern 3C in its narration-feed form. There is no error dialog,
no "input not recognized" system message, and no generated text. The input field is
immediately available.

**6C — Network failure (service unreachable)**: If the service tiers are unreachable
and the cascade cannot complete (distinct from offline sub-state 3D in that the network
exists but the service returned an error), the player receives an authored fallback
narrative in the feed ("Something disrupts your focus. Try again, or approach
differently.") plus a non-blocking in-feed indicator that the resolution failed
technically. The indicator must:
- Use plain language, not HTTP status codes
- Not require the player to take a recovery action to continue playing (next input
  attempt proceeds normally)
- Be distinguishable from a graceful non-response so the player knows this was a
  technical gap, not a designed outcome

**Pass criterion**: QA points the service URL at an unreachable endpoint, submits an
action that would require Tier 2/3. The in-feed message appears using authored text.
No dialog or alert is shown. The next submission attempt proceeds.

**6D — Adventure completion (terminal outcome)**: When the `StateDelta` contains an
`Outcome` op with `OutcomeResult.win`, `escape`, or equivalent terminal value, the
adventure enters a resolved state. The blank-line input becomes inactive (this is the
one valid case where the input is not accepting new actions). A clear "Adventure
complete" state is presented with a summary of key events and state deltas from the
session, and a navigation affordance to start a new adventure or return to the
adventure selection.

**Pass criterion**: On terminal outcome, input is non-focusable. The post-adventure
screen is reachable by keyboard (Tab, Enter): **[A-4.1]**.

**6E — First launch / no adventures available**: If no adventures are present (empty
state), the player sees a designed empty state that explains what Adventures is, not
a raw "no data" message. This state is outside active gameplay and need not show the
blank line.

### Accessibility

- All authored non-response and error text appears in the narration feed live region
  and is announced: **[A-2.2]**.
- Network failure indicators do not rely on color alone (**[A-3.2]**).
- Post-adventure navigation is fully keyboard-operable (**[A-4.1]**).

---

## Pattern 7: Navigation and Deep Linking

**Pillar**: 4 (Creators Play With The Same Toys)

### When to Use

For any navigation between screens and for sharing adventures. The game must support
deep-linkable, shareable adventure URLs on web (per
`docs/engine-reference/flutter/current-best-practices.md` §Web).

### Behavior

**Screen structure**: The game uses a router (Navigator 2.0 or a `go_router`-compatible
approach) that maintains URL-based state on web. Every adventure and every scene node
is addressable by URL. This enables:
- Sharing a link to a specific adventure
- Browser back/forward navigation between scenes within an adventure
- Deep-linking from external sources (social sharing, creator distribution)

**URL structure**: Defined by the ui-programmer and network-programmer based on the
`SceneModel` schema. The UX requirement is that adventure URLs are human-legible (e.g.,
`/adventure/prison-cell` not `/adventure/f3a9b2`).

**Back navigation**: Within an adventure, the browser back button (web) or a game-level
"Undo last action" affordance (all platforms) must not undo world-state changes in a
confusing way. The preferred behavior is that back navigation presents a confirmation
dialog if it would result in world-state reversal. Navigation out of an active
adventure (to the main menu) requires explicit confirmation.

**Save state**: Persistence of `WorldState` across sessions is out of scope for MVP.
On web, refreshing or leaving an in-progress adventure will lose current state. The
player should be warned when attempting to navigate away from an active adventure
(a browser `beforeunload` confirmation on web; a dialog on mobile).

### Platform Variations

**Web**: URL routing is active and required. Sharing a URL for a specific adventure
is a first-class feature. Browser navigation controls (back/forward) are supported.

**PC**: Deep linking is via the URL in the Epic/Steam overlay browser or directly
in the web build. Same URL routing.

**Mobile**: Deep linking is via universal links (iOS) and app links (Android) if
implemented. The URL structure should be compatible with future deep-link support even
if not fully implemented in MVP.

### Accessibility

- All navigation controls are keyboard-operable: **[A-4.1]**.
- Confirmation dialogs are focus-trapped (focus stays within the dialog until
  dismissed) and are Escape-dismissible.
- The back/undo affordance has a semantic label (**[A-2.1]**) and a minimum 48dp
  touch target (**[A-4.3]**).

---

## Pattern Index

| Pattern | Name | Primary Pillar |
|---------|------|----------------|
| 1 | The Blank-Line Input | P1 |
| 2 | The Translation-Moment Beat | P2, P3 |
| 3 | Latency and Offline States | P2 |
| 4 | State-Change Feedback | P2, P3, P6 |
| 5 | Specialist Identity Cue | P5 |
| 6 | Error, Empty, and Edge States | P1, P2 |
| 7 | Navigation and Deep Linking | P4 |

---

## Cross-Cutting Requirements

The following requirements apply to every pattern above:

**Input never blocks output**: The blank-line input must accept text while the
narration feed is updating, while a pending indicator is shown, and while a
translation-moment animation is playing. These are concurrent, not sequential.

**No modal gameplay interruptions**: No in-game event may produce a modal dialog that
blocks the blank-line input during active play. System dialogs (navigation confirmation,
navigation-away warning) are permitted but must be dismissible with Escape and must not
interrupt an in-progress action submission.

**Single scrollable feed**: All game output — narration, state-delta readouts,
non-response messages, offline indicators, error messages — appears in a single
scrollable feed. There is no separate "combat log" or "message box." This is a
text-first game; all information lives in one place. The blank-line input is anchored
below this feed on all platforms.

**Authored text only in the feed**: The narration feed displays content resolved from
`narrationKey` lookups in authored content (ADR-0001). The feed never displays raw
generated prose, API error bodies, or internal system identifiers.
