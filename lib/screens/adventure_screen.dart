/// The MVP "bare text UI" (ADR-0009): the blank line + narration log wired to the router
/// cascade via `setState`. Riverpod/go_router are deferred until technical-director sign-off
/// (ADR-0009 build-order step 3); the layering and DI seams already hold, so swapping the
/// state adapter later touches only this file.
///
/// This is the UI layer: it renders `ResolveResult` and forwards input. It never advances
/// world state itself — the Resolver (behind [RouterCascadeInterface]) owns every beat.
library;

import 'package:flutter/material.dart';

import '../game/state_delta.dart';
import '../resolver/resolver.dart';
import '../resolver/world_state.dart';
import '../services/narration_repository.dart';
import '../services/router/router_cascade_interface.dart';
import '../ui/blank_line_field.dart';
import '../ui/narration_view.dart';

/// One playable encounter. Everything it needs is injected (DI over singletons): the [cascade]
/// that resolves a beat, the [narration] that turns keys into text, and the [initialState].
class AdventureScreen extends StatefulWidget {
  const AdventureScreen({
    super.key,
    required this.cascade,
    required this.narration,
    required this.initialState,
    this.intro,
    this.autofocus = true,
  });

  final RouterCascadeInterface cascade;
  final NarrationRepository narration;
  final WorldState initialState;

  /// Optional opening line shown before the first beat.
  final String? intro;

  /// Forwarded to the blank line; disable for first-launch mobile.
  final bool autofocus;

  @override
  State<AdventureScreen> createState() => _AdventureScreenState();
}

class _AdventureScreenState extends State<AdventureScreen> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final List<NarrationEntry> _entries = [];

  late WorldState _state;
  bool _busy = false;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _state = widget.initialState;
    final intro = widget.intro;
    if (intro != null) _entries.add(NarrationEntry(NarrationKind.intro, intro));
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _submit(String text) async {
    if (_busy || _finished) return;
    setState(() {
      _busy = true;
      _entries.add(NarrationEntry(NarrationKind.player, '› $text'));
      _input.clear();
    });
    _scrollToEnd();

    final result = await widget.cascade.route(text, _state);
    final additions = <NarrationEntry>[];
    switch (result) {
      case Resolved(:final nextState, :final firedDeltas, :final outcome):
        _state = nextState;
        for (final delta in firedDeltas) {
          final key = delta.narrationKey;
          if (key != null) {
            additions.add(
              NarrationEntry(
                NarrationKind.narration,
                await widget.narration.resolve(key),
              ),
            );
          }
        }
        final banner = _outcomeBanner(outcome);
        if (banner != null) {
          additions.add(NarrationEntry(NarrationKind.outcome, banner));
        }
      case NoMatch():
        additions.add(
          NarrationEntry(
            NarrationKind.narration,
            await widget.narration.resolve('_noMatch'),
          ),
        );
    }

    if (!mounted) return;
    setState(() {
      _entries.addAll(additions);
      _busy = false;
    });
    _scrollToEnd();
  }

  /// A terminal-outcome banner, or null for the non-terminal `advance`.
  String? _outcomeBanner(OutcomeResult outcome) {
    switch (outcome) {
      case OutcomeResult.advance:
        return null;
      case OutcomeResult.win:
        _finished = true;
        return '▸ You won.';
      case OutcomeResult.lose:
        _finished = true;
        return '▸ You lost.';
      case OutcomeResult.escape:
        _finished = true;
        return '▸ You escaped.';
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    // Pillar 1: the soft keyboard shrinks the body, never occluding the blank line.
    resizeToAvoidBottomInset: true,
    appBar: AppBar(title: const Text('Adventures')),
    body: SafeArea(
      child: Column(
        children: [
          Expanded(
            child: NarrationView(entries: _entries, scrollController: _scroll),
          ),
          if (_busy) const LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.all(12),
            child: _finished
                ? Text(
                    'The encounter is over.',
                    style: Theme.of(context).textTheme.titleMedium,
                  )
                : RepaintBoundary(
                    child: BlankLineField(
                      controller: _input,
                      onSubmit: _submit,
                      enabled: !_busy,
                      autofocus: widget.autofocus,
                    ),
                  ),
          ),
        ],
      ),
    ),
  );
}
