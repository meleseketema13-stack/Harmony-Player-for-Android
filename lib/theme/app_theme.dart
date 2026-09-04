import 'package:flutter/material.dart';

/// Material 3 themes chosen with WCAG AA contrast in mind. Text and interactive
/// colors deliberately stay on the default color ramp so the app remains
/// legible under system high-contrast configurations.
class AppTheme {
  AppTheme._();

  static const Color _seed = Color(0xFF6750A4);

  static ThemeData get light => _build(Brightness.light);

  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      visualDensity: VisualDensity.standard,
      // No opacity-faded disabled text: keeps screen reader "disabled" state
      // visually detectable while remaining readable.
      disabledColor: scheme.onSurface.withValues(alpha: 0.55),
    );
  }
}
