import 'package:flutter/material.dart';

class CreateTaskWidget extends StatelessWidget {
  const CreateTaskWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final maxH = constraints.maxHeight;
        final shortest = maxW < maxH ? maxW : maxH;

        // Scale everything from the widget boundary, not screen
        final double cell = shortest / 8; // tune per-widget

        final double radius = cell * 0.8;
        final EdgeInsets padding = EdgeInsets.all(cell * 0.8);
        final double titleFont = cell * 1.1;
        final double bodyFont = cell * 0.7;
        final double smallFont = cell * 0.6;
        final double gap = cell * 0.6;

        return Container(
          margin: EdgeInsets.all(cell * 0.2),
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
              Text(
                'Create Task',
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
                  'Quick entry panel to create a new task (demo).',
                  maxLines: 3,
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
  }
}
