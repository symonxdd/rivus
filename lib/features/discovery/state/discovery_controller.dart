import 'dart:async';

import 'package:dart_cast/dart_cast.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_multicast_lock/flutter_multicast_lock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/discovery_state.dart';
import 'discovery_log_provider.dart';

const Duration _discoveryTimeout = Duration(seconds: 5);

final StreamNotifierProvider<RendererDiscoveryController, DiscoveryState>
rendererDiscoveryProvider =
    StreamNotifierProvider<RendererDiscoveryController, DiscoveryState>(
      RendererDiscoveryController.new,
    );

/// Runs an SSDP discovery scan for DLNA MediaRenderer devices.
///
/// Android silently drops multicast UDP packets unless the app holds a
/// WifiManager multicast lock, so one is acquired for the duration of each
/// scan and released once it completes.
class RendererDiscoveryController extends StreamNotifier<DiscoveryState> {
  final FlutterMulticastLock _multicastLock = FlutterMulticastLock();

  @override
  Stream<DiscoveryState> build() {
    CastLogger.setCallback(_logDiscoveryEvent);

    final DlnaDiscoveryProvider provider = DlnaDiscoveryProvider();
    ref.onDispose(provider.dispose);

    return _discover(provider);
  }

  Stream<DiscoveryState> _discover(DlnaDiscoveryProvider provider) async* {
    await _multicastLock.acquireMulticastLock();
    List<CastDevice> latest = const <CastDevice>[];
    try {
      await for (final List<CastDevice> devices in provider.startDiscovery(
        timeout: _discoveryTimeout,
      )) {
        latest = devices;
        yield DiscoveryState(devices: latest, isScanning: true);
      }
      yield DiscoveryState(devices: latest, isScanning: false);
    } finally {
      await _multicastLock.releaseMulticastLock();
    }
  }

  void _logDiscoveryEvent(String level, String message) {
    // Printed directly to the run console too, not just captured for the
    // About sheet's Diagnostics card, since that card only keeps the last
    // 10 lines — nowhere near enough to see a full cast attempt plus the
    // playback poll loop's ongoing chatter.
    debugPrint('dart_cast $level: $message');
    if (!ref.mounted) {
      return;
    }
    ref.read(discoveryLogProvider.notifier).add('$level: $message');
  }

  /// Discards the current scan's results and starts a fresh one.
  void rescan() => ref.invalidateSelf();
}
