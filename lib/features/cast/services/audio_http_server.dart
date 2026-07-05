import 'dart:io';

import 'package:dart_cast/dart_cast.dart';
import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_static/shelf_static.dart';

/// Serves one local audio file at a time over HTTP for a renderer to fetch.
///
/// dart_cast's own embedded server (MediaProxy) was tried first, since it
/// already has proven HEAD/Range handling. But confirmed on a real Sonos
/// Beam: MediaProxy's Content-Type guessing (`_contentTypeForPath`) only
/// recognizes a small, video-oriented extension list (.mp4/.ts/.mkv/.vtt/
/// .srt, plus .aac) and has no way to override it, so any other audio file
/// (.m4a, .mp3, ...) gets served as `application/octet-stream` — a mismatch
/// against the correct MIME type our DIDL-Lite metadata declares. Sonos
/// accepted the SetAVTransportURI call and started fetching, then aborted
/// the connection mid-transfer (`Broken pipe`) once it saw that mismatch.
///
/// shelf_static (dart-lang, already verified elsewhere to handle Range/HEAD
/// correctly) lets us pass an explicit content type instead of guessing, and
/// we already have the correct one from MediaStore's own MIME_TYPE column.
class AudioHttpServer {
  HttpServer? _server;

  /// Starts serving [filePath] (with the given [mimeType]) and returns the
  /// URL a renderer at [targetDeviceIp] can fetch it from.
  Future<String> serveFile({
    required String filePath,
    required String mimeType,
    required String targetDeviceIp,
  }) async {
    await stop();

    final String? localIp = await NetworkUtils.getLocalIpAddress(
      targetDeviceIp: targetDeviceIp,
    );
    if (localIp == null) {
      throw StateError(
        'No local network interface available to serve the file from.',
      );
    }

    final String urlPath = 'track${p.extension(filePath)}';
    final Handler handler = createFileHandler(
      filePath,
      url: urlPath,
      contentType: mimeType,
    );

    _server = await shelf_io.serve(handler, localIp, 0);
    return 'http://$localIp:${_server!.port}/$urlPath';
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
  }
}
