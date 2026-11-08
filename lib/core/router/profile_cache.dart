/// Short-lived, in-memory cache for the row the auth guard reads on every
/// navigation.
class ProfileCache {
  ProfileCache({
    this.ttl = const Duration(minutes: 5),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  /// How long a cached row is trusted.
  final Duration ttl;

  final DateTime Function() _clock;
  final Map<String, _Entry> _entries = {};

  /// The cached row for [userId], or `null` when there is none or it is older
  /// than [ttl]. Expired entries are evicted on read.
  Map<String, dynamic>? read(String userId) {
    final entry = _entries[userId];

    if (entry == null) {
      return null;
    }

    if (_clock().difference(entry.storedAt) >= ttl) {
      _entries.remove(userId);
      return null;
    }

    return entry.profile;
  }

  void write(String userId, Map<String, dynamic> profile) {
    _entries[userId] = _Entry(profile, _clock());
  }

  /// Drops everything.
  void clear() => _entries.clear();
}

class _Entry {
  const _Entry(this.profile, this.storedAt);

  final Map<String, dynamic> profile;
  final DateTime storedAt;
}

