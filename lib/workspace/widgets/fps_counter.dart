import 'package:flutter/material.dart';

class FPSCounter extends StatelessWidget {
  final double fps;
  final bool isAnimating;
  final bool isLowEnd;
  final bool vsyncLocked;
  final double avgFrameTime;
  final bool warmupStable;
  final VoidCallback onToggle;

  const FPSCounter({
    super.key,
    required this.fps,
    required this.isAnimating,
    required this.isLowEnd,
    required this.vsyncLocked,
    required this.avgFrameTime,
    required this.warmupStable,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    Color fpsColor;
    String status;

    if (fps >= 58) {
      fpsColor = Colors.greenAccent;
      status = 'EXCELLENT';
    } else if (fps >= 50) {
      fpsColor = Colors.yellowAccent;
      status = 'GOOD';
    } else if (fps >= 40) {
      fpsColor = Colors.orangeAccent;
      status = 'FAIR';
    } else if (fps >= 28 && fps <= 32) {
      fpsColor = Colors.redAccent;
      status = 'VSYNC 30FPS';
    } else {
      fpsColor = Colors.red;
      status = 'LOW';
    }

    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.85),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: fpsColor.withOpacity(0.6), width: 2),
          boxShadow: [
            BoxShadow(
              color: fpsColor.withOpacity(0.25),
              blurRadius: 14,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.speed, color: fpsColor, size: 18),
                const SizedBox(width: 6),
                Text(
                  '${fps.toStringAsFixed(1)} FPS',
                  style: TextStyle(
                    color: fpsColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              status,
              style: TextStyle(
                color: fpsColor.withOpacity(0.9),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            if (avgFrameTime > 0) ...[
              const SizedBox(height: 4),
              Text(
                'Frame: ${avgFrameTime.toStringAsFixed(1)}ms',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
            ],
            if (warmupStable) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: Colors.greenAccent.withOpacity(0.45),
                    width: 1,
                  ),
                ),
                child: const Text(
                  'WARM-UP OK',
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
            if (vsyncLocked) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.redAccent, width: 1),
                ),
                child: const Text(
                  'VSYNC LOCKED',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
            if (isLowEnd) ...[
              const SizedBox(height: 4),
              const Text(
                'OPTIMIZED',
                style: TextStyle(
                  color: Colors.orangeAccent,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (isAnimating) ...[
              const SizedBox(height: 4),
              const Text(
                'ANIMATING',
                style: TextStyle(
                  color: Colors.cyanAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
