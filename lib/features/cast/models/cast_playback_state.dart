import '../../media_library/models/audio_track.dart';

enum CastPlaybackStatus { idle, loading, playing, paused, error }

/// The current state of the active cast/playback session.
class CastPlaybackState {
  const CastPlaybackState({
    this.status = CastPlaybackStatus.idle,
    this.track,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.volume = 0.5,
    this.error,
  });

  final CastPlaybackStatus status;
  final AudioTrack? track;
  final Duration position;
  final Duration duration;
  final double volume;
  final Object? error;

  CastPlaybackState copyWith({
    CastPlaybackStatus? status,
    AudioTrack? track,
    Duration? position,
    Duration? duration,
    double? volume,
    Object? error,
  }) {
    return CastPlaybackState(
      status: status ?? this.status,
      track: track ?? this.track,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      volume: volume ?? this.volume,
      error: error,
    );
  }
}
