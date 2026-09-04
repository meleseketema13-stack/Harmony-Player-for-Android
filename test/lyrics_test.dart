import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:harmony_player/audio/lyrics.dart';

void main() {
  group('LyricsParser', () {
    test('keeps plain text as-is', () {
      final lyrics = LyricsParser.parse('Line one\nLine two\nLine three');
      expect(lyrics.lines, isNull);
      expect(lyrics.text, 'Line one\nLine two\nLine three');
    });

    test('parses LRC timestamps into timed lines', () {
      final lyrics = LyricsParser.parse(
        '[00:12.50]First verse\n[00:20.00]Second line\n[00:35]Third line',
      );
      expect(lyrics.text, isNull);
      final lines = lyrics.lines!;
      expect(lines, hasLength(3));
      expect(lines[0].time, const Duration(milliseconds: 12500));
      expect(lines[0].text, 'First verse');
      expect(lines[1].time, const Duration(seconds: 20));
      expect(lines[2].time, const Duration(seconds: 35));
    });

    test('drops metadata tags from timed output', () {
      final lyrics = LyricsParser.parse(
        '[ti:Some Song]\n[00:01.00]A\n[00:02.00]B',
      );
      expect(lyrics.lines, hasLength(2));
    });

    test('a single timed line falls back to plain text', () {
      final lyrics = LyricsParser.parse('[00:05.00]Only line');
      expect(lyrics.lines, isNull);
      expect(lyrics.text, isNotNull);
    });
  });

  group('EmbeddedLyrics ID3v2', () {
    Uint8List buildId3v2({required int major, required String lyrics}) {
      final encoding = <int>[3, 0x65, 0x6e, 0x67, 0]; // UTF-8, "eng", NUL
      final frameData = <int>[...encoding, ...utf8.encode(lyrics)];
      final frameHeader = <int>[
        ...ascii.encode('USLT'),
        ...(major == 4 ? _syncsafe4(frameData.length) : _be32(frameData.length)),
        0,
        0,
      ];
      final tag = <int>[...frameHeader, ...frameData];
      final header = <int>[
        ...ascii.encode('ID3'),
        major,
        0,
        0,
        ..._syncsafe4(tag.length),
      ];
      return Uint8List.fromList(<int>[...header, ...tag]);
    }

    test('extracts UTF-8 USLT from ID3v2.3', () {
      final bytes = buildId3v2(major: 3, lyrics: 'La la la\nSecond line');
      expect(EmbeddedLyrics.fromBytes(bytes), 'La la la\nSecond line');
    });

    test('extracts UTF-8 USLT from ID3v2.4', () {
      final bytes = buildId3v2(major: 4, lyrics: 'v4 lyrics');
      expect(EmbeddedLyrics.fromBytes(bytes), 'v4 lyrics');
    });

    test('returns null when no USLT frame exists', () {
      final header = <int>[
        ...ascii.encode('ID3'),
        3,
        0,
        0,
        ..._syncsafe4(0),
      ];
      expect(EmbeddedLyrics.fromBytes(Uint8List.fromList(header)), isNull);
    });
  });

  group('EmbeddedLyrics MP4', () {
    test('extracts ©lyr from an MP4 atom tree', () {
      final text = utf8.encode('MP4 lyrics');
      final dataAtom = <int>[
        ..._be32(8 + 5 + text.length),
        ...ascii.encode('data'),
        0, 0, 0, 0, // version + flags
        1, // type code: UTF-8
        ...text,
      ];
      final lyrAtom = <int>[
        ..._be32(8 + dataAtom.length),
        0xa9, 0x6c, 0x79, 0x72, // ©lyr
        ...dataAtom,
      ];
      final ilstAtom = <int>[
        ..._be32(8 + lyrAtom.length),
        ...ascii.encode('ilst'),
        ...lyrAtom,
      ];
      final metaAtom = <int>[
        ..._be32(8 + 4 + ilstAtom.length),
        ...ascii.encode('meta'),
        0, 0, 0, 0, // version + flags
        ...ilstAtom,
      ];
      final udtaAtom = <int>[
        ..._be32(8 + metaAtom.length),
        ...ascii.encode('udta'),
        ...metaAtom,
      ];
      final moovAtom = <int>[
        ..._be32(8 + udtaAtom.length),
        ...ascii.encode('moov'),
        ...udtaAtom,
      ];
      final ftypAtom = <int>[
        ..._be32(16),
        ...ascii.encode('ftyp'),
        ...ascii.encode('M4A '),
        0, 0, 0, 0,
      ];
      final bytes = Uint8List.fromList(<int>[
        ...ftypAtom,
        ...moovAtom,
      ]);
      expect(EmbeddedLyrics.fromBytes(bytes), 'MP4 lyrics');
    });
  });

  group('LyricsService', () {
    test('parses a real file on disk without a platform channel', () async {
      final lyrics = 'Real file\nlyrics here';
      final bytes = <int>[
        ...ascii.encode('ID3'),
        3, 0, 0,
        ..._syncsafe4(10 + 5 + utf8.encode(lyrics).length),
        ...ascii.encode('USLT'),
        ..._be32(5 + utf8.encode(lyrics).length),
        0, 0,
        3, 0x65, 0x6e, 0x67, 0,
        ...utf8.encode(lyrics),
      ];
      final dir = Directory.systemTemp.createTempSync('harmony_lyrics_test');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File('${dir.path}/track.mp3')..writeAsBytesSync(bytes);

      final service = LyricsService();
      final result = await service.lyricsFor(file.path);
      expect(result, isNotNull);
      expect(result!.text, 'Real file\nlyrics here');
    });

    test('returns null for a file without lyrics', () async {
      final dir = Directory.systemTemp.createTempSync('harmony_lyrics_test');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File('${dir.path}/plain.bin')..writeAsBytesSync(<int>[1, 2, 3]);

      final result = await LyricsService().lyricsFor(file.path);
      expect(result, isNull);
    });
  });
}

List<int> _syncsafe4(int value) => <int>[
      (value >> 21) & 0x7f,
      (value >> 14) & 0x7f,
      (value >> 7) & 0x7f,
      value & 0x7f,
    ];

List<int> _be32(int value) => <int>[
      (value >> 24) & 0xff,
      (value >> 16) & 0xff,
      (value >> 8) & 0xff,
      value & 0xff,
    ];
