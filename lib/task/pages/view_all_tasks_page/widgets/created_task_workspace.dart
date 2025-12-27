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
  String activeView = 'details'; // 'details' or 'chat'

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top bar
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.cyan),
                onPressed: widget.onBack,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.task.title.isEmpty ? 'Task' : widget.task.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Toggle button to switch views
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    activeView = activeView == 'details' ? 'chat' : 'details';
                  });
                },
                icon: Icon(
                  activeView == 'details' ? Icons.chat : Icons.info_outline,
                  color: Colors.cyan,
                ),
                label: Text(
                  activeView == 'details' ? 'Chat with Lead' : 'Task Details',
                  style: const TextStyle(color: Colors.cyan),
                ),
              ),
            ],
          ),
        ),
        const Divider(color: Colors.white24, height: 1),
        // Content
        Expanded(
          child: activeView == 'details'
              ? ManagerTaskDetailsPanel(task: widget.task)
              : buildManagerChat(),
        ),
      ],
    );
  }

  Widget buildManagerChat() {
    // Manager chats with LEAD only using assigned_by_chat
    if (!widget.task.hasLead) {
      return const Center(
        child: Text(
          'No lead assigned to this task',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    final conversation = ChatConversation(
      conversationId: widget.task.docId,
      taskTitle: widget.task.title,
      assignedByUid: widget.currentUserUid,  // You are the manager
      assignedToUids: widget.task.assignedToUids,
      leadMemberUid: widget.task.leadMemberId,
    );

    return ChatShell(
      tenantId: widget.tenantId,
      conversation: conversation,
      channel: ChatChannel.assignedBy,  // Manager <-> Lead channel
      currentUserId: widget.currentUserUid,
    );
  }
}
