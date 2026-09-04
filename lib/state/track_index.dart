import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../audio/harmony_audio_handler.dart';

/// Single shared [OnAudioQuery] instance. The plugin is a stateless facade
/// over the platform channels, so one instance is reused for the whole app.
final OnAudioQuery audioQuery = OnAudioQuery();

/// State of the on-device track index.
sealed class TrackIndexState {
  const TrackIndexState();
}

/// First scan is still running.
class TrackIndexLoading extends TrackIndexState {
  const TrackIndexLoading();
}

/// The library is indexed and [tracks] is ready for display.
class TrackIndexReady extends TrackIndexState {
  const TrackIndexReady(this.tracks);

  final List<LocalTrack> tracks;
}

/// The user denied the audio permission.
class TrackIndexDenied extends TrackIndexState {
  const TrackIndexDenied();
}

/// The scan failed (e.g. no MediaStore available on the platform).
class TrackIndexError extends TrackIndexState {
  const TrackIndexError(this.message);

  final String message;
}

/// A folder entry with its name, path and track count.
class FolderEntry {
  const FolderEntry({required this.name, required this.path, required this.count});
  final String name;
  final String path;
  final int count;
}

/// An album entry with album name, artist, and track count.
class AlbumEntry {
  const AlbumEntry({required this.id, required this.album, required this.artist, required this.count});
  final int id;
  final String album;
  final String? artist;
  final int count;
}

/// An artist entry with artist name and track count.
class ArtistEntry {
  const ArtistEntry({required this.id, required this.artist, required this.count});
  final int id;
  final String artist;
  final int count;
}

/// A genre entry with genre name and track count.
class GenreEntry {
  const GenreEntry({required this.id, required this.genre, required this.count});
  final int id;
  final String genre;
  final int count;
}

/// Scans the on-device MediaStore / MPMediaQuery library once and maps the
/// results to [LocalTrack]s. Watched by both the Library and Search pages so a
/// single scan feeds both.
class TrackIndex extends Notifier<TrackIndexState> {
  @override
  TrackIndexState build() {
    _load();
    return const TrackIndexLoading();
  }

  Future<void> _load() async {
    try {
      final granted = await audioQuery.permissionsStatus();
      if (!granted) {
        state = const TrackIndexDenied();
        return;
      }
      final songs = await audioQuery.querySongs(
        sortType: SongSortType.TITLE,
        orderType: OrderType.ASC_OR_SMALLER,
        ignoreCase: true,
      );
      state = TrackIndexReady(
        List<LocalTrack>.unmodifiable(
          <LocalTrack>[for (final s in songs) _toLocalTrack(s)],
        ),
      );
    } catch (error) {
      state = TrackIndexError('$error');
    }
  }

  /// Prompts for audio access (used by the permission-denied state).
  Future<void> requestPermission() async {
    final granted = await audioQuery.checkAndRequest();
    if (granted) {
      await _load();
    } else {
      state = const TrackIndexDenied();
    }
  }

  /// Re-runs the scan (pull-to-refresh).
  Future<void> refresh() => _load();

  /// Groups tracks by their parent folder path.
  List<FolderEntry> folders() {
    final ready = state;
    if (ready is! TrackIndexReady) return const <FolderEntry>[];
    final map = <String, int>{};
    for (final t in ready.tracks) {
      final uri = Uri.tryParse(t.path);
      String dir;
      if (uri != null && uri.hasScheme) {
        // For content:// URIs, try to extract a usable directory segment
        final segments = uri.pathSegments;
        if (segments.length >= 2) {
          dir = segments[segments.length - 2];
        } else {
          dir = '/';
        }
      } else {
        dir = File(t.path).parent.path;
      }
      map[dir] = (map[dir] ?? 0) + 1;
    }
    final entries = <FolderEntry>[
      for (final e in map.entries)
        FolderEntry(name: e.key.split(Platform.pathSeparator).last, path: e.key, count: e.value),
    ];
    entries.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return entries;
  }

  /// Returns tracks within a specific folder path.
  List<LocalTrack> tracksInFolder(String folderPath) {
    final ready = state;
    if (ready is! TrackIndexReady) return const <LocalTrack>[];
    return ready.tracks.where((t) {
      final uri = Uri.tryParse(t.path);
      if (uri != null && uri.hasScheme) {
        final segments = uri.pathSegments;
        if (segments.length >= 2) {
          return segments[segments.length - 2] ==
              folderPath.split(Platform.pathSeparator).last;
        }
        return false;
      }
      return File(t.path).parent.path == folderPath;
    }).toList();
  }

