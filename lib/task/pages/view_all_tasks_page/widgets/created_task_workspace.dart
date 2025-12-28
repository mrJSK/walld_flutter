import 'package:flutter/material.dart';
import '../../../../chat/models/chat_channel.dart';
import '../../../../chat/models/chat_conversation.dart';
import '../../../../chat/widgets/chat_shell.dart';
import '../models/created_task_view_model.dart';
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

class _CreatedTaskWorkspaceState extends State<CreatedTaskWorkspace>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final ChatConversation _conversation;
  late final bool _showBothTabs;

  @override
  void initState() {
    super.initState();

    // ✅ Show both tabs only if assigneeCount > 1
    _showBothTabs = widget.task.assigneeCount > 1;

    _tabController = TabController(
      length: _showBothTabs ? 2 : 1,
      vsync: this,
    );

    _conversation = ChatConversation(
      conversationId: widget.task.docId,
      taskTitle: widget.task.title,
      assignedByUid: widget.currentUserUid,
      assignedToUids: widget.task.assignedToUids,
      leadMemberUid: widget.task.leadMemberId,
      groupName: widget.task.groupName,
      dueDate: widget.task.dueDate,
    );

    debugPrint(
        'WORKSPACE: assigneeCount=${widget.task.assigneeCount}, '
        'showBothTabs=$_showBothTabs');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          // Header with back button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: widget.onBack,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.task.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.task.groupName.isNotEmpty)
                        Text(
                          widget.task.groupName,
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tab bar (only show if both tabs are needed)
          if (_showBothTabs)
            TabBar(
              controller: _tabController,
              indicatorColor: Colors.cyanAccent,
              labelColor: Colors.cyanAccent,
              unselectedLabelColor: Colors.white60,
              tabs: const [
                Tab(
                  icon: Icon(Icons.info_outline),
                  text: 'Task Details',
                ),
                Tab(
                  icon: Icon(Icons.people),
                  text: 'Team Collaboration',
                ),
              ],
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.white12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.info_outline, color: Colors.cyanAccent, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Task Details',
                    style: TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          const Divider(color: Colors.white12, height: 1),

          // Content
          Expanded(
            child: _showBothTabs
                ? TabBarView(
                    controller: _tabController,
                    children: [
                      // Tab 1: Task Details + Manager Chat
                      _buildManagerChatTab(),

                      // Tab 2: Team Collaboration Chat
                      ChatShell(
                        tenantId: widget.tenantId,
                        conversation: _conversation,
                        channel: ChatChannel.teamMembers,
                        currentUserId: widget.currentUserUid,
                      ),
                    ],
                  )
                : _buildManagerChatTab(), // Single member: only manager chat
          ),
        ],
      ),
    );
  }

  Widget _buildManagerChatTab() {
    return Row(
      children: [
        // Left: Task details panel
        Expanded(
          flex: 2,
          child: ManagerTaskDetailsPanel(
            task: widget.task,
            tenantId: widget.tenantId,
          ),
        ),

        const VerticalDivider(color: Colors.white12, width: 1),

        // Right: Manager communication chat
        Expanded(
          flex: 3,
          child: ChatShell(
            tenantId: widget.tenantId,
            conversation: _conversation,
            channel: ChatChannel.managerCommunication,
            currentUserId: widget.currentUserUid,
          ),
        ),
      ],
    );
  }
}
