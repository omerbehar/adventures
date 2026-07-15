/// Stage B (ADR-0004) — the deterministic, versioned, class-colored scoring tables that turn
/// a [Classification] into a `CapabilityVector`. Pure Dart, zero Flutter imports, no LLM, no
/// I/O: the same `(Classification, classId, SceneModifiers)` always yields the same vector.
///
/// This is the balancing surface. The `.defaults()` set below is illustrative (tune during
/// balancing); [MagnitudeTables.fromJson] is the seam for promoting the tuned data to a
/// versioned `assets/translator/tables.vN.json` artifact without any code change.
library;

import '../capability_vector.dart';
import '../ontology.dart';
import 'classification.dart';

/// `(class, axis, ordinal) -> base magnitude` for one class.
typedef ClassTable = Map<CapabilityAxisKey, Map<CoarseOrdinal, int>>;

/// Per-scene additive magnitude adjustments applied in Stage B (e.g. a scene where force is
/// easier). Deterministic; empty by default.
final class SceneModifiers {
  const SceneModifiers(this.axisDeltas);
  final Map<CapabilityAxisKey, int> axisDeltas;

  /// The additive modifier for [axis], or `0` if unmodified.
  int forAxis(CapabilityAxisKey axis) => axisDeltas[axis] ?? 0;

  /// No scene modifiers.
  static const SceneModifiers none = SceneModifiers({});
}

/// Versioned, class-colored magnitude tables. `default` is the fallback class; a specialist
/// class overrides only the axes it colors and inherits the rest (Pillar 5).
final class MagnitudeTables {
  const MagnitudeTables({
    required this.version,
    required this.classes,
    this.ontology = const Ontology(),
  });

  final String version;

  /// `class id -> (axis -> ordinal -> base magnitude)`. `default` is the fallback class.
  final Map<String, ClassTable> classes;

  /// Owns the canonical magnitude scale magnitudes are clamped to (ADR-0002).
  final Ontology ontology;

  /// The class-colored fallback class id, tried when a specialist class does not color an axis.
  static const String defaultClassId = 'default';

  /// Score [c] under [classId] with optional per-scene [mods] → the `CapabilityVector` the
  /// Resolver consumes. Magnitudes are class-colored table lookups plus scene modifiers,
  /// clamped to the ontology scale; `invokedFacets`/`target` pass through from Stage A.
  CapabilityVector score(
    Classification c,
    String classId, {
    SceneModifiers mods = SceneModifiers.none,
  }) {
    final magnitudes = <CapabilityAxisKey, int>{};
    for (final entry in c.axisOrdinals.entries) {
      final base = _base(classId, entry.key, entry.value);
      magnitudes[entry.key] = (base + mods.forAxis(entry.key)).clamp(
        ontology.magnitudeMin,
        ontology.magnitudeMax,
      );
    }
    return CapabilityVector(
      magnitudes: magnitudes,
      invokedFacets: {...c.facetsInvoked},
      target: c.target,
      classId: classId,
    );
  }

  /// The base magnitude for `(classId, axis, ordinal)`: the specialist class's own value,
  /// else the `default` class's, else `0` (an axis no table colors contributes nothing).
  int _base(String classId, CapabilityAxisKey axis, CoarseOrdinal ordinal) {
    final row = classes[classId]?[axis] ?? classes[defaultClassId]?[axis];
    return row?[ordinal] ?? 0;
  }

  /// Parse a versioned tables artifact:
  /// `{"version":"v1","classes":{"default":{"force":{"none":0,"minor":10,...}},...}}`.
  /// A non-canonical axis key is rejected ([TranslatorException]).
  factory MagnitudeTables.fromJson(Map<String, Object?> json) {
    final classes = <String, ClassTable>{};
    for (final ce in ((json['classes'] as Map?) ?? const {}).entries) {
      final table = <CapabilityAxisKey, Map<CoarseOrdinal, int>>{};
      for (final ae in (ce.value as Map).entries) {
        final axis = CapabilityAxis.parse(ae.key as String);
        final key = axis.key;
        if (key == null || !axis.isCanonical) {
          throw TranslatorException(
            'non-canonical axis "${ae.key}" in magnitude tables',
          );
        }
        table[key] = {
          for (final oe in (ae.value as Map).entries)
            CoarseOrdinal.values.byName(oe.key as String): (oe.value as num)
                .toInt(),
        };
      }
      classes[ce.key as String] = table;
    }
    return MagnitudeTables(
      version: json['version'] as String? ?? 'v0',
      classes: classes,
    );
  }

  /// A minimal, illustrative default table (tune during balancing). `default` covers the MVP
  /// axes; `diplomat` colors the social/talk axes up and intimidation down; `enforcer` does
  /// the inverse — so the same classification scores differently per specialist (Pillar 5).
  factory MagnitudeTables.defaults() {
    CapabilityAxisKey ax(String s) => CapabilityAxis.parse(s).key!;
    Map<CoarseOrdinal, int> band(
      int none,
      int minor,
      int moderate,
      int major,
      int extreme,
    ) => {
      CoarseOrdinal.none: none,
      CoarseOrdinal.minor: minor,
      CoarseOrdinal.moderate: moderate,
      CoarseOrdinal.major: major,
      CoarseOrdinal.extreme: extreme,
    };

    return MagnitudeTables(
      version: 'defaults-v0',
      classes: {
        'default': {
          ax('force'): band(0, 10, 22, 40, 60),
          ax('insight'): band(0, 12, 24, 38, 58),
          ax('mobility'): band(0, 10, 20, 36, 55),
          ax('stealth'): band(0, 11, 22, 38, 58),
          ax('social.persuasion'): band(0, 12, 24, 40, 62),
          ax('social.intimidation'): band(0, 12, 24, 40, 62),
          ax('social.rapport'): band(0, 12, 24, 40, 62),
          ax('social.deception'): band(0, 12, 24, 40, 62),
        },
        'diplomat': {
          ax('social.persuasion'): band(0, 16, 30, 48, 72),
          ax('social.rapport'): band(0, 16, 30, 48, 72),
          ax('social.intimidation'): band(0, 8, 16, 28, 45),
        },
        'enforcer': {
          ax('force'): band(0, 14, 30, 50, 72),
          ax('social.intimidation'): band(0, 16, 30, 48, 72),
          ax('social.persuasion'): band(0, 8, 16, 28, 45),
        },
      },
    );
  }
}
