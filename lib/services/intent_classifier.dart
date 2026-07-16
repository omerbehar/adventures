/// Stage A seam (ADR-0004) — the service-side classifier interface. The live implementation
/// (a structured-output LLM call with schema validation + repair/reject, plus the Tier 2/3
/// routing of ADR-0007) is the network layer's concern and lands separately; this file
/// defines only the boundary so Stage B and the Resolver can be tested against a fake.
library;

import '../game/ontology.dart';
import '../game/translator/classification.dart';

/// Scene + class context handed to the classifier so it can name axes/facets in-vocabulary.
final class ClassifyContext {
  const ClassifyContext({
    required this.sceneId,
    required this.classId,
    this.availableFacets = const {},
  });

  /// The active scene node id.
  final String sceneId;

  /// The active specialist class (Pillar 5) — colors Stage B scoring downstream.
  final String classId;

  /// Facets the classifier may legitimately tag for this scene (its declared facet vocabulary).
  final Set<FacetKey> availableFacets;
}

/// Stage A: turn freeform player text into a structured [Classification]. Evaluative and
/// service-side; injected behind this interface so tests use a fake returning canned results,
/// never the live model. Implementations MUST reject/repair off-schema output before returning
/// (a returned [Classification] is already schema-valid — [TranslatorException] on failure).
// ignore: one_member_abstracts
abstract interface class IntentClassifier {
  /// Classify [text] in [ctx]. Off-schema model output must be repaired or rejected, never
  /// surfaced raw.
  Future<Classification> classify(String text, ClassifyContext ctx);
}
