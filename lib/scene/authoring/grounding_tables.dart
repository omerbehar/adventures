/// Grounding tables (ADR-0005) — canonical bounds the Compiler must stay within and the
/// Linter's "expected band" reference. Pure Dart. See scene-decomposition-spec §4.
library;

import '../../game/ontology.dart';

/// Expected magnitude bands per (axis, difficulty). Inclusive `[lo, hi]`.
final class ThresholdNorms {
  const ThresholdNorms(this.bands);
  final Map<(CapabilityAxisKey, Difficulty), (int lo, int hi)> bands;

  /// The difficulty band a [magnitude] falls into for [axis], or null if the axis has no
  /// norms or the magnitude sits outside every band. Uses the first band that contains it.
  Difficulty? bandOf(CapabilityAxisKey axis, int magnitude) {
    for (final d in Difficulty.values) {
      final b = bands[(axis, d)];
      if (b != null && magnitude >= b.$1 && magnitude <= b.$2) return d;
    }
    return null;
  }

  /// True if [magnitude] is within [axis]'s [difficulty] band. Null band → not checkable.
  bool? inBand(CapabilityAxisKey axis, Difficulty difficulty, int magnitude) {
    final b = bands[(axis, difficulty)];
    if (b == null) return null;
    return magnitude >= b.$1 && magnitude <= b.$2;
  }
}

/// Canonical bounds bundle. Materials/archetypes are placeholders for the Compiler; the
/// Linter primarily uses [thresholdNorms].
final class GroundingTables {
  const GroundingTables(this.version, this.thresholdNorms);
  final String version;
  final ThresholdNorms thresholdNorms;

  /// A minimal default band set (illustrative — tune during balancing). Covers the axes
  /// the MVP scenes exercise; unlisted axes simply skip band checks.
  static GroundingTables defaults() {
    ((CapabilityDimension, SocialChannel?), Difficulty) k(
            CapabilityDimension d, SocialChannel? c, Difficulty diff) =>
        ((d, c), diff);
    return GroundingTables('defaults-v0', ThresholdNorms({
      // force
      k(CapabilityDimension.force, null, Difficulty.trivial): (0, 10),
      k(CapabilityDimension.force, null, Difficulty.easy): (11, 20),
      k(CapabilityDimension.force, null, Difficulty.standard): (21, 35),
      k(CapabilityDimension.force, null, Difficulty.hard): (36, 55),
      k(CapabilityDimension.force, null, Difficulty.extreme): (56, 80),
      // insight
      k(CapabilityDimension.insight, null, Difficulty.trivial): (0, 12),
      k(CapabilityDimension.insight, null, Difficulty.easy): (13, 20),
      k(CapabilityDimension.insight, null, Difficulty.standard): (21, 35),
      k(CapabilityDimension.insight, null, Difficulty.hard): (36, 50),
      k(CapabilityDimension.insight, null, Difficulty.extreme): (51, 75),
      // social.persuasion
      k(CapabilityDimension.social, SocialChannel.persuasion, Difficulty.trivial): (0, 12),
      k(CapabilityDimension.social, SocialChannel.persuasion, Difficulty.easy): (13, 20),
      k(CapabilityDimension.social, SocialChannel.persuasion, Difficulty.standard): (21, 35),
      k(CapabilityDimension.social, SocialChannel.persuasion, Difficulty.hard): (36, 50),
      k(CapabilityDimension.social, SocialChannel.persuasion, Difficulty.extreme): (51, 75),
      // social.intimidation
      k(CapabilityDimension.social, SocialChannel.intimidation, Difficulty.trivial): (0, 12),
      k(CapabilityDimension.social, SocialChannel.intimidation, Difficulty.easy): (13, 22),
      k(CapabilityDimension.social, SocialChannel.intimidation, Difficulty.standard): (23, 38),
      k(CapabilityDimension.social, SocialChannel.intimidation, Difficulty.hard): (39, 55),
      k(CapabilityDimension.social, SocialChannel.intimidation, Difficulty.extreme): (56, 80),
    }));
  }
}
