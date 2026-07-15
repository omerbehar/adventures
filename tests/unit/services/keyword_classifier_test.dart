// keyword_classifier_test — the offline Tier-0 placeholder classifier (ADR-0007) names axes
// and facets deterministically. Pure-Dart, no I/O.
library;

import 'package:adventures/game/ontology.dart';
import 'package:adventures/game/translator/classification.dart';
import 'package:adventures/services/keyword_classifier.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/magistrate_fixture.dart';

CapabilityAxisKey ax(String s) => CapabilityAxis.parse(s).key!;

void main() {
  final classifier = KeywordClassifier.defaults();
  final scene = magistrateScene();

  test('test_keyword_classifier_names_insight_for_examine_verbs', () {
    final c = classifier.classify('examine the magistrate closely', scene);
    expect(c.axisOrdinals[ax('insight')], CoarseOrdinal.major);
    expect(c.target, 'vorne');
  });

  test('test_keyword_classifier_invokes_declared_scandal_facet', () {
    final c = classifier.classify('expose his corruption', scene);
    expect(c.facetsInvoked, contains('scandal'));
    expect(c.axisOrdinals[ax('social.persuasion')], CoarseOrdinal.moderate);
  });

  test('test_keyword_classifier_names_intimidation_for_threats', () {
    final c = classifier.classify('threaten him with the guards', scene);
    expect(c.axisOrdinals[ax('social.intimidation')], CoarseOrdinal.major);
  });

  test('test_keyword_classifier_takes_strongest_ordinal_per_axis', () {
    // "persuade" (major) and "expose" (moderate) both name persuasion → major wins.
    final c = classifier.classify(
      'persuade him by exposing the scandal',
      scene,
    );
    expect(c.axisOrdinals[ax('social.persuasion')], CoarseOrdinal.major);
    expect(c.facetsInvoked, contains('scandal'));
  });

  test('test_keyword_classifier_drops_facets_the_scene_does_not_declare', () {
    // A scene with no declared facets must not carry the scandal facet through.
    final bare = magistrateScene();
    final c = KeywordClassifier([
      KeywordRule(
        keywords: const ['ghost'],
        axis: ax('insight'),
        ordinal: CoarseOrdinal.minor,
        facets: const ['phantom'],
      ),
    ]).classify('ghost', bare);
    expect(c.facetsInvoked, isEmpty);
  });

  test('test_keyword_classifier_returns_empty_for_unmatched_text', () {
    final c = classifier.classify('hum a quiet tune', scene);
    expect(c.axisOrdinals, isEmpty);
    expect(c.facetsInvoked, isEmpty);
  });
}
