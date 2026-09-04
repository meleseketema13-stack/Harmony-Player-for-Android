import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';

import 'track_store.dart';

/// A single track from the on-device library.
///
/// [path] may be a plain absolute file path or a platform URI (e.g.
/// `content://` on Android). The handler resolves both via [_sourceFor].
/// [mediaId] is the MediaStore / MPMediaQuery id used to fetch artwork bytes.
class LocalTrack {
  const LocalTrack({
    required this.id,
    required this.path,
    required this.title,
    this.artist = 'Unknown Artist',
    this.album,
    this.duration = Duration.zero,
    this.artUri,
    this.mediaId,
  });

  final String id;
  final String path;
  final String title;
  final String artist;
  final String? album;
  final Duration duration;
  final Uri? artUri;
  final int? mediaId;

  /// Converts this track into the [MediaItem] shape that [audio_service]
  /// exposes to the platform media session (notification, lock screen,
  /// smartwatches, headset actions).
  MediaItem toMediaItem({bool favorite = false}) => MediaItem(
        id: id,
        title: title,
        artist: artist,
        album: album,
        duration: duration == Duration.zero ? null : duration,
        artUri: artUri,
        extras: <String, dynamic>{
          'path': path,
          'favorite': favorite,
          'mediaId': mediaId,
        },
      );
}

/// Maps [just_audio] playback onto the platform media session ([audio_service])
/// and owns audio focus ([audio_session]).
///
/// This handler deliberately owns **no** `BuildContext` and never touches the
/// widget tree. The UI layer observes its broadcast streams through Riverpod
/// and issues commands through the public methods, which keeps background
/// playback fully decoupled from whatever the UI is currently rendering.
class HarmonyAudioHandler extends BaseAudioHandler {
  HarmonyAudioHandler([this._store = const TrackStore()]) {
    // just_audio surfaces load/decode failures by emitting an error on this
    // just_audio surfaces load/decode failures by emitting an error on this
    // stream, which is translated into AudioProcessingState.error below.
    _eventSub = _player.playbackEventStream.listen(
      _onPlaybackEvent,
      onError: _onPlayerError,
    );
    _positionSub = _player
        .createPositionStream(
          steps: 800,
          minPeriod: const Duration(milliseconds: 250),
          maxPeriod: const Duration(seconds: 1),
        )
        .listen(_onPositionTick);
    _indexSub = _player.currentIndexStream.listen(_onIndexChanged);
  }

  /// The amount of time a single "jump" scrubs by. Kept identical for the
  /// platform fast-forward/rewind actions, the player buttons and the
  /// screen-reader custom actions so the control surfaces never disagree.
  /// Configurable via [setSeekIntervalSeconds] (persisted by [TrackStore]).
  Duration get jumpInterval => Duration(seconds: _seekIntervalSeconds);

  final AudioPlayer _player = AudioPlayer();
  final List<LocalTrack> _tracks = <LocalTrack>[];
  final Set<String> _favorites = <String>{};
  final List<String> _playlistIds = <String>[];
  final TrackStore _store;
  int _seekIntervalSeconds = TrackStore.defaultSeekIntervalSeconds;

  // Broadcast controllers so the handler never buffers events for listeners
  // that are not currently subscribed (e.g. when the UI is backgrounded).
  final StreamController<Set<String>> _favoritesController =
      StreamController<Set<String>>.broadcast();
  final StreamController<List<String>> _playlistController =
      StreamController<List<String>>.broadcast();
  final StreamController<String> _errorController =
      StreamController<String>.broadcast();
  final StreamController<Duration> _positionController =
      StreamController<Duration>.broadcast();
  final StreamController<Duration?> _durationController =
      StreamController<Duration?>.broadcast();
  final StreamController<int> _seekIntervalController =
      StreamController<int>.broadcast();
  final StreamController<int> _sleepTimerController =
      StreamController<int>.broadcast();
  final StreamController<int> _sleepTimerRemainingController =
      StreamController<int>.broadcast();

