/// WorldState + applyDelta (ADR-0001) — the mutable per-beat runtime counterpart to the
/// frozen [SceneModel]. Pure Dart, zero Flutter imports.
///
/// Placed in the resolver layer (not `lib/game/state_delta.dart`) exactly as that file's
/// header notes: bundling the frozen `SceneModel` with mutable state — the pairing ADR-0006
/// calls "WorldState (frozen SceneModel + mutable state)" — keeps the `StateDelta` *data
/// class* dependency-free and avoids the ADR-0001↔0003 type cycle (review finding, ADR-0001).
library;

import '../game/ontology.dart';
import '../game/state_delta.dart';
import '../scene/scene_model.dart';

/// All mutable runtime state for an in-progress adventure, bundled with the frozen active
/// scene it is being played against. An immutable value object: [applyDelta] returns a NEW
/// `WorldState`; nothing mutates in place. Every collection is stored as an unmodifiable
/// view so a previous beat's state can never be mutated — load-bearing for the determinism
/// property test (review finding N3).
final class WorldState {
  WorldState._({
    required this.scene,
    required this.currentNodeId,
    required Map<String, int> meters,
    required Set<FacetKey> facets,
    required Set<FacetKey> revealedFacets,
    required Map<String, Map<String, PropValue>> entityProps,
    required Map<String, int> beatCursors,
  }) : meters = Map.unmodifiable(meters),
       facets = Set.unmodifiable(facets),
       revealedFacets = Set.unmodifiable(revealedFacets),
       entityProps = Map.unmodifiable({
         for (final e in entityProps.entries) e.key: Map.unmodifiable(e.value),
       }),
       beatCursors = Map.unmodifiable(beatCursors);

  /// The initial state for [scene]: meters seeded from their declared `initial`, no facets
  /// set or revealed, no entity-prop overrides, no beat cursors.
  factory WorldState.initial(SceneModel scene) => WorldState._(
    scene: scene,
    currentNodeId: scene.id,
    meters: {for (final e in scene.localMeters.entries) e.key: e.value.initial},
    facets: const {},
    revealedFacets: const {},
    entityProps: const {},
    beatCursors: const {},
  );

  /// The frozen active scene node (the "frozen SceneModel" half of ADR-0006's pairing).
  final SceneModel scene;

  /// Which [scene] node is active. Equals `scene.id` for a single-node MVP scene; a
  /// [TransitionNode] op updates it (multi-node graph swaps land with the SceneGraph runtime).
  final String currentNodeId;

  /// Current meter values, clamped to each meter's `[min, max]` on write.
  final Map<String, int> meters;

  /// Facets currently true via [SetFacet].
  final Set<FacetKey> facets;

  /// Facets surfaced by discovery moves via [RevealFacet].
  final Set<FacetKey> revealedFacets;

  /// Per-entity property overrides vs the frozen scene.
  final Map<String, Map<String, PropValue>> entityProps;

  /// Per-beat state-machine positions (patrols/timers) — advanced by moves, NEVER a clock.
  final Map<String, int> beatCursors;

  /// True when [facet] is present for threshold evaluation. A facet counts as present once
  /// it is either set ([SetFacet]) or revealed ([RevealFacet]) — so a discovery move makes
  /// `WorldFacet(f)` / `IfFacet(f)` true, which is what collapses the magistrate's persuade
  /// path after `scandal` is discovered (scene-decomposition-spec §3).
  bool hasFacet(FacetKey facet) =>
      facets.contains(facet) || revealedFacets.contains(facet);

  /// An immutable, point-in-time capture for the feedback loop (ADR-0008).
  WorldStateSnapshot snapshot() => WorldStateSnapshot(this);

  /// Internal: build a successor state, defaulting each field to this one's value. Every
  /// collection passed here is re-wrapped unmodifiable by the private constructor.
  WorldState _copyWith({
    String? currentNodeId,
    Map<String, int>? meters,
    Set<FacetKey>? facets,
    Set<FacetKey>? revealedFacets,
    Map<String, Map<String, PropValue>>? entityProps,
    Map<String, int>? beatCursors,
  }) => WorldState._(
    scene: scene,
    currentNodeId: currentNodeId ?? this.currentNodeId,
    meters: meters ?? this.meters,
    facets: facets ?? this.facets,
    revealedFacets: revealedFacets ?? this.revealedFacets,
    entityProps: entityProps ?? this.entityProps,
    beatCursors: beatCursors ?? this.beatCursors,
  );
}

/// A serializable, read-only capture of [WorldState] at a beat (ADR-0008). A distinct type
/// — not a typedef — so a live `WorldState` can't be passed where a frozen snapshot is
/// required (review finding N8).
final class WorldStateSnapshot {
  const WorldStateSnapshot(this._state);
  final WorldState _state;

  /// The captured state; the snapshot itself is never mutated.
  WorldState get state => _state;
}

/// Pure application of [delta] to [state]: applies each op in order and returns a NEW
/// [WorldState] built from defensive copies. No I/O, no clocks, no randomness (ADR-0001).
///
/// Meter writes clamp to the active scene's declared `[min, max]`; the Linter (L-09) keeps
/// authored single-step deltas in range, and clamping keeps accumulated values valid too.
WorldState applyDelta(WorldState state, StateDelta delta) {
  var currentNodeId = state.currentNodeId;
  final meters = Map<String, int>.of(state.meters);
  final facets = Set<FacetKey>.of(state.facets);
  final revealedFacets = Set<FacetKey>.of(state.revealedFacets);
  final entityProps = {
    for (final e in state.entityProps.entries)
      e.key: Map<String, PropValue>.of(e.value),
  };

  for (final op in delta.ops) {
    switch (op) {
      case SetFacet(:final key, :final value):
        if (value) {
          facets.add(key);
        } else {
          facets.remove(key);
        }
      case AdjustMeter(:final meter, :final delta):
        final spec = state.scene.localMeters[meter];
        final next = (meters[meter] ?? spec?.initial ?? 0) + delta;
        meters[meter] = spec == null ? next : next.clamp(spec.min, spec.max);
      case SetEntityProp(:final entityId, :final prop, :final value):
        (entityProps[entityId] ??= <String, PropValue>{})[prop] = value;
      case TransitionNode(:final targetNodeId):
        currentNodeId = targetNodeId;
      case RevealFacet(:final key):
        revealedFacets.add(key);
      case Outcome():
        // Terminal marker only — carries no state mutation; the Resolver reads it to
        // report the beat's outcome (ADR-0006 single-source-of-outcome-truth).
        break;
    }
  }

  return state._copyWith(
    currentNodeId: currentNodeId,
    meters: meters,
    facets: facets,
    revealedFacets: revealedFacets,
    entityProps: entityProps,
  );
}
