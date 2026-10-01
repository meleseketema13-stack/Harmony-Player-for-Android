import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../a11y/a11y_engine.dart';
import '../l10n/generated/app_localizations.dart';
import '../state/audio_providers.dart';
import 'pages.dart';
import 'pages/favorites_page.dart';
import 'pages/library_pages.dart';
import 'screens/now_playing_screen.dart';
import 'widgets/main_nav_bar.dart';
import 'widgets/unified_player_bar.dart';

/// Top-level responsive shell.
///
/// Breakpoints (from the Phase 1 blueprint):
///  * Compact   < 600dp — single content column.
///  * Medium  600-840dp — content column.
///  * Expanded   >= 840dp — content + hero now-playing/lyrics pane.
///
/// The bottom edge carries exactly two bars: a single [UnifiedPlayerBar]
/// (artwork + title/artist + Previous / Play-Pause / Next) and, below it, the
/// [MainNavBar] for page navigation (Library / Favorites / Settings). The
/// former mini-player + separate transport-bar stack was collapsed into
/// [UnifiedPlayerBar] to halve the number of swipe stops on the bottom edge for
/// Explore-by-Touch users, and to stop duplicate Play/Pause nodes competing for
/// screen reader focus. Jump-back/jump-forward, the seek bar, secondary controls
/// and lyrics live on the full now-playing screen that the bar expands to.
///
/// Focus-preservation on fold/unfold: the surrounding panes change with the
/// breakpoint, but the [UnifiedPlayerBar] and [MainNavBar] are always mounted
/// as the last two children of the outer `Column` (same runtimeType, same
/// [ValueKey], same position). When a foldable unfolds, only the `Row` above
/// them is rebuilt, so the [Element] behind the focused Play/Pause button
/// survives and TalkBack / Jieshuo+ never drop focus.
class AdaptiveShell extends ConsumerStatefulWidget {
  const AdaptiveShell({super.key});

  @override
  ConsumerState<AdaptiveShell> createState() => _AdaptiveShellState();
}

class _AdaptiveShellState extends ConsumerState<AdaptiveShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Live track-change announcements. Registered at the shell root so they
    // fire for manual skips and auto-advance alike, while staying in the one
    // place that survives every layout transition.
    ref.listen<String?>(
      mediaItemProvider.select((value) => value.valueOrNull?.id),
      (previous, next) {
        if (next == null || next == previous) return;
        final item = ref.read(mediaItemProvider).valueOrNull;
        if (item == null) return;
        final l10n = AppLocalizations.of(context);
        final rawArtist = item.artist;
        final artist = (rawArtist == null || rawArtist.isEmpty)
            ? l10n.unknownArtist
            : rawArtist;
        A11yEngine(l10n, View.of(context))
            .announceTrackPlaying(item.title, artist);
      },
    );

    final width = MediaQuery.sizeOf(context).width;
    final isExpanded = width >= 840;
    final contentFirst = ref.watch(contentFirstSemanticsProvider);
    final hasAudio = ref.watch(transportEnabledProvider);
    final isOnSettings = _selectedIndex == 2;

    // Bottom playback bar visibility:
    // - Hidden when no audio is active
    // - Hidden on the Settings screen, where playback controls are pure clutter
    //   for a screen reader user adjusting preferences
    final showPlayerBar = hasAudio && !isOnSettings;

    // Reading order is decoupled from visual order for screen readers.
    final navOrdinal = contentFirst ? 2 : 0;
    final contentOrdinal = contentFirst ? 0 : 1;
    final sideOrdinal = contentFirst ? 1 : 2;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: Semantics(
                container: true,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Expanded(
                      child: _pane(
                        key: const ValueKey('shell-content'),
                        ordinal: contentOrdinal,
                        child: IndexedStack(
                          index: _selectedIndex,
                          children: const <Widget>[
                            LibraryTabsPage(),
                            FavoritesPage(),
                            SettingsPage(),
                          ],
                        ),
                      ),
                    ),
                    if (isExpanded) ...<Widget>[
                      const VerticalDivider(width: 1),
                      _pane(
                        key: const ValueKey('shell-now-playing'),
                        ordinal: sideOrdinal,
                        child: const SizedBox(
                          width: 340,
                          child: NowPlayingPanel(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Constant element: never moves between layouts, so screen reader
            // focus is preserved when the device unfolds. Holds both the
            // now-playing summary and the transport controls.
            UnifiedPlayerBar(
              key: const ValueKey('harmony-player-bar'),
              visible: showPlayerBar,
              ordinal: navOrdinal.toDouble(),
            ),
          ],
        ),
      ),
      // Page navigation bar, at the very bottom, below the playback bar.
      bottomNavigationBar: MainNavBar(
        selectedIndex: _selectedIndex,
        onNavigate: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }

  /// Wraps a top-level pane in a semantics container with an [OrdinalSortKey]
  /// so the screen reader reading order can be re-arranged independently of
  /// the visual position.
  Widget _pane({
    required Key key,
    required int ordinal,
    required Widget child,
  }) {
    return Semantics(
      key: key,
      container: true,
      sortKey: OrdinalSortKey(ordinal.toDouble()),
      child: child,
    );
  }
}
