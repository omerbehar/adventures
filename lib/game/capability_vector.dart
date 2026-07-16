/// CapabilityVector (ADR-0004) — the deterministic, typed classification the Resolver
/// consumes for one beat. Pure Dart, zero Flutter imports.
///
/// This file carries only the Resolver-facing *result* type. Stage A (`IntentClassifier`,
/// service-side) and Stage B (`MagnitudeTables`, the versioned scoring tables) are the
/// Translator epic (ADR-0004) and land separately; the Resolver depends only on the vector
/// below, never on how it was produced.
library;

import 'ontology.dart';

/// The typed output of the Translator, consumed by the Resolver (ADR-0006).
///
/// `magnitudes` is keyed on the record [CapabilityAxisKey] so lookups use value-equality
/// (ADR-0002) — a plain-class key would miss on every lookup and silently break Resolver
/// determinism. `invokedFacets` is surfaced verbatim from Stage A: it is the *stable*
/// decisive-move signal (the classifier reliably names the invoked leverage even when it
/// disagrees on the axis), so `Invokes(facet)` thresholds read this set (ADR-0003 R2).
final class CapabilityVector {
  const CapabilityVector({
    required this.magnitudes,
    required this.invokedFacets,
    required this.target,
    required this.classId,
  });

  /// Per-axis integer magnitudes computed by Stage B — never by the LLM.
  final Map<CapabilityAxisKey, int> magnitudes;

  /// Facets the action invokes (Stage A `facetsInvoked`, passed through unmodified).
  final Set<FacetKey> invokedFacets;

  /// The entity this action targets, or `'self'`.
  final String target;

  /// The active specialist class (Pillar 5) — colors Stage B scoring upstream.
  final String classId;

  /// The magnitude on [axis], or `0` when the vector names no value for it. A
  /// non-canonical axis (`axis.key == null`) can never carry a magnitude, so returns 0.
  int magnitudeOf(CapabilityAxis axis) {
    final key = axis.key;
    if (key == null) return 0;
    return magnitudes[key] ?? 0;
  }
}
