/// StateDelta primitive (subset needed for authoring/lint) — the typed, validated
/// state-change record every resolution path emits (ADR-0001). Pure Dart.
///
/// This file carries the ops and value types the Scene Model references. The full
/// runtime `applyDelta` / `WorldState` live alongside the Resolver (ADR-0006); the
/// authoring pipeline only needs to construct, parse, and inspect deltas.
library;

/// First-class, JSON-round-trippable value type (ADR-0001, review finding N4).
/// A `sealed` union — never `Object` — so type info survives a JSON round-trip.
sealed class PropValue {
  const PropValue();

  /// Parse `{"string": ...} | {"int": ...} | {"bool": ...} | {"double": ...}`.
  factory PropValue.fromJson(Map<String, Object?> json) {
    final entry = json.entries.single;
    return switch (entry.key) {
      'string' => PropString(entry.value! as String),
      'int' => PropInt(entry.value! as int),
      'bool' => PropBool(entry.value! as bool),
      'double' => PropDouble((entry.value! as num).toDouble()),
      _ => throw SceneParseException('Unknown PropValue tag "${entry.key}"'),
    };
  }
}

final class PropString extends PropValue {
  const PropString(this.value);
  final String value;
}

final class PropInt extends PropValue {
  const PropInt(this.value);
  final int value;
}

final class PropBool extends PropValue {
  const PropBool(this.value);
  final bool value;
}

final class PropDouble extends PropValue {
  const PropDouble(this.value);
  final double value;
}

/// Terminal-or-continue outcome. `advance` is non-terminal.
enum OutcomeResult { escape, win, lose, advance }

/// Exhaustive, typed set of state-change operations (ADR-0001).
sealed class StateDeltaOp {
  const StateDeltaOp();

  /// Parse one op from its single-key JSON form, e.g. `{"AdjustMeter": ["suspicion", 30]}`.
  factory StateDeltaOp.fromJson(Map<String, Object?> json) {
    final entry = json.entries.single;
    final v = entry.value;
    switch (entry.key) {
      case 'SetFacet':
        final a = v! as List;
        return SetFacet(a[0] as String, a[1] as bool);
      case 'AdjustMeter':
        final a = v! as List;
        return AdjustMeter(a[0] as String, a[1] as int);
      case 'SetEntityProp':
        final a = v! as List;
        return SetEntityProp(
            a[0] as String, a[1] as String, PropValue.fromJson((a[2] as Map).cast()));
      case 'TransitionNode':
        return TransitionNode(v! as String);
      case 'RevealFacet':
        return RevealFacet(v! as String);
      case 'Outcome':
        return Outcome(OutcomeResult.values.byName(v! as String));
      default:
        throw SceneParseException('Unknown StateDeltaOp tag "${entry.key}"');
    }
  }
}

final class SetFacet extends StateDeltaOp {
  const SetFacet(this.key, this.value);
  final String key;
  final bool value;
}

final class AdjustMeter extends StateDeltaOp {
  const AdjustMeter(this.meter, this.delta);
  final String meter;
  final int delta;
}

final class SetEntityProp extends StateDeltaOp {
  const SetEntityProp(this.entityId, this.prop, this.value);
  final String entityId;
  final String prop;
  final PropValue value;
}

final class TransitionNode extends StateDeltaOp {
  const TransitionNode(this.targetNodeId);
  final String targetNodeId;
}

/// Discovery move — surfaces a facet without progressing to an outcome.
final class RevealFacet extends StateDeltaOp {
  const RevealFacet(this.key);
  final String key;
}

final class Outcome extends StateDeltaOp {
  const Outcome(this.result);
  final OutcomeResult result;
}

/// An immutable, ordered list of ops plus an optional authored narration key.
/// Narration is referenced by key, never generated free text (Pillar 2).
final class StateDelta {
  const StateDelta(this.ops, {this.narrationKey});
  final List<StateDeltaOp> ops;
  final String? narrationKey;

  factory StateDelta.fromJson(Map<String, Object?> json) {
    final ops = (json['ops'] as List? ?? const [])
        .map((o) => StateDeltaOp.fromJson((o as Map).cast()))
        .toList(growable: false);
    return StateDelta(ops, narrationKey: json['narrationKey'] as String?);
  }
}

/// Thrown when scene JSON is structurally malformed (missing fields, unknown tags).
/// Semantic problems (undeclared facets, unbalanced thresholds) are reported by the
/// Linter as findings, not thrown.
class SceneParseException implements Exception {
  SceneParseException(this.message);
  final String message;
  @override
  String toString() => 'SceneParseException: $message';
}
