import 'dart:ui';
import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  final double blur; // sigma
  final double opacity; // 0..1
  final Color tint;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;
  final Widget child;

  // Visual tuning
  final double borderOpacity;
  final double borderWidth;
  final List<BoxShadow> boxShadow;

  const GlassContainer({
    super.key,
    required this.blur,
    required this.opacity,
    required this.tint,
    required this.borderRadius,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.borderOpacity = 0.18,
    this.borderWidth = 1,
    this.boxShadow = const [
      BoxShadow(color: Color(0x40000000), blurRadius: 18, offset: Offset(0, 10)),
    ],
  });

  @override
  Widget build(BuildContext context) {
    final blurSigma = blur.clamp(0.0, 30.0);
    final a = opacity.clamp(0.0, 1.0);
    final fill = tint.withOpacity(a);

    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: fill,
            borderRadius: borderRadius,
            border: Border.all(
              color: Colors.white.withOpacity(borderOpacity),
              width: borderWidth,
            ),
            boxShadow: boxShadow,
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
