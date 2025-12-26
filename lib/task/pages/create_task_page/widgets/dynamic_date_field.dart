import 'package:flutter/material.dart';
import '../../../../core/glass_container.dart';

class DynamicDateField extends StatefulWidget {
  final String label;
  final bool required;
  final ValueChanged<DateTime?> onChanged;

  const DynamicDateField({
    super.key,
    required this.label,
    required this.required,
    required this.onChanged,
  });

  @override
  State<DynamicDateField> createState() => _DynamicDateFieldState();
}

class _DynamicDateFieldState extends State<DynamicDateField> {
  DateTime? _value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: _pickDateTime,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: widget.label,
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
            suffixIcon:
                const Icon(Icons.calendar_today, color: Colors.cyanAccent),
          ),
          child: Text(
            _value == null
                ? 'Select date & time'
                : '${_value!.year}-${_value!.month.toString().padLeft(2, '0')}-${_value!.day.toString().padLeft(2, '0')} '
                    '${_value!.hour.toString().padLeft(2, '0')}:${_value!.minute.toString().padLeft(2, '0')}',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final initial = _value ?? now;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(now) ? now : initial,
      firstDate: now,
      lastDate: DateTime(now.year + 10),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.cyanAccent,
              onPrimary: Colors.black,
              surface: Colors.transparent,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: Colors.transparent,
          ),
          child: _wrapGlass(child!),
        );
      },
    );

    if (pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.cyanAccent,
              onPrimary: Colors.black,
              surface: Colors.transparent,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: Colors.transparent,
          ),
          child: _wrapGlass(child!),
        );
      },
    );

    if (pickedTime == null) return;

    final combined = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    final clamped = combined.isBefore(now) ? now : combined;
    setState(() => _value = clamped);
    widget.onChanged(clamped);
  }

  Widget _wrapGlass(Widget child) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 640,
          maxWidth: 640,
          minHeight: 420,
          maxHeight: 420,
        ),
        child: GlassContainer(
          blur: 40,
          opacity: 0.22,
          tint: Colors.black,
          borderRadius: BorderRadius.circular(22),
          blurMode: GlassBlurMode.perWidget,
          padding: const EdgeInsets.all(8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: child,
          ),
        ),
      ),
    );
  }
}
