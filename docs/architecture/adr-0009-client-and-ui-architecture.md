# ADR-0009: Client & UI Architecture

## Status

Accepted

## Date

2026-06-22

## Last Verified

2026-06-22

## Decision Makers

technical-director, flutter-specialist, ui-programmer

## Summary

Defines the cross-platform thin-client architecture for Adventures: a strict three-layer
split (pure-Dart core → service layer → UI layer), Riverpod as the state-management
adapter between core and widgets, a URL-routable navigator for shareable adventures,
a `CustomPainter`-backed translation-moment beat, soft-keyboard handling that never
obscures the blank line, a production web build via `flutter build web --wasm` (Skwasm /
<5MB initial load), and a 60fps/16.6ms frame budget with optimistic UI against the ADR-0007
cascade round-trip. This closes the `TR-client-001` coverage gap identified in the
architecture review dated 2026-06-22.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Flutter 3.44.0 / Dart 3.12 |
| **Domain** | UI / Presentation |
| **Knowledge Risk** | MEDIUM — widget APIs and `go_router` are stable; Skwasm/Wasm production build is post-cutoff (verify with WebSearch before implementing Wasm-specific interop); `dart:js_interop` + `package:web` idioms post-date training data |
| **References Consulted** | `docs/engine-reference/flutter/current-best-practices.md`, `docs/engine-reference/flutter/breaking-changes.md`, `docs/engine-reference/flutter/deprecated-apis.md`, `docs/engine-reference/flutter/VERSION.md`, `design/gdd/game-concept.md`, `design/gdd/game-pillars.md`, `.claude/docs/technical-preferences.md` |
| **Post-Cutoff APIs Used** | `flutter build web --wasm` (Skwasm renderer, recommended production target since 3.44); `dart:js_interop` + `package:web` (replaces deprecated `dart:html`/`dart:js`); SwiftPM iOS dependency resolution (default since 3.44); AGP 9 built-in Kotlin (required since 3.44); `WidgetStateProperty` (replaces `MaterialStateProperty`); `PopScope` (replaces `WillPopScope`) |
| **Verification Required** | Confirm `go_router` (or successor) Wasm compatibility under Flutter 3.44; verify Riverpod current stable version + Wasm support; verify `dart:js_interop` / `package:web` API surface against live docs before any JS-interop implementation |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (`narrationKey` lookup, `WorldState`, `StateDelta` display); ADR-0006 (`ResolveResult` rendering, per-beat advancement drives one UI update per beat); ADR-0007 (`RouterCascade` behind a DI interface — optimistic-then-reconcile UI pattern, ≤2s round-trip, `TurnBudget`) |
| **Enables** | MVP "bare text UI" epic; Vertical Slice visual identity and `CustomPainter` translation beat |
| **Owns Types** | `AdventureRouter` (navigation); `TranslationBeatPainter` (CustomPainter); `AdventureScreen`, `BlankLineField` (widgets); `WorldStateProvider`, `ResolveResultProvider` (Riverpod providers); `NarrationResolver` (narrationKey → display text) |
| **Blocks** | MVP UI epic — no widget code should be authored before this ADR is Accepted |
| **Ordering Note** | Must be Accepted after ADR-0001/0006/0007 are Accepted (it binds to their interfaces). Safe to author now in Proposed state alongside the rest of the foundational set. |

## Context

### Problem Statement

