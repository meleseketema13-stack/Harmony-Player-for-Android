import 'dart:ui' show FlutterView, TextDirection;

import 'package:audio_service/audio_service.dart';
import 'package:flutter/semantics.dart';

import '../l10n/generated/app_localizations.dart';

/// Centralized accessibility engine.
///
/// Every screen reader facing string, live announcement and custom semantics
/// action is defined here (backed by the ARB localizations so Jieshuo+/CSR
/// users with a Chinese locale get correct output). Widgets never hardcode
/// announcement text inline; they always go through this class.
///
/// Why this works without a third-party native plugin:
///  * [SemanticsService.sendAnnouncement] maps to the platform announcement
///    channel (`announceForAccessibility` on Android, `UIAccessibility`
///    announcement notification on iOS). TalkBack, Jieshuo+, ShinePlus and
///    Samsung Voice Assistant are all Android accessibility services that
///    receive the same framework event, so one call reaches every engine.
///  * [CustomSemanticsAction] registers native accessibility actions
///    (`AccessibilityAction` on Android, `UIAccessibilityCustomAction` on iOS),
///    which TalkBack's context menu and Jieshuo+'s actions menu render
///    automatically.
class A11yEngine {
  const A11yEngine(this.l10n, this.view);

  final AppLocalizations l10n;

  /// The view this engine announces into. Required by
  /// [SemanticsService.sendAnnouncement] to stay multi-window compatible.
  final FlutterView view;

  /// Minimum touch target in logical pixels required by the accessibility spec
  /// and enforced by every interactive widget in this app.
  static const double minTouchTarget = 48;

  /// Live, non-blocking global announcement.
  ///
  /// `TextDirection.ltr` is required by the API and does not imply the spoken
  /// language — that comes from the localized [l10n] strings.
  void announce(String message) {
    if (message.trim().isEmpty) return;
    SemanticsService.sendAnnouncement(view, message, TextDirection.ltr);
  }

  // --- Track state ---------------------------------------------------------

  /// "Playing: {title} by {artist}" — output format mandated by the spec.
  void announceTrackPlaying(String title, String artist) =>
      announce(l10n.announcePlayingTrack(title, artist));

  void announceTrackPaused(String title, String artist) =>
      announce(l10n.announcePausedTrack(title, artist));

  // --- Seek ----------------------------------------------------------------

  /// "Seek bar, {percent} percent, swipe up or down to adjust".
  void announceSeek(int percent) => announce(l10n.announceSeekPercent(percent));

  // --- Mode toggles --------------------------------------------------------

  void announceShuffle(bool on) =>
      announce(on ? l10n.announceShuffleOn : l10n.announceShuffleOff);

  void announceRepeat(AudioServiceRepeatMode mode) {
    switch (mode) {
      case AudioServiceRepeatMode.none:
        announce(l10n.announceRepeatOff);
      case AudioServiceRepeatMode.all:
      case AudioServiceRepeatMode.group:
        announce(l10n.announceRepeatAll);
      case AudioServiceRepeatMode.one:
        announce(l10n.announceRepeatOne);
    }
  }

  void announceFavorite(bool on) =>
      announce(on ? l10n.announceFavoriteOn : l10n.announceFavoriteOff);

  void announceAddedToPlaylist() => announce(l10n.announceAddedToPlaylist);

  void announcePlayerMinimized() => announce(l10n.announcePlayerMinimized);

  void announceError(String title) => announce(l10n.announceError(title));

  void announceSleepTimerSet(String duration) =>
      announce(l10n.announceSleepTimerSet(duration));

  void announceSleepTimerCancelled() =>
      announce(l10n.announceSleepTimerCancelled);

  // --- Formatting ----------------------------------------------------------

  /// Localized long label for a seek interval in seconds (e.g. "10 seconds").
  String seekIntervalLabel(int seconds) => switch (seconds) {
        10 => l10n.seekInterval10s,
        30 => l10n.seekInterval30s,
        60 => l10n.seekInterval1m,
        600 => l10n.seekInterval10m,
        1800 => l10n.seekInterval30m,
        3600 => l10n.seekInterval60m,
        _ => l10n.seekIntervalSeconds(seconds),
      };

  /// Compact label for the same intervals (e.g. "10 sec"), for space-tight UI.
  String seekIntervalLabelShort(int seconds) => switch (seconds) {
        10 => l10n.seekInterval10sShort,
        30 => l10n.seekInterval30sShort,
        60 => l10n.seekInterval1mShort,
        600 => l10n.seekInterval10mShort,
        1800 => l10n.seekInterval30mShort,
        3600 => l10n.seekInterval60mShort,
        _ => l10n.seekIntervalSeconds(seconds),
      };

  /// `m:ss` or `h:mm:ss`, used as the `value`/`increasedValue`/`decreasedValue`
  /// text on the seek bar so every engine can read the exact position.
  String formatDuration(Duration duration) {
    final h = duration.inHours;
    final m = duration.inMinutes % 60;
    final s = duration.inSeconds % 60;
    String two(int v) => v.toString().padLeft(2, '0');
    return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
  }

  // --- Custom semantics actions --------------------------------------------

  /// The ≤5 secondary actions attached to the seek bar. These appear in the
  /// TalkBack context menu and Jieshuo+/CSR actions menu without any native
  /// plugin, because Flutter exposes them as standard platform accessibility
  /// actions.
  Map<CustomSemanticsAction, VoidCallback> secondaryActions({
    required int jumpSeconds,
    required VoidCallback onJumpForward,
    required VoidCallback onJumpBackward,
    required VoidCallback onToggleFavorite,
    required VoidCallback onAddToPlaylist,
    required VoidCallback onToggleShuffle,
  }) {
    final jump = seekIntervalLabel(jumpSeconds);
    return <CustomSemanticsAction, VoidCallback>{
      CustomSemanticsAction(label: l10n.jumpBackward(jump)): onJumpBackward,
      CustomSemanticsAction(label: l10n.jumpForward(jump)): onJumpForward,
      CustomSemanticsAction(label: l10n.toggleFavorite): onToggleFavorite,
      CustomSemanticsAction(label: l10n.addToPlaylist): onAddToPlaylist,
      CustomSemanticsAction(label: l10n.shuffleButton): onToggleShuffle,
    };
  }
}
