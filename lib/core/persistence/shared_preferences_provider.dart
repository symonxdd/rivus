import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Overridden in `main()` with the resolved [SharedPreferences] instance
/// before the app is run.
final Provider<SharedPreferences> sharedPreferencesProvider =
    Provider<SharedPreferences>((ref) {
      throw UnimplementedError(
        'sharedPreferencesProvider must be overridden in main()',
      );
    });
