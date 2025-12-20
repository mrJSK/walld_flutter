import 'package:flutter/material.dart';

class AdminDesktopScreen extends StatelessWidget {
  const AdminDesktopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final size = MediaQuery.of(context).size;
    final shortest = size.shortestSide;

    // Scale factor: compact < 900, normal 900-1400, large > 1400
    final double scale = shortest < 900 ? 0.85 : (shortest > 1400 ? 1.15 : 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFF05040A),
      body: Container(
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
                _TopBar(now: now, scale: scale),
                SizedBox(height: 24 * scale),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 1200;

                      if (isNarrow) {
                        return SingleChildScrollView(
                          child: Column(
                            children: [
                              _TaskOverviewCard(scale: scale),
                              SizedBox(height: 16 * scale),
                              _ApprovalQueueCard(scale: scale),
                              SizedBox(height: 16 * scale),
                              Row(
                                children: [
                                  Expanded(
                                      child: _OrgHealthCard(scale: scale)),
                                  SizedBox(width: 16 * scale),
                                  Expanded(
                                      child: _QuickActionsCard(scale: scale)),
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
                                  child: _TaskOverviewCard(scale: scale),
                                ),
                                SizedBox(width: 24 * scale),
                                Expanded(
                                  flex: 2,
                                  child: _ApprovalQueueCard(scale: scale),
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
                                    child: _OrgHealthCard(scale: scale)),
                                SizedBox(width: 24 * scale),
                                Expanded(
                                    child: _QuickActionsCard(scale: scale)),
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
      ),
    );
  }
}

/* ------------------------------ Top bar ------------------------------ */

class _TopBar extends StatelessWidget {
  final DateTime now;
  final double scale;

  const _TopBar({required this.now, required this.scale});

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
          Icon(Icons.blur_on_rounded,
              size: 18 * scale, color: Colors.cyan),
          SizedBox(width: 6 * scale),
          Text(
            'Wall-D • Admin',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14 * scale,
            ),
          ),
          const Spacer(),
          Text(
            '$dateStr   $timeStr',
            style: TextStyle(color: Colors.white70, fontSize: 13 * scale),
          ),
          const Spacer(),
          Icon(Icons.cloud_done,
              size: 16 * scale, color: Colors.greenAccent),
          SizedBox(width: 6 * scale),
          Text(
            'default_tenant',
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

/* --------------------------- Reusable card --------------------------- */

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double scale;

  const _GlassCard({
    required this.child,
    required this.scale,
    EdgeInsets? padding,
  }) : padding = padding ?? const EdgeInsets.all(20);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(padding.top * scale),
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

/* ------------------------- Main widgets/cards ------------------------ */

class _TaskOverviewCard extends StatelessWidget {
  final double scale;

  const _TaskOverviewCard({required this.scale});

  @override
  Widget build(BuildContext context) {
    final stats = [
      _TaskStat('Pending', 12, Colors.orangeAccent),
      _TaskStat('In Progress', 34, Colors.cyanAccent),
      _TaskStat('Blocked', 5, Colors.redAccent),
      _TaskStat('Awaiting Approval', 7, Colors.purpleAccent),
      _TaskStat('Completed (Today)', 21, Colors.greenAccent),
    ];

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
            'Live snapshot of your organizations tasks by status.',
            style: TextStyle(color: Colors.white70, fontSize: 13 * scale),
          ),
          SizedBox(height: 18 * scale),
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
        ],
      ),
    );
  }
}

class _TaskStat {
  final String label;
  final int count;
  final Color color;
  _TaskStat(this.label, this.count, this.color);
}

class _ApprovalQueueCard extends StatelessWidget {
  final double scale;

  const _ApprovalQueueCard({required this.scale});

  @override
  Widget build(BuildContext context) {
    final approvals = [
      _ApprovalItem('Task #1042 – Client Onboarding', 'Rahul', '2h ago'),
      _ApprovalItem('Expense – Travel Reimbursement', 'Anita', '5h ago'),
      _ApprovalItem('Task #1031 – Server Upgrade', 'DevOps', '1d ago'),
    ];

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
            child: ListView.separated(
              itemCount: approvals.length,
              separatorBuilder: (_, __) => SizedBox(height: 8 * scale),
              itemBuilder: (context, index) {
                final item = approvals[index];
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
                              item.title,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13 * scale,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 2 * scale),
                            Text(
                              'From ${item.requester} • ${item.age}',
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
                        onPressed: () {},
                        child: Text(
                          'Approve',
                          style: TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 12 * scale,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
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

class _ApprovalItem {
  final String title;
  final String requester;
  final String age;
  _ApprovalItem(this.title, this.requester, this.age);
}

class _OrgHealthCard extends StatelessWidget {
  final double scale;

  const _OrgHealthCard({required this.scale});

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
          _HealthRow(label: 'Active Users', value: '142', scale: scale),
          _HealthRow(label: 'Org Nodes', value: '18', scale: scale),
          _HealthRow(
              label: 'Pending Registrations', value: '3', scale: scale),
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
              onTap: () {},
            ),
            _QuickActionButton(
              icon: Icons.description_outlined,
              label: 'Form Configuration',
              scale: scale,
              onTap: () {},
            ),
            _QuickActionButton(
              icon: Icons.security_outlined,
              label: 'Role & Permission Management',
              scale: scale,
              onTap: () {},
            ),
            _QuickActionButton(
              icon: Icons.rule_folder_outlined,
              label: 'Workflow Configuration',
              scale: scale,
              onTap: () {},
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
              Icon(Icons.arrow_forward_ios,
                  size: 12 * scale, color: Colors.white54),
            ],
          ),
        ),
      ),
    );
  }
}
