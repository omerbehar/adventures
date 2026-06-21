# Technical Preferences

<!-- Populated by /setup-engine. Updated as the user makes decisions throughout development. -->
<!-- All agents reference this file for project-specific standards and conventions. -->

## Engine & Language

- **Engine**: Flutter 3.44.0
- **Language**: Dart 3.12
- **Rendering**: Impeller (mobile default), Skwasm/WebAssembly (web production)
- **Physics**: N/A — text-first game; no physics engine required

## Input & Platform

<!-- Written by /setup-engine. Read by /ux-design, /ux-review, /test-setup, /team-ui, and /dev-story -->
<!-- to scope interaction specs, test helpers, and implementation to the correct input methods. -->

- **Target Platforms**: PC (Steam/Epic), Web (WebAssembly/Skwasm), Mobile (iOS/Android)
- **Input Methods**: Keyboard/Mouse (PC), Touch (Mobile), Both (Web)
- **Primary Input**: Keyboard — the blank line is typed freeform text; text input is the central mechanic
- **Gamepad Support**: None — freeform text input requires a keyboard; gamepad cannot drive the core loop
- **Touch Support**: Full — mobile is a primary target; virtual keyboard handles text entry
- **Platform Notes**: |
    Virtual keyboard must not obscure the text input field on mobile (use `resizeToAvoidBottomInset`
    or equivalent scroll/padding logic). Production web builds use WebAssembly (Skwasm renderer) for
    performance and bundle size. Portrait orientation is primary on mobile; landscape optional.
    All UI text must be legible at varying DPIs (use `sp` units via `TextScaler`).

## Naming Conventions

- **Classes**: PascalCase (e.g., `SceneModel`, `CapabilityVector`, `SceneResolver`)
- **Variables/Functions**: camelCase (e.g., `currentAlertness`, `resolveCapability()`)
- **Constants**: lowerCamelCase or `k`-prefixed in class scope (e.g., `kMaxForce`, `defaultAlertness`)
- **Private members**: `_underscore` prefix (e.g., `_state`, `_resolveInternal()`)
- **Enums**: PascalCase type, lowerCamelCase values (e.g., `CapabilityDimension.force`)
- **Files**: snake_case matching primary class (e.g., `scene_model.dart`, `capability_vector.dart`)
- **Test files**: `<filename>_test.dart` suffix (e.g., `scene_model_test.dart`)
- **Widget files**: snake_case in `lib/ui/` or `lib/screens/` (e.g., `adventure_screen.dart`)
- **Data/content files**: snake_case JSON (e.g., `prison_cell_scene.json`)

## Performance Budgets

- **Target Framerate**: 60fps (all platforms)
- **Frame Budget**: 16.6ms per frame
- **Memory Ceiling**: 150MB runtime (mobile-constrained target)
- **Web Bundle**: <5MB initial WASM load, <20MB total assets
- **Service Latency**: Translator Tier 2/3 round-trip ≤2s; display optimistic UI immediately

## Testing

- **Framework**: `flutter_test` (built-in, unit + widget tests) + `integration_test` (end-to-end)
- **Minimum Coverage**: [TO BE CONFIGURED — set after first sprint]
- **Required Tests**: Resolver determinism (same input → same StateDelta every run), CapabilityTranslator
  classify-don't-score stability, Scene Model threshold evaluation, StateDelta validation

## Forbidden Patterns

<!-- Add patterns that should never appear in this project's codebase -->
- Never emit raw generative prose from the Resolver — output must be a validated StateDelta
- Never coin new scalar capability axes at runtime — promote via ADR only
- Never use real-time clocks for gameplay state — all advancement is per-beat (state-machine only)
- [Add further patterns as architectural decisions are made]

## Allowed Libraries / Addons

<!-- Add approved third-party dependencies here — only add when actively integrating, not speculatively -->
- `flutter_test` — unit and widget testing (built-in)
- `integration_test` — end-to-end integration tests (built-in)
- [Add further libraries as they are approved and actively integrated]

## Architecture Decisions Log

<!-- Quick reference linking to full ADRs in docs/architecture/ -->
- [No ADRs yet — use /architecture-decision to create one]
- Foundational ADRs to author (from concept doc): StateDelta primitive, Capability Ontology,
  Scene Model schema, Classify-don't-score Translator, Scene Compiler + Linter, Resolver as
  deterministic rules engine, Tiered router cascade + bounded fallback, Feedback loop

## Engine Specialists

<!-- Written by /setup-engine when engine is configured. -->
<!-- Read by /code-review, /architecture-decision, /architecture-review, and team skills -->
<!-- to know which specialist to spawn for engine-specific validation. -->

<!-- flutter-specialist is the project-tailored engine authority (.claude/agents/flutter-specialist.md), -->
<!-- version-aware against docs/engine-reference/flutter/. It coordinates the domain programmers below. -->

- **Primary**: flutter-specialist (Flutter/Dart architecture, version-aware idiom review, pub/pubspec, cross-platform export)
- **UI/Widget Specialist**: ui-programmer (all Flutter widget code, screens, navigation, layout)
- **Gameplay/Logic Specialist**: gameplay-programmer (Resolver, Scene Model evaluation, StateDelta, game state)
- **Service Integration**: network-programmer (HTTP client, Translator API calls, embedding retrieval, async flows)
- **Visual/Animation Specialist**: technical-artist (CustomPainter, animations, the translation-moment visual beat)
- **Routing Notes**: Invoke flutter-specialist for engine/architecture decisions, the pure-Dart-core
  vs. widget vs. service boundary, Flutter 3.44 / Dart 3.12 idiom review, and any version-uncertain API.
  It coordinates with (and delegates implementation to) the domain agents: ui-programmer for Widget
  hierarchy, Navigation 2.0, screen layout, and input handling; gameplay-programmer for the core game
  logic (Resolver, CapabilityTranslator, SceneModel, StateDelta schema); network-programmer for all
  service API calls, async data flows, and the Tier 2/3 Translator integration; technical-artist for
  the translation-moment visual beat and any CustomPainter / animation work. Escalate architecture
  conflicts to lead-programmer and version/dependency decisions to technical-director.

### File Extension Routing

<!-- Skills use this table to select the right specialist per file type. -->

| File Extension / Type | Specialist to Spawn |
|-----------------------|---------------------|
| Widget/screen files (`lib/ui/`, `lib/screens/`) | ui-programmer |
| Game logic files (`lib/game/`, `lib/resolver/`, `lib/scene/`) | gameplay-programmer |
| Service/API files (`lib/services/`, `lib/api/`) | network-programmer |
| Rendering/animation files (`lib/rendering/`) | technical-artist |
| `pubspec.yaml`, `.dart_tool/`, project config | flutter-specialist |
| General architecture review | flutter-specialist |
