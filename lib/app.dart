import 'package:flutter/material.dart';

import 'l10n/generated/app_localizations.dart';
import 'theme/app_theme.dart';
import 'ui/adaptive_shell.dart';

class HarmonyApp extends StatelessWidget {
  const HarmonyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HarmonyPlayer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const AdaptiveShell(),
    );
  }
}
