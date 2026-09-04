import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import 'player_controls.dart';

/// Persistent bottom playback bar: the five transport controls only
/// (Previous / Jump-back / Play-Pause / Jump-forward / Next).
///
/// Navigation is handled by the separate [MainNavBar]. This separation keeps
/// the playback surface clean and uncluttered.
///
/// Focus-preservation contract: this widget is always mounted at the *same
/// tree position* (the bottom of the shell's `Column`) on every breakpoint,
/// just like the [MiniPlayer]. Unfolding a foldable or resizing never
/// unmounts the [Element] behind the focused Play/Pause button, so
/// TalkBack/Jieshuo+ never drop focus.
class PlayerNavBar extends StatelessWidget {
  const PlayerNavBar({
    super.key,
    required this.ordinal,
  });

  /// Reading-order position used by [OrdinalSortKey].
  final double ordinal;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      sortKey: OrdinalSortKey(ordinal),
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainer,
        elevation: 8,
        child: const SizedBox(
          height: 72,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TransportControls(),
            ],
          ),
        ),
      ),
    );
  }
}
