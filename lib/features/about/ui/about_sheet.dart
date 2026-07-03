import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../discovery/state/discovery_log_provider.dart';
import '../state/package_info_provider.dart';
import 'sound_wave_ripple.dart';

class AboutSheet extends ConsumerStatefulWidget {
  const AboutSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext context) => const AboutSheet(),
    );
  }

  @override
  ConsumerState<AboutSheet> createState() => _AboutSheetState();
}

class _AboutSheetState extends ConsumerState<AboutSheet>
    with SingleTickerProviderStateMixin {
  static const int _tapsToUnlock = 7;
  static const int _hintStartsAtTap = 4;

  int _tapCount = 0;
  bool _diagnosticsUnlocked = false;
  late final AnimationController _rippleController;

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    _rippleController.dispose();
    super.dispose();
  }

  void _onVersionTap() {
    if (_diagnosticsUnlocked) {
      return;
    }
    setState(() => _tapCount++);
    if (_tapCount >= _tapsToUnlock) {
      setState(() => _diagnosticsUnlocked = true);
      _rippleController.forward(from: 0);
    }
  }

  String? get _tapHint {
    if (_diagnosticsUnlocked || _tapCount < _hintStartsAtTap) {
      return null;
    }
    final int remaining = _tapsToUnlock - _tapCount;
    return '$remaining ${remaining == 1 ? 'tap' : 'taps'} away…';
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<PackageInfo> packageInfo = ref.watch(packageInfoProvider);
    final ThemeData theme = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        // Plain Text/Chip/InkWell children don't claim the full sheet width
        // on their own the way a ListTile would, so the Column would
        // otherwise shrink to its widest child instead of spanning the sheet.
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('About Rivus', style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
              const _EnvironmentChip(isRelease: kReleaseMode),
              const SizedBox(height: 12),
              packageInfo.when(
                data: (PackageInfo info) => _VersionRow(
                  info: info,
                  onTap: _onVersionTap,
                  hint: _tapHint,
                ),
                loading: () => const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (Object _, StackTrace _) => Text(
                  'Version unavailable',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 20),
              Text('app by Symon 💛', style: theme.textTheme.bodyMedium),
              if (_diagnosticsUnlocked) ...<Widget>[
                const SizedBox(height: 24),
                SoundWaveRipple(
                  controller: _rippleController,
                  child: _DiagnosticsCard(packageInfo: packageInfo.value),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EnvironmentChip extends StatelessWidget {
  const _EnvironmentChip({required this.isRelease});

  final bool isRelease;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(
        isRelease ? Icons.verified_outlined : Icons.construction_outlined,
        size: 18,
      ),
      label: Text(isRelease ? 'release' : 'dev'),
    );
  }
}

class _VersionRow extends StatelessWidget {
  const _VersionRow({required this.info, required this.onTap, this.hint});

  final PackageInfo info;
  final VoidCallback onTap;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String? hint = this.hint;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Version ${info.version} (${info.buildNumber})',
              style: theme.textTheme.bodyLarge,
            ),
            if (hint != null)
              Text(
                hint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DiagnosticsCard extends ConsumerWidget {
  const _DiagnosticsCard({required this.packageInfo});

  final PackageInfo? packageInfo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<String> log = ref.watch(discoveryLogProvider);
    final ThemeData theme = Theme.of(context);
    final PackageInfo? info = packageInfo;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Diagnostics', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Version: ${info?.version ?? '—'}'),
            Text('Build number: ${info?.buildNumber ?? '—'}'),
            const Text('Build mode: ${kReleaseMode ? 'release' : 'dev'}'),
            const SizedBox(height: 12),
            Text('Recent SSDP discovery', style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            if (log.isEmpty)
              Text(
                'No discovery activity yet.',
                style: theme.textTheme.bodySmall,
              )
            else
              ...log
                  .take(10)
                  .map(
                    (String line) =>
                        Text(line, style: theme.textTheme.bodySmall),
                  ),
          ],
        ),
      ),
    );
  }
}
