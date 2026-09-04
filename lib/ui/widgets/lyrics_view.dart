import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../audio/lyrics.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../state/audio_providers.dart';

/// Embedded-lyrics panel for the now-playing screen.
///
/// Reads the current track's file once (bounded prefix read), parses the
/// embedded tag, and renders either timestamped lines (with the active line
/// highlighted and auto-scrolled) or plain text. Falls back to a neutral empty
/// card when the file carries no lyrics.
class LyricsView extends ConsumerWidget {
  const LyricsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final item = ref.watch(mediaItemProvider).valueOrNull;
    final path = item?.extras?['path'];

    if (path is! String || path.isEmpty) {
      return _EmptyCard(l10n: l10n);
    }

    final lyrics = ref.watch(lyricsForPathProvider(path));
    return switch (lyrics) {
      AsyncData(:final value) when value != null => _LyricsBody(lyrics: value),
      _ => _EmptyCard(l10n: l10n),
    };
  }
}

class _LyricsBody extends StatelessWidget {
  const _LyricsBody({required this.lyrics});

  final Lyrics lyrics;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final timed = lyrics.lines;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l10n.lyricsHeader,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 12),
          if (timed != null)
            _TimedLyrics(lines: timed)
          else
            _PlainLyrics(text: lyrics.text ?? ''),
        ],
      ),
    );
  }
}

class _PlainLyrics extends StatelessWidget {
  const _PlainLyrics({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n');
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 320),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            for (final line in lines)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  line,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Timestamped lyrics: the line matching the playback position is highlighted
/// and kept in view.
class _TimedLyrics extends ConsumerStatefulWidget {
  const _TimedLyrics({required this.lines});

  final List<LyricLine> lines;

  @override
  ConsumerState<_TimedLyrics> createState() => _TimedLyricsState();
}

class _TimedLyricsState extends ConsumerState<_TimedLyrics> {
  static const double _lineExtent = 40;

  final ScrollController _controller = ScrollController();
  int _lastActive = -1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final position = ref.watch(positionProvider).valueOrNull ?? Duration.zero;
    final lines = widget.lines;

    var active = 0;
    for (var i = 0; i < lines.length; i++) {
      if (lines[i].time <= position) {
        active = i;
      } else {
        break;
      }
    }

    if (active != _lastActive) {
      _lastActive = active;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_controller.hasClients) return;
        _controller.animateTo(
          (active * _lineExtent).clamp(0.0, _controller.position.maxScrollExtent),
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      });
    }

    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 280,
      child: ListView.builder(
        controller: _controller,
        itemCount: lines.length,
        itemBuilder: (BuildContext context, int index) {
          final isActive = index == active;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              lines[index].text.isEmpty ? '\u200b' : lines[index].text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isActive ? scheme.primary : null,
                    fontWeight:
                        isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
            ),
          );
        },
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        l10n.lyricsEmpty,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}
