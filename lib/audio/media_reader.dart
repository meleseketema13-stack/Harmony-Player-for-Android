import 'dart:io';

import 'package:flutter/services.dart';

/// Bounded reads of local media bytes so metadata that is not exposed by the
/// platform media store (embedded lyrics) can be parsed in Dart.
///
/// Content URIs (scoped storage on Android 10+) cannot be opened with [File],
/// so the Android side resolves them through the ContentResolver via a small
/// MethodChannel. Plain file paths are read directly. Only the requested byte
/// ranges are ever transferred, so multi-hundred-MB files never load fully.
class MediaReader {
  MediaReader();

  static const MethodChannel _channel =
      MethodChannel('com.harmonyplayer.harmony_player/media');

  /// Caches one read per (uri, range) so the platform channel is hit at most
  /// once per track per session (lyrics parsing re-reads are free).
  final Map<String, Uint8List?> _cache = <String, Uint8List?>{};

  String _key(String uri, int start, int? length) =>
      '$uri#$start#${length ?? 'eof'}';

  Future<Uint8List?> readRange(
    String uri, {
    int start = 0,
    int? length,
  }) {
    final key = _key(uri, start, length);
    if (_cache.containsKey(key)) return Future.value(_cache[key]);
    return _read(uri, start, length).then((bytes) {
      _cache[key] = bytes;
      return bytes;
    });
  }

  /// Reads up to [length] bytes starting at [start], clamped to the file size.
  Future<Uint8List?> readAtMost(
    String uri,
    int start,
    int length,
  ) async {
    final bytes = await readRange(uri, start: start, length: length);
    return bytes == null || bytes.isEmpty ? null : bytes;
  }

  Future<Uint8List?> _read(String uri, int start, int? length) async {
    final parsed = Uri.tryParse(uri);
    if (parsed != null && parsed.isScheme('content')) {
      try {
        return await _channel.invokeMethod<Uint8List>(
          'readFile',
          <String, Object>{
            'uri': uri,
            'start': start,
            'length': ?length,
          },
        );
      } on PlatformException {
        return null;
      } on MissingPluginException {
        return null;
      }
    }
    final path = parsed != null && parsed.isScheme('file')
        ? parsed.toFilePath()
        : uri;
    final file = File(path);
    if (!file.existsSync()) return null;
    try {
      final raf = file.openSync();
      try {
        final total = raf.lengthSync();
        final clampedStart = start < total ? start : total;
        var read = length ?? total - clampedStart;
        if (clampedStart + read > total) read = total - clampedStart;
        if (read <= 0) return Uint8List(0);
        raf.setPositionSync(clampedStart);
        final bytes = raf.readSync(read);
        return Uint8List.fromList(bytes);
      } finally {
        raf.closeSync();
      }
    } on FileSystemException {
      return null;
    }
  }
}
