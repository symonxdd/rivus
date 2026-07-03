import 'package:flutter/material.dart';

import '../../about/ui/about_sheet.dart';
import '../../settings/ui/theme_selector.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rivus'),
        actions: <Widget>[
          IconButton(
            tooltip: 'About',
            icon: const Icon(Icons.info_outline),
            onPressed: () => AboutSheet.show(context),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.podcasts_outlined,
                size: 64,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'No renderers discovered yet',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Discovery is coming in the next milestone.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              const ThemeSelector(),
            ],
          ),
        ),
      ),
    );
  }
}
