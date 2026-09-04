import 'dart:convert';
import 'dart:typed_data';

import 'media_reader.dart';

/// One synchronized line parsed from an LRC-style lyrics block.
class LyricLine {
  const LyricLine(this.time, this.text);

  final Duration time;
  final String text;
}

/// Embedded lyrics: either plain text or a list of timestamped lines.
///
/// [text] and [lines] are mutually exclusive: when at least two `[mm:ss]`
/// timed lines are present the result is [lines] (so the UI can auto-scroll),
/// otherwise everything is [text].
class Lyrics {
  const Lyrics.plain(this.text) : lines = null;

  const Lyrics.timed(this.lines) : text = null;

  final String? text;
  final List<LyricLine>? lines;

  bool get isEmpty {
    final trimmed = text?.trim();
    if (trimmed != null) return trimmed.isEmpty;
    return lines == null || lines!.isEmpty;
  }
}

/// Turns raw lyrics text into [Lyrics], splitting on LRC timestamps when they
/// are present and consistent.
class LyricsParser {
  static final RegExp _timeTag = RegExp(r'^\[(\d{1,2}):(\d{2})(?:[.:](\d{1,3}))?\]');
  static final RegExp _lrcLine =
      RegExp(r'^(\[[0-9:.]+\])+(.*)$');

  static Lyrics parse(String raw) {
    final lines = raw.replaceAll('\r\n', '\n').split('\n');
    final timed = <LyricLine>[];
    final plain = <String>[];

    for (final line in lines) {
      final match = _lrcLine.firstMatch(line);
      if (match == null) {
        if (line.trim().isNotEmpty) plain.add(line.trimRight());
        continue;
      }
      var rest = line;
      var hasTime = false;
      while (rest.isNotEmpty && rest.startsWith('[')) {
        final tag = _timeTag.firstMatch(rest);
        if (tag == null) break;
        hasTime = true;
        final minutes = int.parse(tag.group(1)!);
        final seconds = int.parse(tag.group(2)!);
        final fraction = tag.group(3);
        final ms = switch (fraction) {
          null => 0,
          final f when f.length == 1 => int.parse(f) * 100,
          final f when f.length == 2 => int.parse(f) * 10,
          final f => int.parse(f),
        };
        timed.add(LyricLine(
          Duration(minutes: minutes, seconds: seconds, milliseconds: ms),
          rest.substring(tag.end).trim(),
        ));
        rest = rest.substring(tag.end);
      }
      if (!hasTime) {
        final text = match.group(2)?.trim();
        if (text != null && text.isNotEmpty) plain.add(text);
      }
    }

    if (timed.length >= 2) return Lyrics.timed(timed);
    if (plain.isEmpty) return Lyrics.plain(raw.trim());
    return Lyrics.plain(plain.join('\n'));
  }
}

/// Extracts lyrics embedded in the file's own metadata tags.
///
/// Supported containers:
///  * ID3v2.3/2.4 `USLT` (unsynchronised lyrics) frames in MP3 files.
///  * the `©lyr` metadata atom in MP4/M4A files.
///
/// The parser only looks at the first 512 KiB (both containers keep their tag
/// tables near the start), so reading a whole multi-hundred-MB file is never
/// required.
class EmbeddedLyrics {
  static String? fromBytes(Uint8List prefix) {
    if (prefix.length >= 3 &&
        prefix[0] == 0x49 &&
        prefix[1] == 0x44 &&
        prefix[2] == 0x33) {
      return _id3v2(prefix);
    }
    if (prefix.length >= 8 &&
        prefix[4] == 0x66 &&
        prefix[5] == 0x74 &&
        prefix[6] == 0x79 &&
        prefix[7] == 0x70) {
      return _mp4(prefix);
    }
    return null;
  }

  // --- ID3v2 ---------------------------------------------------------------

  static int _syncsafe(Uint8List b, int i) =>
      (b[i] << 21) | (b[i + 1] << 14) | (b[i + 2] << 7) | b[i + 3];

  static int _be32(Uint8List b, int i) =>
      (b[i] << 24) | (b[i + 1] << 16) | (b[i + 2] << 8) | b[i + 3];

