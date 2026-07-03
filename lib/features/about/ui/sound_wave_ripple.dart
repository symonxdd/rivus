import 'package:flutter/material.dart';

/// Wraps [child] with a brief sound-wave ripple that sweeps outward from
/// the top center, played once whenever [controller] runs forward.
class SoundWaveRipple extends AnimatedWidget {
  const SoundWaveRipple({
    super.key,
    required AnimationController controller,
    required this.child,
  }) : super(listenable: controller);

  final Widget child;

  AnimationController get _controller => listenable as AnimationController;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _SoundWaveRipplePainter(
        progress: _controller.value,
        color: Theme.of(context).colorScheme.primary,
      ),
      child: child,
    );
  }
}

class _SoundWaveRipplePainter extends CustomPainter {
  _SoundWaveRipplePainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  static const int _ringCount = 3;
  static const double _ringStagger = 0.18;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) {
      return;
    }
    final Offset origin = Offset(size.width / 2, 0);
    final double maxRadius = size.longestSide;

    for (int i = 0; i < _ringCount; i++) {
      final double ringProgress = (progress - i * _ringStagger).clamp(0.0, 1.0);
      if (ringProgress <= 0) {
        continue;
      }
      final double opacity = (1 - ringProgress) * 0.35;
      if (opacity <= 0) {
        continue;
      }
      final Paint paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(origin, maxRadius * ringProgress, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SoundWaveRipplePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
