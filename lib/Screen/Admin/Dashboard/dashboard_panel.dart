import 'package:flutter/material.dart';
import '../admin_repository.dart';

class DashboardPanel extends StatefulWidget {
  final String tenantId;

  const DashboardPanel({super.key, required this.tenantId});

  @override
  State<DashboardPanel> createState() => _DashboardPanelState();
}

class _DashboardPanelState extends State<DashboardPanel> {
  final AdminRepository _repo = AdminRepository();

  bool _loading = true;
  Map<String, int> _taskCounts = {};
  List<Map<String, dynamic>> _pendingTasks = [];
  List<Map<String, dynamic>> _completedTasks = [];
  Map<String, int> _orgHealth = {};
  List<Map<String, dynamic>> _approvals = [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
  setState(() => _loading = true);

  try {
    final results = await Future.wait([
      _repo.loadTaskCounts(widget.tenantId),
      _repo.loadRecentTasks(widget.tenantId, status: 'PENDING'),
      _repo.loadRecentTasks(widget.tenantId, status: 'COMPLETED'),
      _repo.loadOrgHealth(widget.tenantId),
      _repo.loadPendingApprovals(widget.tenantId),
    ]);

    if (!mounted) return; // ADDED: Check if still mounted

    setState(() {
      _taskCounts = results[0] as Map<String, int>;
      _pendingTasks = results[1] as List<Map<String, dynamic>>;
      _completedTasks = results[2] as List<Map<String, dynamic>>;
      _orgHealth = results[3] as Map<String, int>;
      _approvals = results[4] as List<Map<String, dynamic>>;
      _loading = false;
    });
  } catch (e) {
    debugPrint('Failed to load admin dashboard: $e');
    if (!mounted) return; // ADDED: Check if still mounted
    
    // ADDED: Show error state with default values
    setState(() {
      _taskCounts = {
        'PENDING': 0,
        'IN_PROGRESS': 0,
        'BLOCKED': 0,
        'PENDING_APPROVAL': 0,
        'COMPLETED': 0,
      };
      _pendingTasks = [];
      _completedTasks = [];
      _orgHealth = {
        'activeUsers': 0,
        'orgNodes': 0,
        'pendingRegistrations': 0,
      };
      _approvals = [];
      _loading = false;
    });
  }
}

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final size = MediaQuery.of(context).size;
    final shortest = size.shortestSide;
    final double scale = shortest < 900 ? 0.85 : (shortest > 1400 ? 1.15 : 1.0);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF05040A), Color(0xFF151827)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 32 * scale,
            vertical: 16 * scale,
          ),
          child: Column(
            children: [
              _TopBar(now: now, scale: scale, tenantId: widget.tenantId),
              SizedBox(height: 24 * scale),
              if (_loading)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.cyan),
                  ),
                )
              else
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 1200;

                      if (isNarrow) {
                        return SingleChildScrollView(
                          child: Column(
                            children: [
                              _TaskOverviewCard(
                                scale: scale,
                                counts: _taskCounts,
                                pendingTasks: _pendingTasks,
                                completedTasks: _completedTasks,
                              ),
                              SizedBox(height: 16 * scale),
                              _ApprovalQueueCard(
                                scale: scale,
                                approvals: _approvals,
                                tenantId: widget.tenantId,
                                repo: _repo,
                                onChanged: _reload,
                              ),
                              SizedBox(height: 16 * scale),
                              Row(
                                children: [
                                  Expanded(
                                    child: _OrgHealthCard(
                                      scale: scale,
                                      health: _orgHealth,
                                    ),
                                  ),
                                  SizedBox(width: 16 * scale),
                                  Expanded(
                                    child: _QuickActionsCard(scale: scale),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }

                      return Column(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: _TaskOverviewCard(
                                    scale: scale,
                                    counts: _taskCounts,
                                    pendingTasks: _pendingTasks,
                                    completedTasks: _completedTasks,
                                  ),
                                ),
                                SizedBox(width: 24 * scale),
                                Expanded(
                                  flex: 2,
                                  child: _ApprovalQueueCard(
                                    scale: scale,
                                    approvals: _approvals,
                                    tenantId: widget.tenantId,
                                    repo: _repo,
                                    onChanged: _reload,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 24 * scale),
                          Expanded(
                            flex: 2,
                            child: Row(
                              children: [
                                Expanded(
                                  child: _OrgHealthCard(
                                    scale: scale,
                                    health: _orgHealth,
                                  ),
                                ),
                                SizedBox(width: 24 * scale),
                                Expanded(
                                  child: _QuickActionsCard(scale: scale),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ========================== TOP BAR ==========================

class _TopBar extends StatelessWidget {
  final DateTime now;
  final double scale;
  final String tenantId;

  const _TopBar({
    required this.now,
    required this.scale,
    required this.tenantId,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return Container(
      height: 36 * scale,
      decoration: BoxDecoration(
        color: const Color(0x660A0A12),
        borderRadius: BorderRadius.circular(18 * scale),
        border: Border.all(color: const Color(0x33FFFFFF)),
      ),
      child: Row(
        children: [
          SizedBox(width: 12 * scale),
          Icon(Icons.blur_on_rounded, size: 18 * scale, color: Colors.cyan),
          SizedBox(width: 6 * scale),
          Text(
            'Wall-D Admin',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14 * scale,
            ),
          ),
          const Spacer(),
          Text(
            '$dateStr $timeStr',
            style: TextStyle(color: Colors.white70, fontSize: 13 * scale),
          ),
          const Spacer(),
          Icon(Icons.cloud_done, size: 16 * scale, color: Colors.greenAccent),
          SizedBox(width: 6 * scale),
          Text(
            tenantId,
            style: TextStyle(color: Colors.white70, fontSize: 13 * scale),
          ),
          SizedBox(width: 12 * scale),
          CircleAvatar(
            radius: 12 * scale,
            backgroundColor: Colors.deepPurple,
            child: Text(
              'A',
              style: TextStyle(fontSize: 12 * scale, color: Colors.white),
            ),
          ),
          SizedBox(width: 8 * scale),
        ],
      ),
    );
  }
}

// ========================== GLASS CARD ==========================

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double scale;

  const _GlassCard({
    required this.child,
    required this.scale,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? EdgeInsets.all(20 * scale),
      decoration: BoxDecoration(
        color: const Color(0x6611111C),
        borderRadius: BorderRadius.circular(24 * scale),
        border: Border.all(color: const Color(0x22FFFFFF)),
        boxShadow: [
          BoxShadow(
            color: const Color(0x33000000),
            blurRadius: 18 * scale,
            offset: Offset(0, 10 * scale),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ========================== TASK OVERVIEW CARD ==========================

class _TaskOverviewCard extends StatefulWidget {
  final double scale;
  final Map<String, int> counts;
  final List<Map<String, dynamic>> pendingTasks;
  final List<Map<String, dynamic>> completedTasks;

  const _TaskOverviewCard({
    required this.scale,
    required this.counts,
    required this.pendingTasks,
    required this.completedTasks,
  });

  @override
  State<_TaskOverviewCard> createState() => _TaskOverviewCardState();
}

class _TaskOverviewCardState extends State<_TaskOverviewCard> {
  String _activeTab = 'pending';

  @override
  Widget build(BuildContext context) {
    final scale = widget.scale;
    final c = widget.counts;

    final stats = [
      _TaskStat('Pending', c['PENDING'] ?? 0, Colors.orangeAccent),
      _TaskStat('In Progress', c['IN_PROGRESS'] ?? 0, Colors.cyanAccent),
      _TaskStat('Blocked', c['BLOCKED'] ?? 0, Colors.redAccent),
      _TaskStat('Awaiting Approval', c['PENDING_APPROVAL'] ?? 0, Colors.purpleAccent),
      _TaskStat('Completed', c['COMPLETED'] ?? 0, Colors.greenAccent),
    ];

    final pendingTasks = widget.pendingTasks
        .map((t) => _RecentTask(
              title: t['title'] ?? 'Untitled Task',
              status: (t['status'] ?? 'PENDING').toString(),
              statusColor: Colors.orangeAccent,
            ))
        .toList();

    final completedTasks = widget.completedTasks
        .map((t) => _RecentTask(
              title: t['title'] ?? 'Untitled Task',
              status: (t['status'] ?? 'COMPLETED').toString(),
              statusColor: Colors.greenAccent,
            ))
        .toList();

    final activeList = _activeTab == 'pending' ? pendingTasks : completedTasks;

    return _GlassCard(
      scale: scale,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Task Overview',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18 * scale,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4 * scale),
          Text(
            'Live snapshot of your organization\'s tasks by status.',
            style: TextStyle(color: Colors.white70, fontSize: 13 * scale),
          ),
          SizedBox(height: 18 * scale),
          
          // Top stats
          Wrap(
            spacing: 16 * scale,
            runSpacing: 16 * scale,
            children: stats
                .map(
                  (s) => _GlassCard(
                    scale: scale,
                    padding: EdgeInsets.symmetric(
                      horizontal: 16 * scale,
                      vertical: 14 * scale,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.label,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13 * scale,
                          ),
                        ),
                        SizedBox(height: 6 * scale),
                        Text(
                          s.count.toString(),
                          style: TextStyle(
                            color: s.color,
                            fontSize: 24 * scale,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
          SizedBox(height: 24 * scale),
          
          // Tabs + horizontal task list
          Row(
            children: [
              Text(
                'Recent Tasks',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14 * scale,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              _TabChip(
                label: 'Pending',
                selected: _activeTab == 'pending',
                scale: scale,
                onTap: () => setState(() => _activeTab = 'pending'),
              ),
              SizedBox(width: 8 * scale),
              _TabChip(
                label: 'Completed',
                selected: _activeTab == 'completed',
                scale: scale,
                onTap: () => setState(() => _activeTab = 'completed'),
              ),
            ],
          ),
          SizedBox(height: 8 * scale),
          SizedBox(
            height: 120 * scale,
            child: activeList.isEmpty
                ? Center(
                    child: Text(
                      'No tasks found.',
                      style: TextStyle(color: Colors.white54, fontSize: 12 * scale),
                    ),
                  )
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: activeList.length,
                    separatorBuilder: (_, __) => SizedBox(width: 12 * scale),
                    itemBuilder: (context, index) {
                      final t = activeList[index];
                      return SizedBox(
                        width: 260 * scale,
                        child: _GlassCard(
                          scale: scale,
                          padding: EdgeInsets.symmetric(
                            horizontal: 16 * scale,
                            vertical: 12 * scale,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13 * scale,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 8 * scale),
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8 * scale,
                                      vertical: 4 * scale,
                                    ),
                                    decoration: BoxDecoration(
                                      color: t.statusColor.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12 * scale),
                                    ),
                                    child: Text(
                                      t.status,
                                      style: TextStyle(
                                        color: t.statusColor,
                                        fontSize: 11 * scale,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool selected;
  final double scale;
  final VoidCallback onTap;

  const _TabChip({
    required this.label,
    required this.selected,
    required this.scale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16 * scale),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 12 * scale,
          vertical: 6 * scale,
        ),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF26263A) : Colors.transparent,
          borderRadius: BorderRadius.circular(16 * scale),
          border: Border.all(
            color: selected
                ? Colors.cyanAccent.withOpacity(0.6)
                : Colors.white24,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.cyanAccent : Colors.white70,
            fontSize: 12 * scale,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _RecentTask {
  final String title;
  final String status;
  final Color statusColor;

  _RecentTask({
    required this.title,
    required this.status,
    required this.statusColor,
  });
}

class _TaskStat {
  final String label;
  final int count;
  final Color color;

  _TaskStat(this.label, this.count, this.color);
}

// ========================== APPROVAL QUEUE CARD ==========================

class _ApprovalQueueCard extends StatelessWidget {
  final double scale;
  final List<Map<String, dynamic>> approvals;
  final String tenantId;
  final AdminRepository repo;
  final Future<void> Function() onChanged;

  const _ApprovalQueueCard({
    required this.scale,
    required this.approvals,
    required this.tenantId,
    required this.repo,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      scale: scale,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Approval Queue',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18 * scale,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4 * scale),
          Text(
            'Requests waiting for manager/admin decision.',
            style: TextStyle(color: Colors.white70, fontSize: 13 * scale),
          ),
          SizedBox(height: 12 * scale),
          Expanded(
            child: approvals.isEmpty
                ? Center(
                    child: Text(
                      'No pending approvals.',
                      style: TextStyle(color: Colors.white54, fontSize: 12 * scale),
                    ),
                  )
                : ListView.separated(
                    itemCount: approvals.length,
                    separatorBuilder: (_, __) => SizedBox(height: 8 * scale),
                    itemBuilder: (context, index) {
                      final a = approvals[index];
                      final title = a['title'] ?? 'Approval Request';
                      final requester = a['requesterName'] ?? 'Unknown';
                      final taskId = a['taskId'] ?? '';
                      final approvalId = a['id'] as String;

                      return _GlassCard(
                        scale: scale,
                        padding: EdgeInsets.symmetric(
                          horizontal: 12 * scale,
                          vertical: 10 * scale,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13 * scale,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 2 * scale),
                                  Text(
                                    'From $requester • Task #$taskId',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11 * scale,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 8 * scale),
                            TextButton(
                              onPressed: () async {
                                await repo.approveTask(tenantId, approvalId);
                                await onChanged();
                              },
                              child: Text(
                                'Approve',
                                style: TextStyle(
                                  color: Colors.greenAccent,
                                  fontSize: 12 * scale,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                await repo.rejectTask(tenantId, approvalId);
                                await onChanged();
                              },
                              child: Text(
                                'Reject',
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 12 * scale,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ========================== ORG HEALTH CARD ==========================

class _OrgHealthCard extends StatelessWidget {
  final double scale;
  final Map<String, int> health;

  const _OrgHealthCard({
    required this.scale,
    required this.health,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      scale: scale,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Org Health',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16 * scale,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 8 * scale),
          _HealthRow(
            label: 'Active Users',
            value: (health['activeUsers'] ?? 0).toString(),
            scale: scale,
          ),
          _HealthRow(
            label: 'Org Nodes',
            value: (health['orgNodes'] ?? 0).toString(),
            scale: scale,
          ),
          _HealthRow(
            label: 'Pending Registrations',
            value: (health['pendingRegistrations'] ?? 0).toString(),
            scale: scale,
          ),
        ],
      ),
    );
  }
}

class _HealthRow extends StatelessWidget {
  final String label;
  final String value;
  final double scale;

  const _HealthRow({
    required this.label,
    required this.value,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4 * scale),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.white70, fontSize: 12 * scale),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: Colors.cyanAccent,
              fontWeight: FontWeight.w600,
              fontSize: 13 * scale,
            ),
          ),
        ],
      ),
    );
  }
}

// ========================== QUICK ACTIONS CARD ==========================

class _QuickActionsCard extends StatelessWidget {
  final double scale;

  const _QuickActionsCard({required this.scale});

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      scale: scale,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16 * scale,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 8 * scale),
            _QuickActionButton(
              icon: Icons.account_tree_rounded,
              label: 'Organization Structure',
              scale: scale,
              onTap: () {
                // TODO: Navigate to org structure
              },
            ),
            _QuickActionButton(
              icon: Icons.description_outlined,
              label: 'Form Configuration',
              scale: scale,
              onTap: () {
                // TODO: Navigate to form config
              },
            ),
            _QuickActionButton(
              icon: Icons.security_outlined,
              label: 'Role & Permission Management',
              scale: scale,
              onTap: () {
                // TODO: Navigate to roles
              },
            ),
            _QuickActionButton(
              icon: Icons.rule_folder_outlined,
              label: 'Workflow Configuration',
              scale: scale,
              onTap: () {
                // TODO: Navigate to workflows
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final double scale;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.scale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4 * scale),
      child: InkWell(
        borderRadius: BorderRadius.circular(16 * scale),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 12 * scale,
            vertical: 10 * scale,
          ),
          decoration: BoxDecoration(
            color: const Color(0x331A1A28),
            borderRadius: BorderRadius.circular(16 * scale),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18 * scale, color: Colors.cyanAccent),
              SizedBox(width: 10 * scale),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(color: Colors.white, fontSize: 13 * scale),
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 12 * scale, color: Colors.white54),
            ],
          ),
        ),
      ),
    );
  }
}