  static String? _id3v2(Uint8List b) {
    if (b.length < 10) return null;
    final major = b[3];
    if (major != 2 && major != 3 && major != 4) return null;
    final flags = b[5];
    final tagSize = _syncsafe(b, 6);
    final tagEnd = (10 + tagSize).clamp(0, b.length);
    if (tagEnd - 10 < 10) return null;

    var contentStart = 10;
    if (flags & 0x40 != 0) {
      // Extended header.
      if (major == 4) {
        final size = _syncsafe(b, contentStart);
        if (size < 6) return null;
        contentStart += size;
      } else {
        final size = _be32(b, contentStart);
        if (size < 6) return null;
        contentStart += 4 + size;
      }
      if (contentStart >= tagEnd) return null;
    }

    var frameData = b.sublist(contentStart, tagEnd);
    if (flags & 0x80 != 0) frameData = _deUnsync(frameData);

    var pos = 0;
    while (pos + 10 <= frameData.length) {
      if (frameData[pos] == 0) break; // padding
      final id = String.fromCharCodes(frameData, pos, pos + 4);
      if (id == 'USLT') {
        final headerSize =
            major == 4 ? _syncsafe(frameData, pos + 4) : _be32(frameData, pos + 4);
        final formatFlags = frameData[pos + 9];
        var dataStart = pos + 10;
        var dataSize = headerSize;
        if (major == 4 && formatFlags & 0x40 != 0) {
          // Data length indicator: skip the 4 syncsafe bytes after the flags.
          if (dataStart + 4 > frameData.length) break;
          dataSize = _syncsafe(frameData, dataStart);
          dataStart += 4;
        }
        if (dataStart + dataSize > frameData.length) {
          dataSize = frameData.length - dataStart;
        }
        if (dataSize < 4) break;
        final lyrics = _decodeUslt(frameData, dataStart, dataSize);
        if (lyrics != null && lyrics.trim().isNotEmpty) return lyrics.trim();
        break;
      }
      if (id.startsWith('\u0000')) {
        break; // zero-padded padding
      }
      final size = major == 4
          ? _syncsafe(frameData, pos + 4)
          : _be32(frameData, pos + 4);
      var next = pos + 10 + size;
      if (next > frameData.length) break;
      pos = next;
    }
    return null;
  }

  /// De-unsynchronisation: `FF 00` -> `FF` (only inside the tag region).
  static Uint8List _deUnsync(Uint8List b) {
    final out = BytesBuilder();
    for (var i = 0; i < b.length; i++) {
      out.addByte(b[i]);
      if (b[i] == 0xFF && i + 1 < b.length && b[i + 1] == 0x00) i++;
    }
    return out.toBytes();
  }

  /// USLT frame payload: encoding byte, language, descriptor, lyrics.
  static String? _decodeUslt(Uint8List b, int start, int size) {
    final end = start + size;
    if (end > b.length || start + 4 > end) return null;
    final encoding = b[start];
    var pos = start + 4; // skip encoding + 3-byte language
    if (pos >= end) return null;
    pos = _skipString(b, pos, end, encoding); // content descriptor
    if (pos < 0 || pos >= end) return null;
    final lyrics = _decodeText(b, pos, end, encoding);
    if (lyrics == null) return null;
    return lyrics.trim().replaceAll('\u0000', '').trim();
  }

  static int _skipString(Uint8List b, int start, int end, int encoding) {
    var i = start;
    if (encoding == 1 || encoding == 2) {
      while (i + 1 < end) {
        if (b[i] == 0 && b[i + 1] == 0) return i + 2;
        i += 2;
      }
      return -1;
    }
    while (i < end) {
      if (b[i] == 0) return i + 1;
      i++;
    }
    return -1;
  }

  static String? _decodeText(Uint8List b, int start, int end, int encoding) {
    switch (encoding) {
      case 0:
        return latin1.decode(b.sublist(start, end));
      case 1:
        return _decodeUtf16(b, start, end);
      case 2:
        return _decodeUtf16Be(b, start, end);
      case 3:
        return utf8.decode(b.sublist(start, end), allowMalformed: true);
      default:
        return null;
    }
  }

  static String _decodeUtf16(Uint8List b, int start, int end) {
    if (end - start >= 2 && b[start] == 0xFF && b[start + 1] == 0xFE) {
      return _utf16WithEndian(b, start + 2, end, false);
    }
    if (end - start >= 2 && b[start] == 0xFE && b[start + 1] == 0xFF) {
      return _utf16WithEndian(b, start + 2, end, true);
    }
    return _utf16WithEndian(b, start, end, true);
  }

