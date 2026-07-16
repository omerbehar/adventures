/// Router-cascade DI seam (ADR-0009 / ADR-0007, review finding N5). The UI layer and tests
/// depend on this interface — never on a concrete cascade — so a fake can be injected in a
/// `ProviderScope`/widget test. Pure Dart, zero Flutter imports.
library;

import '../../resolver/resolver.dart';
import '../../resolver/world_state.dart';

/// Turn freeform player text into a per-beat [ResolveResult] for the active [WorldState].
/// The production implementation is the tiered cascade (ADR-0007, Tier 0→3); the MVP ships a
/// local, offline implementation. Either way the UI only ever sees a validated result.
// ignore: one_member_abstracts
abstract interface class RouterCascadeInterface {
  /// Resolve one beat for [playerText] against [state]. Async so Tier 2/3 escalation fits the
  /// same signature; the local MVP implementation completes synchronously-fast.
  Future<ResolveResult> route(String playerText, WorldState state);
}
