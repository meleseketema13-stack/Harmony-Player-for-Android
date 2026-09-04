import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../state/audio_providers.dart';
import '../screens/now_playing_screen.dart';
import '../widgets/player_controls.dart';
import 'album_art.dart';

/// Compact, persistent now-playing bar with streamlined controls.
///
/// Shows: artwork + title/artist + Play/Pause + Next/Previous.
/// Tapping the artwork/title region opens the full now-playing screen.
///
/// Focus-preservation contract: this widget is always mounted at the *same
/// tree position* (the bottom of the shell's `Column`) on every breakpoint.
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key, this.visible = true});

  /// When false, renders a zero-height spacer to maintain tree position
  /// without exposing any semantics to screen readers.
  final bool visible;

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
      } else {
        await handler.play();
      }
    }

    return Semantics(
      container: true,
      label: titleLabel,
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        elevation: 3,
        child: SizedBox(
          height: 64,
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
              const SizedBox(width: 4),
              // Streamlined transport: Previous / Play-Pause / Next
              PlayerButton(
                icon: Icons.skip_previous_rounded,
                label: l10n.previousButton,
                onPressed:
                    enabled ? () => unawaited(handler.skipToPrevious()) : null,
              ),
              PlayerButton(
                icon: playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                label: playing ? l10n.pauseButton : l10n.playButton,
                iconSize: 28,
                toggled: playing,
                onPressed: enabled ? onPlayPause : null,
              ),
              PlayerButton(
                icon: Icons.skip_next_rounded,
                label: l10n.nextButton,
                onPressed:
                    enabled ? () => unawaited(handler.skipToNext()) : null,
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }
}
