// lib/core/glasscontainer.dart
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'performance_state.dart';

/// Controls whether this widget applies per-widget BackdropFilter blur.
///
/// - [none]: Never uses BackdropFilter (recommended when you plan to use ONE global blur layer,
///           or a pre-blurred wallpaper image).
/// - [perWidget]: Always uses BackdropFilter when blur >= 2.0 (expensive; avoid on low-end).
/// - [auto]: Uses BackdropFilter only when conditions are good (warm-up stable + good FPS + not interacting).
enum GlassBlurMode {
  none,
  perWidget,
  auto,
}

/// High-level quality selection.
///
/// - [auto]: Decides based on [PerformanceState.instance.currentFps] and [isInteracting].
/// - Others: Force a specific quality level.
enum GlassQualityMode {
  auto,
  high,
  medium,
  low,
  ultraLow,
}

/// A performant “glass” container.
///
/// Key performance idea:
/// - Prefer a SINGLE global blur layer (or pre-blurred wallpaper) instead of per-widget blur.
/// - This widget can be used in "no blur" mode while still keeping the glass look via opacity/tint.
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

  /// New: controls blur strategy.
  final GlassBlurMode blurMode;

  /// New: controls quality strategy.
  final GlassQualityMode qualityMode;

  /// New: hint from callers (dragging/resizing/scrolling/animating) to reduce effects.
  final bool isInteracting;

  /// New: allow callers to disable shadows completely (useful during animations).
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

    // Defaults: prioritize FPS.
    this.blurMode = GlassBlurMode.auto,
    this.qualityMode = GlassQualityMode.auto,
    this.isInteracting = false,
    this.disableShadows = false,
  });

  GlassQualityMode _resolveQualityMode() {
    if (qualityMode != GlassQualityMode.auto) return qualityMode;

    // Caller says this is a hot path (dragging/resizing/scrolling/animating)
    if (isInteracting) return GlassQualityMode.low;

    final fps = PerformanceState.instance.currentFps;

    // If FPS is unknown (e.g., early startup), be conservative.
    if (fps == null) return GlassQualityMode.low;

    if (fps < 30) return GlassQualityMode.ultraLow;
    if (fps < 45) return GlassQualityMode.low;
    if (fps < 55) return GlassQualityMode.medium;
    return GlassQualityMode.high;
  }

  double _effectiveBlur(GlassQualityMode q, double requested) {
    final b = requested.clamp(0.0, 40.0);
    switch (q) {
      case GlassQualityMode.ultraLow:
        return 0.0;
      case GlassQualityMode.low:
        // Keep only a tiny blur (or none) to avoid saveLayer+blur cost.
        return b.clamp(0.0, 2.0);
      case GlassQualityMode.medium:
        return b.clamp(0.0, 6.0);
      case GlassQualityMode.high:
      case GlassQualityMode.auto:
        return b;
    }
  }

  double _effectiveOpacity(GlassQualityMode q, double requested) {
    final o = requested.clamp(0.0, 1.0);
    switch (q) {
      case GlassQualityMode.ultraLow:
        // More opaque reduces blending cost & overdraw artifacts.
        return o.clamp(0.08, 0.30);
      case GlassQualityMode.low:
        return o.clamp(0.06, 0.28);
      case GlassQualityMode.medium:
        return o.clamp(0.05, 0.26);
      case GlassQualityMode.high:
      case GlassQualityMode.auto:
        return o;
    }
  }

  List<BoxShadow> _effectiveShadows(GlassQualityMode q) {
    if (disableShadows) return const [];

    // Shadows add overdraw; remove them on low quality.
    if (q == GlassQualityMode.ultraLow || q == GlassQualityMode.low) {
      return const [];
    }

    final factor = q == GlassQualityMode.medium ? 0.55 : 1.0;
    return boxShadow
        .map(
          (s) => BoxShadow(
            color: s.color.withOpacity(s.color.opacity * factor),
            offset: s.offset * factor,
            blurRadius: s.blurRadius * factor,
            spreadRadius: s.spreadRadius * factor,
          ),
        )
        .toList(growable: false);
  }

  bool _shouldUseBackdropFilter({
    required GlassQualityMode q,
    required double blurSigma,
  }) {
    if (blurSigma < 2.0) return false;

    switch (blurMode) {
      case GlassBlurMode.none:
        return false;

      case GlassBlurMode.perWidget:
        // Always enable (expensive).
        return true;

      case GlassBlurMode.auto:
        // Only enable in "high" mode and only after warm-up stability
        // so low-end / startup doesn’t pay the blur cost.
        if (!PerformanceState.instance.isWarmupStable) return false;
        return q == GlassQualityMode.high && !isInteracting;
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = _resolveQualityMode();

    final blurSigma = _effectiveBlur(q, blur);
    final a = _effectiveOpacity(q, opacity);

    // Tint fill
    final fill = tint.withOpacity(a);

    // Reduce border work in low quality.
    final effBorderOpacity = (q == GlassQualityMode.ultraLow)
        ? (borderOpacity * 0.35).clamp(0.0, 1.0)
        : (q == GlassQualityMode.low)
            ? (borderOpacity * 0.55).clamp(0.0, 1.0)
            : borderOpacity.clamp(0.0, 1.0);

    final effBorderWidth = (q == GlassQualityMode.ultraLow)
        ? (borderWidth * 0.5).clamp(0.0, borderWidth)
        : borderWidth;

    final decoration = BoxDecoration(
      color: fill,
      borderRadius: borderRadius,
      border: Border.all(
        color: Colors.white.withOpacity(effBorderOpacity),
        width: effBorderWidth,
      ),
      boxShadow: _effectiveShadows(q),
    );

    final body = Container(
      decoration: decoration,
      padding: padding,
      child: child,
    );

    final useBackdrop = _shouldUseBackdropFilter(q: q, blurSigma: blurSigma);

    // Fast path (recommended): no BackdropFilter at all.
    if (!useBackdrop) {
      return body;
    }

    // Slow path (high quality only): per-widget BackdropFilter.
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: body,
      ),
    );
  }
}
