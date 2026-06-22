# Flutter — Version Reference

| Field | Value |
|-------|-------|
| **Engine Version** | Flutter 3.44.0 |
| **Language Version** | Dart 3.12 |
| **Project Pinned** | 2026-06-21 |
| **Last Docs Verified** | 2026-06-21 |
| **LLM Knowledge Cutoff** | May 2025 |
| **Risk Level** | HIGH — version is well beyond LLM training data |

## Risk Assessment

The LLM's training data covers Flutter up to roughly **3.24 / early 3.27** (mid-2025)
and Dart up to roughly **3.5 / 3.6**. The project is pinned to **Flutter 3.44 / Dart 3.12**
(released at Google I/O, May 2026). This is a **HIGH RISK** knowledge gap: there are
multiple stable releases, several breaking changes, and significant tooling shifts
between the training cutoff and the pinned version.

**Agents MUST consult the reference docs in this directory before suggesting Flutter
or Dart APIs, and SHOULD use WebSearch to verify any API whose behavior is uncertain.**

## Post-Cutoff Version Timeline

| Version | Approx. Release | Status vs. Training Data |
|---------|-----------------|--------------------------|
| 3.24 | Aug 2024 | Within training data |
| 3.27 | Dec 2024 | Edge / partial — known Impeller-on-Vulkan bugs; upgrade to 3.29+ |
| 3.29 | Feb 2025 | Edge / partial |
| 3.32 | May 2025 | Beyond — web hot reload, deprecations begin |
| 3.36 | ~late 2025 | Beyond training data |
| 3.41 | ~early 2026 | Beyond training data |
| **3.44** | **May 2026** | **Beyond — PINNED VERSION** |

## What Changed Since the Cutoff (high-level)

- **SwiftPM is now the default** iOS/macOS dependency manager (replaces CocoaPods).
- **Android Kotlin Gradle Plugin (KGP) migration** required under AGP 9 (built-in Kotlin).
- **Material & Cupertino are moving out of the SDK** into `material_ui` / `cupertino_ui`
  packages on pub.dev (decoupled from the 3-month release cycle).
- **WebAssembly (Skwasm) is the recommended production web build** — smaller bundles,
  better semantics/SEO.
- **Dart 3.12** stabilizes macros (static metaprogramming), adds pub workspaces,
  private named parameters, and an experimental primary-constructors feature.
- **Impeller** is the default renderer on mobile; the legacy Skia path is being retired.
- **Dart & Flutter MCP server** enables agentic hot reload.

See `breaking-changes.md`, `deprecated-apis.md`, and `current-best-practices.md` for detail.

## Maintenance

- Run `/setup-engine refresh` to re-verify against the latest Flutter docs.
- Run `/setup-engine upgrade 3.44 <new-version>` when bumping the pinned version.
- Every reference file in this directory carries a "Last verified" date — treat any
  file older than ~3 months (one release cycle) as needing a refresh.
