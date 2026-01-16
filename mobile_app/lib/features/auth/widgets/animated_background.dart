import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../../../core/theme/app_theme.dart';

class AnimatedBackground extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final List<Color>? colors;

  const AnimatedBackground({
    super.key,
    required this.child,
    this.duration = const Duration(seconds: 8),
    this.colors,
  });

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_controller);

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Animated Background
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return CustomPaint(
                painter: BackgroundPainter(
                  animation: _animation.value,
                  colors: widget.colors ??
                      [
                        AppTheme.primaryColor.withValues(alpha: 0.1),
                        AppTheme.primaryLightColor.withValues(alpha: 0.05),
                        AppTheme.accentColor.withValues(alpha: 0.08),
                      ],
                ),
              );
            },
          ),
        ),

        // Floating Particles
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return CustomPaint(
                painter: ParticlesPainter(
                  animation: _animation.value,
                ),
              );
            },
          ),
        ),

        // Content
        widget.child,
      ],
    );
  }
}

class BackgroundPainter extends CustomPainter {
  final double animation;
  final List<Color> colors;

  BackgroundPainter({
    required this.animation,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Create gradient background
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        AppTheme.backgroundColor,
        AppTheme.secondaryLightColor.withValues(alpha: 0.3),
      ],
    );

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    paint.shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);

    // Draw animated shapes
    _drawAnimatedShapes(canvas, size);
  }

  void _drawAnimatedShapes(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = colors[0];

    // Large circle
    final circle1Center = Offset(
      size.width * 0.8 + math.sin(animation * 2 * math.pi) * 50,
      size.height * 0.2 + math.cos(animation * 2 * math.pi) * 30,
    );
    canvas.drawCircle(circle1Center, 80, paint);

    // Medium circle
    paint.color = colors[1];
    final circle2Center = Offset(
      size.width * 0.1 + math.cos(animation * 2 * math.pi) * 30,
      size.height * 0.7 + math.sin(animation * 2 * math.pi) * 40,
    );
    canvas.drawCircle(circle2Center, 60, paint);

    // Small circle
    paint.color = colors[2];
    final circle3Center = Offset(
      size.width * 0.6 + math.sin(animation * 3 * math.pi) * 25,
      size.height * 0.5 + math.cos(animation * 3 * math.pi) * 35,
    );
    canvas.drawCircle(circle3Center, 40, paint);

    // Floating rectangles
    paint.color = AppTheme.primaryColor.withValues(alpha: 0.05);
    final rect1 = Rect.fromCenter(
      center: Offset(
        size.width * 0.3 + math.cos(animation * 2 * math.pi) * 20,
        size.height * 0.3 + math.sin(animation * 2 * math.pi) * 15,
      ),
      width: 60,
      height: 60,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect1, const Radius.circular(12)),
      paint,
    );

    final rect2 = Rect.fromCenter(
      center: Offset(
        size.width * 0.7 + math.sin(animation * 1.5 * math.pi) * 30,
        size.height * 0.8 + math.cos(animation * 1.5 * math.pi) * 20,
      ),
      width: 80,
      height: 40,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect2, const Radius.circular(20)),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class ParticlesPainter extends CustomPainter {
  final double animation;
  static const int particleCount = 20;

  ParticlesPainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = AppTheme.primaryColor.withValues(alpha: 0.3);

    for (int i = 0; i < particleCount; i++) {
      final progress = (animation + i / particleCount) % 1.0;
      final x = (i * 37) % size.width.toInt();
      final y = size.height * progress;

      final opacity = math.sin(progress * math.pi);
      paint.color = AppTheme.primaryColor.withValues(alpha: opacity * 0.2);

      final radius = 2 + math.sin(progress * 2 * math.pi) * 2;
      canvas.drawCircle(Offset(x.toDouble(), y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class GradientBackground extends StatelessWidget {
  final Widget child;
  final List<Color>? colors;
  final AlignmentGeometry begin;
  final AlignmentGeometry end;

  const GradientBackground({
    super.key,
    required this.child,
    this.colors,
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: begin,
          end: end,
          colors: colors ??
              [
                AppTheme.backgroundColor,
                AppTheme.secondaryLightColor.withValues(alpha: 0.5),
                AppTheme.primaryColor.withValues(alpha: 0.1),
              ],
        ),
      ),
      child: child,
    );
  }
}

class FloatingCard extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double amplitude;

  const FloatingCard({
    super.key,
    required this.child,
    this.duration = const Duration(seconds: 3),
    this.amplitude = 10.0,
  });

  @override
  State<FloatingCard> createState() => _FloatingCardState();
}

class _FloatingCardState extends State<FloatingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: -widget.amplitude,
      end: widget.amplitude,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: widget.child,
        );
      },
    );
  }
}

class PulsingWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double minScale;
  final double maxScale;

  const PulsingWidget({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
    this.minScale = 0.95,
    this.maxScale = 1.05,
  });

  @override
  State<PulsingWidget> createState() => _PulsingWidgetState();
}

class _PulsingWidgetState extends State<PulsingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: widget.minScale,
      end: widget.maxScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: widget.child,
        );
      },
    );
  }
}
