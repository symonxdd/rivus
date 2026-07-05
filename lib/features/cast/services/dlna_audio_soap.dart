import 'package:dart_cast/dart_cast.dart';

/// Builds a SetAVTransportURI SOAP envelope with correct audio DIDL-Lite
/// metadata.
///
/// dart_cast's own [DlnaSoapBuilder.buildSetAVTransportURI] hardcodes
/// `<upnp:class>object.item.videoItem</upnp:class>` and defaults to a
/// `video/mp4` protocolInfo, since dart_cast is built for casting video.
/// Confirmed on a real Sonos Beam: sending that for an audio file returns
/// HTTP 500 from the speaker's own SOAP handler, before it even tries to
/// fetch the file. This builds the same action with
/// `object.item.audioItem.musicTrack` and the file's real audio MIME type
/// instead.
abstract final class DlnaAudioSoap {
  static String buildSetAVTransportURI({
    required String url,
    required String mimeType,
    String? title,
    String? duration,
    int? size,
  }) {
    final String escapedUrl = _escapeXml(url);
    final String escapedTitle = _escapeXml(title ?? 'Track');
    // DLNA.ORG_OP=01 tells the renderer this resource supports byte-range
    // requests (seeking); without it, some renderers (Sonos included) will
    // accept SetAVTransportURI without error but never actually start
    // playback. DLNA.ORG_FLAGS marks it as a streaming, seekable resource;
    // these bits are generic to any streamed media, not video-specific,
    // despite living in a spec mostly documented with video in mind.
    final String protocolInfo =
        'http-get:*:$mimeType:'
        'DLNA.ORG_OP=01;'
        'DLNA.ORG_FLAGS=01700000000000000000000000000000';

    final String durationAttr = duration != null ? ' duration="$duration"' : '';
    final String sizeAttr = size != null ? ' size="$size"' : '';

    final String didlLite = _escapeXml(
      '<DIDL-Lite xmlns="urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/"'
      ' xmlns:dc="http://purl.org/dc/elements/1.1/"'
      ' xmlns:upnp="urn:schemas-upnp-org:metadata-1-0/upnp/">'
      '<item id="0" parentID="0" restricted="0">'
      '<dc:title>$escapedTitle</dc:title>'
      '<upnp:class>object.item.audioItem.musicTrack</upnp:class>'
      '<res protocolInfo="$protocolInfo"$durationAttr$sizeAttr>$escapedUrl</res>'
      '</item>'
      '</DIDL-Lite>',
    );

    return _wrapSoap(
      DlnaServiceType.avTransport,
      'SetAVTransportURI',
      '<InstanceID>0</InstanceID>'
          '<CurrentURI>$escapedUrl</CurrentURI>'
          '<CurrentURIMetaData>$didlLite</CurrentURIMetaData>',
    );
  }

  static String _wrapSoap(String serviceType, String action, String body) {
    return '<?xml version="1.0" encoding="utf-8"?>'
        '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/"'
        ' s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">'
        '<s:Body>'
        '<u:$action xmlns:u="$serviceType">'
        '$body'
        '</u:$action>'
        '</s:Body>'
        '</s:Envelope>';
  }

  static String _escapeXml(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}
