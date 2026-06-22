# Test Framework for Adventures

This directory contains the automated test suite for Adventures, organized by system and test type.

## Directory Structure

```
tests/
├── unit/                        # Unit tests (pure Dart, no I/O, fast)
│   ├── state/                   # StateDelta, WorldState, validation
│   ├── ontology/                # CapabilityOntology, CapabilityDimension, CapabilityVector
│   ├── scene/                   # SceneModel, ThresholdExpr, evaluation
│   ├── translator/              # CapabilityTranslator, classify-don't-score
│   ├── resolver/                # Resolver, determinism, threshold matching
│   └── [system]/                # Additional systems as architecture expands
│
├── integration/                 # Integration tests (multi-system, flutter_test framework)
│   ├── resolver_integration_test.dart  # Resolver + SceneModel + state application
│   ├── translator_integration_test.dart # Translator + Resolver pipeline
│   └── [feature]/               # Feature-level integration tests
│
└── README.md (this file)
```

## Test Naming Conventions

File naming: `[system]_[feature]_test.dart`
- Example: `resolver_determinism_test.dart`, `state_delta_validation_test.dart`

Function naming: `test_[scenario]_[expected]`
- Example: `test_same_input_produces_same_output()`, `test_invalid_facet_reference_rejected()`

## Test Evidence by Story Type

Adventures uses story-driven test gates. All stories must have appropriate evidence before they can be marked Done:

| Story Type | Required Evidence | Location | Gate Level |
|---|---|---|---|
| **Logic** (formulas, AI, state machines) | Automated unit test — must pass | `tests/unit/[system]/` | **BLOCKING** |
| **Integration** (multi-system) | Integration test OR documented playtest | `tests/integration/[system]/` | **BLOCKING** |
| **Visual/Feel** (animation, VFX, feel) | Screenshot + lead sign-off | `production/qa/evidence/` | ADVISORY |
| **UI** (menus, HUD, screens) | Manual walkthrough doc OR interaction test | `production/qa/evidence/` | ADVISORY |
| **Config/Data** (balance tuning) | Smoke check pass | `production/qa/smoke-[date].md` | ADVISORY |

**BLOCKING** stories cannot be merged if tests fail — no exceptions. **ADVISORY** stories provide confidence but do not gate merging.

## Automated Test Rules (Coding Standard)

### Determinism
- Tests must produce the same result every run.
- **Forbidden**: `DateTime.now()`, unseeded `Random`, time-dependent assertions, floating-point equality without tolerance.
- **Allowed**: seeded RNG (injected via constructor), constant test data, deterministic clock mocks.

### Isolation
- Each test sets up and tears down its own state.
- Tests must not depend on execution order — reorder them and they should all still pass.
- Use factory functions or fixture builders, never global mutable state.

### Independence
- Unit tests do not call external APIs, databases, or file I/O.
- Use **dependency injection** to substitute fakes/mocks for external services.
- Exception: integration tests **may** spin up in-process fakes (e.g., a fake HTTP server).

### No Hardcoded Magic Numbers (Except Boundary Tests)
- Test fixtures use constant files or factory functions, not inline magic numbers.
- Exception: boundary value tests (where the exact number IS the point of the test).

## What NOT to Automate

- **Visual fidelity** (shader output, VFX appearance, animation curves) — test on target hardware.
- **"Feel" qualities** (input responsiveness, perceived weight, timing) — covered by playtesting.
- **Platform-specific rendering** — test on real devices, not headlessly.
- **Full gameplay sessions** — long playtests are covered by QA, not automation.

## Running Tests Locally

```bash
# Run all unit tests
flutter test tests/unit/

# Run tests for a specific system
flutter test tests/unit/resolver/

# Run a specific test file
flutter test tests/unit/resolver/resolver_determinism_test.dart

# Run integration tests
flutter test integration_test/

# Run all tests with coverage
flutter test --coverage
```

## CI/CD Rules

- Automated test suite runs on every push to `main` and `develop`, and on all PRs.
- **No merge if tests fail** — tests are a blocking gate in CI.
- **Never disable or skip a failing test to make CI pass** — fix the underlying issue instead.
- GitHub Actions workflow: `.github/workflows/tests.yml`
  - Triggers on push to `main` / `develop` and all PRs.
  - Runs `flutter analyze`, `dart format`, `flutter test`.
  - All three are blocking; any failure stops the merge.

## Required Tests for MVP

