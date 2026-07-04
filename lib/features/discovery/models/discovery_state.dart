import 'package:dart_cast/dart_cast.dart';

/// The current state of an SSDP renderer discovery scan.
class DiscoveryState {
  const DiscoveryState({required this.devices, required this.isScanning});

  final List<CastDevice> devices;
  final bool isScanning;
}
