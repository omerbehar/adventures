# Accessibility Requirements: Adventures

*Created: 2026-06-22*
*Status: Draft — UX Foundation*
*Scope: All platforms — PC (Steam/Epic), Web (Wasm/Skwasm), Mobile (iOS/Android)*

---

## Overview

Adventures is a text-first RPG. Its single most important accessibility surface is
the blank line: if a player cannot reach, read, or operate the text input field, the
entire game is inaccessible. Every requirement below traces back to that constraint.
Requirements are phrased so QA can produce an unambiguous pass/fail result.

---

## 1. Text Scaling

### 1.1 sp Units Required

**Requirement**: All in-game text — narration output, the blank-line input, suggested
verbs, state-delta readouts, scene descriptions, meter labels, and UI chrome — must
be sized in logical `sp` (scale-independent pixels) using Flutter's `TextScaler` API,
never in raw `dp` or hard-coded `px`.

**Rationale**: The target audience spans PC at 1x DPI to mobile at 3x+ DPI. Hard-coded
pixel sizes produce unreadable text on high-DPI displays and ignore OS-level font-scale
preferences, creating an accessibility barrier for users with low vision who rely on
system font scaling.

**Pass criterion**: At OS font-scale 1.0× and 2.0× on Android, iOS, and the desktop
runner, all text remains fully legible (no clipping, no overflow, no text truncated by
a fixed-height container). QA verifies by setting the device font-scale to 200% and
walking every screen.

**Pass criterion**: No widget in the UI uses a hard-coded font size in `px` or `dp`.
Flutter's `flutter analyze` with `always_use_package_imports` and a custom lint rule
(or grep for `fontSize:` combined with a raw numeric literal not wrapped in
`TextScaler`) must return zero violations.

### 1.2 OS Font-Scale Honoring

**Requirement**: The app must not clamp or override `MediaQuery.textScaler`. No call
to `TextScaler.noScaling` or equivalent suppression may appear in production widget
code without explicit UX sign-off and a documented override reason.

**Pass criterion**: On an Android device with "Font size" set to "Largest" (approx.
1.3× scale) and on iOS with "Accessibility → Larger Text" enabled at maximum, all
text in the narration feed and the blank-line input field renders at the scaled size
with no layout breakage.

### 1.3 Minimum Legible Size

**Requirement**: The minimum rendered font size for any body text (narration, input)
must be no smaller than 14sp at 1.0× scale. UI chrome (meter labels, verb hints) must
be no smaller than 12sp at 1.0× scale.

**Pass criterion**: QA measures rendered text with Flutter's inspector or a
ruler-on-screenshot at 1.0× device font-scale and confirms body text is ≥ 14sp, chrome
text ≥ 12sp.

---

## 2. Screen Reader Support

### 2.1 Semantic Tree Coverage

**Requirement**: Every interactive and meaningful element must be wrapped in a Flutter
`Semantics` widget with a meaningful `label`. This includes:
- The blank-line `TextField` (label: e.g., "Action input — type what you want to do")
- The narration output region
- State-delta readouts (meter changes, revealed facets)
- Suggested verb chips
- Any navigation controls (back, menu)
- The specialist/class identity indicator

**Rationale**: TalkBack (Android), VoiceOver (iOS), and NVDA/JAWS (Windows) all rely
on the `Semantics` tree Flutter exposes. Elements without semantic labels are
invisible to these tools.

**Pass criterion**: Enable TalkBack on Android and navigate the full new-player flow
from launch to completing one action. Every focusable element receives a spoken label.
No element is skipped silently or announced only as "button" or "image" without context.

### 2.2 Narration as a Live Region (Post-3.32 API)

**Requirement**: The narration output widget — the region where authored text appears
after the player submits an action — must be marked as a live region using
`SemanticsProperties.liveRegion: true` with politeness level "polite".

**Engine reference**: Flutter 3.32 deprecated imperative Android semantic announcement
events (the old approach of programmatically pushing screen-reader announcements). As
of 3.44 (project-pinned version), the correct API is `SemanticsProperties.liveRegion`.
See `docs/engine-reference/flutter/breaking-changes.md` §Flutter 3.32 and
`docs/engine-reference/flutter/deprecated-apis.md` for the explicit deprecation entry.
Do not use the imperative announcement event pattern.

