import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_state.dart';

/// Monto estático. Si [hide] es true muestra "••••".
class MoneyText extends StatelessWidget {
  final double value;
  final TextStyle? style;
  final bool sign; // muestra '+' para positivos (ingresos)
  final String? prefix;
  final String? suffix;
  final bool hide;

  const MoneyText(
    this.value, {
    super.key,
    this.style,
    this.sign = false,
    this.prefix,
    this.suffix,
    this.hide = false,
  });

  @override
  Widget build(BuildContext context) {
    final app = AppState.instance;
    if (hide) {
      return Text('${prefix ?? ''}••••${suffix ?? ''}', style: style);
    }
    final s = value < 0 ? '-' : (sign && value > 0 ? '+' : '');
    return Text(
      '$s${prefix ?? ''}${app.symbol}${value.abs().toStringAsFixed(2)}${suffix ?? ''}',
      style: style,
    );
  }
}

/// Monto que cuenta de 0 hasta su valor al aparecer (microanimación).
class AnimatedMoney extends StatefulWidget {
  final double value;
  final TextStyle? style;
  final bool sign;
  final String? prefix;
  final String? suffix;
  final Duration duration;
  final bool hide;

  const AnimatedMoney(
    this.value, {
    super.key,
    this.style,
    this.sign = false,
    this.prefix,
    this.suffix,
    this.duration = const Duration(milliseconds: 900),
    this.hide = false,
  });

  @override
  State<AnimatedMoney> createState() => _AnimatedMoneyState();
}

class _AnimatedMoneyState extends State<AnimatedMoney>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant AnimatedMoney oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppState.instance;
    if (widget.hide) {
      return Text('${widget.prefix ?? ''}••••${widget.suffix ?? ''}',
          style: widget.style);
    }
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final v = widget.value * _animation.value;
        final s = widget.value < 0
            ? '-'
            : (widget.sign && widget.value > 0 ? '+' : '');
        return Text(
          '$s${widget.prefix ?? ''}${app.symbol}${v.abs().toStringAsFixed(2)}${widget.suffix ?? ''}',
          style: widget.style,
        );
      },
    );
  }
}

/// Barra de progreso que se llena al aparecer (microanimación).
class AnimatedProgress extends StatefulWidget {
  final double value; // 0..1
  final Color color;
  final Color? backgroundColor;
  final double height;
  final Duration duration;

  const AnimatedProgress({
    super.key,
    required this.value,
    required this.color,
    this.backgroundColor,
    this.height = 8,
    this.duration = const Duration(milliseconds: 900),
  });

  @override
  State<AnimatedProgress> createState() => _AnimatedProgressState();
}

class _AnimatedProgressState extends State<AnimatedProgress>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant AnimatedProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clamped = widget.value.clamp(0.0, 1.0);
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => ClipRRect(
        borderRadius: BorderRadius.circular(widget.height / 2),
        child: LinearProgressIndicator(
          value: math.max(0.0, clamped * _animation.value),
          minHeight: widget.height,
          color: widget.color,
          backgroundColor: widget.backgroundColor ??
              Colors.white.withValues(alpha: 0.08),
        ),
      ),
    );
  }
}
