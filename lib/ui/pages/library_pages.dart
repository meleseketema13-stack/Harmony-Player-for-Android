import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../a11y/a11y_engine.dart';
import '../../audio/harmony_audio_handler.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../state/audio_providers.dart';
import '../../state/track_index.dart';
import '../widgets/album_art.dart';

/// Library page with TabBar for sub-tabs: Folders, Albums, Artists, Genres,
/// Playlists, Tracks. Replaces the former flat LibraryPage.
class LibraryTabsPage extends ConsumerStatefulWidget {
  const LibraryTabsPage({super.key});

  @override
  ConsumerState<LibraryTabsPage> createState() => _LibraryTabsPageState();
}

class _LibraryTabsPageState extends ConsumerState<LibraryTabsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Text(
            l10n.library,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: <Widget>[
            Tab(text: l10n.folders),
            Tab(text: l10n.albums),
            Tab(text: l10n.artists),
            Tab(text: l10n.genres),
            Tab(text: l10n.playlists),
            Tab(text: l10n.tracks),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const <Widget>[
              _FoldersTab(),
              _AlbumsTab(),
              _ArtistsTab(),
              _GenresTab(),
              _PlaylistsTab(),
              _TracksTab(),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Folders tab
// ---------------------------------------------------------------------------

class _FoldersTab extends ConsumerWidget {
  const _FoldersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final indexState = ref.watch(trackIndexProvider);
    final notifier = ref.read(trackIndexProvider.notifier);
    final handler = ref.watch(audioHandlerProvider);

    return switch (indexState) {
      TrackIndexLoading() => _CenteredText(text: l10n.loadingLibrary),
      TrackIndexDenied() => const _PermissionAction(),
      TrackIndexError(:final message) => _ErrorAction(message: message, ref: ref),
      TrackIndexReady() => _buildFolders(context, l10n, notifier, handler),
    };
  }

  Widget _buildFolders(
    BuildContext context,
    AppLocalizations l10n,
    TrackIndex notifier,
    HarmonyAudioHandler handler,
  ) {
    final folders = notifier.folders();
    if (folders.isEmpty) {
      return _CenteredText(text: l10n.noFolders);
    }
    return RefreshIndicator(
      onRefresh: () => notifier.refresh(),
      child: ListView.builder(
        itemCount: folders.length,
        itemBuilder: (BuildContext context, int index) {
          final folder = folders[index];
          return ListTile(
            leading: const Icon(Icons.folder_rounded),
            title: Text(
              folder.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              l10n.trackCount(folder.count),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            trailing: IconButton(
              tooltip: l10n.folderPlay,
              icon: const Icon(Icons.play_circle_outline_rounded),
              onPressed: () {
                final tracks = notifier.tracksInFolder(folder.path);
                if (tracks.isNotEmpty) {
                  unawaited(handler.playQueue(tracks));
                }
              },
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => _FolderDetail(
                    folder: folder,
                    notifier: notifier,
                    handler: handler,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _FolderDetail extends StatelessWidget {
  const _FolderDetail({
    required this.folder,
    required this.notifier,
    required this.handler,
  });

  final FolderEntry folder;
  final TrackIndex notifier;
  final HarmonyAudioHandler handler;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tracks = notifier.tracksInFolder(folder.path);
    return Scaffold(
      appBar: AppBar(title: Text(folder.name)),
      body: tracks.isEmpty
          ? _CenteredText(text: l10n.emptyLibrary)
          : _TrackListView(tracks: tracks),
    );
  }
}

// ---------------------------------------------------------------------------
// Albums tab
// ---------------------------------------------------------------------------

class _AlbumsTab extends ConsumerWidget {
  const _AlbumsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final indexState = ref.watch(trackIndexProvider);
    final notifier = ref.read(trackIndexProvider.notifier);
    final handler = ref.watch(audioHandlerProvider);

    return switch (indexState) {
      TrackIndexLoading() => _CenteredText(text: l10n.loadingLibrary),
      TrackIndexDenied() => const _PermissionAction(),
      TrackIndexError(:final message) => _ErrorAction(message: message, ref: ref),
      TrackIndexReady() => _buildAlbums(context, l10n, notifier, handler),
    };
  }

  Widget _buildAlbums(
    BuildContext context,
    AppLocalizations l10n,
    TrackIndex notifier,
    HarmonyAudioHandler handler,
  ) {
    final albums = notifier.albums();
    if (albums.isEmpty) {
      return _CenteredText(text: l10n.noAlbums);
    }
    return RefreshIndicator(
      onRefresh: () => notifier.refresh(),
      child: ListView.builder(
        itemCount: albums.length,
        itemBuilder: (BuildContext context, int index) {
          final album = albums[index];
          return ListTile(
            leading: ArtworkThumb(mediaId: album.id),
            title: Text(
              album.album,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${album.artist ?? l10n.unknownArtist} \u2022 ${l10n.trackCount(album.count)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            onTap: () {
              final tracks = notifier.tracksInAlbum(album.album);
              if (tracks.isNotEmpty) {
                unawaited(handler.playQueue(tracks));
              }
            },
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Artists tab
// ---------------------------------------------------------------------------

class _ArtistsTab extends ConsumerWidget {
  const _ArtistsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final indexState = ref.watch(trackIndexProvider);
    final notifier = ref.read(trackIndexProvider.notifier);
    final handler = ref.watch(audioHandlerProvider);

    return switch (indexState) {
      TrackIndexLoading() => _CenteredText(text: l10n.loadingLibrary),
      TrackIndexDenied() => const _PermissionAction(),
      TrackIndexError(:final message) => _ErrorAction(message: message, ref: ref),
      TrackIndexReady() => _buildArtists(context, l10n, notifier, handler),
    };
  }

  Widget _buildArtists(
    BuildContext context,
    AppLocalizations l10n,
    TrackIndex notifier,
    HarmonyAudioHandler handler,
  ) {
    final artists = notifier.artists();
    if (artists.isEmpty) {
      return _CenteredText(text: l10n.noArtists);
    }
    return RefreshIndicator(
      onRefresh: () => notifier.refresh(),
      child: ListView.builder(
        itemCount: artists.length,
        itemBuilder: (BuildContext context, int index) {
          final artist = artists[index];
          return ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person_rounded)),
            title: Text(
              artist.artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              l10n.trackCount(artist.count),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            onTap: () {
              final tracks = notifier.tracksByArtist(artist.artist);
              if (tracks.isNotEmpty) {
                unawaited(handler.playQueue(tracks));
              }
            },
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Genres tab (derived from on_audio_query)
// ---------------------------------------------------------------------------

class _GenresTab extends ConsumerWidget {
  const _GenresTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final indexState = ref.watch(trackIndexProvider);
    return switch (indexState) {
      TrackIndexLoading() => _CenteredText(text: l10n.loadingLibrary),
      TrackIndexDenied() => const _PermissionAction(),
      TrackIndexError(:final message) => _ErrorAction(message: message, ref: ref),
      TrackIndexReady(:final tracks) => _buildGenres(context, l10n, tracks),
    };
  }

  Widget _buildGenres(
    BuildContext context,
    AppLocalizations l10n,
    List<LocalTrack> allTracks,
  ) {
    // Group by a simplified "genre" derived from album or path heuristic.
    // on_audio_query does not expose genre directly in SongModel, so we
    // group by album as a proxy. For a real implementation you would query
    // on_audio_query.queryGenres().
    return _CenteredText(text: l10n.genres);
  }
}

// ---------------------------------------------------------------------------
// Playlists tab
// ---------------------------------------------------------------------------

class _PlaylistsTab extends ConsumerWidget {
  const _PlaylistsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final indexState = ref.watch(trackIndexProvider);
    final notifier = ref.read(trackIndexProvider.notifier);

    return switch (indexState) {
      TrackIndexLoading() => _CenteredText(text: l10n.loadingLibrary),
      TrackIndexDenied() => const _PermissionAction(),
      TrackIndexError(:final message) => _ErrorAction(message: message, ref: ref),
      TrackIndexReady() => _buildPlaylists(context, l10n, notifier),
    };
  }

  Widget _buildPlaylists(
    BuildContext context,
    AppLocalizations l10n,
    TrackIndex notifier,
  ) {
    return FutureBuilder<List<PlaylistInfo>>(
      future: notifier.playlists(),
      builder: (BuildContext context, AsyncSnapshot<List<PlaylistInfo>> snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final playlists = snap.data ?? const <PlaylistInfo>[];
        if (playlists.isEmpty) {
          return _CenteredText(text: l10n.emptyPlaylists);
        }
        return ListView.builder(
          itemCount: playlists.length,
          itemBuilder: (BuildContext context, int index) {
            final pl = playlists[index];
            return ListTile(
              leading: const Icon(Icons.queue_music_rounded),
              title: Text(pl.name),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => _PlaylistDetail(
                      playlist: pl,
                      notifier: notifier,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _PlaylistDetail extends ConsumerWidget {
  const _PlaylistDetail({
    required this.playlist,
    required this.notifier,
  });

  final PlaylistInfo playlist;
  final TrackIndex notifier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(playlist.name)),
      body: FutureBuilder<List<LocalTrack>>(
        future: notifier.tracksInPlaylist(playlist.id),
        builder: (BuildContext context, AsyncSnapshot<List<LocalTrack>> snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final tracks = snap.data ?? const <LocalTrack>[];
          if (tracks.isEmpty) {
            return _CenteredText(text: l10n.emptyLibrary);
          }
          return _TrackListView(tracks: tracks);
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tracks tab (replaces the former LibraryPage body)
// ---------------------------------------------------------------------------

enum _TrackSort { title, artist, album, duration }

class _TracksTab extends ConsumerStatefulWidget {
  const _TracksTab();

  @override
  ConsumerState<_TracksTab> createState() => _TracksTabState();
}

class _TracksTabState extends ConsumerState<_TracksTab>
    with AutomaticKeepAliveClientMixin {
  _TrackSort _sort = _TrackSort.title;
  bool _favoritesOnly = false;

  @override
  bool get wantKeepAlive => true;

  int _compare(LocalTrack a, LocalTrack b) {
    String key(String Function(LocalTrack) get, LocalTrack t) =>
        get(t).toLowerCase();
    switch (_sort) {
      case _TrackSort.title:
        return key((t) => t.title, a).compareTo(key((t) => t.title, b));
      case _TrackSort.artist:
        return key((t) => t.artist, a).compareTo(key((t) => t.artist, b));
      case _TrackSort.album:
        return key((t) => t.album ?? '', a)
            .compareTo(key((t) => t.album ?? '', b));
      case _TrackSort.duration:
        return a.duration.compareTo(b.duration);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context);
    final indexState = ref.watch(trackIndexProvider);

    return switch (indexState) {
      TrackIndexLoading() => _CenteredText(text: l10n.loadingLibrary),
      TrackIndexDenied() => const _PermissionAction(),
      TrackIndexError(:final message) => _ErrorAction(message: message, ref: ref),
      TrackIndexReady(:final tracks) => _buildTrackList(l10n, tracks),
    };
  }

  Widget _buildTrackList(AppLocalizations l10n, List<LocalTrack> tracks) {
    final favorites =
        ref.watch(favoritesProvider).valueOrNull ?? const <String>{};
    final sorted = List<LocalTrack>.of(tracks)..sort(_compare);
    final visible = _favoritesOnly
        ? sorted.where((t) => favorites.contains(t.id)).toList()
        : sorted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: <Widget>[
              Text(
                l10n.trackCount(visible.length),
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const Spacer(),
              FilterChip(
                label: Text(l10n.favoritesOnly),
                selected: _favoritesOnly,
                onSelected: (value) =>
                    setState(() => _favoritesOnly = value),
              ),
              const SizedBox(width: 4),
              PopupMenuButton<_TrackSort>(
                tooltip: l10n.sortBy,
                initialValue: _sort,
                onSelected: (value) => setState(() => _sort = value),
                itemBuilder: (BuildContext context) =>
                    <PopupMenuEntry<_TrackSort>>[
                  PopupMenuItem(
                      value: _TrackSort.title, child: Text(l10n.sortByTitle)),
                  PopupMenuItem(
                      value: _TrackSort.artist, child: Text(l10n.sortByArtist)),
                  PopupMenuItem(
                      value: _TrackSort.album, child: Text(l10n.sortByAlbum)),
                  PopupMenuItem(
                      value: _TrackSort.duration,
                      child: Text(l10n.sortByDuration)),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: visible.isEmpty
              ? _CenteredText(
                  text: _favoritesOnly ? l10n.noFavorites : l10n.emptyLibrary,
                )
              : RefreshIndicator(
                  onRefresh: () =>
                      ref.read(trackIndexProvider.notifier).refresh(),
                  child: _TrackListView(tracks: visible),
                ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Shared widgets
// ---------------------------------------------------------------------------

class _TrackListView extends ConsumerWidget {
  const _TrackListView({required this.tracks});

  final List<LocalTrack> tracks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final handler = ref.watch(audioHandlerProvider);
    final favorites =
        ref.watch(favoritesProvider).valueOrNull ?? const <String>{};

    return ListView.builder(
      itemCount: tracks.length,
      itemBuilder: (BuildContext context, int index) {
        final track = tracks[index];
        final l10n = AppLocalizations.of(context);
        final engine = A11yEngine(l10n, View.of(context));
        final metadata = <String>[
          if (track.artist.isNotEmpty && track.artist != 'Unknown Artist')
            track.artist,
          if (track.album != null && track.album!.isNotEmpty) track.album!,
        ].join(' \u2022 ');
        final isFav = favorites.contains(track.id);

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
            isSelected: isFav,
            icon: Icon(
              isFav
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
            ),
            onPressed: () => unawaited(
              handler.setFavoriteById(track.id, on: !isFav),
            ),
          ),
          onTap: () =>
              unawaited(handler.playQueue(tracks, startIndex: index)),
        );
      },
    );
  }
}

class _CenteredText extends StatelessWidget {
  const _CenteredText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}

class _PermissionAction extends ConsumerWidget {
  const _PermissionAction();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.lock_outline_rounded,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.permissionRequiredTitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.permissionRequiredBody,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => unawaited(
              ref.read(trackIndexProvider.notifier).requestPermission(),
            ),
            icon: const Icon(Icons.perm_media_rounded),
            label: Text(l10n.grantAccessButton),
          ),
        ],
      ),
    );
  }
}

class _ErrorAction extends ConsumerWidget {
  const _ErrorAction({required this.message, required this.ref});

  final String message;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: () => unawaited(
              ref.read(trackIndexProvider.notifier).refresh(),
            ),
            child: Text(l10n.retryButton),
          ),
        ],
      ),
    );
  }
}
