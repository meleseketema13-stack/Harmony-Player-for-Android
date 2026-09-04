import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../audio/harmony_audio_handler.dart';
import '../audio/lyrics.dart';

/// The singleton [HarmonyAudioHandler] created in `main.dart` and injected via
/// a ProviderScope override. Because it is overridden, this provider body is
/// never executed in the app; the override guarantees the exact same instance
/// that `AudioService.init` is running.
///
/// Riverpod keeps UI rebuilds decoupled from the audio service: the handler
/// broadcasts through its own streams and never references a `BuildContext`,
/// while the UI merely subscribes through the StreamProviders below. When the
/// UI is torn down (app backgrounded), the subscriptions are released but the
/// handler — owned by the platform media session — keeps playing.
final audioHandlerProvider = Provider<HarmonyAudioHandler>((ref) {
  final handler = HarmonyAudioHandler();
  ref.onDispose(handler.dispose);
  return handler;
});

/// Playback state mirror of the OS media session (playing, processing,
/// repeat/shuffle mode, position, error state).
final playbackStateProvider = StreamProvider<PlaybackState>((ref) {
  return ref.watch(audioHandlerProvider).playbackState;
});

/// The currently selected media item, or null before a queue is loaded.
final mediaItemProvider = StreamProvider<MediaItem?>((ref) {
  return ref.watch(audioHandlerProvider).mediaItem;
});

/// Live playback position (ticks while playing; also updates on paused seeks).
final positionProvider = StreamProvider<Duration>((ref) {
  return ref.watch(audioHandlerProvider).positionStream;
});

/// Decoder-reported duration once a source loads.
final trackDurationProvider = StreamProvider<Duration?>((ref) {
  return ref.watch(audioHandlerProvider).durationStream;
});

/// The set of favorited track ids.
final favoritesProvider = StreamProvider<Set<String>>((ref) {
  return ref.watch(audioHandlerProvider).favoritesStream;
});

/// The persisted playlist as an ordered list of track ids.
final playlistIdsProvider = StreamProvider<List<String>>((ref) {
  return ref.watch(audioHandlerProvider).playlistStream;
});

/// Embedded lyrics for the track currently served by [path], or null when the
/// file has none.
final lyricsForPathProvider = FutureProvider.family<Lyrics?, String>((ref, path) {
  return lyricsService.lyricsFor(path);
});

/// Error messages emitted for missing/corrupted local files.
final playerErrorsProvider = StreamProvider<String>((ref) {
  return ref.watch(audioHandlerProvider).errorMessagesStream;
});

/// The configured fast-forward/rewind jump size in seconds.
final seekIntervalProvider = StreamProvider<int>((ref) {
  return ref.watch(audioHandlerProvider).seekIntervalStream;
});

/// The configured sleep timer duration in minutes (0 = off).
final sleepTimerProvider = StreamProvider<int>((ref) {
  return ref.watch(audioHandlerProvider).sleepTimerStream;
});

/// Remaining seconds on the active sleep timer (0 when inactive).
final sleepTimerRemainingProvider = StreamProvider<int>((ref) {
  return ref.watch(audioHandlerProvider).sleepTimerRemainingStream;
});

// --- Derived, UI-consumable states ----------------------------------------

final isPlayingProvider = Provider<bool>((ref) {
  return ref.watch(playbackStateProvider).valueOrNull?.playing ?? false;
});

final processingStateProvider = Provider<AudioProcessingState>((ref) {
  return ref.watch(playbackStateProvider).valueOrNull?.processingState ??
      AudioProcessingState.idle;
});

final shuffleModeProvider = Provider<AudioServiceShuffleMode>((ref) {
  return ref.watch(playbackStateProvider).valueOrNull?.shuffleMode ??
      AudioServiceShuffleMode.none;
});

final repeatModeProvider = Provider<AudioServiceRepeatMode>((ref) {
  return ref.watch(playbackStateProvider).valueOrNull?.repeatMode ??
      AudioServiceRepeatMode.none;
});

/// Whether the current track is favorited.
final isFavoriteProvider = Provider<bool>((ref) {
  final media = ref.watch(mediaItemProvider).valueOrNull;
  final favorites = ref.watch(favoritesProvider).valueOrNull ?? const <String>{};
  return media != null && favorites.contains(media.id);
});

/// Whether transport controls should be enabled (a source is loaded).
final transportEnabledProvider = Provider<bool>((ref) {
  final processing = ref.watch(processingStateProvider);
  return processing != AudioProcessingState.idle &&
      processing != AudioProcessingState.error;
});

/// Screen reader reading-order preference. `true` = content before navigation,
/// `false` = visual order (navigation first).
class ContentFirstSemanticsOrder extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
}

final contentFirstSemanticsProvider =
    NotifierProvider<ContentFirstSemanticsOrder, bool>(
  ContentFirstSemanticsOrder.new,
);
