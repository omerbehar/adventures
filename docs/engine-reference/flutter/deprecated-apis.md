# Flutter — Deprecated APIs & Replacements (as of 3.44)

> **Last verified: 2026-06-21**
> Source of truth: <https://docs.flutter.dev/release/breaking-changes> (per-version
> "Deprecated API removed after vX.Y" pages). Run `dart fix --apply` to auto-migrate
> most of these. Always verify against the official page before relying on a replacement.

---

## Don't Use → Use Instead

| Deprecated / Removed | Use Instead | Since / Notes |
|----------------------|-------------|---------------|
| `findChildIndexCallback` (ListView/SliverList separated ctors) | `findItemIndexCallback` | Deprecated 3.41 |
| Imperative Android semantic announcement events | `SemanticsProperties.liveRegion` ("polite" implicit announcements) | Android API 36, deprecated 3.32 |
| CocoaPods as default iOS/macOS dep manager | Swift Package Manager (SwiftPM) — CLI auto-migrates | Default since 3.44 |
| Standalone `kotlin-android` (KGP) plugin (AGP 9) | AGP 9 built-in Kotlin (remove KGP) | Required 3.44 / AGP 9 |
| CanvasKit/HTML web renderers for production | WebAssembly (Skwasm) — `flutter build web --wasm` | Recommended 3.44 |
| Legacy Skia renderer on mobile | Impeller (default) | Default on mobile |
| First-party `flutter_markdown`, `ios_platform_images`, `css_colors`, `palette_generator`, `flutter_image` | Community-maintained forks / alternatives | Discontinued 3.29 |

---

## APIs Likely Stale in Training Data

The LLM may suggest these older patterns. Prefer the modern equivalent:

| LLM may suggest (older) | Modern equivalent (3.44 / Dart 3.12) |
|-------------------------|--------------------------------------|
| `MaterialStateProperty` / `MaterialState` | `WidgetStateProperty` / `WidgetState` (renamed; `Material*` aliases deprecated) |
| `Color.value` / manual ARGB int packing | `Color.from` / `.withValues()` (wide-gamut color API) |
| `theme.textTheme.headline6` etc. (M2 names) | Material 3 text-theme names (`titleLarge`, `bodyMedium`, …) |
| `ButtonBar` | `OverflowBar` / `Row` with alignment |
| `RaisedButton` / `FlatButton` / `OutlineButton` | `ElevatedButton` / `TextButton` / `OutlinedButton` |
| `WillPopScope` | `PopScope` (predictive back support) |
| Imperative `Navigator.push` everywhere | Consider Navigator 2.0 / a router for deep-linkable, web-friendly nav |
| Long, deprecated `dart:core` / `dart:async` APIs | Removed in Dart 3.x cleanup — run `dart fix` |

> ⚠️ The exact deprecation state of `MaterialStateProperty`, color APIs, and theme names
> shifts release-to-release. **Verify with WebSearch or `flutter analyze`** before asserting
> a specific API is removed vs. merely deprecated.

---

## Verification Commands

```bash
dart fix --dry-run     # preview auto-migrations
dart fix --apply       # apply supported migrations
flutter analyze        # surface remaining deprecation warnings
```