  /// Groups tracks by album.
  List<AlbumEntry> albums() {
    final ready = state;
    if (ready is! TrackIndexReady) return const <AlbumEntry>[];
    final map = <String, _AlbumGroup>{};
    for (final t in ready.tracks) {
      final album = t.album ?? 'Unknown Album';
      final existing = map[album];
      if (existing != null) {
        existing.count++;
      } else {
        map[album] = _AlbumGroup(album: album, artist: t.artist);
      }
    }
    final entries = <AlbumEntry>[
      for (final e in map.entries)
        AlbumEntry(id: e.key.hashCode, album: e.value.album, artist: e.value.artist, count: e.value.count),
    ];
    entries.sort((a, b) => a.album.toLowerCase().compareTo(b.album.toLowerCase()));
    return entries;
  }

  /// Returns tracks in a specific album.
  List<LocalTrack> tracksInAlbum(String album) {
    final ready = state;
    if (ready is! TrackIndexReady) return const <LocalTrack>[];
    return ready.tracks.where((t) => (t.album ?? 'Unknown Album') == album).toList();
  }

  /// Groups tracks by artist.
  List<ArtistEntry> artists() {
    final ready = state;
    if (ready is! TrackIndexReady) return const <ArtistEntry>[];
    final map = <String, int>{};
    for (final t in ready.tracks) {
      map[t.artist] = (map[t.artist] ?? 0) + 1;
    }
    final entries = <ArtistEntry>[
      for (final e in map.entries)
        ArtistEntry(id: e.key.hashCode, artist: e.key, count: e.value),
    ];
    entries.sort((a, b) => a.artist.toLowerCase().compareTo(b.artist.toLowerCase()));
    return entries;
  }

  /// Returns tracks by a specific artist.
  List<LocalTrack> tracksByArtist(String artist) {
    final ready = state;
    if (ready is! TrackIndexReady) return const <LocalTrack>[];
    return ready.tracks.where((t) => t.artist == artist).toList();
  }

  /// Returns playlist entries from on_audio_query.
  Future<List<PlaylistInfo>> playlists() async {
    try {
      final raw = await audioQuery.queryPlaylists();
      return raw.map((p) => PlaylistInfo(id: p.id, name: p.playlist)).toList();
    } catch (_) {
      return const <PlaylistInfo>[];
    }
  }

  /// Returns tracks in a specific playlist.
  Future<List<LocalTrack>> tracksInPlaylist(int playlistId) async {
    try {
      final raw = await audioQuery.queryAudiosFrom(
        AudiosFromType.PLAYLIST,
        playlistId,
      );
      return raw.map(_toLocalTrack).toList();
    } catch (_) {
      return const <LocalTrack>[];
    }
  }

  static LocalTrack _toLocalTrack(SongModel song) {
    final rawUri = song.uri;
    final path = (rawUri != null && rawUri.isNotEmpty) ? rawUri : song.data;
    final title = song.title.trim().isEmpty ? song.displayNameWOExt : song.title;
    final artist = _nonEmpty(song.artist);
    final album = _nonEmpty(song.album);
    return LocalTrack(
      id: 'song-${song.id}',
      path: path,
      title: title,
      artist: artist ?? 'Unknown Artist',
      album: album,
      duration: Duration(milliseconds: song.duration ?? 0),
      mediaId: song.id,
      artUri: song.albumId != null
          ? Uri.parse(
              'content://media/external/audio/albumart/${song.albumId}',
            )
          : null,
    );
  }

  static String? _nonEmpty(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return value.trim();
  }
}

class _AlbumGroup {
  _AlbumGroup({required this.album, required this.artist});
  final String album;
  final String? artist;
  int count = 1;
}

/// Simple playlist info from on_audio_query.
class PlaylistInfo {
  const PlaylistInfo({required this.id, required this.name});
  final int id;
  final String name;
}

final trackIndexProvider =
    NotifierProvider<TrackIndex, TrackIndexState>(TrackIndex.new);

/// Album artwork for a MediaStore / MPMediaQuery id, decoded from bytes.
final trackArtworkProvider = FutureProvider.family<Uint8List?, int>(
  (ref, mediaId) => audioQuery.queryArtwork(mediaId, ArtworkType.AUDIO),
);