  StreamSubscription<PlaybackEvent>? _eventSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<int?>? _indexSub;
  StreamSubscription<AudioInterruptionEvent>? _interruptionSub;
  StreamSubscription<void>? _noisySub;
  Timer? _forwardTimer;
  Timer? _backwardTimer;
  Timer? _sleepTimer;
  Timer? _sleepTimerTick;
  int _sleepTimerMinutes = 0;
  int _sleepTimerRemainingSeconds = 0;
  AudioSession? _session;
  bool _sessionActive = false;

  PlaybackState _playbackState = PlaybackState(
    controls: <MediaControl>[
      MediaControl.skipToPrevious,
      MediaControl.play,
      MediaControl.skipToNext,
    ],
    androidCompactActionIndices: const <int>[0, 1, 2],
    systemActions: const <MediaAction>{
      MediaAction.seek,
      MediaAction.seekForward,
      MediaAction.seekBackward,
      MediaAction.skipToNext,
      MediaAction.skipToPrevious,
      MediaAction.setShuffleMode,
      MediaAction.setRepeatMode,
      MediaAction.stop,
    },
  );

  // --- Public UI-facing state streams -------------------------------------

  /// Fires whenever the set of favorited track ids changes.
  Stream<Set<String>> get favoritesStream => _favoritesController.stream;

  /// Fires whenever the persisted playlist changes (full ordered id list).
  Stream<List<String>> get playlistStream => _playlistController.stream;

  /// Human-readable error messages (e.g. missing/corrupted local files).
  Stream<String> get errorMessagesStream => _errorController.stream;

  /// Live playback position, also updated on explicit seeks while paused so
  /// the UI slider never goes stale.
  Stream<Duration> get positionStream => _positionController.stream;

  /// The real duration reported by the decoder once a source is loaded.
  Stream<Duration?> get durationStream => _durationController.stream;

  /// The currently configured seek-jump size in seconds.
  Stream<int> get seekIntervalStream => _seekIntervalController.stream;

  /// The configured sleep timer duration in minutes (0 = off).
  Stream<int> get sleepTimerStream => _sleepTimerController.stream;

  /// Remaining seconds on the active sleep timer (0 when inactive).
  Stream<int> get sleepTimerRemainingStream => _sleepTimerRemainingController.stream;

  LocalTrack? get currentTrack {
    final index = _player.currentIndex;
    if (index == null || index < 0 || index >= _tracks.length) return null;
    return _tracks[index];
  }

  // --- Setup / teardown ----------------------------------------------------

  /// Configures the audio session, audio focus and interruption handling.
  ///
  /// Must be awaited before [AudioService.init] so the session is active while
  /// the foreground service starts.
  Future<void> init() async {
    // Restore persisted user state before any UI subscribes, so the favorites
    // and playlist are correct from the very first frame.
    _favorites.addAll(await _store.loadFavorites());
    _favoritesController.add(Set<String>.of(_favorites));
    _playlistIds.addAll(await _store.loadPlaylist());
    _playlistController.add(List<String>.of(_playlistIds));
    _seekIntervalSeconds = await _store.loadSeekIntervalSeconds();
    _seekIntervalController.add(_seekIntervalSeconds);
    _sleepTimerMinutes = await _store.loadSleepTimerMinutes();
    _sleepTimerController.add(_sleepTimerMinutes);

    final session = await AudioSession.instance;
    _session = session;
    // Music: lets the OS duck/pause us for calls, timers and other apps, and
    // re-activates focus automatically for the next playback request.
    await session.configure(const AudioSessionConfiguration.music());
    _sessionActive = await session.setActive(true);
    _interruptionSub = session.interruptionEventStream.listen(_onInterruption);
    _noisySub = session.becomingNoisyEventStream.listen((_) {
      // Headphones unplugged or Bluetooth disconnected mid-playback.
      if (_player.playing) {
        unawaited(pause());
      }
    });
  }

