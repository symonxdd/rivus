import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/theme_mode_controller.dart';

/// A Light/Dark toggle. Never shows a "System" option: while the user
/// hasn't made a manual choice, it highlights whatever the system
/// currently resolves to.
class ThemeSelector extends ConsumerWidget {
  const ThemeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeMode? chosen = ref.watch(themeModeControllerProvider);
    final Brightness systemBrightness = MediaQuery.platformBrightnessOf(
      context,
    );
    final ThemeMode resolved =
        chosen ??
        (systemBrightness == Brightness.dark
            ? ThemeMode.dark
            : ThemeMode.light);

    return SegmentedButton<ThemeMode>(
      segments: const <ButtonSegment<ThemeMode>>[
        ButtonSegment<ThemeMode>(
          value: ThemeMode.light,
          label: Text('Light'),
          icon: Icon(Icons.light_mode_outlined),
        ),
        ButtonSegment<ThemeMode>(
          value: ThemeMode.dark,
          label: Text('Dark'),
          icon: Icon(Icons.dark_mode_outlined),
        ),
      ],
      selected: <ThemeMode>{resolved},
      onSelectionChanged: (Set<ThemeMode> selection) {
        unawaited(
          ref
              .read(themeModeControllerProvider.notifier)
              .select(selection.first),
        );
      },
    );
  }
}
