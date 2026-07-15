// narration_repository_test — key→text resolution with an authored fallback (ADR-0009 DP8).
// Pure-Dart, no I/O.
library;

import 'package:adventures/services/narration_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('test_narration_resolves_known_key', () async {
    const repo = InMemoryNarrationRepository({'acquit': 'You walk free.'});
    expect(await repo.resolve('acquit'), 'You walk free.');
  });

  test('test_narration_missing_key_returns_authored_fallback', () async {
    const repo = InMemoryNarrationRepository({});
    final text = await repo.resolve('ghost');
    expect(text, isNotEmpty);
    expect(
      text,
      isNot(contains('ghost')),
    ); // default fallback has no {key} slot
  });

  test('test_narration_custom_fallback_substitutes_key', () async {
    const repo = InMemoryNarrationRepository({}, fallback: 'missing:{key}');
    expect(await repo.resolve('nope'), 'missing:nope');
  });
}
