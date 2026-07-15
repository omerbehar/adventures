/// Scene Model schema (ADR-0003, Revision 2) — the frozen, JSON-serializable model of
/// possibility a scene is dismantled into. Pure Dart, zero Flutter imports.
/// See docs/architecture/scene-decomposition-spec.md for the full contract.
library;

import '../game/ontology.dart';
import '../game/state_delta.dart';

/// Scalar world-state meter bounds.
final class MeterSpec {
  const MeterSpec({required this.min, required this.max, required this.initial});
  final int min, max, initial;

  factory MeterSpec.fromJson(Map<String, Object?> j) =>
      MeterSpec(min: j['min'] as int, max: j['max'] as int, initial: j['initial'] as int);
}

/// An authored entity with typed properties. `PropValue`, never `Object` (finding N4).
final class Entity {
  const Entity({required this.id, required this.type, required this.props});
  final String id;
  final String type;
  final Map<String, PropValue> props;

  factory Entity.fromJson(Map<String, Object?> j) => Entity(
        id: j['id'] as String,
        type: j['type'] as String,
        props: {
          for (final e in ((j['props'] as Map?) ?? const {}).entries)
            e.key as String: PropValue.fromJson((e.value as Map).cast()),
        },
      );
}

enum PathKind { progress, discovery }

/// A `sealed` conditional-threshold tree evaluated to bool against the CapabilityVector
/// (ADR-0004) + WorldState.facets (ADR-0001). Seven variants as of ADR-0003 R2. The
/// decisive move (Pillar 3) keys the collapse on [Invokes] — the reliably-classified
/// leverage signal — not a specific axis magnitude.
sealed class ThresholdExpr {
  const ThresholdExpr();

  factory ThresholdExpr.fromJson(Object? node) {
    if (node is! Map) throw SceneParseException('ThresholdExpr must be an object: $node');
    final json = node.cast<String, Object?>();
    final entry = json.entries.single;
    final v = entry.value;
    switch (entry.key) {
      case 'AxisAtLeast':
        final a = v! as List;
        return AxisAtLeast(CapabilityAxis.parse(a[0] as String), a[1] as int);
      case 'IfFacet':
        final a = v! as List;
        return IfFacet(a[0] as String, ThresholdExpr.fromJson(a[1]), ThresholdExpr.fromJson(a[2]));
      case 'WorldFacet':
        return WorldFacet(v! as String);
      case 'Invokes':
        return Invokes(v! as String);
      case 'AllOf':
        return AllOf([for (final c in (v! as List)) ThresholdExpr.fromJson(c)]);
      case 'AnyOf':
        return AnyOf([for (final c in (v! as List)) ThresholdExpr.fromJson(c)]);
      case 'Not':
        return Not(ThresholdExpr.fromJson(v));
      default:
        throw SceneParseException('Unknown ThresholdExpr tag "${entry.key}"');
    }
  }
}

final class AxisAtLeast extends ThresholdExpr {
  const AxisAtLeast(this.axis, this.magnitude);
  final CapabilityAxis axis;
  final int magnitude;
}

final class IfFacet extends ThresholdExpr {
  const IfFacet(this.facet, this.thenExpr, this.elseExpr);
  final FacetKey facet;
  final ThresholdExpr thenExpr, elseExpr;
}

final class WorldFacet extends ThresholdExpr {
  const WorldFacet(this.facet);
  final FacetKey facet;
}

final class Invokes extends ThresholdExpr {
  const Invokes(this.facet);
  final FacetKey facet;
}

final class AllOf extends ThresholdExpr {
  const AllOf(this.parts);
  final List<ThresholdExpr> parts;
}

final class AnyOf extends ThresholdExpr {
  const AnyOf(this.parts);
  final List<ThresholdExpr> parts;
}

final class Not extends ThresholdExpr {
  const Not(this.part);
  final ThresholdExpr part;
}

