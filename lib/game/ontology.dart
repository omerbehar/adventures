/// Capability Ontology — the closed scalar axes + open facet keys every action and
/// threshold is expressed in. Pure Dart, zero Flutter imports (ADR-0002).
library;

/// The closed, canonical scalar dimensions. Adding a member is an editorial ADR act —
/// no runtime code may extend this set (ADR-0002 forbidden pattern).
enum CapabilityDimension {
  force,
  sizeForm,
  mobility,
  energy,
  durability,
  stealth,
  insight,
  social,
  loreArcane,
  techCraft,
  wealthResources,
}

/// Social is evaluative and sub-vectored (ADR-0002).
enum SocialChannel { persuasion, intimidation, deception, rapport }

/// Difficulty bands used by the grounding tables (scene-decomposition-spec §4).
enum Difficulty { trivial, easy, standard, hard, extreme }

/// Canonical value-equality key for an axis: `(dimension, channel?)`. Records give
/// structural equality for free, so this is the correct type for map keys / threshold
/// matching (ADR-0002 — a plain-class key would miss on every lookup).
typedef CapabilityAxisKey = (
  CapabilityDimension dimension,
  SocialChannel? channel,
);

/// Open, scene-local facet key. Declared per-scene; no global enum (ADR-0002).
typedef FacetKey = String;

/// A typed axis reference that is total over parsing: [dimension] is null when the raw
/// string does not resolve to a canonical axis, so the Linter can report axis misuse
/// (rule L-02) instead of the parser throwing.
final class CapabilityAxis {
  const CapabilityAxis._(this.raw, this.dimension, this.channel);

  /// The raw authored string (e.g. `social.persuasion`, `force`).
  final String raw;

  /// Resolved dimension, or null if [raw] is not a canonical axis.
  final CapabilityDimension? dimension;

  /// Resolved social channel, or null for non-social axes / unresolved.
  final SocialChannel? channel;

  /// Canonical iff it resolves to a dimension with a channel exactly-when social.
  bool get isCanonical =>
      dimension != null &&
      (dimension == CapabilityDimension.social
          ? channel != null
          : channel == null);

  /// The value-equality key, or null if unresolved.
  CapabilityAxisKey? get key =>
      dimension == null ? null : (dimension!, channel);

  /// Parse `dimension` or `social.channel`. Always returns; leaves [dimension] null when
  /// the string is not a canonical axis (unknown dimension, a channel on a non-social axis,
  /// or extra segments) so callers can lint (rule L-02) rather than throw.
  factory CapabilityAxis.parse(String s) {
    final parts = s.split('.');
    final dim = _dimByName[parts[0]];
    if (dim == null) return CapabilityAxis._(s, null, null);
    if (parts.length == 1) return CapabilityAxis._(s, dim, null);
    if (parts.length == 2 && dim == CapabilityDimension.social) {
      return CapabilityAxis._(
        s,
        dim,
        _chanByName[parts[1]],
      ); // channel may be null → not canonical
    }
    return CapabilityAxis._(
      s,
      null,
      null,
    ); // channel on a non-social axis, or malformed
  }

  static final Map<String, CapabilityDimension> _dimByName = {
    for (final d in CapabilityDimension.values) d.name: d,
  };
  static final Map<String, SocialChannel> _chanByName = {
    for (final c in SocialChannel.values) c.name: c,
  };

  @override
  String toString() => raw;
}

/// Aggregate ontology value. ADR-0002 owns the canonical magnitude scale.
final class Ontology {
  const Ontology({this.magnitudeMin = 0, this.magnitudeMax = 100});
  final int magnitudeMin;
  final int magnitudeMax;
}
