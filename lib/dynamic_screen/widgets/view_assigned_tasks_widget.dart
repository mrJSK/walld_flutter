// lib/dynamic_screen/widgets/view_assigned_tasks_widget.dart
import 'package:flutter/material.dart';

class ViewAssignedTasksWidget extends StatelessWidget {
  const ViewAssignedTasksWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // This is the boundary decided by the screen grid (colSpan × rowSpan)
        final maxW = constraints.maxWidth;
        final maxH = constraints.maxHeight;

        // Use the smaller side as baseline for scaling
        final shortest = maxW < maxH ? maxW : maxH;

        // Derive a "unit" from the boundary; tweak divisor to taste
        final double unit = shortest / 9.0;

        final double radius = unit * 0.9;
        final EdgeInsets padding = EdgeInsets.symmetric(
          horizontal: unit * 0.9,
          vertical: unit * 0.7,
        );
        final double titleFont = unit * 1.1;
        final double bodyFont = unit * 0.7;
        final double smallFont = unit * 0.6;
        final double gap = unit * 0.6;

        return Container(
          margin: EdgeInsets.all(unit * 0.25),
          decoration: BoxDecoration(
            color: const Color(0x6611111C),
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
            mainAxisSize: MainAxisSize.max,
            children: [
              // TITLE AREA (top of the card)
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

              // DESCRIPTION AREA (takes all remaining height except footer)
              Expanded(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    'Tasks currently assigned to you will appear here (demo).',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: bodyFont,
                      height: 1.2,
                    ),
                  ),
                ),
              ),

              // FOOTER AREA (bottom line)
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
  }
}
