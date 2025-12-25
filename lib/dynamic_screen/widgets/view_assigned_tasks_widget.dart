// lib/dynamic_screen/widgets/view_assigned_tasks_widget.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:walld_flutter/core/wallpaper_service.dart';

class ViewAssignedTasksWidget extends StatelessWidget {
  const ViewAssignedTasksWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: WallpaperService.instance, // same as CompleteTaskWidget [file:11]
      builder: (context, _) {
        final ws = WallpaperService.instance;
        // Same glass color formula as CompleteTaskWidget [file:11]
        final Color bgColor = const Color(0xFF11111C)
            .withOpacity((ws.globalGlassOpacity * 3).clamp(0.05, 0.45));

        return LayoutBuilder(
          builder: (context, constraints) {
            final maxW = constraints.maxWidth;
            final maxH = constraints.maxHeight;
            final shortest = math.min(maxW, maxH);
            final double unit = (shortest / 9.0).clamp(10.0, 48.0);
            final double radius = (unit * 0.90).clamp(12.0, 44.0);
            final double margin = (unit * 0.25).clamp(4.0, 12.0);
            final EdgeInsets padding = EdgeInsets.symmetric(
              horizontal: (unit * 0.90).clamp(10.0, 30.0),
              vertical: (unit * 0.70).clamp(8.0, 24.0),
            );
            final double titleFont = (unit * 1.10).clamp(12.0, 26.0);
            final double bodyFont = (unit * 0.72).clamp(10.0, 18.0);
            final double smallFont = (unit * 0.60).clamp(9.0, 16.0);
            final double gap = (unit * 0.60).clamp(6.0, 18.0); // [file:10]

            return Container(
              margin: EdgeInsets.all(margin),
              decoration: BoxDecoration(
                color: bgColor, // updated from 0xCC0B0F1C to glass color [file:10][file:11]
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
                    'View Assigned Tasks',
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
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        'Tasks currently assigned to you will appear here (demo).',
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: bodyFont,
                          height: 1.2,
                        ),
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
