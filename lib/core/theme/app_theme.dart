import 'package:flutter/material.dart';

/// Rivus' Material 3 theme definitions.
abstract final class AppTheme {
  static const Color _seed = Color(0xFF2F6690);

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(seedColor: _seed),
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.dark,
    ),
  );
}
