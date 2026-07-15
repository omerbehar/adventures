// adventure_screen_test — the MVP bare UI resolves a submitted line end-to-end (blank line →
// cascade → Resolver → authored narration). Widget test: the whole stack, injected fakes only.

import 'package:adventures/game/translator/magnitude_tables.dart';
import 'package:adventures/resolver/world_state.dart';
import 'package:adventures/screens/adventure_screen.dart';
import 'package:adventures/services/local_resolver_cascade.dart';
import 'package:adventures/services/narration_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/magistrate_fixture.dart';

Widget harness() => MaterialApp(
  home: AdventureScreen(
    cascade: LocalResolverCascade(
      tables: MagnitudeTables.defaults(),
      classId: 'default',
    ),
    narration: const InMemoryNarrationRepository(magistrateNarration),
    initialState: WorldState.initial(magistrateScene()),
    // Autofocus off so the test doesn't fight the soft-keyboard focus in the harness.
    autofocus: false,
  ),
);

Future<void> submit(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.testTextInput.receiveAction(TextInputAction.send);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('test_ui_threaten_resolves_to_win_narration', (tester) async {
    await tester.pumpWidget(harness());
    await submit(tester, 'threaten the magistrate');

    // The player's line is echoed, and the authored win narration is rendered.
    expect(find.textContaining('threaten the magistrate'), findsOneWidget);
    expect(find.textContaining('Vorne flinches and signs'), findsOneWidget);
    expect(find.text('▸ You won.'), findsOneWidget);
    // A terminal outcome ends the encounter: the blank line is gone.
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('test_ui_examine_then_expose_wins_via_collapse', (tester) async {
    await tester.pumpWidget(harness());

    await submit(tester, 'examine the magistrate');
    expect(find.textContaining('would rather stayed buried'), findsOneWidget);
    // Discovery is non-terminal: the blank line is still there.
    expect(find.byType(TextField), findsOneWidget);

    await submit(tester, 'expose his corruption');
    expect(find.textContaining('signs the release'), findsOneWidget);
    expect(find.text('▸ You won.'), findsOneWidget);
  });

  testWidgets('test_ui_unmatched_intent_shows_no_match_narration', (
    tester,
  ) async {
    await tester.pumpWidget(harness());
    await submit(tester, 'hum a quiet tune');
    expect(find.textContaining('Nothing you did lands'), findsOneWidget);
    // Non-terminal: still playable.
    expect(find.byType(TextField), findsOneWidget);
  });
}
