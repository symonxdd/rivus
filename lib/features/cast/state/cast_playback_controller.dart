import 'dart:async';
import 'dart:io';

import 'package:dart_cast/dart_cast.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../media_library/models/audio_track.dart';
import '../models/cast_playback_state.dart';
import '../services/audio_http_server.dart';
import '../services/dlna_audio_soap.dart';

final NotifierProvider<CastPlaybackController, CastPlaybackState>
castPlaybackProvider =
    NotifierProvider<CastPlaybackController, CastPlaybackState>(
      CastPlaybackController.new,
    );

/// Drives casting and transport control for the currently selected renderer.
///
/// Reuses dart_cast's generic, non-video-specific pieces directly
/// (DlnaHttpClient for SOAP transport, DlnaSoapBuilder's Play/Pause/Seek/
/// Volume actions, DlnaSoapParser for responses) but builds its own
/// SetAVTransportURI call via [DlnaAudioSoap] and serves the file itself via
/// [AudioHttpServer], instead of dart_cast's own MediaProxy/DlnaSession.
/// Both were confirmed, on a real Sonos Beam, to assume video content:
/// DlnaSession's DIDL-Lite hardcodes `videoItem` (HTTP 500 from Sonos), and
/// MediaProxy's Content-Type guessing only recognizes a small video-oriented
/// extension list, serving anything else (like .m4a) as
/// `application/octet-stream` — a mismatch against our correct metadata that
/// made Sonos abort mid-transfer (`Broken pipe`) after accepting the call.
class CastPlaybackController extends Notifier<CastPlaybackState> {
  final DlnaHttpClient _httpClient = DlnaHttpClient();
  final AudioHttpServer _fileServer = AudioHttpServer();
  Timer? _pollTimer;
  bool _isPolling = false;
  String? _avTransportControlUrl;
  String? _renderingControlUrl;

  @override
  CastPlaybackState build() {
    ref.onDispose(() {
      _pollTimer?.cancel();
      _httpClient.close();
      unawaited(_fileServer.stop());
    });
    return const CastPlaybackState();
  }

  Future<void> loadAndPlay(CastDevice device, AudioTrack track) async {
    final String? avTransportUrl = device.metadata['avTransportControlUrl'];
    if (avTransportUrl == null || avTransportUrl.isEmpty) {
      state = state.copyWith(
        status: CastPlaybackStatus.error,
        error: StateError('No AVTransport control URL for "${device.name}".'),
      );
      return;
    }
    _avTransportControlUrl = avTransportUrl;
    _renderingControlUrl = _correctedRenderingControlUrl(
      device.metadata['renderingControlUrl'],
    );

    state = state.copyWith(status: CastPlaybackStatus.loading, track: track);

    try {
      final String fileUrl = await _fileServer.serveFile(
        filePath: track.path,
        mimeType: track.mimeType,
        targetDeviceIp: device.address.address,
      );
      final int? fileSize = File(track.path).existsSync()
          ? File(track.path).lengthSync()
          : null;

      await _sendAvTransport(
        'SetAVTransportURI',
        DlnaAudioSoap.buildSetAVTransportURI(
          url: fileUrl,
          mimeType: track.mimeType,
          title: track.title,
          duration: _formatDuration(track.duration),
          size: fileSize,
        ),
      );

      await _sendAvTransport('Play', DlnaSoapBuilder.buildPlay());

      state = state.copyWith(
        status: CastPlaybackStatus.playing,
        duration: track.duration,
        position: Duration.zero,
      );
      _startPolling();
    } catch (e) {
      state = state.copyWith(status: CastPlaybackStatus.error, error: e);
    }
  }

  Future<void> play() async {
    await _sendAvTransport('Play', DlnaSoapBuilder.buildPlay());
    state = state.copyWith(status: CastPlaybackStatus.playing);
  }

  Future<void> pause() async {
    await _sendAvTransport('Pause', DlnaSoapBuilder.buildPause());
    state = state.copyWith(status: CastPlaybackStatus.paused);
  }

