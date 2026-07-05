import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../media_library/models/audio_track.dart';
import '../models/cast_playback_state.dart';
import '../state/cast_playback_controller.dart';

/// A persistent bottom bar with the current track, play/pause, seek, and
/// volume. Hidden entirely until something has been cast.
class TransportControlsBar extends ConsumerWidget {
  const TransportControlsBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final CastPlaybackState playback = ref.watch(castPlaybackProvider);
    final AudioTrack? track = playback.track;

    if (track == null) {
      return const SizedBox.shrink();
    }

    final CastPlaybackController controller = ref.read(
      castPlaybackProvider.notifier,
    );
    final ThemeData theme = Theme.of(context);
    final bool isPlaying = playback.status == CastPlaybackStatus.playing;
    final bool isLoading = playback.status == CastPlaybackStatus.loading;
    final double durationSeconds = playback.duration.inSeconds.toDouble();
    final double positionSeconds = playback.position.inSeconds.toDouble().clamp(
      0,
      durationSeconds <= 0 ? 0 : durationSeconds,
    );

    return Material(
      elevation: 4,
      color: theme.colorScheme.surfaceContainerHigh,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      track.title,
                      style: theme.textTheme.titleSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                    onPressed: isLoading
                        ? null
                        : () => isPlaying
                              ? controller.pause()
                              : controller.play(),
                  ),
                ],
              ),
              Slider(
                value: durationSeconds <= 0 ? 0 : positionSeconds,
                max: durationSeconds <= 0 ? 1 : durationSeconds,
                onChanged: durationSeconds <= 0
                    ? null
                    : (double value) =>
                          controller.seek(Duration(seconds: value.round())),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      _formatMmSs(playback.position),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    Text(
                      _formatMmSs(playback.duration),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: <Widget>[
                  Icon(Icons.volume_down, color: theme.colorScheme.outline),
                  Expanded(
                    child: Slider(
                      value: playback.volume,
                      onChanged: (double value) => controller.setVolume(value),
                    ),
                  ),
                  Icon(Icons.volume_up, color: theme.colorScheme.outline),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatMmSs(Duration duration) {
    final int minutes = duration.inMinutes;
    final int seconds = duration.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
