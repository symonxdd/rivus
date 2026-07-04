import 'package:flutter/material.dart';

import '../../about/ui/about_sheet.dart';
import 'theme_selector.dart';

class SettingsSheet extends StatelessWidget {
  const SettingsSheet({super.key, required this.rootContext});

  /// The context this sheet was opened from, kept around so the About entry
  /// can reopen a new sheet from it after this one has popped and its own
  /// context is no longer valid to use.
  final BuildContext rootContext;

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext _) => SettingsSheet(rootContext: context),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Theme', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              const ThemeSelector(),
              const Divider(height: 32),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.info_outline),
                title: const Text('About'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).pop();
                  AboutSheet.show(rootContext);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
