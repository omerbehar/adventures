/// The blank line (ADR-0009 Decision Point 5 / Pillar 1) — the always-available freeform text
/// input. Never modal-locked out; submits trimmed, non-empty text. Styling is a placeholder
/// pending the art bible; no game logic lives here.
library;

import 'package:flutter/material.dart';

/// A single-line text field that forwards submitted intent to [onSubmit]. The parent owns the
/// [controller] (so it can clear the line after a beat) and toggles [enabled] while a beat
/// resolves. Wrap in a `RepaintBoundary` at the call site so keystrokes don't repaint the
/// narration view.
class BlankLineField extends StatelessWidget {
  const BlankLineField({
    super.key,
    required this.controller,
    required this.onSubmit,
    this.enabled = true,
    this.autofocus = true,
  });

  /// Owned by the parent; cleared after each submitted beat.
  final TextEditingController controller;

  /// Called with trimmed, non-empty text when the player submits the line.
  final ValueChanged<String> onSubmit;

  /// False while a beat is resolving, so the player can't submit twice.
  final bool enabled;

  /// Autofocus on desktop/web; the composition root disables it for first-launch mobile.
  final bool autofocus;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    enabled: enabled,
    autofocus: autofocus,
    textInputAction: TextInputAction.send,
    decoration: const InputDecoration(
      hintText: 'What do you do?',
      border: OutlineInputBorder(),
    ),
    onSubmitted: (text) {
      final trimmed = text.trim();
      if (trimmed.isNotEmpty) onSubmit(trimmed);
    },
  );
}