  /// Cancels every subscription and frees the player. Called by
  /// [AudioService.init] teardown paths and the Riverpod `onDispose` hook.
  Future<void> dispose() async {
    _forwardTimer?.cancel();
    _backwardTimer?.cancel();
    await _interruptionSub?.cancel();
    await _noisySub?.cancel();
    await _eventSub?.cancel();
    await _positionSub?.cancel();
    await _indexSub?.cancel();
    await _player.dispose();
    await _favoritesController.close();
    await _playlistController.close();
    await _errorController.close();
    await _positionController.close();
    await _durationController.close();
    await _seekIntervalController.close();
    await _sleepTimerController.close();
    await _sleepTimerRemainingController.close();
    _sleepTimer?.cancel();
    _sleepTimerTick?.cancel();
    if (_session != null) {
      await _session!.setActive(false);
    }
  }

  // --- Queue / playback commands -------------------------------------------

  /// Replaces the queue with [tracks] and starts playback at [startIndex].
  ///
  /// Missing or unreadable files surface as errors on [errorMessagesStream]
  /// (and as `AudioProcessingState.error`) instead of crashing the app.
  Future<void> playQueue(List<LocalTrack> tracks, {int startIndex = 0}) async {
    if (tracks.isEmpty) return;
    _tracks
      ..clear()
      ..addAll(tracks);
    if (startIndex < 0 || startIndex >= _tracks.length) startIndex = 0;

    queue.add(<MediaItem>[
      for (final t in _tracks)
        t.toMediaItem(favorite: _favorites.contains(t.id)),
    ]);

    final sources = <AudioSource>[for (final t in _tracks) _sourceFor(t)];
    final sequence = ConcatenatingAudioSource(children: sources);
    try {
      await _player.setAudioSource(sequence, initialIndex: startIndex);
      mediaItem.add(_tracks[startIndex]
          .toMediaItem(favorite: _favorites.contains(_tracks[startIndex].id)));
      await _player.play();
    } catch (error) {
      _onPlayerError(error, StackTrace.current);
    }
  }

  @override
  Future<void> play() async {
    // A finished track needs a seek before it can replay.
    if (_player.processingState == ProcessingState.completed) {
      await _player.seek(Duration.zero);
    }
    if (_session != null && !_sessionActive) {
      _sessionActive = await _session!.setActive(true);
    }
    await _player.play();
  }

  @override
  Future<void> pause() async {
    await _player.pause();
  }

  @override
  Future<void> stop() async {
    await _player.pause();
    await _player.seek(Duration.zero);
    _playbackState =
        _playbackState.copyWith(playing: false, updatePosition: Duration.zero);
    playbackState.add(_playbackState);
    _positionController.add(Duration.zero);
  }

  @override
  Future<void> seek(Duration position) async {
    var target = position;
    final duration = _player.duration;
    if (duration != null && target > duration) target = duration;
    if (target < Duration.zero) target = Duration.zero;
    await _player.seek(target);
    _playbackState = _playbackState.copyWith(updatePosition: target);
    playbackState.add(_playbackState);
    _positionController.add(target);
  }

  @override
  Future<void> skipToNext() async {
    if (_player.hasNext) {
      await _player.seekToNext();
    } else {
      await _player.seek(Duration.zero);
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_player.hasPrevious) {
      await _player.seekToPrevious();
    } else {
      await _player.seek(Duration.zero);
    }
  }

