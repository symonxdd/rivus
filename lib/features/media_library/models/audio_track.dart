/// A single audio track found on the device, as returned by MediaStore.
class AudioTrack {
  const AudioTrack({
    required this.id,
    required this.title,
    required this.duration,
    required this.path,
    required this.mimeType,
  });

  factory AudioTrack.fromMap(Map<Object?, Object?> map) {
    return AudioTrack(
      id: map['id']! as String,
      title: map['title'] as String? ?? 'Unknown',
      duration: Duration(milliseconds: map['durationMs'] as int? ?? 0),
      path: map['path']! as String,
      mimeType: map['mimeType'] as String? ?? 'audio/mpeg',
    );
  }

  final String id;
  final String title;
  final Duration duration;
  final String path;

  /// The file's real MIME type (e.g. `audio/mpeg`, `audio/mp4`), as reported
  /// by MediaStore. Used to build correct DIDL-Lite protocolInfo when
  /// casting, instead of guessing from the file extension.
  final String mimeType;
}
