/// A deterministic, offline keyword classifier — a placeholder Tier-0 for the router cascade
/// (ADR-0007) so the MVP plays with no API key or network. Pure Dart, zero Flutter imports.
///
/// This is intentionally crude: it matches lowercase substrings to name axes/facets, exactly
/// the "classify, don't score" contract (ADR-0004) — Stage B still owns the magnitude. The
/// real Tier 0/1 (embeddings) and Tier 2/3 (LLM) classifiers replace this behind the same
/// `IntentClassifier`-shaped boundary; nothing downstream changes when they do.
library;

import '../game/ontology.dart';
import '../game/translator/classification.dart';
import '../scene/scene_model.dart';

/// One keyword→classification rule: any [keywords] substring present names [axis] at
/// [ordinal] and invokes [facets] (kept only if the active scene declares them).
final class KeywordRule {
  const KeywordRule({
    required this.keywords,
    required this.axis,
    required this.ordinal,
    this.facets = const [],
  });
  final List<String> keywords;
  final CapabilityAxisKey axis;
  final CoarseOrdinal ordinal;
  final List<FacetKey> facets;
}

/// Maps freeform text to a [Classification] by substring matching. Deterministic: the same
/// text + scene always yields the same classification.
final class KeywordClassifier {
  const KeywordClassifier(this.rules);
  final List<KeywordRule> rules;

  /// Classify [text] against [scene]. When several rules name the same axis, the strongest
  /// ordinal wins; invoked facets are unioned and filtered to the scene's declared facets.
  Classification classify(String text, SceneModel scene) {
    final lower = text.toLowerCase();
    final axisOrdinals = <CapabilityAxisKey, CoarseOrdinal>{};
    final facets = <FacetKey>{};
    for (final rule in rules) {
      if (!rule.keywords.any(lower.contains)) continue;
      final existing = axisOrdinals[rule.axis];
      if (existing == null || rule.ordinal.index > existing.index) {
        axisOrdinals[rule.axis] = rule.ordinal;
      }
      facets.addAll(rule.facets.where(scene.declaredFacets.contains));
    }
    return Classification(
      axisOrdinals: axisOrdinals,
      target: scene.entities.isNotEmpty ? scene.entities.first.id : 'self',
      tactics: const [],
      facetsInvoked: facets.toList(),
    );
  }

  /// A small, illustrative rule set covering the MVP's social/insight/force verbs. Tune or
  /// replace during balancing; the real classifiers supersede this entirely (ADR-0007).
  factory KeywordClassifier.defaults() {
    CapabilityAxisKey ax(String s) => CapabilityAxis.parse(s).key!;
    return KeywordClassifier([
      KeywordRule(
        keywords: const [
          'examine',
          'study',
          'inspect',
          'read',
          'look',
          'observe',
          'notice',
          'investigate',
          'search',
          'analyze',
          'analyse',
        ],
        axis: ax('insight'),
        ordinal: CoarseOrdinal.major,
      ),
      KeywordRule(
        keywords: const [
          'scandal',
          'corrupt',
          'corruption',
          'bribe',
          'expose',
          'blackmail',
          'reveal',
          'secret',
          'leverage',
          'dirt',
        ],
        axis: ax('social.persuasion'),
        ordinal: CoarseOrdinal.moderate,
        facets: const ['scandal'],
      ),
      KeywordRule(
        keywords: const [
          'persuade',
          'convince',
          'argue',
          'reason',
          'plead',
          'appeal',
          'negotiate',
          'flatter',
          'charm',
        ],
        axis: ax('social.persuasion'),
        ordinal: CoarseOrdinal.major,
      ),
      KeywordRule(
        keywords: const [
          'threaten',
          'intimidate',
          'scare',
          'menace',
          'coerce',
          'frighten',
          'bully',
          'loom',
        ],
        axis: ax('social.intimidation'),
        ordinal: CoarseOrdinal.major,
      ),
      KeywordRule(
        keywords: const ['force', 'smash', 'break', 'shove', 'strike', 'grab'],
        axis: ax('force'),
        ordinal: CoarseOrdinal.major,
      ),
    ]);
  }
}
