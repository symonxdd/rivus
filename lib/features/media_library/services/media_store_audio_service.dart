import 'package:flutter/services.dart';

import '../models/audio_track.dart';

/// Thrown when the user has not granted (or has denied) the audio library
/// permission needed to query MediaStore.
class AudioPermissionDeniedException implements Exception {
  const AudioPermissionDeniedException();
}

/// Queries the device's local audio library via a platform channel into
/// Android's MediaStore.Audio.
///
/// Every actively-maintained pub.dev package for this turned out to be
/// either abandoned (on_audio_query's repo is archived) or a small,
/// unverified fork; MediaStore querying itself is a small, stable Android
/// API, so this is implemented directly in Kotlin instead
/// (see android/app/src/main/kotlin/me/symon/rivus/MediaStoreAudioQuery.kt).
class MediaStoreAudioService {
  static const MethodChannel _channel = MethodChannel(
    'me.symon.rivus/media_store_audio',
  );

  Future<List<AudioTrack>> querySongs() async {
    final List<Object?> result =
        await _channel.invokeMethod<List<Object?>>('querySongs') ??
        const <Object?>[];
    return result
        .cast<Map<Object?, Object?>>()
        .map(AudioTrack.fromMap)
        .toList();
  }
}
