import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Recent SSDP discovery log lines, newest first.
///
/// Empty until milestone 2 wires up real SSDP discovery; the About sheet's
/// Diagnostics card reads this so it has somewhere to show entries once
/// discovery exists.
final NotifierProvider<DiscoveryLogController, List<String>>
discoveryLogProvider = NotifierProvider<DiscoveryLogController, List<String>>(
  DiscoveryLogController.new,
);

class DiscoveryLogController extends Notifier<List<String>> {
  @override
  List<String> build() => const <String>[];

  void add(String line) {
    state = <String>[line, ...state];
  }
}
