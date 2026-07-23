/// Sports supported in v1. Stored in Firestore by [id] (a stable string),
/// never by enum index, so reordering this enum can't corrupt existing data.
enum Sport {
  football('football', 'Football', '⚽'),
  basketball('basketball', 'Basketball', '🏀'),
  tennis('tennis', 'Tennis', '🎾'),
  volleyball('volleyball', 'Volleyball', '🏐'),
  padel('padel', 'Padel', '🎾');

  const Sport(this.id, this.label, this.emoji);

  /// Stable identifier persisted to Firestore.
  final String id;

  /// Human-readable name for the UI.
  final String label;

  /// Emoji used as a lightweight icon.
  final String emoji;

  /// Resolves a [Sport] from its stored [id]. Falls back to [football] for
  /// unknown values so an unrecognized record never crashes the app.
  static Sport fromId(String? id) {
    return Sport.values.firstWhere(
      (s) => s.id == id,
      orElse: () => Sport.football,
    );
  }
}
