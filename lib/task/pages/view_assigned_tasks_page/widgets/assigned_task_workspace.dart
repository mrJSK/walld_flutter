import 'package:flutter/material.dart';

import '../../../../core/glass_container.dart';
import '../models/assigned_task_view_model.dart';
import 'task_details_panel.dart';

class AssignedTaskWorkspace extends StatefulWidget {
  final AssignedTaskViewModel task;
  final String currentUserUid;
  final String tenantId;
  final VoidCallback onBack;

  const AssignedTaskWorkspace({
    super.key,
    required this.task,
    required this.currentUserUid,
    required this.tenantId,
    required this.onBack,
  });

  @override
  State<AssignedTaskWorkspace> createState() => _AssignedTaskWorkspaceState();
}

class _AssignedTaskWorkspaceState extends State<AssignedTaskWorkspace> {
  // later this can control which sub‑view is visible: details, Ask Doubt chat, Submit Progress chat, etc.
  String _activeView = 'details'; // 'details' | 'ask_doubt' | 'submit_progress'

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top bar with back button and title
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white70, size: 18),
                onPressed: widget.onBack,
                tooltip: 'Back to list',
              ),
              const SizedBox(width: 4),
              Text(
                'Task details',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 4),

        Expanded(
          child: GlassContainer(
            blur: 18,
            opacity: 0.1,
            tint: Colors.black,
            borderRadius: BorderRadius.circular(18),
            padding: const EdgeInsets.all(16),
            child: _buildActiveView(),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveView() {
    switch (_activeView) {
      case 'ask_doubt':
        // TODO: integrate WhatsApp-style chat (Ask Doubt) here using shared chat module
        return const Center(
          child: Text(
            'Ask Doubt chat will appear here.',
            style: TextStyle(color: Colors.white70),
          ),
        );

      case 'submit_progress':
        // TODO: integrate Submit Progress chat view here
        return const Center(
          child: Text(
            'Submit Progress chat will appear here.',
            style: TextStyle(color: Colors.white70),
          ),
        );

      case 'details':
      default:
        return TaskDetailsPanel(
          task: widget.task,
          currentUserUid: widget.currentUserUid,
          onAskDoubt: () {
            setState(() => _activeView = 'ask_doubt');
          },
          onSubmitProgress: () {
            setState(() => _activeView = 'submit_progress');
          },
        );
    }
  }
}
