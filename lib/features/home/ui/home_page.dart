import 'package:flutter/material.dart';

import '../../discovery/ui/renderer_list.dart';
import '../../settings/ui/settings_sheet.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rivus'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => SettingsSheet.show(context),
          ),
        ],
      ),
      body: const SafeArea(child: RendererList()),
    );
  }
}