Per the Technical Preferences and ADRs, these systems must have deterministic test coverage before the Resolver epic can be considered Done:

1. **Resolver Determinism** (`tests/unit/resolver/resolver_determinism_test.dart`)
   - Same `(WorldState, CapabilityVector)` → identical `ResolveResult` across 1000 runs.

2. **CapabilityTranslator Classify-Don't-Score Stability** (`tests/unit/translator/translator_stability_test.dart`)
   - Translator produces consistent `CapabilityVector` classification (no scoring, no ranking).

3. **SceneModel Threshold Evaluation** (`tests/unit/scene/scene_threshold_eval_test.dart`)
   - `ThresholdExpr` matches correctly against facets/meters; facet collapse fires decisively.

4. **StateDelta Validation** (`tests/unit/state/state_delta_validation_test.dart`)
   - `validateDelta` rejects deltas referencing unknown facets/meters/entities.
   - `applyDelta` is a pure function: same inputs → identical output, 1000 runs.

## Frameworks & Tools

- **`flutter_test`** (built-in) — unit tests and widget tests.
  - Use `test()` for pure-Dart unit tests.
  - Use `testWidgets()` for widget tests.
  - No platform-specific dependencies needed.

- **`integration_test`** (built-in) — end-to-end integration tests.
  - Run via `flutter test integration_test/`.
  - Can test full app flows across multiple systems.

- **Mocks/Fakes via Dependency Injection**
  - Do NOT use `mockito` or `mocktail` for pure-Dart logic tests.
  - Inject test doubles (fakes, stubs) through constructor parameters.
  - Example: `Resolver(fakeOntology: FakeOntology(), ...)`.

- **Golden Tests (ADVISORY only)**
  - Use `testWidgets()` + `matchesGoldenFile()` for UI golden snapshots.
  - Golden tests are ADVISORY evidence for visual story types, not BLOCKING.
  - Stored in `tests/golden/` (created by `flutter test --update-goldens`).

## Adding a New Test

1. Create a file matching `[system]_[feature]_test.dart` in the appropriate `tests/unit/[system]/` directory.
2. Import `flutter_test` and the system under test.
3. Use factory/builder functions for test fixtures (not inline magic numbers).
4. Name tests `test_[scenario]_[expected]()`.
5. Example:

   ```dart
   // tests/unit/resolver/resolver_determinism_test.dart
   import 'package:flutter_test/flutter_test.dart';
   import 'package:adventures/game/resolver.dart';
   import 'package:adventures/game/state_delta.dart';
   
   void main() {
     group('Resolver Determinism', () {
       test('test_same_input_produces_same_output_1000_runs', () {
         const resolver = Resolver();
         final worldState = _buildTestWorldState();
         final vector = _buildTestCapabilityVector();
   
         final results = <ResolveResult>[];
         for (int i = 0; i < 1000; i++) {
           results.add(resolver.resolve(worldState, vector));
         }
   
         // All results should be identical
         for (int i = 1; i < results.length; i++) {
           expect(results[i], equals(results[0]));
         }
       });
     });
   }
   
   WorldState _buildTestWorldState() {
     return WorldState(
       currentNodeId: 'start',
       meters: {'alertness': 30},
       facets: {},
       revealedFacets: {},
       entityProps: {},
       beatCursors: {},
     );
   }
   ```

6. Run locally: `flutter test tests/unit/resolver/resolver_determinism_test.dart`
7. Commit with a message referencing the story/task ID (Conventional Commits format).

## Continuous Integration

GitHub Actions automatically runs tests on every push and PR. See `.github/workflows/tests.yml` for the workflow definition.

- No merge if any test fails.
- All formatting must pass `dart format`.
- All lints must pass `flutter analyze`.

## Next Steps

Once the Flutter SDK is installed and the project is initialized:

1. Run `flutter create .` to generate platform-specific folders (`ios/`, `android/`, `web/`, `macos/`, `windows/`, `linux/`).
2. Run `flutter pub get` to fetch dependencies.
3. Run `flutter test` to verify the test harness is working.
4. Begin authoring tests alongside the first systems (Resolver, StateDelta, Translator).

---

For more information, see:
- `.claude/docs/coding-standards.md` (Testing Standards section)
- `.claude/docs/technical-preferences.md` (Testing section)
- `docs/engine-reference/flutter/current-best-practices.md` (Testing section)
- `docs/architecture/` for system-specific ADRs
