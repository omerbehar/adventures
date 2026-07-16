/// Stage A output (ADR-0004) — what the classifier is *allowed* to emit: which axes an
/// action invokes (each with a coarse ordinal, never a number), its target, the tactics it
/// used, and the facets it invokes. Pure Dart, zero Flutter imports.
///
/// Deterministic scoring (Stage B, `MagnitudeTables`) turns this into a `CapabilityVector`;
/// the LLM never sees or emits the final magnitude — the "classify, don't score" discipline
/// that keeps the same argument scored the same run-to-run (the prototype kill-criterion).
library;

import '../ontology.dart';

/// The coarse, stable strength band the classifier names per axis — never a magnitude.
enum CoarseOrdinal { none, minor, moderate, major, extreme }

/// Thrown when a classifier response is off-schema (e.g. a non-canonical axis). Stage A must
/// repair or reject such output; it is never passed downstream to Stage B / the Resolver.
class TranslatorException implements Exception {
  TranslatorException(this.message);
  final String message;
  @override
  String toString() => 'TranslatorException: $message';
}

/// The structured classification the Translator's Stage A produces and Stage B consumes.
final class Classification {
  const Classification({
    required this.axisOrdinals,
    required this.target,
    required this.tactics,
    required this.facetsInvoked,
  });

  /// Coarse ordinal per invoked axis, keyed on the record [CapabilityAxisKey] for
  /// value-equality (ADR-0002).
  final Map<CapabilityAxisKey, CoarseOrdinal> axisOrdinals;

  /// The entity the action targets, or `'self'`.
  final String target;

  /// Free-form tactic tags (advisory; not scored).
  final List<String> tactics;

  /// Facets the action invokes — the stable decisive-move signal, passed through Stage B to
  /// the `CapabilityVector` verbatim (ADR-0003 R2 / scene-decomposition-spec §7).
  final List<FacetKey> facetsInvoked;

  /// Parse the classifier's structured output:
  /// `{"axes":[{"axis":"social.persuasion","ordinal":"major"}], "target":"vorne",
  ///   "tactics":["cite-law"], "facetsInvoked":["scandal"]}`.
  ///
  /// A non-canonical axis is off-schema and [TranslatorException] is thrown — Stage A's
  /// repair/reject boundary, so the Resolver never sees an unresolved axis (ADR-0004).
  factory Classification.fromJson(Map<String, Object?> json) {
    final axisOrdinals = <CapabilityAxisKey, CoarseOrdinal>{};
    for (final raw in (json['axes'] as List? ?? const [])) {
      final m = (raw as Map).cast<String, Object?>();
      final axis = CapabilityAxis.parse(m['axis'] as String);
      final key = axis.key;
      if (key == null || !axis.isCanonical) {
        throw TranslatorException(
          'non-canonical axis "${m['axis']}" in classifier output',
        );
      }
      axisOrdinals[key] = CoarseOrdinal.values.byName(m['ordinal'] as String);
    }
    return Classification(
      axisOrdinals: axisOrdinals,
      target: json['target'] as String? ?? 'self',
      tactics: [...(json['tactics'] as List? ?? const []).cast<String>()],
      facetsInvoked: [
        ...(json['facetsInvoked'] as List? ?? const []).cast<String>(),
      ],
    );
  }
}
