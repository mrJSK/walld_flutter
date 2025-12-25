import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Simple non-interactive card widget (no create-task logic).
class CreateTaskWidget extends StatelessWidget {
  const CreateTaskWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final maxH = constraints.maxHeight;
        final shortest = math.min(maxW, maxH);

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
            // CHANGED background color (more neutral glass-like)
            color: const Color(0xCC0B0F1C),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: const Color(0x33FFFFFF)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x44000000),
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
                'Task Panel',
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
                  'This area can be used to show summary or status of tasks. '
                  'Creation flow has been removed.',
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
                  'Static widget',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.cyanAccent.withOpacity(0.85),
                    fontSize: smallFont,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
