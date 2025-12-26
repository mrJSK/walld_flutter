import 'package:flutter/material.dart';

class LeadBadge extends StatelessWidget {
  final bool isCurrentUserLead;

  const LeadBadge({
    super.key,
    required this.isCurrentUserLead,
  });

  @override
  Widget build(BuildContext context) {
    if (!isCurrentUserLead) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.16),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber, width: 0.8),
      ),
      child: const Text(
        'YOU ARE THE LEAD',
        style: TextStyle(
          color: Colors.amber,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
