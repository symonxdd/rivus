import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rivus/core/persistence/shared_preferences_provider.dart';
import 'package:rivus/features/settings/state/theme_mode_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ThemeModeController', () {
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
    });

    tearDown(() => container.dispose());

    test('has no chosen mode before any manual selection', () {
      expect(container.read(themeModeControllerProvider), isNull);
    });

    test('select persists and updates state', () async {
      await container
          .read(themeModeControllerProvider.notifier)
          .select(ThemeMode.dark);

      expect(container.read(themeModeControllerProvider), ThemeMode.dark);
    });

    test('reloads the persisted choice on a fresh container', () async {
      await container
          .read(themeModeControllerProvider.notifier)
          .select(ThemeMode.light);

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final ProviderContainer freshContainer = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(freshContainer.dispose);

      expect(freshContainer.read(themeModeControllerProvider), ThemeMode.light);
    });
  });
}
