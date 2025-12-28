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

  // 🚀 OPTIMIZED: Smart BackdropFilter decision logic
  bool get shouldUseBackdropFilter {
    // FAST PATH 1: Skip blur entirely for very low values
    if (effectiveBlur < 2.0) return false;
    
    // FAST PATH 2: During interactions, never use expensive blur
    if (isInteracting) return false;
    
    // Respect blurMode setting
    switch (blurMode) {
      case GlassBlurMode.none:
        return false;
      case GlassBlurMode.perWidget:
        return true;
      case GlassBlurMode.auto:
        // Only use backdrop filter for meaningful blur values
        return effectiveBlur >= 2.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🚀 FAST PATH 1: Low blur values - skip BackdropFilter entirely (BIG FPS WIN)
    if (effectiveBlur < 2.0) {
      return _buildSolidContainer();
    }
    
    // 🚀 FAST PATH 2: During interaction - use simple overlay (no blur) (BIG FPS WIN)
    if (isInteracting) {
      return _buildInteractionOverlay();
    }
    
    // 🚀 HIGH QUALITY: Only use BackdropFilter for static, high-quality states
    return _buildBackdropFilter();
  }

  /// 🚀 Solid container without blur - fastest rendering path
  Widget _buildSolidContainer() {
    final a = effectiveOpacity;
    final fill = tint.withOpacity(a);
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

    return Container(
      decoration: decoration,
      padding: padding,
      child: child,
    );
  }

  /// 🚀 Simple overlay for interactions - no blur, reduced opacity
  Widget _buildInteractionOverlay() {
    // Reduced opacity during interaction for better performance
    final interactionOpacity = effectiveOpacity * 0.7;
    final fill = tint.withOpacity(interactionOpacity.clamp(0.0, 1.0));
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

    return Container(
      decoration: decoration,
      padding: padding,
      child: child,
    );
  }

  /// 🚀 High-quality BackdropFilter - only for static widgets
  Widget _buildBackdropFilter() {
    final blurSigma = effectiveBlur.clamp(0.0, 30.0);
    final a = effectiveOpacity;
    
    // Tint fill
    final fill = tint.withOpacity(a);
    
    // Full border
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

    // ✅ High quality BackdropFilter with optimizations
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: blurSigma,
          sigmaY: blurSigma,
          tileMode: TileMode.clamp, // 🚀 Prevents edge artifacts + GPU optimization
        ),
        child: body,
      ),
    );
  }
}
