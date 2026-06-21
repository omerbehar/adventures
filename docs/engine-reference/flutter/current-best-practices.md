# Flutter — Current Best Practices (3.44 / Dart 3.12)

> **Last verified: 2026-06-21**
> Practices that are current as of the pinned version but may post-date the LLM's
> training data. Bias toward these when writing or reviewing Flutter/Dart code for
> Adventures. Verify uncertain specifics with WebSearch.

---

## Dart 3.x Language Idioms

- **Records** for lightweight multiple returns instead of ad-hoc classes or `List`/`Map`:
  ```dart
  ({CapabilityDimension dim, int magnitude, String target}) translate(String input) { ... }
  ```
- **Patterns + switch expressions** for resolving capability vectors against thresholds —
  exhaustive, destructuring matches read cleanly for the Resolver:
  ```dart
  final outcome = switch (vector) {
    (dim: CapabilityDimension.force, magnitude: final m, :final target) when m >= threshold =>
      Outcome.breach(target),
    _ => Outcome.noMatch,
  };
  ```
- **Class modifiers** (`sealed`, `final`, `base`, `interface`) — use `sealed` for closed
  type hierarchies like `StateDelta` variants so switches are exhaustive at compile time.
- **Private named parameters** (Dart 3.12) — constructors can initialize private fields
  directly via named params; the underscore is stripped for callers.
- **Sound null safety** is 100% — no migration flags; prefer non-nullable types and
  explicit `?`/`!` only where genuinely needed.
- Run **`dart fix --apply`** routinely; lean on `package:lints` / `flutter_lints`.

---

## State Management

- No state-management library is mandated yet. When one is needed, evaluate **Riverpod**
  (compile-safe, testable, DI-friendly — aligns with the project's "dependency injection
  over singletons" coding standard) before reaching for `provider` or raw `InheritedWidget`.
- Keep the **deterministic Resolver and Scene Model as plain Dart** (no Flutter imports) so
  they are unit-testable without a widget harness and could run client- or edge-side.
- Separate pure game logic (`lib/game/`, `lib/resolver/`) from UI (`lib/ui/`) — the concept's
  "deterministic hot path" must not depend on the widget layer.

---

## Architecture for Adventures (thin client + service)

- **Pure Dart core**: `StateDelta`, `SceneModel`, `CapabilityVector`, `Resolver` — zero
  Flutter dependencies, fully unit-tested for determinism (same input → same StateDelta).
- **Service layer** (`lib/services/`): async HTTP/WebSocket to the Translator service
  (Tier 2/3) and embedding retrieval. Wrap in interfaces for DI + mockability.
- **UI layer** (`lib/ui/`): typography-forward widgets; the blank line is a `TextField`;
  the translation moment is a deliberate visual beat (animation / `CustomPainter`).
- **Content** (`assets/scenes/`): Scene Models as JSON; this format IS the creator-facing
  primitive (Pillar 4). Validate against a schema on load.

---

## Web (production target)

- Build with **`flutter build web --wasm`** (Skwasm) for production — smaller bundle,
  better accessibility/SEO semantics. Watch the <5MB initial-load budget.
- Verify any plugin / JS-interop works under Wasm (some legacy `dart:html` interop does not;
  prefer `package:web` + `dart:js_interop`).
- Use a router (Navigator 2.0 / `go_router`-style) for deep-linkable, shareable adventure URLs.

---

## Mobile

- **Impeller** is the default renderer — no `--enable-impeller` flag needed.
- iOS/macOS dependencies resolve via **SwiftPM** by default (3.44).
- Android builds use **AGP 9 built-in Kotlin** — no standalone KGP plugin.
- Handle the soft keyboard for the blank line: `resizeToAvoidBottomInset`, scroll-into-view
  on focus, and test on small screens.

---

## Testing

- **`flutter_test`** for unit + widget tests; **`integration_test`** for end-to-end flows.
- Keep Resolver/SceneModel tests as **pure-Dart unit tests** — no `WidgetTester`, no I/O,
  deterministic, fast.
- Use **fakes/mocks via DI** for the Translator service so logic tests never hit the network
  (honors the "unit tests do not call external APIs" coding standard).
- Golden tests are available for the typography-forward UI, but treat visual fidelity as
  ADVISORY evidence (per testing standards), not a blocking gate.

---

## Tooling

- **Dart & Flutter MCP server** enables agentic hot reload — an AI agent can hot-reload the
  running app to close the edit→observe loop.
- `dart format` (now part of the unified `dart` CLI) for consistent formatting.
- `flutter analyze` in CI as a blocking lint gate.
