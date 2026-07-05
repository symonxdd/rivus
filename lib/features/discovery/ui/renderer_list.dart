import 'package:dart_cast/dart_cast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../media_library/ui/library_page.dart';
import '../models/discovery_state.dart';
import '../state/discovery_controller.dart';
import '../state/selected_renderer_controller.dart';

class RendererList extends ConsumerWidget {
  const RendererList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<DiscoveryState> discovery = ref.watch(
      rendererDiscoveryProvider,
    );
    final CastDevice? selected = ref.watch(selectedRendererProvider);

    void rescan() => ref.read(rendererDiscoveryProvider.notifier).rescan();

    return discovery.when(
      data: (DiscoveryState state) => _DiscoveryResults(
        state: state,
        selected: selected,
        onSelect: (CastDevice device) {
          ref.read(selectedRendererProvider.notifier).select(device);
          Navigator.of(
            context,
          ).push(MaterialPageRoute<void>(builder: (_) => const LibraryPage()));
        },
        onRescan: rescan,
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object error, StackTrace _) =>
          _ErrorState(error: error, onRescan: rescan),
    );
  }
}

class _DiscoveryResults extends StatelessWidget {
  const _DiscoveryResults({
    required this.state,
    required this.selected,
    required this.onSelect,
    required this.onRescan,
  });

  final DiscoveryState state;
  final CastDevice? selected;
  final ValueChanged<CastDevice> onSelect;
  final VoidCallback onRescan;

  @override
  Widget build(BuildContext context) {
    if (state.devices.isEmpty) {
      return state.isScanning
          ? const Center(child: CircularProgressIndicator())
          : _EmptyState(onRescan: onRescan);
    }

    return Column(
      children: <Widget>[
        Align(
          alignment: Alignment.topRight,
          child: IconButton(
            tooltip: 'Scan again',
            icon: const Icon(Icons.refresh),
            onPressed: onRescan,
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: state.devices.length + (state.isScanning ? 1 : 0),
            itemBuilder: (BuildContext context, int index) {
              if (index >= state.devices.length) {
                return const _ScanningIndicator();
              }
              final CastDevice device = state.devices[index];
              final bool isSelected = device == selected;
              final ColorScheme colorScheme = Theme.of(context).colorScheme;
              return ListTile(
                leading: Icon(
                  Icons.speaker_group_outlined,
                  color: isSelected ? colorScheme.primary : null,
                ),
                title: Text(device.name),
                subtitle: Text(device.address.address),
                trailing: isSelected
                    ? Icon(Icons.check, color: colorScheme.primary)
                    : null,
                onTap: () => onSelect(device),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ScanningIndicator extends StatelessWidget {
  const _ScanningIndicator();

  @override
  Widget build(BuildContext context) {
    return const ListTile(
      leading: SizedBox(
        width: 24,
        height: 24,
        child: Padding(
          padding: EdgeInsets.all(2),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      title: Text('Still searching...'),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRescan});

  final VoidCallback onRescan;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.wifi_find_outlined,
              size: 48,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No renderers found',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Make sure your renderer is powered on and on the same '
              'network.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRescan,
              icon: const Icon(Icons.refresh),
              label: const Text('Scan again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRescan});

  final Object error;
  final VoidCallback onRescan;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text('Discovery failed', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              '$error',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRescan,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
