import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:walld_flutter/core/wallpaper_service.dart'; // adjust package name if different

class CompleteTaskWidget extends StatelessWidget {
  const CompleteTaskWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: WallpaperService.instance,
      builder: (context, _) {
        final ws = WallpaperService.instance;
        // Glass color derived from global glass opacity
        final Color bgColor = const Color(0xFF11111C)
            .withOpacity((ws.globalGlassOpacity * 3).clamp(0.05, 0.45));

        return LayoutBuilder(
          builder: (context, constraints) {
            final maxW = constraints.maxWidth;
            final maxH = constraints.maxHeight;
            final shortest = (maxW < maxH ? maxW : maxH);
            final double unit = (shortest / 8.0).clamp(10.0, 48.0);
            final double radius = (unit * 0.85).clamp(12.0, 42.0);
            final double margin = (unit * 0.25).clamp(4.0, 12.0);
            final EdgeInsets padding =
                EdgeInsets.all((unit * 0.75).clamp(8.0, 28.0));
            final double titleFont = (unit * 1.05).clamp(12.0, 26.0);
            final double bodyFont = (unit * 0.70).clamp(10.0, 18.0);
            final double smallFont = (unit * 0.60).clamp(9.0, 16.0);
            final double gap = (unit * 0.60).clamp(6.0, 18.0);

            return Container(
              margin: EdgeInsets.all(margin),
              decoration: BoxDecoration(
                color: bgColor, // <-- uses the local bgColor
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(color: const Color(0x22FFFFFF)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 18,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              padding: padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Complete Task',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: titleFont,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: gap),
                  Expanded(
                    child: Text(
                      'Panel to mark tasks as completed demo.',
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: bodyFont,
                        height: 1.2,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      'Demo widget content',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: smallFont,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