  Future<void> stop() async {
    _stopPolling();
    await _sendAvTransport('Stop', DlnaSoapBuilder.buildStop());
    state = state.copyWith(
      status: CastPlaybackStatus.idle,
      position: Duration.zero,
    );
  }

  Future<void> seek(Duration position) async {
    await _sendAvTransport('Seek', DlnaSoapBuilder.buildSeek(position));
    state = state.copyWith(position: position);
  }

  Future<void> setVolume(double volume) async {
    // Update immediately so the Slider thumb tracks the drag in real time;
    // a Slider fires onChanged many times per second and expects the bound
    // value to update synchronously, not after a network round trip.
    state = state.copyWith(volume: volume);

    final String? controlUrl = _renderingControlUrl;
    if (controlUrl == null) return;
    final int intVolume = (volume.clamp(0.0, 1.0) * 100).round();
    await _httpClient.sendAction(
      controlUrl,
      DlnaServiceType.renderingControl,
      'SetVolume',
      DlnaSoapBuilder.buildSetVolume(intVolume),
    );
  }

  Future<String> _sendAvTransport(String action, String body) {
    final String? controlUrl = _avTransportControlUrl;
    if (controlUrl == null) {
      throw StateError('No active AVTransport control URL.');
    }
    return _httpClient.sendAction(
      controlUrl,
      DlnaServiceType.avTransport,
      action,
      body,
    );
  }

  void _startPolling() {
    _stopPolling();
    _pollTimer = Timer.periodic(const Duration(seconds: 1), (_) => _poll());
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _poll() async {
    if (_isPolling || !ref.mounted) return;
    _isPolling = true;
    try {
      final String positionResponse = await _sendAvTransport(
        'GetPositionInfo',
        DlnaSoapBuilder.buildGetPositionInfo(),
      );
      final PositionInfo posInfo = DlnaSoapParser.parsePositionInfo(
        positionResponse,
      );

      final String transportResponse = await _sendAvTransport(
        'GetTransportInfo',
        DlnaSoapBuilder.buildGetTransportInfo(),
      );
      final String transportState = DlnaSoapParser.parseTransportInfo(
        transportResponse,
      );

      if (!ref.mounted) return;
      state = state.copyWith(
        position: posInfo.position,
        duration: posInfo.duration > Duration.zero
            ? posInfo.duration
            : state.duration,
        status: _statusFor(transportState),
      );
    } catch (_) {
      // Polling failures are transient (renderer busy, brief network hiccup);
      // don't surface them as a hard error state.
    } finally {
      _isPolling = false;
    }
  }

  CastPlaybackStatus _statusFor(String transportState) {
    switch (transportState) {
      case 'PLAYING':
        return CastPlaybackStatus.playing;
      case 'PAUSED_PLAYBACK':
        return CastPlaybackStatus.paused;
      case 'STOPPED':
        return CastPlaybackStatus.idle;
      default:
        return state.status;
    }
  }

  static String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final String hours = twoDigits(duration.inHours);
    final String minutes = twoDigits(duration.inMinutes.remainder(60));
    final String seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  /// Works around a dart_cast device-description parsing bug: it picks the
  /// RenderingControl URL via `serviceType.contains('RenderingControl')`,
  /// which also matches Sonos's separate `GroupRenderingControl` service
  /// (its action set uses names like SetGroupVolume, not SetVolume, so
  /// sending SetVolume there gets rejected with UPnP error 401 "Invalid
  /// Action" — confirmed on a real Sonos Beam).
  ///
  /// This is a no-op for every other renderer: GroupRenderingControl is a
  /// Sonos-specific service for multi-room speaker groups, so the substring
  /// this looks for is simply absent from any other device's URL, which
  /// dart_cast's parser already resolves correctly on its own. Sonos's
  /// control URLs follow a consistent `.../MediaRenderer/{ServiceName}/Control`
  /// pattern, so the plain RenderingControl URL can be recovered by
  /// substitution.
  static String? _correctedRenderingControlUrl(String? url) {
    if (url == null) return null;
    return url.replaceFirst('GroupRenderingControl', 'RenderingControl');
  }
}
