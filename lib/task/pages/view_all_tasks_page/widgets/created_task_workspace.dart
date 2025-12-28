import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:walld_flutter/core/wallpaper_service.dart'; // ADD: WallpaperService import

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
    return AnimatedBuilder(
      animation: WallpaperService.instance, // 🚀 Listen to wallpaper changes
      child: const _StaticWorkspaceContent(), // 🚀 CRITICAL: Static content cache
      builder: (context, child) {
        // 🚀 Only rebuilds decoration - content stays cached!
        final ws = WallpaperService.instance;
        final glassBg = const Color(0xFF11111C)
            .withOpacity((ws.globalGlassOpacity * 3).clamp(0.05, 0.45));


        return Container(
          decoration: BoxDecoration(
            color: glassBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.22),
              width: 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 18,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: child!, // 🚀 Reuses the SAME static content widget
        );
      },
    );
  }
}

/// 🚀 STATIC CONTENT - Never rebuilds on wallpaper changes
class _StaticWorkspaceContent extends StatelessWidget {
  const _StaticWorkspaceContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Expanded(
          flex: 0, // Fixed height top bar
          child: _StaticTopBar(),
        ),
        const Divider(color: Colors.white24, height: 1),
        const Expanded(
          child: _StaticContentArea(),
        ),
      ],
    );
  }
}

/// 🚀 STATIC TOP BAR - Independent rebuild scope
class _StaticTopBar extends StatefulWidget {
  const _StaticTopBar();

  @override
  State<_StaticTopBar> createState() => _StaticTopBarState();
}

class _StaticTopBarState extends State<_StaticTopBar> {
  String activeView = 'details'; // details | manager

  String get currentUserUid => FirebaseAuth.instance.currentUser?.uid ?? '';

  Widget _buildTopBar(CreatedTaskViewModel task, VoidCallback onBack) {
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
                onPressed: onBack,
                tooltip: 'Back',
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  task.title.isEmpty ? 'TASK' : task.title.toUpperCase(),
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

          // Tab buttons
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
                  label: 'Manager Communication',
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

  @override
  Widget build(BuildContext context) {
    // Access parent widget data via Builder
    return Builder(
      builder: (context) {
        final state = context.findAncestorStateOfType<_CreatedTaskWorkspaceState>();
        if (state == null) return const SizedBox();
        
        return _buildTopBar(
          state.widget.task,
          state.widget.onBack,
        );
      },
    );
  }
}

/// 🚀 STATIC CONTENT AREA - Tab content container
class _StaticContentArea extends StatefulWidget {
  const _StaticContentArea();

  @override
  State<_StaticContentArea> createState() => _StaticContentAreaState();
}

class _StaticContentAreaState extends State<_StaticContentArea> {
  String get currentUserUid => FirebaseAuth.instance.currentUser?.uid ?? '';

  Widget _buildContent(CreatedTaskViewModel task, String tenantId) {
    switch (activeView) {
      case 'manager':
        return _buildManagerCommunication(task, tenantId);
      case 'details':
      default:
        return ManagerTaskDetailsPanel(
          task: task,
          tenantId: tenantId,
        );
    }
  }

  Widget _buildManagerCommunication(CreatedTaskViewModel task, String tenantId) {
    final conversation = ChatConversation(
      conversationId: task.docId,
      taskTitle: task.title,
      assignedByUid: currentUserUid,
      assignedToUids: task.assignedToUids,
      leadMemberUid: task.leadMemberId,
      groupName: task.groupName,
      dueDate: task.dueDate,
    );

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ChatShell(
        tenantId: tenantId,
        conversation: conversation,
        channel: ChatChannel.managerCommunication,
        currentUserId: currentUserUid,
      ),
    );
  }

  String get activeView {
    // Sync with top bar state
    final state = context.findAncestorStateOfType<_StaticTopBarState>();
    return state?.activeView ?? 'details';
  }

  @override
  Widget build(BuildContext context) {
    // Access parent widget data
    return Builder(
      builder: (context) {
        final state = context.findAncestorStateOfType<_CreatedTaskWorkspaceState>();
        if (state == null) return const SizedBox();
        
        return _buildContent(
          state.widget.task,
          state.widget.tenantId,
        );
      },
    );
  }
}
