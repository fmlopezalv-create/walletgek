import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Escala el widget al presionarlo (efecto "se hunde"), sin interferir con
/// el gesto de tap del hijo (usa Listener, que es pasivo).
class PressableScale extends StatefulWidget {
  final Widget child;
  final double pressedScale;
  const PressableScale({
    super.key,
    required this.child,
    this.pressedScale = 0.92,
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => setState(() => _pressed = true),
      onPointerUp: (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Aparece con desvanecimiento + deslizamiento (retardo opcional para
/// escalonar la entrada de tarjetas).
class FadeIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final double offsetY;
  const FadeIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offsetY = 12,
  });

  @override
  State<FadeIn> createState() => _FadeInState();
}

class _FadeInState extends State<FadeIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );

  late final Animation<double> _fade =
      CurvedAnimation(parent: _controller, curve: Curves.easeOut);

  late final Animation<Offset> _slide = Tween<Offset>(
    begin: Offset(0, widget.offsetY / 100),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

/// Brillo que recorre el borde del widget hijo (efecto "luz que da la vuelta").
/// Vuelve a animarse cada vez que se reconstruye (p. ej. al refrescar o al
/// entrar un valor nuevo).
class BorderShine extends StatefulWidget {
  final Widget child;
  final Color color;
  final double radius;
  final double strokeWidth;
  const BorderShine({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.radius = 20,
    this.strokeWidth = 2.5,
  });

  @override
  State<BorderShine> createState() => _BorderShineState();
}

class _BorderShineState extends State<BorderShine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant BorderShine oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) => Stack(
        children: [
          child!,
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _ShinePainter(
                  _controller.value,
                  widget.color,
                  widget.strokeWidth,
                  widget.radius,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShinePainter extends CustomPainter {
  final double t; // 0..1
  final Color color;
  final double strokeWidth;
  final double radius;

  _ShinePainter(this.t, this.color, this.strokeWidth, this.radius);

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(strokeWidth / 2),
      Radius.circular(radius),
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: 2 * math.pi,
        transform: GradientRotation(t * 2 * math.pi),
        colors: [
          color.withValues(alpha: 0),
          color.withValues(alpha: 0),
          color.withValues(alpha: 0),
          color.withValues(alpha: 0.9),
          color.withValues(alpha: 0),
          color.withValues(alpha: 0),
        ],
        stops: const [0.0, 0.4, 0.46, 0.5, 0.54, 1.0],
      ).createShader(rect);
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _ShinePainter old) =>
      old.t != t || old.color != color;
}

/// Indicador de refresco con anillos de luz expansivos (ripple), en lugar
/// del spinner gris por defecto. Se usa igual que [RefreshIndicator].
class RippleRefresh extends StatefulWidget {
  final Future<void> Function() onRefresh;
  final Widget child;
  const RippleRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  @override
  State<RippleRefresh> createState() => _RippleRefreshState();
}

class _RippleRefreshState extends State<RippleRefresh>
    with SingleTickerProviderStateMixin {
  bool _refreshing = false;
  late final AnimationController _ring = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  late final Animation<double> _ring2 = CurvedAnimation(
    parent: _ring,
    curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
  );

  Future<void> _handle() async {
    setState(() => _refreshing = true);
    try {
      await widget.onRefresh();
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Widget _ringWidget(Animation<double> t) {
    return AnimatedBuilder(
      animation: t,
      builder: (context, _) {
        final v = t.value;
        final size = 18 + 44 * v;
        final opacity = (1 - v).clamp(0.0, 1.0);
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.emerald.withValues(alpha: 0.55 * opacity),
              width: 2.5,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _handle,
          color: Colors.transparent,
          backgroundColor: Colors.transparent,
          child: widget.child,
        ),
        if (_refreshing)
          Positioned(
            top: 10,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Center(
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      _ringWidget(_ring),
                      _ringWidget(_ring2),
                      const Icon(Icons.sync,
                          color: AppColors.emerald, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
