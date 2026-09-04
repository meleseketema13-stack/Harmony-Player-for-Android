import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../a11y/a11y_engine.dart';
import '../../audio/harmony_audio_handler.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../state/audio_providers.dart';
import '../../state/track_index.dart';
import '../widgets/album_art.dart';

/// Dedicated favorites list page shown as a main tab.
class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final indexState = ref.watch(trackIndexProvider);
    final favorites =
        ref.watch(favoritesProvider).valueOrNull ?? const <String>{};
    final handler = ref.watch(audioHandlerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            l10n.favorites,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            l10n.trackCount(favorites.length),
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
        Expanded(
          child: switch (indexState) {
            TrackIndexLoading() => _loading(l10n),
            TrackIndexDenied() => _denied(ref, l10n),
            TrackIndexError(:final message) => _error(message, ref, l10n),
            TrackIndexReady(:final tracks) => _buildFavorites(
                context, ref, l10n, handler, tracks, favorites),
          },
        ),
      ],
    );
  }

  Widget _buildFavorites(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    HarmonyAudioHandler handler,
    List<LocalTrack> allTracks,
    Set<String> favorites,
  ) {
    final favTracks =
        allTracks.where((t) => favorites.contains(t.id)).toList();
    if (favTracks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l10n.noFavorites,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }
    return ListView.builder(
      itemCount: favTracks.length,
      itemBuilder: (BuildContext context, int index) {
        final track = favTracks[index];
        return _FavTile(
          track: track,
          onPlay: () =>
              unawaited(handler.playQueue(favTracks, startIndex: index)),
          onRemove: () => unawaited(
            handler.setFavoriteById(track.id, on: false),
          ),
        );
      },
    );
  }

  Widget _loading(AppLocalizations l10n) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(l10n.loadingLibrary),
          ],
        ),
      );

  Widget _denied(WidgetRef ref, AppLocalizations l10n) => Center(
        child: FilledButton.icon(
          onPressed: () => unawaited(
            ref.read(trackIndexProvider.notifier).requestPermission(),
          ),
          icon: const Icon(Icons.perm_media_rounded),
          label: Text(l10n.grantAccessButton),
        ),
      );

  Widget _error(String message, WidgetRef ref, AppLocalizations l10n) =>
      Center(
        child: FilledButton.tonal(
          onPressed: () => unawaited(
            ref.read(trackIndexProvider.notifier).refresh(),
          ),
          child: Text(l10n.retryButton),
        ),
      );
}

class _FavTile extends StatelessWidget {
  const _FavTile({
    required this.track,
    required this.onPlay,
    required this.onRemove,
  });

  final LocalTrack track;
  final VoidCallback onPlay;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final engine = A11yEngine(l10n, View.of(context));
    final metadata = <String>[
      if (track.artist.isNotEmpty && track.artist != 'Unknown Artist')
        track.artist,
      if (track.album != null && track.album!.isNotEmpty) track.album!,
    ].join(' \u2022 ');

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: ArtworkThumb(mediaId: track.mediaId),
      title: Text(
        track.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (metadata.isNotEmpty)
            Text(
              metadata,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          Text(
            engine.formatDuration(track.duration),
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
      trailing: IconButton(
        tooltip: l10n.favoriteButton,
        icon: const Icon(Icons.favorite_rounded),
        onPressed: onRemove,
      ),
      onTap: onPlay,
    );
  }
}
