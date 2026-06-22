# Flutter — Breaking Changes (Training Cutoff → 3.44)

> **Last verified: 2026-06-21**
> Source of truth: <https://docs.flutter.dev/release/breaking-changes>
> This file summarizes changes between the LLM training cutoff (~Flutter 3.24, May 2025)
> and the project's pinned version (Flutter 3.44 / Dart 3.12). Always confirm specifics
> against the official migration guides linked below before relying on them.

---

## Flutter 3.44 (May 2026) — PINNED

### SwiftPM replaces CocoaPods (iOS / macOS)
- **What changed**: Swift Package Manager (SwiftPM) is now the **default** dependency
  manager for iOS and macOS. The Flutter CLI migrates the Xcode project automatically
  on build/run.
- **Action**: Set a minimum Flutter constraint of `3.44` in `pubspec.yaml`
  (`environment: flutter: ">=3.44.0"`). CocoaPods still works as a fallback if a plugin
  has not yet published a Swift package, but plan for SwiftPM.
- **Impact on this project**: Low at present (no iOS plugins integrated yet) but relevant
  once mobile plugins are added.

### Android Kotlin Gradle Plugin (KGP) migration under AGP 9
- **What changed**: AGP 9 ships built-in Kotlin. Apps that still apply the separate
  `kotlin-android` (KGP) plugin **fail to build**.
- **Action**: Remove the standalone KGP plugin from Android Gradle files; rely on AGP 9's
  built-in Kotlin. See migration guide.
- **Guide**: <https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin>

### ABI filtering flag under AGP 9
- **What changed**: Custom `abiFilters` inside specific build types or product flavors now
  require `-Pdisable-abi-filtering=true` when building/running.
- **Action**: Pass the flag if you use per-flavor ABI filters.

### iOS UIScene lifecycle
- **What changed**: Apps built with the latest iOS SDK will be required to adopt the
  **UIScene lifecycle**. Flutter 3.44 begins this transition.
- **Action**: Verify the iOS runner adopts UIScene before submitting to the App Store.

### Material & Cupertino package decoupling
- **What changed**: Material and Cupertino widgets are migrating out of `flutter/flutter`
  into independent `material_ui` and `cupertino_ui` packages on pub.dev.
- **Action**: For now `package:flutter/material.dart` still works. Watch for the migration
  notice; new Material 3 features may ship first via the standalone packages.

### WebAssembly is the recommended production web renderer
- **What changed**: Skwasm/WebAssembly is now the recommended build for production Flutter
  Web (smaller bundles, better accessibility/SEO semantics) over the legacy CanvasKit/HTML
  renderers.
- **Action**: Build web with `flutter build web --wasm`. Validate that any JS-interop or
  plugin works under Wasm.

---

## Flutter 3.41 (~early 2026)

- **`findChildIndexCallback` deprecated** → use **`findItemIndexCallback`** in `ListView`
  and `SliverList` separated constructors.
- Synchronous image decoding added (`decodeImageFromPixelsSync`) — generate a texture and
  sample it within the same frame.
- "Bounded blur" visual style introduced.
- Continued work splitting Material/Cupertino into separate packages.

---

## Flutter 3.36 (~late 2025)

- Continued Impeller rollout and migration of the rendering backend; legacy Skia path
  increasingly deprecated on mobile.
- Web and tooling improvements (verify specifics against release notes before relying on them).

---

## Flutter 3.32 (May 2025)

- **Web hot reload** shipped.
- **Android semantic announcement events deprecated** (API 36) → configure
  `SemanticsProperties.liveRegion` for "polite" implicit announcements instead of imperative
  announcement events.
- Native platform and performance improvements.
- Guide: <https://medium.com/flutter/whats-new-in-flutter-3-32-40c1086bab6e>

---

## Flutter 3.29 (Feb 2025)

- Fixes the Impeller-on-Vulkan rendering bugs/crashes present in 3.27.
- **Discontinued first-party packages**: `flutter_markdown`, `ios_platform_images`,
  `css_colors`, `palette_generator`, `flutter_image`. Find community-maintained
  replacements if any were in use.

---

## Flutter 3.27 (Dec 2024) — AVOID

- Known **Impeller-on-Vulkan rendering bugs and crashes**. The Flutter team did **not**
  hotfix these and recommends upgrading to **3.29 or later**. Do not pin to 3.27.

---

## Dart 3.x Language Changes (cutoff → 3.12)

- **Macros** (static metaprogramming) stabilized in Dart 3.12.
- **Pub workspaces** for cleaner monorepos.
- **Private named parameters** — constructors can accept named params that initialize
  private fields; the underscore is stripped at the call site (`this._count` → callers
  pass `count:`).
- **Experimental primary constructors** (preview — do not rely on for production yet).
- Core libraries cleaned of long-deprecated APIs — run `dart fix` after upgrading.

---

## General Migration Workflow

1. After bumping the SDK, run `dart fix --apply` to auto-migrate supported breaking changes.
2. Run `flutter analyze` and resolve remaining deprecation warnings.
3. For Android, follow the built-in Kotlin migration guide.
4. For iOS/macOS, let the CLI migrate to SwiftPM, then verify all plugins resolve.
5. Re-run the test suite (`flutter test` + `integration_test`) before committing.
6. Not every breaking change is `dart fix`-supported — check the official guide per version.
