import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';

/// Primary bottom navigation bar with three tabs: Library, Favorites, Settings.
///
/// This bar is separated from the transport controls (which live in
/// [PlayerNavBar]) so navigation never clutters the playback surface.
class MainNavBar extends StatelessWidget {
  const MainNavBar({
    super.key,
    required this.selectedIndex,
    required this.onNavigate,
  });

  final int selectedIndex;

  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: onNavigate,
      destinations: <Widget>[
        NavigationDestination(
          icon: const Icon(Icons.library_music_outlined),
          selectedIcon: const Icon(Icons.library_music_rounded),
          label: l10n.library,
        ),
        NavigationDestination(
          icon: const Icon(Icons.favorite_border_rounded),
          selectedIcon: const Icon(Icons.favorite_rounded),
          label: l10n.favorites,
        ),
        NavigationDestination(
          icon: const Icon(Icons.settings_outlined),
          selectedIcon: const Icon(Icons.settings_rounded),
          label: l10n.settings,
        ),
      ],
    );
  }
}
