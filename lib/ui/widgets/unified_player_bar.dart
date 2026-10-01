import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../a11y/a11y_engine.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../state/audio_providers.dart';
import '../screens/now_playing_screen.dart';
import 'album_art.dart';
import 'player_controls.dart';

/// The single persistent bottom playback bar.
///
/// This widget replaces the former two-bar arrangement (a `MiniPlayer` stacked
/// above a separate `PlayerNavBar` transport row). Stacking two bars meant:
///  * twelve swipe stops across the bottom edge for Explore-by-Touch users, and
///  * duplicate transport controls competing for screen reader focus.
///
/// Now one bar carries artwork, title/artist and Previous / Play-Pause / Next.
/// Jump-back and jump-forward are intentionally *not* here: they live on the
/// full now-playing screen where they sit next to the seek bar they affect, and
/// they remain reachable from any screen through the seek bar's TalkBack /
/// Jieshuo+ context-menu actions. Tapping the artwork/title region opens the
/// full now-playing screen.
///
/// Reading order is decoupled from visual order via [ordinal], so
/// `contentFirstSemanticsProvider` can move this bar ahead of or behind the
/// content pane.
///
/// Focus-preservation contract: this widget is always mounted at the *same
/// tree position* (the bottom of the shell's `Column`) on every breakpoint, so
/// unfolding a foldable or resizing never unmounts the [Element] behind the
/// focused Play/Pause button and TalkBack/Jieshuo+ never drop focus.
class UnifiedPlayerBar extends ConsumerWidget {
  const UnifiedPlayerBar({
    super.key,
    this.visible = true,
    required this.ordinal,
  });

  /// When false, renders a zero-height spacer to maintain tree position
  /// without exposing any semantics to screen readers. Used on Settings, where
  /// playback controls are pure clutter.
  final bool visible;

  /// Reading-order position used by [OrdinalSortKey].
  final double ordinal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final item = ref.watch(mediaItemProvider).valueOrNull;
    final handler = ref.watch(audioHandlerProvider);
    final playing = ref.watch(isPlayingProvider);
    final enabled = ref.watch(transportEnabledProvider);

    if (item == null || !visible) {
      return const SizedBox(height: 4);
    }

    final engine = A11yEngine(l10n, View.of(context));
    final rawArtist = item.artist;
    final artist =
        (rawArtist == null || rawArtist.isEmpty) ? l10n.unknownArtist : rawArtist;
    final titleLabel = '${item.title}, by $artist';

    void openNowPlaying() {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const NowPlayingScreen(),
        ),
      );
    }

    Future<void> onPlayPause() async {
      if (playing) {
        await handler.pause();
        engine.announceTrackPaused(item.title, artist);
      } else {
        await handler.play();
        engine.announceTrackPlaying(item.title, artist);
      }
    }

    return Semantics(
      container: true,
      label: titleLabel,
      sortKey: OrdinalSortKey(ordinal),
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        elevation: 8,
        child: SizedBox(
          height: 72,
          child: Row(
            children: <Widget>[
              const SizedBox(width: 8),
              // Tap target on the artwork/title region to expand the player.
              Expanded(
                child: InkWell(
                  excludeFromSemantics: true,
                  onTap: openNowPlaying,
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    children: <Widget>[
                      AlbumArt(
                        label: l10n.albumArt(item.title),
                        artUri: item.artUri,
                        mediaId: item.extras?['mediaId'] as int?,
                        size: 48,
                        borderRadius: 8,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            Text(
                              artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Transport cluster is intrinsically sized so the title column
              // absorbs the shrinkage on narrow screens instead of overflowing:
              // 3 x 48dp targets always fit alongside a 48dp thumbnail.
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  PlayerButton(
                    icon: Icons.skip_previous_rounded,
                    label: l10n.previousButton,
                    onPressed:
                        enabled ? () => unawaited(handler.skipToPrevious()) : null,
                  ),
                  PlayerButton(
                    icon: playing
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    label: playing ? l10n.pauseButton : l10n.playButton,
                    active: playing,
                    iconSize: 28,
                    onPressed: enabled ? onPlayPause : null,
                  ),
                  PlayerButton(
                    icon: Icons.skip_next_rounded,
                    label: l10n.nextButton,
                    onPressed:
                        enabled ? () => unawaited(handler.skipToNext()) : null,
                  ),
                ],
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }
}