**Implementation note**: The `liveRegion` property on `Semantics` causes the
accessibility framework to announce the widget's content automatically when it
changes. Set it on the outermost container of the narration output feed, not on
each individual text span, to avoid double-announcements.

**Pass criterion**: With TalkBack active on Android (API 36+) and VoiceOver active on
iOS, submitting an action causes the narration output to be read aloud automatically
without the user moving focus to it. The announcement does not interrupt an in-progress
reading (polite behavior). QA tests on a physical device, not the emulator, for
screen-reader audio.

### 2.3 Blank-Line Input Field Accessibility

**Requirement**: The `TextField` implementing the blank line must have:
- A persistent semantic label announced on focus: "Type your action"
- Hint text that is included in the accessibility tree
- Correct `TextInputAction` (e.g., `TextInputAction.send` or `TextInputAction.done`)
  so the keyboard's action button is announced as "Send" or equivalent, not the generic
  "Return"

**Pass criterion**: With TalkBack active, tap the input field. VoiceOver/TalkBack
announces the field label and hint. Activating the keyboard action button submits the
action without requiring a separate tap on a submit button.

### 2.4 State-Delta Readouts

**Requirement**: When the Resolver emits a `StateDelta` and the UI updates meters or
facet reveals, the changed values must be surfaced in the semantics tree. Meter changes
(e.g., "Alertness increased to 60") must appear as a live-region update or be included
in the narration region's next update. Facet reveals (discovery moves) must be
described in text, not communicated only through a visual pulse.

**Pass criterion**: With TalkBack active, perform an action that raises a meter and one
that reveals a facet. Both changes are announced within the narration/state sequence
without the player navigating to a separate UI region.

---

## 3. Color and Contrast

### 3.1 WCAG AA Text Contrast

**Requirement**: All text must meet WCAG 2.1 AA contrast ratios:
- Normal text (< 18pt or < 14pt bold): minimum 4.5:1 contrast ratio against its
  background.
- Large text (≥ 18pt or ≥ 14pt bold): minimum 3:1 contrast ratio against its
  background.

This applies across all visual identity directions, including the recommended
Direction 2 (The Illuminated Word) with its parchment/ink palette.

**Pass criterion**: QA runs every screen through a contrast analyzer (e.g., the Colour
Contrast Analyser tool or an automated accessibility scanner) at both the default color
theme and any high-contrast variant. Zero AA failures permitted on body text, input
text, and narration.

### 3.2 Translation-Moment Color Not Sole Signal

**Requirement**: The "gold illuminated word" visual that marks the translation-moment
climax (Pillar 2, Direction 2 visual identity) must NOT be the only indicator that the
translation resolved. The same event must be communicated through at least one
additional non-color channel: motion (the word animating into place), typography
(weight or scale change), or explicit text (a narration update in the semantic live
region).

**Rationale**: Users with protanopia or deuteranopia may not distinguish the gold
highlight from surrounding text. Relying on hue alone violates WCAG 1.4.1 (Use of
Color) and breaks the core translation-moment feedback for a significant portion of
players.

**Pass criterion**: QA applies a monochrome filter (device accessibility → grayscale
mode or a simulator filter) and verifies that the translation moment is still clearly
identifiable as a distinct event — the animation, scale change, or live-region
narration update must remain perceptible with no color information.

### 3.3 Colorblind Mode Option

**Requirement**: The game must offer a colorblind-friendly alternative for any UI
element where color is used to communicate state. At minimum, the specialist identity
cue (Pillar 5) and any meter status indicators (e.g., Alertness threshold warnings)
must be expressible without relying on hue alone. This may be implemented as a global
"Colorblind mode" toggle in Settings that substitutes patterns, icons, or labels for
color-only signals.

**Pass criterion**: With colorblind mode enabled, a QA tester can identify all
specialist classes and all meter states without color information. The mode toggle is
reachable from the main Settings screen within two navigation steps.

