import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../a11y/a11y_engine.dart';
import '../../audio/track_store.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../state/audio_providers.dart';

/// A single transport or secondary control button.
///
/// Accessibility contract:
///  * Exactly one semantics node: the `Semantics` wrapper supplies
///    label/button/enabled/onTap, while the `InkWell` uses
///    `excludeFromSemantics: true` so no duplicate tappable node leaks into
///    the tree (TalkBack/Jieshuo+ would otherwise announce the control twice).
///  * Hard 48x48 logical pixel minimum touch target via [A11yEngine.minTouchTarget]
///    — never smaller, enforced structurally rather than by convention.
///  * Plain *action* button, never a toggle switch. The semantics node
///    deliberately omits `SemanticsFlag.isToggled`, because Android screen
///    readers render that flag as a checkbox/switch and prefix the label with
///    "Switch on" / "Switch off" — noisy and wrong for a Play/Pause button.
///    On/off state is conveyed through [label] and [value] instead, which read
///    as plain speech ("Play", "Shuffle, On"), and [active] only drives the
///    icon tint so sighted users keep the visual cue for free.
///  * Optional [CustomSemanticsAction]s surfaced in TalkBack's context menu
///    and Jieshuo+'s actions menu.
class PlayerButton extends StatelessWidget {
  const PlayerButton({
    super.key,
    required this.icon,
    required this.label,
    this.onPressed,
    this.active = false,
    this.value,
    this.iconSize = 24,
    this.activeColor,
    this.customActions = const <CustomSemanticsAction, VoidCallback>{},
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  /// Highlights the icon when the underlying state is on. Purely visual — it is
  /// never exposed to the semantics tree, see the class doc comment.
  final bool active;
  final String? value;
  final double iconSize;
  final Color? activeColor;
  final Map<CustomSemanticsAction, VoidCallback> customActions;

  bool get _enabled => onPressed != null;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      button: true,
      enabled: _enabled,
      label: label,
      value: value,
      onTap: _enabled ? onPressed : null,
      customSemanticsActions: customActions,
      child: SizedBox.square(
        dimension: A11yEngine.minTouchTarget,
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            excludeFromSemantics: true,
            onTap: onPressed,
            child: Center(
              child: Icon(
                icon,
                size: iconSize,
                color: active
                    ? (activeColor ?? scheme.primary)
                    : IconTheme.of(context).color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
/// Previous / Jump-back / Play-Pause / Jump-forward / Next.
class TransportControls extends ConsumerWidget {
  const TransportControls({super.key, this.prominent = false, this.jumpsOnly = false});

  final bool prominent;

  /// Renders only the two jump buttons. Used by the tablet side pane, whose
  /// Previous / Play-Pause / Next already live in the mini bar directly beneath
  /// it — a second full transport row would put duplicate nodes in the
  /// semantics tree and make the screen reader announce Play twice.
  final bool jumpsOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final handler = ref.watch(audioHandlerProvider);
    final l10n = AppLocalizations.of(context);
    final engine = A11yEngine(l10n, View.of(context));
    final playing = ref.watch(isPlayingProvider);
    final enabled = ref.watch(transportEnabledProvider);
    final item = ref.watch(mediaItemProvider).valueOrNull;
    final jumpSeconds = ref.watch(seekIntervalProvider).valueOrNull ??
        TrackStore.defaultSeekIntervalSeconds;
    final jumpLabel = engine.seekIntervalLabel(jumpSeconds);

    Future<void> onPlayPause() async {
      if (playing) {
        await handler.pause();
        engine.announceTrackPaused(
          item?.title ?? l10n.unknownTrack,
          item?.artist ?? l10n.unknownArtist,
        );
      } else {
        await handler.play();
        engine.announceTrackPlaying(
          item?.title ?? l10n.unknownTrack,
          item?.artist ?? l10n.unknownArtist,
        );
      }
    }

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        if (!jumpsOnly)
          PlayerButton(
            icon: Icons.skip_previous_rounded,
            label: l10n.previousButton,
            onPressed:
                enabled ? () => unawaited(handler.skipToPrevious()) : null,
          ),
        PlayerButton(
          icon: Icons.fast_rewind_rounded,
          label: l10n.jumpBackward(jumpLabel),
          onPressed:
              enabled ? () => unawaited(handler.jumpBackward()) : null,
        ),
        if (!jumpsOnly) ...<Widget>[
          PlayerButton(
            icon: playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
            label: playing ? l10n.pauseButton : l10n.playButton,
            active: playing,
            iconSize: prominent ? 36 : 28,
            onPressed: enabled ? onPlayPause : null,
          ),
          PlayerButton(
            icon: Icons.fast_forward_rounded,
            label: l10n.jumpForward(jumpLabel),
            onPressed:
                enabled ? () => unawaited(handler.jumpForward()) : null,
          ),
        ],
        if (!jumpsOnly)
          PlayerButton(
            icon: Icons.skip_next_rounded,
            label: l10n.nextButton,
            onPressed:
                enabled ? () => unawaited(handler.skipToNext()) : null,
          ),
      ],
    );
  }
}

/// Shuffle / Favorite / Add-to-playlist / Repeat.
class SecondaryControls extends ConsumerWidget {
  const SecondaryControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final handler = ref.watch(audioHandlerProvider);
    final l10n = AppLocalizations.of(context);
    final engine = A11yEngine(l10n, View.of(context));
    final enabled = ref.watch(transportEnabledProvider);
    final shuffleOn =
        ref.watch(shuffleModeProvider) == AudioServiceShuffleMode.all;
    final repeat = ref.watch(repeatModeProvider);
    final isFavorite = ref.watch(isFavoriteProvider);

    Future<void> toggleShuffle() async {
      final target = shuffleOn
          ? AudioServiceShuffleMode.none
          : AudioServiceShuffleMode.all;
      await handler.setShuffleMode(target);
      engine.announceShuffle(!shuffleOn);
    }

    Future<void> cycleRepeat() async {
      final next = switch (repeat) {
        AudioServiceRepeatMode.none => AudioServiceRepeatMode.all,
        AudioServiceRepeatMode.all => AudioServiceRepeatMode.one,
        AudioServiceRepeatMode.one => AudioServiceRepeatMode.none,
        AudioServiceRepeatMode.group => AudioServiceRepeatMode.none,
      };
      await handler.setRepeatMode(next);
      engine.announceRepeat(next);
    }

    Future<void> toggleFavorite() async {
      final on = await handler.toggleFavorite();
      engine.announceFavorite(on);
    }

    Future<void> addToPlaylist() async {
      await handler.addToPlaylist();
      engine.announceAddedToPlaylist();
    }

    final repeatLabel = switch (repeat) {
      AudioServiceRepeatMode.none => l10n.repeatOff,
      AudioServiceRepeatMode.all => l10n.repeatAll,
      AudioServiceRepeatMode.one => l10n.repeatOne,
      AudioServiceRepeatMode.group => l10n.repeatAll,
    };

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        PlayerButton(
          icon: Icons.shuffle_rounded,
          label: l10n.shuffleButton,
          active: shuffleOn,
          value: shuffleOn ? l10n.stateOn : l10n.stateOff,
          onPressed: enabled ? () => unawaited(toggleShuffle()) : null,
        ),
        PlayerButton(
          icon: isFavorite ? Icons.favorite_rounded : Icons.favorite_border,
          label: l10n.favoriteButton,
          active: isFavorite,
          value: isFavorite ? l10n.stateOn : l10n.stateOff,
          onPressed: enabled ? () => unawaited(toggleFavorite()) : null,
        ),
        PlayerButton(
          icon: Icons.playlist_add_rounded,
          label: l10n.addToPlaylist,
          onPressed: enabled ? () => unawaited(addToPlaylist()) : null,
        ),
        PlayerButton(
          icon: Icons.repeat_rounded,
          label: l10n.repeatButton,
          value: repeatLabel,
          active: repeat != AudioServiceRepeatMode.none,
          onPressed: enabled ? () => unawaited(cycleRepeat()) : null,
        ),
      ],
    );
  }
}
