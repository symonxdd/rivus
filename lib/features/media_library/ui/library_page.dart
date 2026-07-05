import 'package:dart_cast/dart_cast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../cast/models/cast_playback_state.dart';
import '../../cast/state/cast_playback_controller.dart';
import '../../cast/ui/transport_controls_bar.dart';
import '../../discovery/state/selected_renderer_controller.dart';
import '../models/audio_track.dart';
import '../services/media_store_audio_service.dart';
import '../state/media_library_controller.dart';

class LibraryPage extends ConsumerWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<AudioTrack>> library = ref.watch(
      mediaLibraryProvider,
    );

    ref.listen<CastPlaybackState>(castPlaybackProvider, (
      CastPlaybackState? previous,
      CastPlaybackState next,
    ) {
      if (next.status == CastPlaybackStatus.error &&
          next.error != previous?.error) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Cast failed: ${next.error}')));
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Library')),
      body: SafeArea(
        child: library.when(
          data: (List<AudioTrack> tracks) => _TrackList(
            tracks: tracks,
            onTap: (AudioTrack track) => _cast(ref, track),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object error, StackTrace _) =>
              error is AudioPermissionDeniedException
              ? _PermissionDeniedState(
                  onRetry: () =>
                      ref.read(mediaLibraryProvider.notifier).refresh(),
                )
              : _ErrorState(
                  error: error,
                  onRetry: () =>
                      ref.read(mediaLibraryProvider.notifier).refresh(),
                ),
        ),
      ),
      bottomNavigationBar: const TransportControlsBar(),
    );
  }

  void _cast(WidgetRef ref, AudioTrack track) {
    final CastDevice? device = ref.read(selectedRendererProvider);
    if (device == null) return;
    ref.read(castPlaybackProvider.notifier).loadAndPlay(device, track);
  }
}

class _TrackList extends StatelessWidget {
  const _TrackList({required this.tracks, required this.onTap});

  final List<AudioTrack> tracks;
  final ValueChanged<AudioTrack> onTap;

  @override
  Widget build(BuildContext context) {
    if (tracks.isEmpty) {
      return const _EmptyState();
    }

    return ListView.builder(
      itemCount: tracks.length,
      itemBuilder: (BuildContext context, int index) {
        final AudioTrack track = tracks[index];
        return ListTile(
          leading: const Icon(Icons.music_note_outlined),
          title: Text(track.title),
          subtitle: Text(_formatDuration(track.duration)),
          onTap: () => onTap(track),
        );
      },
    );
  }

  static String _formatDuration(Duration duration) {
    final int minutes = duration.inMinutes;
    final int seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.library_music_outlined,
              size: 48,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No audio found',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Add some music to this device to see it here.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionDeniedState extends StatelessWidget {
  const _PermissionDeniedState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.lock_outline,
              size: 48,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Music access needed',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Rivus needs permission to see the audio files on this device.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.lock_open_outlined),
              label: const Text('Grant access'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Could not load your library',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '$error',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