---

## 4. Input Accessibility

### 4.1 Full Keyboard Operability on PC

**Requirement**: On PC (Steam, Epic, Web), every game screen must be fully operable
using the keyboard alone with no mouse required. This includes:
- Navigating to and from the blank-line input
- Submitting an action (Enter / Return)
- Accessing Settings, the scrollback log, and any modal dialogs
- Closing or dismissing any overlay

**Rationale**: Pillar 1 states "the text input is never modal-locked out." Keyboard
operability is a direct engineering expression of that pillar, and it is simultaneously
a WCAG 2.1 Level A requirement (2.1.1: Keyboard).

**Pass criterion**: QA navigates the full new-player flow from launch to submitting
five actions using only the physical keyboard (Tab, Enter, arrow keys, Escape). No
step requires a mouse click. All focus states are visually visible.

**Pass criterion**: No focus trap exists except in modal dialogs where the trap is
intentional and Escape closes the dialog.

### 4.2 Blank-Line Input: Never Modal-Locked

**Requirement**: The blank-line `TextField` must never be programmatically disabled,
obscured, or blocked during normal gameplay. The only valid state where the input is
not operable is when an explicit non-actionable modal is displayed (e.g., a settings
dialog), and even then it must be reachable once the modal is closed.

**Pass criterion**: At any point during active gameplay (including while a state-delta
animation is playing or while a pending indicator is shown for a Tier 2/3 service
call), the blank-line input field remains focusable and accepts text entry. QA tests
by pressing Tab or tapping the field immediately after submitting an action, before any
animation completes.

### 4.3 Touch Targets

**Requirement**: All interactive touch targets on mobile must be a minimum of 48×48
logical pixels (dp), regardless of the visual size of the element. If a visual element
is smaller (e.g., a suggested verb chip rendered at a compact size), its touch target
must be padded to meet the 48dp minimum using Flutter's `GestureDetector` or
`InkWell` with padding, or by wrapping in a `SizedBox` with constraints.

**Pass criterion**: QA uses Flutter's "Show widget size overlays" option or the Widget
Inspector to measure touch target sizes on all interactive elements on the mobile
build. All targets measure ≥ 48×48dp.

### 4.4 Soft Keyboard Must Not Obscure the Input Field

**Requirement**: On mobile, when the soft (virtual) keyboard is raised in response to
focusing the blank-line `TextField`, the input field must remain visible above the
keyboard. The layout must use `Scaffold`'s `resizeToAvoidBottomInset: true` (or an
equivalent scroll/padding mechanism) so the input field scrolls into the visible
viewport when the keyboard opens.

**Engine reference**: `docs/engine-reference/flutter/current-best-practices.md` §Mobile
explicitly requires this. Portrait orientation is primary.

**Pass criterion**: On a physical iPhone SE (smallest common supported screen) and an
Android device with a typical soft keyboard, focusing the blank-line input raises the
keyboard. The input field is fully visible (not occluded) with at least 8dp of visible
space above the keyboard. QA tests on physical devices, not emulators.

**Pass criterion**: After the keyboard closes, the layout returns to its original
position without residual padding. Verified by scrolling the narration log before and
after keyboard open/close.

---

## 5. Motion and Animation

### 5.1 Reduce-Motion Setting

**Requirement**: The game must provide a user-accessible "Reduce motion" toggle in
Settings. When enabled, the following animations must be disabled or replaced with
an instant cut:
- The translation-moment "illuminated word" animation (the word entering the scene,
  any glow or kinetic effect)
- Any screen-transition animations
- The decisive-move visual climax (Pillar 3 Art note)
- Any pulsing, looping, or parallax idle effects in scene backgrounds

When "Reduce motion" is enabled, state changes may still show distinct visual states
(e.g., the gold highlighted word appears instantaneously) — the motion is removed, not
the state change itself.

**Rationale**: WCAG 2.3.3 (Animation from Interactions, AAA) recommends motion can be
disabled. More practically, motion-sensitive players (vestibular disorders, epilepsy
risk) need control over animation. The translation moment is the game's signature
visual beat; it must be expressible without motion.

