// classification_test — Stage A output parsing (ADR-0004): the classifier's structured
// output deserializes to a Classification, and off-schema axes are rejected at the boundary.
// Pure-Dart, no I/O.
library;

import 'package:adventures/game/ontology.dart';
import 'package:adventures/game/translator/classification.dart';
import 'package:flutter_test/flutter_test.dart';

CapabilityAxisKey ax(String s) => CapabilityAxis.parse(s).key!;

void main() {
  group('Classification.fromJson', () {
    test('test_classification_parses_axes_target_and_facets', () {
      final c = Classification.fromJson(const {
        'axes': [
          {'axis': 'social.persuasion', 'ordinal': 'major'},
          {'axis': 'insight', 'ordinal': 'minor'},
        ],
        'target': 'vorne',
        'tactics': ['cite-law'],
        'facetsInvoked': ['scandal'],
      });
      expect(c.axisOrdinals[ax('social.persuasion')], CoarseOrdinal.major);
      expect(c.axisOrdinals[ax('insight')], CoarseOrdinal.minor);
      expect(c.target, 'vorne');
      expect(c.tactics, ['cite-law']);
      expect(c.facetsInvoked, ['scandal']);
    });

    test('test_classification_rejects_noncanonical_axis', () {
      // A social axis with no channel is not canonical → off-schema, must be rejected.
      expect(
        () => Classification.fromJson(const {
          'axes': [
            {'axis': 'social', 'ordinal': 'major'},
          ],
          'target': 'self',
        }),
        throwsA(isA<TranslatorException>()),
      );
    });

    test('test_classification_rejects_unknown_axis', () {
      expect(
        () => Classification.fromJson(const {
          'axes': [
            {'axis': 'telekinesis', 'ordinal': 'minor'},
          ],
          'target': 'self',
        }),
        throwsA(isA<TranslatorException>()),
      );
    });

    test('test_classification_defaults_missing_optional_fields', () {
      final c = Classification.fromJson(const {'axes': []});
      expect(c.target, 'self');
      expect(c.tactics, isEmpty);
      expect(c.facetsInvoked, isEmpty);
      expect(c.axisOrdinals, isEmpty);
    });
  });
}