Adventures ships on PC (Steam/Epic), Web (WebAssembly), and Mobile (iOS/Android) from a
single Flutter codebase. The concept mandates "one portable cross-platform UI layer"
(stack-shaping constraint #3) over a thin client that keeps its deterministic hot path
on-device. Without an explicit architecture decision, the team risks:

- Importing `package:flutter` into the pure-Dart core (destroys headless testability and
  edge-side deployability of the Resolver).
- Widget state diverging from `WorldState` (breaks the single source of truth for
  resolution).
- No router → no shareable adventure URLs for the web target.
- Soft keyboard occluding the blank line on mobile (violates Pillar 1: "the text input
  is never modal-locked out").
- A web bundle that blows the <5MB initial-load budget.
- Rebuilding the entire screen on every keystroke, missing the 16.6ms frame budget.

### Current State

No production code exists. The concept is pre-production/concept-complete. The foundational
ADRs (0001–0008) cover the pure-Dart core and service tiers but leave the client/widget
layer unspecified. `TR-client-001` is the only confirmed gap in the architecture review.

### Constraints

- **Pure-Dart core is immutable**: `lib/game/`, `lib/resolver/`, `lib/scene/` have zero
  Flutter imports. This ADR may not alter that constraint.
- **Determinism is sacred**: no UI component may trigger or advance resolution — it only
  renders `ResolveResult` and forwards player input. The Resolver (ADR-0006) is the sole
  engine that steps world state.
- **ADR-0007 Wasm interop constraint**: any JS interop must use `dart:js_interop` +
  `package:web`; `dart:html` and `dart:js` do not work under the Skwasm/Wasm production
  web build.
- **No library additions without technical-director sign-off**: Riverpod and `go_router`
  are recommended here but require sign-off before `pubspec.yaml` is updated.
- **Performance**: 60fps / 16.6ms frame budget; 150MB memory ceiling; <5MB initial Wasm
  load / <20MB total assets.

### Requirements

From `TR-client-001` (tr-registry.yaml):
1. Cross-platform thin-client architecture for PC, Web (Wasm), and Mobile from one codebase.
2. UI/state-management strategy that adapts `WorldState` to widgets without owning game logic.
3. Navigation / router for deep-linkable, shareable adventure URLs (web target).
4. Translation-moment visual beat (the "illuminated word" gold moment from the concept's
   visual identity anchor, Direction 2).
5. Soft-keyboard handling that never obscures the blank line (Pillar 1).
6. Web bundle budget: <5MB initial Wasm load, <20MB total assets.
7. Narration rendering driven by authored `narrationKey`s (ADR-0001), never generated prose.

## Decision

A strict three-layer client architecture. Each layer is defined by what it imports and
what it is forbidden to import.

### Architecture

```
╔══════════════════════════════════════════════════════════════════╗
║                PURE-DART CORE  (zero Flutter imports)            ║
║  lib/game/        WorldState, StateDelta, applyDelta             ║
║  lib/resolver/    Resolver, ResolveResult (NoMatch | Resolved)   ║
║  lib/scene/       SceneModel, NarrationTable (key → String)      ║
╠══════════════════════════════════════════════════════════════════╣
║                SERVICE LAYER  (async, DI-injectable)              ║
║  lib/services/    RouterCascadeService  (wraps RouterCascade,    ║
║                   ADR-0007, behind RouterCascadeInterface)       ║
║                   NarrationRepository  (loads narration tables   ║
║                   from assets; resolves narrationKey → String)   ║
╠══════════════════════════════════════════════════════════════════╣
║                UI LAYER  (Flutter widgets; depends inward only)   ║
║  lib/ui/          AdventureScreen, BlankLineField,               ║
║                   NarrationView, TranslationBeatWidget           ║
║  lib/screens/     top-level screen wrappers (AdventureScreen,    ║
║                   HomeScreen, etc.)                              ║
║  lib/providers/   Riverpod providers adapting core → widgets     ║
║  lib/router/      AdventureRouter  (go_router-based)             ║
╚══════════════════════════════════════════════════════════════════╝

Dependency direction: UI → Service → Core.
The Core NEVER imports Service or UI. The Service NEVER imports UI.

Beat sequence (one player action):
  BlankLineField (submit)
       │
       ▼
  RouterCascadeService.route(text, worldState)     ← async; optimistic UI fires immediately
       │  (ADR-0007 cascade: Tier 0 → 1 → 2 → 3)
       ├──[Tier 0/1 + Resolver hit] Resolved ──────► WorldStateProvider.update(nextState)
       │                                                    │
       └──[Tier 2/3 escalation, ≤2s]   Resolved ──────────┘
                                                     │
                                             ResolveResultProvider
                                             (narrationKey → NarrationRepository)
                                                     │
                                             ┌───────┴──────────────┐
                                             │ NarrationView        │
                                             │ TranslationBeat      │
                                             │ (CustomPainter/anim) │
                                             └──────────────────────┘
```

### Decision Point 1 — Layering

The three-layer split is **enforced by import discipline**, not just convention:

- `lib/game/`, `lib/resolver/`, `lib/scene/` have zero `package:flutter` imports.
  A `flutter analyze` lint rule (`always_use_package_imports`, no-flutter-in-core custom
  lint) gates this in CI.
- `lib/services/` may import `dart:async`, `package:http`, `dart:js_interop`, and
  `package:web` for Wasm-safe interop. It imports the core packages but not `package:flutter`.
- `lib/ui/`, `lib/screens/`, `lib/providers/`, `lib/router/` import Flutter freely but
  must never import `lib/resolver/` or `lib/game/` directly to drive resolution — they
  receive `ResolveResult` and `WorldState` via Riverpod providers.

`RouterCascade` (ADR-0007) sits behind a `RouterCascadeInterface` DI interface in
`lib/services/router/`. The UI layer consumes only the interface, enabling test doubles.
This addresses the architecture-review finding N5 ("RouterCascade should sit behind a DI
interface").

### Decision Point 2 — State Management: Riverpod

**Riverpod** (compile-safe, testable, DI-friendly) is the recommended state-management
adapter between the pure-Dart core and the widget tree.

Rationale:
- `provider` uses `InheritedWidget` under the hood and requires a `BuildContext` for
  lookups, coupling service-layer logic to the widget tree.
- Raw `InheritedWidget` is verbose and lacks the scoping and testing utilities needed
  for a multi-screen app across three platforms.
- Riverpod providers are plain Dart objects; they can be unit-tested without a
  `WidgetTester`, matching the project's DI-over-singletons coding standard.

`WorldState` is **owned by the pure core** and mutated only via `applyDelta`. Riverpod
providers are thin adapters:

```dart
// lib/providers/world_state_provider.dart
// (flutter imports permitted here; this is the UI layer)
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:adventures/game/state_delta.dart';  // pure core

final worldStateProvider = StateNotifierProvider<WorldStateNotifier, WorldState>(
  (ref) => WorldStateNotifier(WorldState.initial()),
);

class WorldStateNotifier extends StateNotifier<WorldState> {
  WorldStateNotifier(super.initial);

  /// Called only when a ResolveResult (from the cascade) delivers a new state.
  /// The Resolver owns advancement; this notifier never calls applyDelta itself.
  void reconcile(WorldState nextState) => state = nextState;
}

// lib/providers/resolve_result_provider.dart
final resolveResultProvider = StateProvider<ResolveResult?>((ref) => null);

// Narration: UI resolves narrationKey via the NarrationRepository, never stores prose.
final narrationProvider = FutureProvider.family<String, String>(
  (ref, key) => ref.read(narrationRepositoryProvider).resolve(key),
);
```

`WorldState` is never held in widget `setState`. Riverpod is the single conduit from
core to widget tree. Sign-off from technical-director is required before adding
`flutter_riverpod` to `pubspec.yaml`.

### Decision Point 3 — Navigation

A **`go_router`-based navigator** (Navigator 2.0 declarative API) provides:
- Deep-linkable URLs for web: `adventures.example.com/play/<adventureId>` is shareable.
- Predictive-back support via `PopScope` (the `WillPopScope` replacement).
- Clean separation between route state and game state — the router holds adventure ID and
  screen path, not `WorldState`.

```dart
// lib/router/adventure_router.dart
final router = GoRouter(
  routes: [
    GoRoute(path: '/',           builder: (ctx, state) => const HomeScreen()),
    GoRoute(path: '/play/:id',   builder: (ctx, state) => AdventureScreen(
      adventureId: state.pathParameters['id']!,
    )),
    GoRoute(path: '/settings',   builder: (ctx, state) => const SettingsScreen()),
  ],
);
```

The Vertical Slice may add creator routes (`/create/:id`). Sign-off required before
adding `go_router` to `pubspec.yaml`.

### Decision Point 4 — Translation-Moment Visual Beat

The translation moment ("I said what I wanted, and the world took it seriously") is
a deliberate visual beat defined by this ADR as a widget/painter boundary. The visual
design itself (Direction 2: "The Illuminated Word", gold typography) is an Art Director
decision deferred to the `/art-bible` phase.

```dart
// lib/ui/translation_beat_widget.dart
// Wraps the CustomPainter and animation controller.
// Receives a resolved narrationKey (never raw prose) from the provider.
class TranslationBeatWidget extends StatefulWidget {
  const TranslationBeatWidget({super.key, required this.triggerBeat});
  final bool triggerBeat;   // flips true when a Resolved result arrives
  @override
  State<TranslationBeatWidget> createState() => _TranslationBeatWidgetState();
}

// lib/ui/translation_beat_painter.dart
// CustomPainter owned by technical-artist. No game logic.
// Inputs: animation value, narration text (resolved from narrationKey by the widget layer).
class TranslationBeatPainter extends CustomPainter {
  const TranslationBeatPainter({required this.progress, required this.narrationText});
  final double progress;
  final String narrationText;
  @override
  void paint(Canvas canvas, Size size) { /* visual-identity implementation — see /art-bible */ }
  @override
  bool shouldRepaint(TranslationBeatPainter old) =>
      old.progress != progress || old.narrationText != narrationText;
}
```

`RepaintBoundary` wraps `TranslationBeatWidget` so the animation does not force the
rest of the screen to repaint. The `AnimationController` lives in the widget's `State`;
it is not a Riverpod provider.

### Decision Point 5 — Input / Soft Keyboard (Pillar 1)

The blank line is a `TextField` that is **never modal-locked out** (Pillar 1):

```dart
// lib/ui/blank_line_field.dart
class BlankLineField extends StatelessWidget {
  const BlankLineField({super.key, required this.onSubmit});
  final ValueChanged<String> onSubmit;

  @override
  Widget build(BuildContext context) {
    return TextField(
      autofocus: true,
      textInputAction: TextInputAction.send,
      onSubmitted: (text) {
        if (text.trim().isNotEmpty) onSubmit(text.trim());
      },
      // Styled per art-bible; no logic here.
    );
  }
}
```

Mobile layout rules:
- `Scaffold(resizeToAvoidBottomInset: true)` ensures the scaffold body shrinks when the
  soft keyboard appears, keeping the input field above the keyboard.
- The narration scroll view scrolls-into-view on `TextField` focus so prior beats remain
  readable.
- `BlankLineField` uses `autofocus: true` on PC/desktop; on mobile, autofocus is
  disabled at first launch and activates after the player taps the blank line (prevents
  the keyboard from immediately covering onboarding text).
- The `TextField` rebuilds only itself on each keystroke — it is isolated via
  `RepaintBoundary` from the narration view. The broader adventure screen does not rebuild
  on every character.
- Portrait primary on mobile; landscape optional. All text uses `TextScaler`-aware sizes
  (never hardcoded `sp`).

### Decision Point 6 — Web / Wasm

Production web builds use `flutter build web --wasm` (Skwasm renderer, recommended since
Flutter 3.44). Budgets:

| Budget | Target | Gate |
|--------|--------|------|
| Initial Wasm bundle | <5MB | Blocking — fail CI if exceeded |
| Total assets | <20MB | Blocking |
| Web hot reload | Enabled in dev (Flutter 3.32+) | — |

Implementation rules:
- Never import `dart:html` or `dart:js` anywhere in the codebase — use `dart:js_interop`
  and `package:web` for any browser API access. This also satisfies the ADR-0007 Wasm
  interop constraint.
- Asset JSON (Scene Models, narration tables) is loaded via `rootBundle` / `AssetBundle`,
  which works under Wasm without special handling.
- Any future on-device embedding runtime for Tier 1 (ADR-0007, open decision) must be
  verified for Wasm compatibility before integration.
- Run `flutter build web --wasm --analyze-size` before each milestone to catch bundle growth.

### Decision Point 7 — Performance: 60fps / Optimistic UI

| Rule | Rationale |
|------|-----------|
| Wrap `TranslationBeatWidget` in `RepaintBoundary` | Isolates animation repaints from text layout |
| `BlankLineField` isolated from narration scroll | Keystroke rebuilds do not repaint the narrative scroll view |
| `ListView.builder` for narration history | Lazy; no eager `children:` list |
| `const` constructors on all stateless widgets | Skips rebuilds at the framework level |
| Optimistic acknowledgment on submit | Render an immediate "processing..." state before the cascade returns; reconcile when `ResolveResult` arrives (≤2s per ADR-0007) |

Optimistic-UI sequence:
1. Player submits blank line → `BlankLineField.onSubmit` fires immediately.
2. `resolveResultProvider` is set to `Pending` → UI renders an optimistic acknowledgment
   (e.g., spinner or pulsing blank line — visual design TBD at `/art-bible`).
3. `RouterCascadeService.route(...)` completes (Tier 0/1: near-instant; Tier 2/3: ≤2s).
4. `worldStateProvider.reconcile(nextState)` and `resolveResultProvider` → `Resolved`
   → `NarrationView` and `TranslationBeatWidget` render the final authored beat.

The UI must **never block the render thread** waiting for the cascade. All service calls
are `async`/`await` behind a Riverpod `AsyncNotifier`; the widget tree reacts to
`AsyncValue` states.

### Decision Point 8 — Narration Rendering

The UI **never holds generated prose**. It only holds authored `narrationKey` values from
`StateDelta` (ADR-0001) and resolves them through `NarrationRepository`:

```dart
// lib/services/narration_repository.dart
abstract interface class NarrationRepository {
  Future<String> resolve(String narrationKey);
}

// lib/services/narration_repository_impl.dart
// Loads a JSON narration table from assets/narration/<locale>.json on first call.
// Returns a fallback string if the key is not found (never crashes).
```

`NarrationView` consumes `narrationProvider` (a `FutureProvider.family<String, String>`)
and renders the resolved string. If the key is missing (content bug), it renders a
clearly authored fallback, not raw JSON or an empty widget. The core never holds a prose
string; the service layer resolves keys lazily; the UI layer displays the result.

### Key Interfaces in Dart

```dart
// lib/services/router/router_cascade_interface.dart
// DI seam — UI layer and tests depend on this, never on RouterCascade directly.
abstract interface class RouterCascadeInterface {
  Future<ResolveResult> route(String playerText, WorldState state);
}

// lib/services/narration_repository.dart  (shown above)

// lib/providers/adventure_providers.dart  (abbreviated)
final routerCascadeProvider = Provider<RouterCascadeInterface>(
  (ref) => throw UnimplementedError('Override in ProviderScope'),
  // Production: override with RouterCascadeService(...)
  // Tests: override with FakeRouterCascade(...)
);

final worldStateProvider = StateNotifierProvider<WorldStateNotifier, WorldState>(...);
final resolveResultProvider = StateProvider<AsyncValue<ResolveResult?>>((ref) => const AsyncData(null));
```

### Implementation Guidelines

- Start with `lib/game/`, `lib/resolver/`, `lib/scene/` already in place from the core
  ADRs (0001/0006). Do not write any widget code until those are Accepted.
- The MVP "bare text UI" requires only: `AdventureScreen` + `BlankLineField` +
  `NarrationView` + wiring to `RouterCascadeInterface` via Riverpod. The
  `TranslationBeatWidget` is a Vertical Slice deliverable.
- Add `flutter_riverpod` and `go_router` to `pubspec.yaml` only after technical-director
  sign-off. Until then, use `InheritedWidget` or plain `setState` for the prototype so
  no unapproved dependency is introduced.
- Enforce the import boundary in CI: `flutter analyze` plus a custom lint
  (`package:custom_lint` or a regex check) that forbids `import 'package:flutter'` in
  files under `lib/game/`, `lib/resolver/`, and `lib/scene/`.
- Use `WidgetStateProperty` (not deprecated `MaterialStateProperty`) for all Material
  widget theming.
- Use `PopScope` (not deprecated `WillPopScope`) for back-navigation handling.
- Use `findItemIndexCallback` (not `findChildIndexCallback`) in any `SliverList` /
  `ListView` separated constructors.
- iOS: SwiftPM is the default dependency manager since 3.44; CocoaPods is the fallback.
  Do not introduce new CocoaPods-only plugins without verifying SwiftPM availability.
- Android: do not apply the standalone `kotlin-android` plugin; AGP 9 provides Kotlin
  built-in.
- Verify `go_router` and `flutter_riverpod` Wasm compatibility before shipping the first
  web build; if either is Wasm-incompatible at 3.44, escalate to technical-director
  before proceeding.

## Alternatives Considered

### Alternative 1: Raw `InheritedWidget` + `setState` for all state (no library)

- **Description**: Use Flutter's built-in `InheritedWidget` and `StatefulWidget.setState`
  throughout. No third-party state management.
- **Pros**: Zero dependencies; no sign-off needed; familiar to any Flutter developer.
- **Cons**: `InheritedWidget` requires `BuildContext` for lookups, coupling service-layer
  code to the widget tree. As the adventure screen grows (narration history, meters, beat
  animation), `setState` in the root widget triggers full-subtree rebuilds — an O(n)
  rebuild on each beat, hard to scope. DI for tests requires manual wiring. Riverpod
  solves all three cleanly.
- **Estimated Effort**: Lower upfront; medium remediation when the screen grows.
- **Rejection Reason**: Rebuild discipline and DI testability become structural problems
  at Vertical Slice complexity. Riverpod's cost is one sign-off; its benefit is lifelong.

### Alternative 2: `provider` package

- **Description**: Use the `provider` package, the immediate predecessor to Riverpod,
  widely adopted and battle-tested.
- **Pros**: Simpler than Riverpod; large ecosystem familiarity; zero-to-hero onboarding
  is faster.
- **Cons**: `provider` looks up state via `BuildContext.watch`, which inextricably ties
  provider reads to the widget tree. Service-layer code that needs game state must receive
  a `BuildContext` or be restructured. Riverpod removes this coupling — providers are
  plain Dart objects accessible from anywhere. For a codebase where the deterministic core
  must be reachable from tests without a widget harness, `provider`'s `BuildContext`
  dependency is a structural mismatch.
- **Estimated Effort**: Similar to Riverpod; migration to Riverpod later is non-trivial.
- **Rejection Reason**: The `BuildContext` coupling contradicts the "DI over singletons"
  coding standard and makes the service layer harder to test headlessly.

### Alternative 3: BLoC / `flutter_bloc`

- **Description**: Use the BLoC pattern (`flutter_bloc` package) for explicit event →
  state streams.
- **Pros**: Explicit event typing; excellent separation of concerns; very testable.
- **Cons**: Significant boilerplate (Event / State classes per feature); the explicit
  event-stream model duplicates work already done by the pure-Dart `Resolver` + sealed
  `ResolveResult` hierarchy. The core already defines a typed, exhaustive event set
  (`StateDeltaOp`); wrapping it in a second BLoC event hierarchy adds indirection without
  new capability. Riverpod's `AsyncNotifier` covers the one genuine async-state concern
  (cascade round-trip) without the overhead.
- **Estimated Effort**: Higher — a BLoC per screen plus mapping from `ResolveResult` to
  BLoC events.
- **Rejection Reason**: Redundant abstraction over the existing pure-core event model;
  higher team overhead for no net testability gain.

## Consequences

### Positive

- The pure-Dart core remains zero-Flutter, headlessly testable, and eligible for
  edge-side deployment — the Resolver is never entangled with the widget tree.
- Riverpod's compile-safe provider graph catches missing dependency wires at startup, not
  at runtime.
- `go_router` URLs make adventures shareable links on the web target from day one.
- Optimistic UI keeps the blank line feeling instant; Tier 2/3 escalation reconciles
  silently within the ≤2s budget (ADR-0007).
- The `CustomPainter` seam gives the technical-artist full control over the translation
  beat visual without touching game logic.
- `ResizeToAvoidBottomInset` + `RepaintBoundary` on the text field prevents the two most
  common mobile UX failures (keyboard occlusion and full-screen keystroke rebuilds).

### Negative

- Two new third-party dependencies (`flutter_riverpod`, `go_router`) require
  technical-director sign-off and must be verified for Wasm compatibility.
- The three-layer import discipline requires a CI enforcement step (custom lint or
  regex check) that adds setup cost.
- `CustomPainter` + `AnimationController` for the translation beat adds complexity
  relative to a plain `Text` widget — but this complexity is explicitly isolated to
  `lib/ui/` and owned by the technical-artist.

### Neutral

- The MVP prototype may run with plain `setState` and no router; Riverpod and `go_router`
  are introduced at the MVP proper, after sign-off. The layering and import discipline
  apply from day one regardless.
- Narration key lookup adds one async hop between `ResolveResult` and the rendered word.
  The latency is negligible (in-memory map after first load) but the indirection is new
  to developers unfamiliar with the authored-content model.

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| `go_router` or `flutter_riverpod` are Wasm-incompatible at 3.44 | Low | High | Verify before adding to `pubspec.yaml`; alternatives exist (`auto_route`; raw `InheritedWidget`) — escalate to technical-director if incompatible |
| Flutter import leaks into pure-Dart core | Medium | High | CI lint gate forbids `package:flutter` in `lib/game/`, `lib/resolver/`, `lib/scene/`; enforced from first commit |
| Optimistic UI reconciles to a user-visible state jump | Low | Medium | Design the "pending" state to visually transition smoothly to "resolved"; reconcile only `WorldState`, not the narration text in mid-animation |
| Wasm bundle exceeds 5MB | Medium | Medium | `--analyze-size` at every milestone; defer asset-heavy visual identity to Vertical Slice; lazy-load narration tables per adventure |
| Soft keyboard occludes blank line on an unusual device/OS | Low | High (Pillar 1 violation) | Automated scroll-into-view tests; manual QA on small-screen iOS/Android devices before MVP |
| `CustomPainter` translation beat drops below 60fps | Low | Medium | `RepaintBoundary` isolation; profile with Flutter DevTools before Vertical Slice |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| Frame time (beat render) | n/a | <8ms (narration text layout + painter) | 16.6ms |
| Frame time (keystroke) | n/a | <2ms (isolated `TextField` rebuild) | 16.6ms |
| Memory (widget tree) | n/a | Small — text + painter; no large off-screen widgets | 150MB ceiling |
| Initial Wasm bundle | n/a | <5MB (Dart code + minimal assets) | <5MB blocking |
| Total assets | n/a | <20MB (narration JSON + fonts) | <20MB blocking |
| Cascade round-trip (Tier 2/3) | n/a | ≤2s; optimistic UI fires immediately | ≤2s per ADR-0007 |

## Migration Plan

Greenfield — no migration from a prior codebase.

**Build order:**
1. Establish `lib/game/`, `lib/resolver/`, `lib/scene/` from ADRs 0001/0006 (pure Dart,
   no UI).
2. Add the service-layer stubs in `lib/services/` with `RouterCascadeInterface` and
   `NarrationRepository` (interfaces only; fake implementations for the prototype).
3. After technical-director sign-off, add `flutter_riverpod` and `go_router` to
   `pubspec.yaml`; wire `ProviderScope` at `main.dart`.
4. Implement MVP bare UI: `AdventureScreen` + `BlankLineField` + `NarrationView` +
   providers.
5. Add the CI bundle-size gate (`flutter build web --wasm --analyze-size`) before
   shipping any web build.
6. Implement `TranslationBeatWidget` + `TranslationBeatPainter` at Vertical Slice, after
   the visual identity is finalized at `/art-bible`.

**Rollback plan:** the pure-Dart core and service layer are decoupled from the UI layer by
design. If a UI library choice proves wrong, only `lib/ui/`, `lib/providers/`, and
`lib/router/` need to be rewritten — the core and services are unaffected. The
`RouterCascadeInterface` DI seam ensures tests continue to pass regardless of UI changes.

## Validation Criteria

- [ ] `flutter analyze` reports zero errors/warnings on the full codebase
- [ ] No file under `lib/game/`, `lib/resolver/`, or `lib/scene/` imports `package:flutter` (CI lint gate)
- [ ] `BlankLineField` is never obscured by the soft keyboard on a small-screen iOS and Android device (manual QA)
- [ ] `flutter build web --wasm --analyze-size` reports initial bundle <5MB (CI gate)
- [ ] `AdventureScreen` keystroke rebuild does not trigger a repaint of `NarrationView` (Flutter DevTools rebuild count = 0 for `NarrationView` on keystroke)
- [ ] `TranslationBeatWidget` sustains 60fps during the beat animation (DevTools GPU thread)
- [ ] Adventure URL (`/play/<id>`) deep-links correctly on web (shareable URL navigation)
- [ ] `NarrationView` never renders a raw narrationKey string — always resolved text or the authored fallback
- [ ] Optimistic UI acknowledgment appears within one frame of blank-line submission (no wait for cascade)
- [ ] Cascade `ResolveResult` reconciliation completes within the ≤2s budget under a simulated Tier-2 round-trip

## GDD Requirements Addressed

Closes `TR-client-001` from `docs/architecture/tr-registry.yaml`.

| Source | TR-ID / Pillar / Concept | How This ADR Satisfies It |
|--------|--------------------------|--------------------------|
| `tr-registry.yaml` TR-client-001 | Cross-platform thin-client architecture (PC/Web/Mobile) | Three-layer split; Flutter single-codebase; Wasm web build; SwiftPM iOS; AGP 9 Android |
| `tr-registry.yaml` TR-client-001 | UI/state-management | Riverpod adapts `WorldState` to widgets; game state never held in `setState` |
| `tr-registry.yaml` TR-client-001 | Navigation/router for shareable URLs | `go_router`-based `AdventureRouter`; `/play/:id` deep links |
| `tr-registry.yaml` TR-client-001 | Translation-moment visual beat | `TranslationBeatWidget` + `TranslationBeatPainter` seam (visual design deferred to `/art-bible`) |
| `tr-registry.yaml` TR-client-001 | Soft-keyboard handling | `resizeToAvoidBottomInset`; scroll-into-view; `autofocus` policy |
| `tr-registry.yaml` TR-client-001 | <5MB initial Wasm bundle | `flutter build web --wasm`; CI bundle-size gate |
| `design/gdd/game-pillars.md` Pillar 1 | "The text input is never modal-locked out" | `BlankLineField` always visible; keyboard never occludes the blank line |
| `design/gdd/game-pillars.md` Pillar 2 | "Make the translation moment visible (the gold illuminated word)" | `TranslationBeatWidget` + `CustomPainter` seam defined; visual implementation at `/art-bible` |
| `design/gdd/game-pillars.md` Pillar 2 | "All resolution paths return the same `StateDelta`, validated before applying; on failure, safe default — never raw text" | UI renders only resolved `narrationKey` strings; `NarrationRepository` fallback; no prose in providers |
| `design/gdd/game-concept.md` §Technical Considerations | "One portable cross-platform UI layer" (stack-shaping constraint #3) | Single Flutter codebase; three-layer import discipline |
| `design/gdd/game-concept.md` §Where each piece runs | Client/edge hot path runs without a round-trip | Pure-Dart core + Riverpod provider; cascade is async, UI is immediate |
| `design/gdd/game-concept.md` §MVP | "Bare text UI" | MVP validation criteria scoped to `AdventureScreen` + `BlankLineField` + `NarrationView` |

## Related

- ADR-0001 (StateDelta) — `narrationKey` is the UI's authored-content handle; `WorldState` is the core state type adapted by Riverpod providers
- ADR-0006 (Resolver) — `ResolveResult` is the per-beat output this ADR renders; one UI update per beat, never per wall-clock tick
- ADR-0007 (Router cascade) — `RouterCascadeInterface` DI seam; optimistic-then-reconcile pattern; Wasm interop constraint inherited here
- `design/gdd/game-pillars.md` — Pillar 1 (blank line sacred), Pillar 2 (translation moment), Pillar 3 (no real-time pressure)
- `docs/engine-reference/flutter/current-best-practices.md` — Riverpod recommendation, Navigator 2.0/go_router, Wasm build, Impeller
- `docs/engine-reference/flutter/deprecated-apis.md` — `WidgetStateProperty`, `PopScope`, `findItemIndexCallback` replacements used here
- `docs/engine-reference/flutter/breaking-changes.md` — SwiftPM default, AGP 9 built-in Kotlin, Skwasm production web build
