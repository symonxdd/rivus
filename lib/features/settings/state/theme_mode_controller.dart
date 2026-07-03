import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/persistence/shared_preferences_provider.dart';

const String _themeModePrefsKey = 'theme_mode';

/// The user's manually chosen [ThemeMode], or `null` if they haven't picked
/// one yet — in which case the app follows [ThemeMode.system].
///
/// The first manual selection is persisted and permanently disables
/// system-following from then on.
final NotifierProvider<ThemeModeController, ThemeMode?>
themeModeControllerProvider = NotifierProvider<ThemeModeController, ThemeMode?>(
  ThemeModeController.new,
);

class ThemeModeController extends Notifier<ThemeMode?> {
  @override
  ThemeMode? build() {
    final String? stored = ref
        .watch(sharedPreferencesProvider)
        .getString(_themeModePrefsKey);
    return switch (stored) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => null,
    };
  }

  Future<void> select(ThemeMode mode) async {
    assert(mode != ThemeMode.system, 'Only light/dark can be selected.');
    state = mode;
    await ref
        .read(sharedPreferencesProvider)
        .setString(_themeModePrefsKey, mode.name);
  }
}
