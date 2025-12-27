import 'package:flutter/material.dart';
import '../models/created_task_view_model.dart';
import '../../../../chat/models/chat_channel.dart';
import '../../../../chat/models/chat_conversation.dart';
import '../../../../chat/widgets/chat_shell.dart';
import 'manager_task_details_panel.dart';

class CreatedTaskWorkspace extends StatefulWidget {
  final CreatedTaskViewModel task;
  final String currentUserUid;
  final String tenantId;
  final VoidCallback onBack;

  const CreatedTaskWorkspace({
    super.key,
    required this.task,
    required this.currentUserUid,
    required this.tenantId,
    required this.onBack,
  });

  @override
  State<CreatedTaskWorkspace> createState() => _CreatedTaskWorkspaceState();
}

class _CreatedTaskWorkspaceState extends State<CreatedTaskWorkspace> {
  String activeView = 'details'; // 'details', 'chat'

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildTopBar(),
        const Divider(color: Colors.white24, height: 1),
        Expanded(child: _buildContent()),
      ],
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.cyan),
                onPressed: widget.onBack,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.task.title.isEmpty ? 'Task' : widget.task.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.purple.withOpacity(0.5)),
                      ),
                      child: const Text(
                        'YOU ARE THE MANAGER',
                        style: TextStyle(
                          color: Colors.purpleAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.info_outline,
                  label: 'Task Details',
                  isActive: activeView == 'details',
                  onTap: () => setState(() => activeView = 'details'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.chat_bubble_outline,
                  label: 'Chat with Lead',
                  isActive: activeView == 'chat',
                  onTap: () => setState(() => activeView = 'chat'),
                  color: Colors.cyanAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    Color color = Colors.white70,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isActive
              ? color.withOpacity(0.15)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? color : Colors.white24,
            width: isActive ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isActive ? color : Colors.white54),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isActive ? color : Colors.white54,
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (activeView) {
      case 'chat':
        return _buildManagerChat();
      default:
        return ManagerTaskDetailsPanel(
          task: widget.task,
          tenantId: widget.tenantId,
        );
    }
  }

  Widget _buildManagerChat() {
    // Check if lead is assigned
    if (!widget.task.hasLead) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_off_outlined,
                size: 64,
                color: Colors.white.withOpacity(0.2),
              ),
              const SizedBox(height: 16),
              const Text(
                'No lead member assigned to this task',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Assign a lead member to start communication',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final conversation = ChatConversation(
      conversationId: widget.task.docId,
      taskTitle: widget.task.title,
      assignedByUid: widget.currentUserUid, // You are the manager
      assignedToUids: widget.task.assignedToUids,
      leadMemberUid: widget.task.leadMemberId,
    );

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ChatShell(
        tenantId: widget.tenantId,
        conversation: conversation,
        channel: ChatChannel.managerCommunication,
        currentUserId: widget.currentUserUid,
      ),
    );
  }
}
