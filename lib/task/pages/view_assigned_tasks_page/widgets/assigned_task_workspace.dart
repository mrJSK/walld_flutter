import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../chat/models/chat_channel.dart';
import '../../../../chat/models/chat_conversation.dart';
import '../../../../chat/widgets/chat_shell.dart';
import '../models/assigned_task_view_model.dart';
import 'task_details_panel.dart';

enum TaskRole { manager, lead, member }

class AssignedTaskWorkspace extends StatefulWidget {
  final AssignedTaskViewModel task;
  final String tenantId;
  final VoidCallback onBack;

  const AssignedTaskWorkspace({
    super.key,
    required this.task,
    required this.tenantId,
    required this.onBack,
  });

  @override
  State<AssignedTaskWorkspace> createState() => _AssignedTaskWorkspaceState();
}

class _AssignedTaskWorkspaceState extends State<AssignedTaskWorkspace> {
  String activeView = 'details'; // details | manager | team

  String get currentUserUid => FirebaseAuth.instance.currentUser?.uid ?? '';

  /// ✅ Determine user role
  TaskRole get role {
    if (currentUserUid == widget.task.assignedByUid) return TaskRole.manager;
    if (widget.task.isUserLead(currentUserUid)) return TaskRole.lead;
    return TaskRole.member;
  }

  /// ✅ NEW: Check if this is a single-member task
  bool get isSingleMember => widget.task.assigneeCount == 1;

  /// ✅ NEW: Check if this is a group task
  bool get isGroupTask => widget.task.assigneeCount > 1;

  /// ✅ NEW: Show Manager Communication tab logic
  bool get showManagerComm {
    // Single member (Member): YES (Details, Manager Comm)
    if (isSingleMember && role == TaskRole.member) return true;
    
    // Group task (Lead): YES (Details, Manager, Team)
    if (isGroupTask && role == TaskRole.lead) return true;
    
    // Group task (Member): NO (Details, Team only)
    return false;
  }

  /// ✅ NEW: Show Team Collaboration tab logic
  bool get showTeamCollab {
    // Single member: NO (only Details, Manager Comm)
    if (isSingleMember) return false;
    
    // Group task (Lead): YES (Details, Manager, Team)
    if (isGroupTask && role == TaskRole.lead) return true;
    
    // Group task (Member): YES (Details, Team)
    if (isGroupTask && role == TaskRole.member) return true;
    
    return false;
  }

  @override
  void initState() {
    super.initState();
    _validateActiveView();
  }

  /// ✅ Ensure activeView is valid for current role and task type
  void _validateActiveView() {
    if (!showManagerComm && activeView == 'manager') {
      activeView = 'details';
    }
    if (!showTeamCollab && activeView == 'team') {
      activeView = 'details';
    }
  }

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

          // ✅ Dynamic tab buttons based on role and task type
          _buildTabButtons(),
        ],
      ),
    );
  }

  /// ✅ NEW: Build tabs dynamically based on visibility rules
  Widget _buildTabButtons() {
    final List<Widget> buttons = [];

    // 1. Task Details - ALWAYS VISIBLE
    buttons.add(
      Expanded(
        child: _buildTabButton(
          icon: Icons.info_outline,
          label: 'Details',
          isActive: activeView == 'details',
          onTap: () => setState(() => activeView = 'details'),
        ),
      ),
    );

    // 2. Manager Communication - Conditional
    if (showManagerComm) {
      buttons.add(const SizedBox(width: 12));
      buttons.add(
        Expanded(
          child: _buildTabButton(
            icon: Icons.support_agent,
            label: 'Manager',
            isActive: activeView == 'manager',
            onTap: () => setState(() => activeView = 'manager'),
            activeColor: Colors.cyanAccent,
          ),
        ),
      );
    }

    // 3. Team Collaboration - Conditional
    if (showTeamCollab) {
      buttons.add(const SizedBox(width: 12));
      buttons.add(
        Expanded(
          child: _buildTabButton(
            icon: Icons.group,
            label: 'Team',
            isActive: activeView == 'team',
            onTap: () => setState(() => activeView = 'team'),
            activeColor: Colors.greenAccent,
          ),
        ),
      );
    }

    return Row(children: buttons);
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
    // ✅ Validate view before rendering
    if (!showManagerComm && activeView == 'manager') activeView = 'details';
    if (!showTeamCollab && activeView == 'team') activeView = 'details';

    switch (activeView) {
      case 'manager':
        return _buildManagerCommunication();
      case 'team':
        return _buildTeamCollaboration();
      case 'details':
      default:
        return TaskDetailsPanel(
          task: widget.task,
          tenantId: widget.tenantId,
        );
    }
  }

  Widget _buildManagerCommunication() {
    final conversation = ChatConversation(
      conversationId: widget.task.docId,
      taskTitle: widget.task.title,
      assignedByUid: widget.task.assignedByUid,
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

  Widget _buildTeamCollaboration() {
    final conversation = ChatConversation(
      conversationId: widget.task.docId,
      taskTitle: widget.task.title,
      assignedByUid: widget.task.assignedByUid,
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
        channel: ChatChannel.teamMembers,
        currentUserId: currentUserUid,
      ),
    );
  }
}
