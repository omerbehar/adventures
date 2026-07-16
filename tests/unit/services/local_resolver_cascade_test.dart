// local_resolver_cascade_test — the offline cascade wires keyword-classify → Stage B → the
// Resolver into a playable beat. Pure-Dart, no I/O.
library;

import 'package:adventures/game/state_delta.dart';
import 'package:adventures/game/translator/magnitude_tables.dart';
import 'package:adventures/resolver/resolver.dart';
import 'package:adventures/resolver/world_state.dart';
import 'package:adventures/services/local_resolver_cascade.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/magistrate_fixture.dart';

void main() {
  LocalResolverCascade cascade() => LocalResolverCascade(
    tables: MagnitudeTables.defaults(),
    classId: 'default',
  );

  test('test_cascade_threaten_wins_via_intimidation', () async {
    final state = WorldState.initial(magistrateScene());
    final result = await cascade().route('threaten the magistrate', state);
    expect((result as Resolved).matchedPathId, 'intimidate');
    expect(result.outcome, OutcomeResult.win);
  });

  test('test_cascade_examine_discovers_scandal_then_expose_wins', () async {
    final cas = cascade();
    // Beat 1: examine → insight discovery reveals scandal (non-terminal).
    final beat1 =
        await cas.route(
              'examine the magistrate',
              WorldState.initial(magistrateScene()),
            )
            as Resolved;
    expect(beat1.matchedPathId, 'discover');
    expect(beat1.outcome, OutcomeResult.advance);
    expect(beat1.nextState.hasFacet('scandal'), isTrue);

    // Beat 2: expose → invokes scandal + persuasion, collapses to a win.
    final beat2 = await cas.route('expose his corruption', beat1.nextState);
    expect((beat2 as Resolved).matchedPathId, 'persuade');
    expect(beat2.outcome, OutcomeResult.win);
  });

  test('test_cascade_unmatched_text_is_no_match', () async {
    final result = await cascade().route(
      'hum a quiet tune',
      WorldState.initial(magistrateScene()),
    );
    expect(result, isA<NoMatch>());
  });

  test('test_cascade_is_deterministic', () async {
    final state = WorldState.initial(magistrateScene());
    final a = await cascade().route('persuade him passionately', state);
    for (var i = 0; i < 50; i++) {
      final b = await cascade().route('persuade him passionately', state);
      expect((b as Resolved).matchedPathId, (a as Resolved).matchedPathId);
      expect(b.outcome, a.outcome);
    }
  });
}
