/// The narration history (ADR-0009 Decision Point 8) — a lazily-built, scrollable log of the
/// beats so far. Renders only resolved, authored text (never a raw `narrationKey`). No game
/// logic; styling is a placeholder pending the art bible.
library;

import 'package:flutter/material.dart';

/// What a log line represents, so the view can style each kind distinctly.
enum NarrationKind { intro, player, narration, outcome }

/// One rendered log line: its [kind] and already-resolved display [text].
class NarrationEntry {
  const NarrationEntry(this.kind, this.text);
  final NarrationKind kind;
  final String text;
}

/// A lazy `ListView.builder` of [entries]. The parent owns [scrollController] so it can scroll
/// to the newest line after each beat.
class NarrationView extends StatelessWidget {
  const NarrationView({
    super.key,
    required this.entries,
    required this.scrollController,
  });

  final List<NarrationEntry> entries;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) => ListView.builder(
    controller: scrollController,
    padding: const EdgeInsets.all(16),
    itemCount: entries.length,
    itemBuilder: (context, index) {
      final entry = entries[index];
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(
          entry.text,
          style: _styleFor(entry.kind, Theme.of(context)),
        ),
      );
    },
  );

  TextStyle? _styleFor(NarrationKind kind, ThemeData theme) {
    final base = theme.textTheme.bodyLarge;
    return switch (kind) {
      NarrationKind.player => base?.copyWith(
        fontStyle: FontStyle.italic,
        color: theme.colorScheme.primary,
      ),
      NarrationKind.outcome => base?.copyWith(fontWeight: FontWeight.bold),
      NarrationKind.intro => base?.copyWith(color: theme.hintColor),
      NarrationKind.narration => base,
    };
  }
}
