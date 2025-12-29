import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../chat/models/chat_channel.dart';
import '../../../../chat/models/chat_conversation.dart';
import '../../../../chat/widgets/chat_shell.dart';
import '../models/created_task_view_model.dart';
import 'manager_task_details_panel.dart';

class CreatedTaskWorkspace extends StatefulWidget {
  final CreatedTaskViewModel task;
  final String tenantId;
  final VoidCallback onBack;

  const CreatedTaskWorkspace({
    super.key,
    required this.task,
    required this.tenantId,
    required this.onBack,
  });

  @override
  State<CreatedTaskWorkspace> createState() => _CreatedTaskWorkspaceState();
}

class _CreatedTaskWorkspaceState extends State<CreatedTaskWorkspace> {
  String activeView = 'details'; // details | manager

  String get currentUserUid => FirebaseAuth.instance.currentUser?.uid ?? '';

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
          // Header row with back button and title
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.cyan),
                onPressed: widget.onBack,
                tooltip: 'Back',
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.task.title.isEmpty ? 'TASK' : widget.task.title.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ✅ FIXED: Only 2 tabs (Details, Manager Communication) for View All
          Row(
            children: [
              Expanded(
                child: _buildTabButton(
                  icon: Icons.info_outline,
                  label: 'Task Details',
                  isActive: activeView == 'details',
                  onTap: () => setState(() => activeView = 'details'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTabButton(
                  icon: Icons.support_agent,
                  label: 'Manager Comm',
                  isActive: activeView == 'manager',
                  onTap: () => setState(() => activeView = 'manager'),
                  activeColor: Colors.greenAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    Color activeColor = Colors.cyanAccent,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withOpacity(0.15)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isActive ? activeColor : Colors.white.withOpacity(0.2),
            width: isActive ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive ? activeColor : Colors.white60,
              size: 20,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isActive ? activeColor : Colors.white60,
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                ),
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
        return _buildManagerCommunication();
      case 'details':
      default:
        return ManagerTaskDetailsPanel(
          task: widget.task,
          tenantId: widget.tenantId,
        );
    }
  }

  Widget _buildManagerCommunication() {
    final conversation = ChatConversation(
      conversationId: widget.task.docId,
      taskTitle: widget.task.title,
      assignedByUid: currentUserUid,
      assignedToUids: widget.task.assignedToUids,
      leadMemberUid: widget.task.leadMemberId,
      groupName: widget.task.groupName,
      dueDate: widget.task.dueDate,
    );

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ChatShell(
        tenantId: widget.tenantId,
        conversation: conversation,
        channel: ChatChannel.managerCommunication,
        currentUserId: currentUserUid,
      ),
    );
  }
}
