import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Persistence for the user's favorites and playlist.
///
/// Both are stored as JSON arrays of track ids in [SharedPreferences], so they
/// survive app restarts and platform media-session teardowns without any
/// database dependency.
class TrackStore {
  const TrackStore();

  static const String favoritesKey = 'favorites';
  static const String playlistKey = 'playlist';
  static const String seekIntervalKey = 'seekIntervalSeconds';
  static const String sleepTimerKey = 'sleepTimerMinutes';

  /// Allowable fast-forward/rewind jump sizes, in seconds.
  static const List<int> seekIntervalOptions = <int>[10, 30, 60, 600, 1800, 3600];

  /// The jump size used until the user changes it.
  static const int defaultSeekIntervalSeconds = 10;

  /// Allowable sleep timer durations in minutes. 0 = off.
  static const List<int> sleepTimerOptions = <int>[0, 5, 10, 15, 30, 45, 60, 90, 120];

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<Set<String>> loadFavorites() async {
    final prefs = await _prefs;
    final raw = prefs.getString(favoritesKey);
    if (raw == null) return <String>{};
    final decoded = jsonDecode(raw);
    if (decoded is! List) return <String>{};
    return <String>{
      for (final item in decoded)
        if (item is String) item,
    };
  }

  Future<void> saveFavorites(Set<String> ids) async {
    final prefs = await _prefs;
    await prefs.setString(favoritesKey, jsonEncode(ids.toList()..sort()));
  }

  Future<List<String>> loadPlaylist() async {
    final prefs = await _prefs;
    final raw = prefs.getString(playlistKey);
    if (raw == null) return <String>[];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return <String>[];
    return <String>[
      for (final item in decoded)
        if (item is String) item,
    ];
  }

  Future<void> savePlaylist(List<String> ids) async {
    final prefs = await _prefs;
    await prefs.setString(playlistKey, jsonEncode(ids));
  }

  /// The persisted seek-jump size in seconds, clamped to [seekIntervalOptions].
  Future<int> loadSeekIntervalSeconds() async {
    final prefs = await _prefs;
    final value = prefs.getInt(seekIntervalKey);
    if (value == null || !seekIntervalOptions.contains(value)) {
      return defaultSeekIntervalSeconds;
    }
    return value;
  }

  Future<void> saveSeekIntervalSeconds(int seconds) async {
    final prefs = await _prefs;
    await prefs.setInt(seekIntervalKey, seconds);
  }

  Future<int> loadSleepTimerMinutes() async {
    final prefs = await _prefs;
    final value = prefs.getInt(sleepTimerKey);
    if (value == null || !sleepTimerOptions.contains(value)) return 0;
    return value;
  }

  Future<void> saveSleepTimerMinutes(int minutes) async {
    final prefs = await _prefs;
    await prefs.setInt(sleepTimerKey, minutes);
  }
}