**Pass criterion**: With "Reduce motion" enabled, QA plays through one complete scene.
No element animates continuously or on-trigger. State changes are still visible as
immediate visual updates.

**Pass criterion**: The "Reduce motion" setting persists across sessions and is applied
on app launch, not only after the first action.

### 5.2 No Unwarned Flashing

**Requirement**: No UI element may flash at a rate between 3 and 50 Hz without a
content warning displayed before that content appears. The translation-moment animation
and the decisive-move sting must be reviewed against WCAG 2.3.1 (Three Flashes or
Below Threshold) before shipping.

**Pass criterion**: The technical-artist confirms in writing (as part of the Visual/Feel
story acceptance) that the translation-moment animation does not produce flashes above
the 3-per-second threshold. This is an ADVISORY gate per the testing standards, but
the attestation is required.

---

## 6. Subtitles and Audio

### 6.1 All Audio Cues Have a Visual Equivalent

**Requirement**: Any audio cue that communicates game state — the "commit" sound on
action submit (Pillar 1, Audio note), the consequence sonic signature (Pillar 2, Audio
note), and the decisive-move sting (Pillar 3, Audio note) — must have a corresponding
visual indicator. Audio must not be the sole delivery mechanism for any game event.

**Pass criterion**: With device audio muted, QA plays through one complete scene
including a decisive move. Every audio-meaningful event (submit, resolution, decisive
move) has a visible correlate (input field response, narration update, visual climax).

### 6.2 Subtitles for All Voiced Content

**Requirement**: If any voiced dialogue, narration, or ambient audio containing speech
is added in future production, subtitles must be available. A subtitle toggle must be
present in Settings regardless of whether voiced content exists in the current build
(to establish the pattern before it is needed).

**Pass criterion**: The Settings screen contains a "Subtitles" toggle. If no voiced
content is present, the toggle is visible but may be labeled "Subtitles (not yet
available in this build)."

---

## 7. UI Scale and Resolution

### 7.1 Correct Layout at All Supported Resolutions

**Requirement**: The UI must render correctly (no overflow, no occluded elements, no
truncated text, no misaligned touch targets) at all supported resolutions. Minimum
verified targets:
- Mobile: 360×640dp (Android baseline), 375×667pt (iPhone SE)
- Web: 1024×768px through 2560×1440px
- Desktop: 1280×720 through 3840×2160

**Pass criterion**: QA uses Flutter's responsive layout tools to test at the minimum
resolution on each platform class. Zero `RenderFlex overflow` warnings in the debug
console.

### 7.2 Portrait-Primary on Mobile

**Requirement**: The primary supported orientation on mobile is portrait. The UI must
be fully operable in portrait mode. Landscape is optional but if supported must also
satisfy all requirements in this document.

**Pass criterion**: The app does not lock to landscape. All core gameplay (blank line,
narration feed, state readouts) is usable in portrait on a 360×640dp viewport with the
soft keyboard raised.

---

## 8. Accessibility Settings Persistence

**Requirement**: All accessibility settings — Reduce motion, Colorblind mode, Subtitles
toggle, and any future additions — must be persisted locally across app sessions. They
must not reset to defaults on relaunch.

**Pass criterion**: QA enables Reduce motion and Colorblind mode, force-quits the app,
relaunches it, and verifies both settings are still active.

---

## Accessibility Checklist (per feature gate)

Before any feature is marked Done, confirm:

- [ ] Usable with keyboard only (PC and Web)
- [ ] All touch targets ≥ 48×48dp (Mobile)
- [ ] Text sized in sp units; legible at 2.0× OS font scale
- [ ] Narration output uses `SemanticsProperties.liveRegion` (not deprecated imperative events)
- [ ] Color is not the sole signal for any meaningful state
- [ ] Reduce-motion setting tested and effective
- [ ] No content flashes at 3–50 Hz without a warning
- [ ] Soft keyboard does not occlude the blank-line input on mobile
- [ ] UI scales correctly at minimum and maximum supported resolutions
- [ ] All semantic labels present and tested with TalkBack / VoiceOver
