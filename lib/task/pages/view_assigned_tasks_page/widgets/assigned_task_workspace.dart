import 'package:flutter/material.dart';
import 'package:walld_flutter/task/pages/view_assigned_tasks_page/widgets/task_details_panel.dart';
import '../../../../chat/models/chat_channel.dart';
import '../../../../chat/models/chat_conversation.dart';
import '../../../../chat/widgets/chat_shell.dart';
import '../models/assigned_task_view_model.dart';

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
  String activeView = 'details'; // 'details', 'manager', 'team'

  @override
  Widget build(BuildContext context) {
    final isLead = widget.task.isUserLead(widget.currentUserUid);

    return Column(
      children: [
        _buildTopBar(isLead),
        const Divider(color: Colors.white24, height: 1),
        Expanded(child: _buildContent()),
      ],
    );
  }


  Widget _buildTopBar(bool isLead) {
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
                    if (isLead)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.withOpacity(0.5)),
                        ),
                        child: const Text(
                          'YOU ARE THE LEAD',
                          style: TextStyle(
                            color: Colors.amber,
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
              if (isLead)
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.support_agent,
                    label: 'Manager Communication',
                    isActive: activeView == 'manager',
                    onTap: () => setState(() => activeView = 'manager'),
                    color: Colors.cyanAccent,
                  ),
                ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.groups,
                  label: 'Team Collaboration',
                  isActive: activeView == 'team',
                  onTap: () => setState(() => activeView = 'team'),
                  color: Colors.greenAccent,
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
                  fontSize: 10,
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
    case 'manager':
      return _buildManagerChat();
    case 'team':
      return _buildTeamChat();
    default:
      return TaskDetailsPanel(task: widget.task);
  }
}

Widget _buildManagerChat() {
  // Only lead can access manager communication
  if (!widget.task.isUserLead(widget.currentUserUid)) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: 64,
              color: Colors.white.withOpacity(0.2),
            ),
            const SizedBox(height: 16),
            const Text(
              'Only the lead member can communicate with the manager',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
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
    assignedByUid: widget.task.assignedByUid,
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

Widget _buildTeamChat() {
  final conversation = ChatConversation(
    conversationId: widget.task.docId,
    taskTitle: widget.task.title,
    assignedByUid: widget.task.assignedByUid,
    assignedToUids: widget.task.assignedToUids,
    leadMemberUid: widget.task.leadMemberId,
  );

  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: ChatShell(
      tenantId: widget.tenantId,
      conversation: conversation,
      channel: ChatChannel.teamMembers,
      currentUserId: widget.currentUserUid,
    ),
  );
}

}

