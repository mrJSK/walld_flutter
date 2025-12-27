import 'package:flutter/material.dart';
import '../../../../core/glass_container.dart';

class AssignmentTypeSelector extends StatelessWidget {
  final String? selectedType;
  final ValueChanged<String?> onChanged;

  const AssignmentTypeSelector({
    super.key,
    required this.selectedType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      const DropdownMenuItem(
        value: 'subordinateunit',
        child: Text(
          'Subordinate Unit (Department/Team)',
          style: TextStyle(color: Colors.white),
        ),
      ),
      const DropdownMenuItem(
        value: 'team_member',
        child: Text(
          'Team Member (Colleague)',
          style: TextStyle(color: Colors.white),
        ),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: PopupMenuButton<String>(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        offset: const Offset(0, 8),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'Assignment Type',
            labelStyle: const TextStyle(color: Colors.white70),
            floatingLabelStyle: const TextStyle(color: Colors.cyanAccent),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.white24),
              borderRadius: BorderRadius.circular(18),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.cyanAccent, width: 2),
              borderRadius: BorderRadius.circular(18),
            ),
            filled: true,
            fillColor: Colors.white.withOpacity(0.04),
            suffixIcon: const Icon(Icons.arrow_drop_down, color: Colors.cyanAccent),
          ),
          child: Text(
            selectedType == 'subordinateunit'
                ? 'Subordinate Unit'
                : selectedType == 'team_member'
                    ? 'Team Member'
                    : 'Select Type',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        itemBuilder: (context) => items
            .map(
              (item) => PopupMenuItem<String>(
                value: item.value,
                padding: EdgeInsets.zero,
                child: GlassContainer(
                  blur: 28,
                  opacity: 0.3,
                  tint: Colors.black,
                  blurMode: GlassBlurMode.perWidget,
                  borderRadius: BorderRadius.circular(10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: SizedBox(
                    width: 250,
                    child: item.child,
                  ),
                ),
              ),
            )
            .toList(),
        onSelected: onChanged,
      ),
    );
  }
}
