/// Narration resolution (ADR-0009 Decision Point 8 / ADR-0001). The UI never holds generated
/// prose — it holds authored `narrationKey`s and resolves them here to display text. A missing
/// key returns a clearly-authored fallback, never raw JSON, an empty string, or a crash.
/// Pure Dart, zero Flutter imports (the asset-loading wiring lives at the composition root).
library;

/// Resolves an authored `narrationKey` to its display string.
// ignore: one_member_abstracts
abstract interface class NarrationRepository {
  /// Resolve [narrationKey] to display text; a stable fallback if the key is unknown.
  Future<String> resolve(String narrationKey);
}

/// An in-memory table of `narrationKey -> text`. The composition root builds one from a bundled
/// `assets/narration/<locale>.json`; tests build one from an inline map. Deterministic and
/// I/O-free, so it is unit-testable without a widget harness.
final class InMemoryNarrationRepository implements NarrationRepository {
  const InMemoryNarrationRepository(
    this._table, {
    this.fallback = _defaultFallback,
  });

  final Map<String, String> _table;

  /// Rendered when a key is absent — visibly authored, so a content gap reads as a gap rather
  /// than leaking a raw key or blanking the beat. `{key}` is substituted for the missing key.
  final String fallback;

  static const String _defaultFallback =
      '(the world stirs, but the words are lost)';

  @override
  Future<String> resolve(String narrationKey) async =>
      _table[narrationKey] ?? fallback.replaceAll('{key}', narrationKey);
}
