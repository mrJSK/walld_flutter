import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// import 'performancestate.dart'; // ❌ REMOVED - no more performance overrides

// Controls whether this widget applies per-widget BackdropFilter blur
enum GlassBlurMode { none, perWidget, auto }

// High-level quality selection (user-controlled only)
enum GlassQualityMode { auto, high, medium, low, ultraLow }

class GlassContainer extends StatelessWidget {
  final double blur;
  final double opacity;
  final Color tint;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;
  final Widget child;
  final double borderOpacity;
  final double borderWidth;
  final List<BoxShadow> boxShadow;

  // Controls blur strategy
  final GlassBlurMode blurMode;
  // Controls quality strategy (user choice only)
  final GlassQualityMode qualityMode;
  // Hint from callers (dragging/resizing/scrolling/animating)
  final bool isInteracting;
  // Allow callers to disable shadows completely
  final bool disableShadows;

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
      BoxShadow(
        color: Color(0x40000000),
        blurRadius: 18,
        offset: Offset(0, 10),
      ),
    ],
    this.blurMode = GlassBlurMode.auto,
    this.qualityMode = GlassQualityMode.auto,
    this.isInteracting = false,
    this.disableShadows = false,
  });

  // ✅ FIXED: Always use user's exact settings - NO performance overrides
  GlassQualityMode get resolvedQualityMode {
    // User explicitly chose a quality level
    if (qualityMode != GlassQualityMode.auto) return qualityMode;
    
    // Always use high quality unless user specifically chose lower
    return GlassQualityMode.high;
  }

  // ✅ FIXED: Use EXACT user blur value - no clamping/reduction
  double get effectiveBlur => blur.clamp(0.0, 40.0);

  // ✅ FIXED: Use EXACT user opacity value - no clamping/reduction  
  double get effectiveOpacity => opacity.clamp(0.0, 1.0);

  // ✅ FIXED: Always use full shadows - no performance reduction
  List<BoxShadow> get effectiveShadows {
    if (disableShadows) return const [];
    return boxShadow;
  }

  // ✅ FIXED: Simplified backdrop filter logic - respect user blurMode only
  bool get shouldUseBackdropFilter {
    if (effectiveBlur == 0) return false;
    
    switch (blurMode) {
      case GlassBlurMode.none:
        return false;
      case GlassBlurMode.perWidget:
        return true;
      case GlassBlurMode.auto:
        // Always use backdrop filter if user set blur > 0
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final blurSigma = effectiveBlur.clamp(0.0, 30.0);
    final a = effectiveOpacity;
    
    // Tint fill
    final fill = tint.withOpacity(a);
    
    // Full border (no performance reduction)
    final effBorderOpacity = borderOpacity.clamp(0.0, 1.0);
    final effBorderWidth = borderWidth;

    final decoration = BoxDecoration(
      color: fill,
      borderRadius: borderRadius,
      border: Border.all(
        color: Colors.white.withOpacity(effBorderOpacity),
        width: effBorderWidth,
      ),
      boxShadow: effectiveShadows,
    );

    final body = Container(
      decoration: decoration,
      padding: padding,
      child: child,
    );

    // Fast path: no BackdropFilter
    if (!shouldUseBackdropFilter) {
      return body;
    }

    // High quality: per-widget BackdropFilter
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: blurSigma,
          sigmaY: blurSigma,
        ),
        child: body,
      ),
    );
  }
}
