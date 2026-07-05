import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/audio_track.dart';
import '../services/media_store_audio_service.dart';

final AsyncNotifierProvider<MediaLibraryController, List<AudioTrack>>
mediaLibraryProvider =
    AsyncNotifierProvider<MediaLibraryController, List<AudioTrack>>(
      MediaLibraryController.new,
    );

/// Requests the audio library permission (if needed) and loads the local
/// track list. Throws [AudioPermissionDeniedException] if permission isn't
/// granted, so the UI can show a distinct "grant access" state instead of a
/// generic error.
class MediaLibraryController extends AsyncNotifier<List<AudioTrack>> {
  final MediaStoreAudioService _service = MediaStoreAudioService();

  @override
  Future<List<AudioTrack>> build() async {
    final PermissionStatus status = await Permission.audio.request();
    if (!status.isGranted) {
      throw const AudioPermissionDeniedException();
    }
    return _service.querySongs();
  }

  /// Re-requests permission and/or reloads the track list.
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}