  static String _decodeUtf16Be(Uint8List b, int start, int end) =>
      _utf16WithEndian(b, start, end, true);

  static String _utf16WithEndian(Uint8List b, int start, int end, bool be) {
    final units = <int>[];
    var i = start;
    while (i + 1 <= end) {
      final unit = be
          ? (b[i] << 8) | b[i + 1]
          : (b[i + 1] << 8) | b[i];
      if (unit == 0) break;
      units.add(unit);
      i += 2;
    }
    return String.fromCharCodes(units);
  }

  // --- MP4 -----------------------------------------------------------------

  static String? _mp4(Uint8List b) {
    return _findMeta(b, 0, b.length);
  }

  /// Walks MP4 atoms recursively looking for `©lyr` under `moov > udta > meta
  /// > ilst`. Handles 32-bit and 64-bit (size == 1) atom sizes.
  static String? _findMeta(Uint8List b, int start, int end) {
    var pos = start;
    while (pos + 8 <= end) {
      final size32 = _be32(b, pos);
      final type = String.fromCharCodes(b, pos + 4, pos + 8);
      int size;
      int header;
      if (size32 == 1) {
        if (pos + 16 > end) return null;
        final high = _be32(b, pos + 8);
        final low = _be32(b, pos + 12);
        size = high * 0x100000000 + low;
        header = 16;
      } else {
        size = size32;
        header = 8;
      }
      if (size < header || pos + size > end) return null;
      final bodyStart = pos + header;
      final bodyEnd = pos + size;

      if (type == 'moov' || type == 'udta' || type == 'ilst') {
        final found = _findMeta(b, bodyStart, bodyEnd);
        if (found != null) return found;
      } else if (type == 'meta') {
        // meta has a 4-byte version/flags field before its child atoms.
        final found = _findMeta(b, bodyStart + 4, bodyEnd);
        if (found != null) return found;
      } else if (type == '\u00a9lyr') {
        final text = _decodeIlstData(b, bodyStart, bodyEnd);
        if (text != null && text.trim().isNotEmpty) return text.trim();
      }
      pos += size;
    }
    return null;
  }

  static String? _decodeIlstData(Uint8List b, int start, int end) {
    // `data` atom: size + "data" + 1 version byte + 3 flags + 1 type byte.
    var pos = start;
    while (pos + 8 <= end) {
      final size = _be32(b, pos);
      final type = String.fromCharCodes(b, pos + 4, pos + 8);
      if (type != 'data' || size < 16 || pos + size > end) {
        pos += size < 8 ? 8 : size;
        continue;
      }
      final typeCode = b[pos + 12];
      // `data` payload = 1 version + 3 flags + 1 type byte, then the text.
      final payloadStart = pos + 13;
      final payloadEnd = pos + size;
      if (typeCode == 2) {
        // UTF-16BE, null terminated.
        return _utf16WithEndian(b, payloadStart, payloadEnd, true)
            .replaceAll('\u0000', '')
            .trim();
      }
      return utf8
          .decode(b.sublist(payloadStart, payloadEnd), allowMalformed: true)
          .replaceAll('\u0000', '')
          .trim();
    }
    return null;
  }
}

/// Coordinates bounded file reads and parsing for the now-playing screen.
class LyricsService {
  LyricsService({MediaReader? reader}) : _reader = reader ?? MediaReader();

  static const int _probeBytes = 512 * 1024;

  final MediaReader _reader;
  final Map<String, Lyrics?> _cache = <String, Lyrics?>{};

  Future<Lyrics?> lyricsFor(String uri) {
    final cached = _cache[uri];
    if (cached != null || _cache.containsKey(uri)) {
      return Future.value(cached);
    }
    return _load(uri).then((lyrics) {
      _cache[uri] = lyrics;
      return lyrics;
    });
  }

  Future<Lyrics?> _load(String uri) async {
    final prefix = await _reader.readAtMost(uri, 0, _probeBytes);
    if (prefix == null || prefix.isEmpty) return null;
    final embedded = EmbeddedLyrics.fromBytes(prefix);
    if (embedded == null || embedded.trim().isEmpty) return null;
    final parsed = LyricsParser.parse(embedded);
    return parsed.isEmpty ? null : parsed;
  }
}

/// App-wide lyrics service; caches parsed results per URI for the session so
/// switching back to a track never re-reads its file.
final LyricsService lyricsService = LyricsService();
