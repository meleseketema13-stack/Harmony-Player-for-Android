import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../a11y/a11y_engine.dart';
import '../../audio/track_store.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../state/audio_providers.dart';
import '../widgets/accessible_seek_bar.dart';
import '../widgets/album_art.dart';
import '../widgets/lyrics_view.dart';
import '../widgets/player_controls.dart';
import '../widgets/player_nav_bar.dart';

/// Full-screen now-playing view (used on compact and medium viewports).
class NowPlayingScreen extends ConsumerWidget {
  const NowPlayingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final item = ref.watch(mediaItemProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.nowPlaying)),
      body: SafeArea(
        child: item == null
            ? _EmptyState(l10n: l10n)
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: NowPlayingContent(showTransport: true),
              ),
      ),
    );
  }
}

/// Hero now-playing pane used by the Expanded (>= 840dp) layout. Intentionally
/// contains no transport buttons — those stay in the persistent [PlayerNavBar]
/// so no duplicate Play/Pause nodes exist in the semantics tree.
class NowPlayingPanel extends ConsumerWidget {
  const NowPlayingPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = ref.watch(mediaItemProvider).valueOrNull;
    if (item == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
              child: NowPlayingContent(showTransport: false),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shared player body: art, metadata, seek bar, secondary controls, lyrics.
class NowPlayingContent extends ConsumerWidget {
  const NowPlayingContent({super.key, required this.showTransport});

  final bool showTransport;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final handler = ref.watch(audioHandlerProvider);
    final l10n = AppLocalizations.of(context);
    final engine = A11yEngine(l10n, View.of(context));
    final item = ref.watch(mediaItemProvider).valueOrNull;
    final position =
        ref.watch(positionProvider).valueOrNull ?? Duration.zero;
    final loadedDuration = ref.watch(trackDurationProvider).valueOrNull;
    final duration = loadedDuration ?? item?.duration ?? Duration.zero;
    final enabled = ref.watch(transportEnabledProvider);
    final jumpSeconds = ref.watch(seekIntervalProvider).valueOrNull ??
        TrackStore.defaultSeekIntervalSeconds;

    final rawArtist = item?.artist;
    final artist = (rawArtist == null || rawArtist.isEmpty)
        ? l10n.unknownArtist
        : rawArtist;

    void announceSeek() {
      if (duration > Duration.zero) {
        final percent =
            (position.inMilliseconds / duration.inMilliseconds * 100).round();
        engine.announceSeek(percent.clamp(0, 100));
      }
    }

    final customActions = engine.secondaryActions(
      jumpSeconds: jumpSeconds,
      onJumpForward: () => unawaited(handler.jumpForward()),
      onJumpBackward: () => unawaited(handler.jumpBackward()),
      onToggleFavorite: () async {
        final on = await handler.toggleFavorite();
        engine.announceFavorite(on);
      },
      onAddToPlaylist: () async {
        await handler.addToPlaylist();
        engine.announceAddedToPlaylist();
      },
      onToggleShuffle: () async {
        final shuffleOn = ref.read(shuffleModeProvider) ==
            AudioServiceShuffleMode.all;
        await handler.setShuffleMode(
          shuffleOn ? AudioServiceShuffleMode.none : AudioServiceShuffleMode.all,
        );
        engine.announceShuffle(!shuffleOn);
      },
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Center(
          child: AlbumArt(
            label: item == null ? '' : l10n.albumArt(item.title),
            artUri: item?.artUri,
            mediaId: item?.extras?['mediaId'] as int?,
            size: 240,
          ),
        ),
        const SizedBox(height: 24),
        Semantics(
          container: true,
          label: item == null
              ? l10n.unknownTrack
              : '${item.title}, by $artist',
          excludeSemantics: true,
          child: Column(
            children: <Widget>[
              Text(
                item?.title ?? l10n.unknownTrack,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                artist,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(engine.formatDuration(position),
                style: Theme.of(context).textTheme.labelMedium),
            Text(engine.formatDuration(duration),
                style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
        const SizedBox(height: 4),
        AccessibleSeekBar(
          position: position,
          duration: duration,
          enabled: enabled && duration > Duration.zero,
          jump: Duration(seconds: jumpSeconds),
          onSeek: (pos) => unawaited(handler.seek(pos)),
          onSeekStart: announceSeek,
          onSeekEnd: announceSeek,
          customActions: customActions,
        ),
        const SizedBox(height: 16),
        if (showTransport) ...<Widget>[
          const TransportControls(prominent: true),
          const SizedBox(height: 8),
        ],
        const SecondaryControls(),
        const SizedBox(height: 32),
        const LyricsView(),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          l10n.emptyLibrary,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