  @override
  Future<void> playMediaItem(MediaItem mediaItem) async {
    final index = _tracks.indexWhere((t) => t.id == mediaItem.id);
    if (index == -1) return;
    await _player.seek(Duration.zero, index: index);
    await _player.play();
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= _tracks.length) return;
    await _player.seek(Duration.zero, index: index);
    await _player.play();
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    await _player.setLoopMode(_toLoopMode(repeatMode));
    _playbackState = _playbackState.copyWith(repeatMode: repeatMode);
    playbackState.add(_playbackState);
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    await _player
        .setShuffleModeEnabled(shuffleMode == AudioServiceShuffleMode.all);
    _playbackState = _playbackState.copyWith(shuffleMode: shuffleMode);
    playbackState.add(_playbackState);
  }

  // Continuous seek used by press-and-hold headset / notification buttons.
  @override
  Future<void> seekForward(bool begin) async {
    if (begin) {
      _forwardTimer?.cancel();
      _forwardTimer = Timer.periodic(
        const Duration(milliseconds: 500),
        (_) => unawaited(_seekBy(jumpInterval)),
      );
      await _seekBy(jumpInterval);
    } else {
      _forwardTimer?.cancel();
    }
  }

  @override
  Future<void> seekBackward(bool begin) async {
    if (begin) {
      _backwardTimer?.cancel();
      _backwardTimer = Timer.periodic(
        const Duration(milliseconds: 500),
        (_) => unawaited(_seekBy(-jumpInterval)),
      );
      await _seekBy(-jumpInterval);
    } else {
      _backwardTimer?.cancel();
    }
  }

  @override
  Future<void> fastForward() => _seekBy(jumpInterval);

  @override
  Future<void> rewind() => _seekBy(-jumpInterval);

  // --- App-level commands used by screen reader custom actions -------------

  Future<void> jumpForward() => _seekBy(jumpInterval);

  Future<void> jumpBackward() => _seekBy(-jumpInterval);

  /// Changes and persists the seek-jump size. Unknown values are rejected.
  Future<void> setSeekIntervalSeconds(int seconds) async {
    if (!TrackStore.seekIntervalOptions.contains(seconds)) return;
    if (seconds == _seekIntervalSeconds) return;
    _seekIntervalSeconds = seconds;
    await _store.saveSeekIntervalSeconds(seconds);
    _seekIntervalController.add(seconds);
  }

  /// Sets the sleep timer duration in minutes. 0 cancels any active timer.
  Future<void> setSleepTimerMinutes(int minutes) async {
    if (!TrackStore.sleepTimerOptions.contains(minutes)) return;
    _sleepTimer?.cancel();
    _sleepTimerTick?.cancel();
    _sleepTimerMinutes = minutes;
    _sleepTimerController.add(minutes);

    if (minutes <= 0) {
      _sleepTimerRemainingSeconds = 0;
      _sleepTimerRemainingController.add(0);
      await _store.saveSleepTimerMinutes(0);
      return;
    }

    await _store.saveSleepTimerMinutes(minutes);
    _sleepTimerRemainingSeconds = minutes * 60;
    _sleepTimerRemainingController.add(_sleepTimerRemainingSeconds);

    _sleepTimerTick = Timer.periodic(const Duration(seconds: 1), (_) {
      _sleepTimerRemainingSeconds--;
      _sleepTimerRemainingController.add(_sleepTimerRemainingSeconds);
      if (_sleepTimerRemainingSeconds <= 0) {
        _sleepTimerTick?.cancel();
      }
    });

    _sleepTimer = Timer(Duration(minutes: minutes), () async {
      _sleepTimerTick?.cancel();
      _sleepTimerRemainingSeconds = 0;
      _sleepTimerRemainingController.add(0);
      await pause();
    });
  }

  /// Toggles favorite for the current track. Returns the new favorite state
  /// so the UI can announce the outcome.
  Future<bool> toggleFavorite() async {
    final track = currentTrack;
    if (track == null) return false;
    return setFavoriteById(track.id, on: !_favorites.contains(track.id));
  }

  /// Sets the favorite state of an arbitrary track (used by the library list).
  /// Returns the resulting favorite state.
  Future<bool> setFavoriteById(String id, {required bool on}) async {
    if (on) {
      _favorites.add(id);
    } else {
      _favorites.remove(id);
    }
    await _store.saveFavorites(_favorites);
    _favoritesController.add(Set<String>.of(_favorites));

    // Keep the media session metadata in sync when the toggled track is the
    // one currently on the lock-screen / notification.
    final index = _tracks.indexWhere((t) => t.id == id);
    if (index >= 0 && index == _player.currentIndex) {
      final updated = _tracks[index].toMediaItem(favorite: on);
      final currentQueue = List<MediaItem>.of(queue.value);
      if (index < currentQueue.length) {
        currentQueue[index] = updated;
        queue.add(currentQueue);
      }
      mediaItem.add(updated);
    }
    return on;
  }

  /// Registers the current track with the persisted playlist. Returns whether
  /// a new entry was added (tracks already present are left untouched).
  Future<bool> addToPlaylist() async {
    final track = currentTrack;
    if (track == null) return false;
    if (_playlistIds.contains(track.id)) return false;
    _playlistIds.add(track.id);
    await _store.savePlaylist(_playlistIds);
    _playlistController.add(List<String>.of(_playlistIds));
    return true;
  }

  /// Removes a track id from the persisted playlist (returns whether it was
  /// present).
  Future<bool> removeFromPlaylist(String id) async {
    final before = _playlistIds.length;
    _playlistIds.removeWhere((t) => t == id);
    if (_playlistIds.length == before) return false;
    await _store.savePlaylist(_playlistIds);
    _playlistController.add(List<String>.of(_playlistIds));
    return true;
  }

  /// Whether [id] is currently in the persisted playlist.
  bool isInPlaylist(String id) => _playlistIds.contains(id);

  // --- just_audio event mapping --------------------------------------------

  void _onPlaybackEvent(PlaybackEvent event) {
    _playbackState = _playbackState.copyWith(
      processingState: _toAudioProcessing(event.processingState),
      updatePosition: event.updatePosition,
      bufferedPosition: event.bufferedPosition,
      playing: _player.playing,
      queueIndex: event.currentIndex,
    );
    playbackState.add(_playbackState);
    _positionController.add(event.updatePosition);
    if (event.duration != null) {
      _durationController.add(event.duration);
    }
  }

  void _onPositionTick(Duration position) {
    _positionController.add(position);
    if (_player.playing) {
      _playbackState = _playbackState.copyWith(updatePosition: position);
      playbackState.add(_playbackState);
    }
  }

  void _onIndexChanged(int? index) {
    if (index == null || index < 0 || index >= _tracks.length) return;
    final track = _tracks[index];
    mediaItem.add(track.toMediaItem(favorite: _favorites.contains(track.id)));
  }

  void _onPlayerError(Object error, StackTrace stackTrace) {
    final track = currentTrack;
    final message = _friendlyErrorMessage(error, track);
    _playbackState = _playbackState.copyWith(
      processingState: AudioProcessingState.error,
      playing: false,
      errorCode: -1,
      errorMessage: message,
    );
    playbackState.add(_playbackState);
    _errorController.add(track?.title ?? message);
  }

  Future<void> _onInterruption(AudioInterruptionEvent event) async {
    if (event.begin) {
      switch (event.type) {
        case AudioInterruptionType.duck:
          await _player.setVolume(0.25);
        case AudioInterruptionType.pause:
        case AudioInterruptionType.unknown:
          if (_player.playing) {
            await pause();
          }
      }
    } else if (event.type == AudioInterruptionType.duck) {
      await _player.setVolume(1.0);
    }
  }

  Future<void> _seekBy(Duration delta) async {
    var target = _player.position + delta;
    final duration = _player.duration;
    if (duration != null && target > duration) target = duration;
    if (target < Duration.zero) target = Duration.zero;
    await seek(target);
  }

  AudioSource _sourceFor(LocalTrack track) {
    final uri = Uri.tryParse(track.path);
    if (uri != null && uri.hasScheme) {
      // content://, file://, http(s):// etc.
      return AudioSource.uri(uri);
    }
    if (!File(track.path).existsSync()) {
      throw PlayerException(0, 'File not found: ${track.path}');
    }
    return AudioSource.uri(Uri.file(track.path));
  }

  String _friendlyErrorMessage(Object error, LocalTrack? track) {
    final subject = track?.title ?? 'track';
    if (error is PlayerException) {
      return 'Could not load "$subject": $error';
    }
    return 'Playback failed for "$subject": $error';
  }

  AudioProcessingState _toAudioProcessing(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }

  LoopMode _toLoopMode(AudioServiceRepeatMode mode) {
    switch (mode) {
      case AudioServiceRepeatMode.none:
        return LoopMode.off;
      case AudioServiceRepeatMode.all:
      case AudioServiceRepeatMode.group:
        return LoopMode.all;
      case AudioServiceRepeatMode.one:
        return LoopMode.one;
    }
  }
}
