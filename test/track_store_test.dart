import 'package:flutter_test/flutter_test.dart';
import 'package:harmony_player/audio/track_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('favorites round-trip through the store', () async {
    final store = TrackStore();
    expect(await store.loadFavorites(), isEmpty);

    await store.saveFavorites(<String>{'song-1', 'song-2'});
    expect(await store.loadFavorites(), <String>{'song-1', 'song-2'});

    await store.saveFavorites(<String>{'song-2'});
    expect(await store.loadFavorites(), <String>{'song-2'});
  });

  test('playlist round-trips preserving order', () async {
    final store = TrackStore();
    expect(await store.loadPlaylist(), isEmpty);

    await store.savePlaylist(<String>['song-3', 'song-1', 'song-2']);
    expect(await store.loadPlaylist(), <String>['song-3', 'song-1', 'song-2']);
  });

  test('a fresh instance reads the same persisted data', () async {
    await const TrackStore().saveFavorites(<String>{'song-9'});
    await const TrackStore().savePlaylist(<String>['song-9']);

    expect(await TrackStore().loadFavorites(), <String>{'song-9'});
    expect(await TrackStore().loadPlaylist(), <String>['song-9']);
  });

  test('seek interval defaults to 10 seconds and round-trips', () async {
    final store = TrackStore();
    expect(await store.loadSeekIntervalSeconds(), 10);

    await store.saveSeekIntervalSeconds(600);
    expect(await store.loadSeekIntervalSeconds(), 600);

    // Unknown stored values fall back to the default.
    SharedPreferences.setMockInitialValues(
      <String, Object>{TrackStore.seekIntervalKey: 999},
    );
    expect(await TrackStore().loadSeekIntervalSeconds(), 10);
  });

  test('seek interval options cover 10s, 30s, 1 min, 10 min, 30 min and 60 min',
      () {
    expect(TrackStore.seekIntervalOptions, <int>[10, 30, 60, 600, 1800, 3600]);
  });
}
