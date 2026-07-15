/// The MVP's offline router cascade (ADR-0009 build-order step 2 / ADR-0007 Tier 0): classify
/// player text locally, score it through the deterministic magnitude tables, and resolve one
/// beat — all on-device, no network. Pure Dart, zero Flutter imports.
///
/// It satisfies [RouterCascadeInterface] so the real tiered cascade (with live Tier 2/3 LLM
/// escalation) can drop in later without any UI change.
library;

import '../game/translator/magnitude_tables.dart';
import '../resolver/resolver.dart';
import '../resolver/world_state.dart';
import 'keyword_classifier.dart';
import 'router/router_cascade_interface.dart';

/// A local, deterministic cascade: [KeywordClassifier] (Stage A placeholder) →
/// [MagnitudeTables] (Stage B) → [Resolver]. Same text + state always resolves the same way.
final class LocalResolverCascade implements RouterCascadeInterface {
  LocalResolverCascade({
    required this.tables,
    required this.classId,
    KeywordClassifier? classifier,
  }) : _classifier = classifier ?? KeywordClassifier.defaults();

  /// The Stage B scoring tables (class-colored).
  final MagnitudeTables tables;

  /// The active specialist class the scoring is colored by (Pillar 5).
  final String classId;

  final KeywordClassifier _classifier;
  final Resolver _resolver = const Resolver();

  @override
  Future<ResolveResult> route(String playerText, WorldState state) async {
    final classification = _classifier.classify(playerText, state.scene);
    final vector = tables.score(classification, classId);
    return _resolver.resolve(state, vector);
  }
}