/// A solution path: a conditional requirement over the Ontology, a target, an effect
/// StateDelta, and its kind. `priority` establishes the authored total order (ADR-0006);
/// `difficulty` is an optional authoring hint checked against grounding bands (L-04).
final class SolutionPath {
  const SolutionPath({
    required this.id,
    required this.requirement,
    required this.target,
    required this.effect,
    required this.kind,
    required this.priority,
    this.difficulty,
  });
  final String id;
  final ThresholdExpr requirement;
  final String target;
  final StateDelta effect;
  final PathKind kind;
  final int priority;
  final Difficulty? difficulty;

  factory SolutionPath.fromJson(Map<String, Object?> j) => SolutionPath(
        id: j['id'] as String,
        requirement: ThresholdExpr.fromJson(j['requirement']),
        target: j['target'] as String,
        effect: StateDelta.fromJson((j['effect'] as Map).cast()),
        kind: PathKind.values.byName(j['kind'] as String),
        priority: j['priority'] as int,
        difficulty:
            j['difficulty'] == null ? null : Difficulty.values.byName(j['difficulty'] as String),
      );
}

/// Meter-watcher: fires an authored StateDelta when a meter crosses.
final class ReactiveThreshold {
  const ReactiveThreshold(
      {required this.id, required this.meter, required this.atLeast, required this.effect});
  final String id;
  final String meter;
  final int atLeast;
  final StateDelta effect;

  factory ReactiveThreshold.fromJson(Map<String, Object?> j) => ReactiveThreshold(
        id: j['id'] as String,
        meter: j['meter'] as String,
        atLeast: j['atLeast'] as int,
        effect: StateDelta.fromJson((j['effect'] as Map).cast()),
      );
}

/// Creator-declared envelope a Tier-3 fallback may not exceed (ADR-0003/0007).
final class FallbackBounds {
  const FallbackBounds({
    required this.touchableFacets,
    required this.touchableMeters,
    required this.maxMeterDelta,
    required this.allowOutcome,
  });
  final Set<FacetKey> touchableFacets;
  final Set<String> touchableMeters;
  final int maxMeterDelta;
  final bool allowOutcome;

  factory FallbackBounds.fromJson(Map<String, Object?> j) => FallbackBounds(
        touchableFacets: {...(j['touchableFacets'] as List? ?? const []).cast<String>()},
        touchableMeters: {...(j['touchableMeters'] as List? ?? const []).cast<String>()},
        maxMeterDelta: j['maxMeterDelta'] as int,
        allowOutcome: j['allowOutcome'] as bool,
      );
}

/// An encounter / node. Frozen after authoring.
final class SceneModel {
  const SceneModel({
    required this.id,
    required this.schemaVersion,
    required this.entities,
    required this.paths,
    required this.declaredFacets,
    required this.localMeters,
    required this.reactiveThresholds,
    required this.fallbackBounds,
    required this.narrationKeys,
  });
  final String id;
  final int schemaVersion;
  final List<Entity> entities;
  final List<SolutionPath> paths;
  final Set<FacetKey> declaredFacets;
  final Map<String, MeterSpec> localMeters;
  final List<ReactiveThreshold> reactiveThresholds;
  final FallbackBounds fallbackBounds;
  final Set<String> narrationKeys;

  factory SceneModel.fromJson(Map<String, Object?> j) => SceneModel(
        id: j['id'] as String,
        schemaVersion: j['schemaVersion'] as int? ?? 1,
        entities: [for (final e in (j['entities'] as List? ?? const [])) Entity.fromJson((e as Map).cast())],
        paths: [for (final p in (j['paths'] as List? ?? const [])) SolutionPath.fromJson((p as Map).cast())],
        declaredFacets: {...(j['declaredFacets'] as List? ?? const []).cast<String>()},
        localMeters: {
          for (final e in ((j['localMeters'] as Map?) ?? const {}).entries)
            e.key as String: MeterSpec.fromJson((e.value as Map).cast()),
        },
        reactiveThresholds: [
          for (final r in (j['reactiveThresholds'] as List? ?? const []))
            ReactiveThreshold.fromJson((r as Map).cast())
        ],
        fallbackBounds: FallbackBounds.fromJson((j['fallbackBounds'] as Map).cast()),
        narrationKeys: {...(j['narrationKeys'] as List? ?? const []).cast<String>()},
      );
}
