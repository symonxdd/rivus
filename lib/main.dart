import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/persistence/shared_preferences_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/home/ui/home_page.dart';
import 'features/settings/state/theme_mode_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const RivusApp(),
    ),
  );
}

class RivusApp extends ConsumerWidget {
  const RivusApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeMode? themeMode = ref.watch(themeModeControllerProvider);

    return MaterialApp(
      title: 'Rivus',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode ?? ThemeMode.system,
      home: const HomePage(),
    );
  }
}
