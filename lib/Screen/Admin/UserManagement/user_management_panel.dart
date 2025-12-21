import 'package:flutter/material.dart';
import '../../../core/app_colors.dart';
import 'user_repository.dart';
import 'user_model.dart';

class UserManagementPanel extends StatefulWidget {
  final String tenantId;

  const UserManagementPanel({super.key, required this.tenantId});

  @override
  State<UserManagementPanel> createState() => _UserManagementPanelState();
}

class _UserManagementPanelState extends State<UserManagementPanel> {
  final UserRepository _repo = UserRepository();
  List<UserMeta> _users = [];
  bool _loading = false;
  String? _status;
  bool _showPendingOnly = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    try {
      final users = _showPendingOnly
          ? await _repo.loadPendingUsers(widget.tenantId)
          : await _repo.loadAllUsers(widget.tenantId);
      setState(() {
        _users = users;
        _status = 'Loaded ${users.length} users';
      });
    } catch (e) {
      setState(() => _status = 'Error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'User Management',
            style: TextStyle(
              fontSize: 24,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Approve pending registrations and manage existing users.',
            style: TextStyle(color: AppColors.grey400),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              FilledButton.icon(
                onPressed: _loading ? null : _reload,
                icon: _loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Icon(Icons.refresh),
                label: const Text('Reload'),
              ),
              const SizedBox(width: 12),
              ChoiceChip(
                label: const Text('Pending Only'),
                selected: _showPendingOnly,
                onSelected: (val) {
                  setState(() => _showPendingOnly = val);
                  _reload();
                },
              ),
              const SizedBox(width: 12),
              ChoiceChip(
                label: const Text('All Users'),
                selected: !_showPendingOnly,
                onSelected: (val) {
                  setState(() => _showPendingOnly = !val);
                  _reload();
                },
              ),
              const Spacer(),
              if (_status != null)
                Text(
                  _status!,
                  style: const TextStyle(color: Colors.cyan, fontSize: 12),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              color: const Color(0xFF111118),
              child: _users.isEmpty
                  ? const Center(
                      child: Text(
                        'No users found.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _users.length,
                      separatorBuilder: (_, __) => const Divider(color: Colors.white12),
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getStatusColor(user.status),
                            child: Text(
                              user.fullName[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(
                            user.fullName,
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            '${user.email} • ${user.designation} • ${user.status}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          trailing: user.status == 'pending_approval'
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextButton(
                                      onPressed: () async {
                                        await _repo.approveUser(widget.tenantId, user.id);
                                        _reload();
                                      },
                                      child: const Text('Approve'),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        await _repo.rejectUser(widget.tenantId, user.id);
                                        _reload();
                                      },
                                      child: const Text(
                                        'Reject',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                )
                              : PopupMenuButton(
                                  icon: const Icon(Icons.more_vert, color: Colors.white54),
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'suspend',
                                      child: Text('Suspend'),
                                    ),
                                  ],
                                  onSelected: (value) async {
                                    if (value == 'suspend') {
                                      await _repo.suspendUser(widget.tenantId, user.id);
                                      _reload();
                                    }
                                  },
                                ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'pending_approval':
        return Colors.orange;
      case 'suspended':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
