import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/admin_user_service.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final AdminUserService _userService = AdminUserService();
  final TextEditingController _searchController = TextEditingController();

  late Future<Map<String, dynamic>> _userStatsFuture;
  late Future<AdminUsersPage> _usersFuture;

  final Set<String> _processingUserIds = <String>{};

  int _currentPage = 1;
  final int _pageSize = 10;
  String _selectedRole = 'all';
  String _selectedStatus = 'all';
  String _selectedVerified = 'all';
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _loadData() {
    _userStatsFuture = _userService.getUserStats();
    _usersFuture = _userService.getAllUsers(
      search: _searchController.text.trim(),
      role: _selectedRole,
      status: _selectedStatus,
      verified: _selectedVerified,
      page: _currentPage,
      limit: _pageSize,
    );
  }

  Future<void> _refreshData() async {
    setState(_loadData);
    await Future.wait([_userStatsFuture, _usersFuture]);
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() {
        _currentPage = 1;
        _loadData();
      });
    });
  }

  void _onFilterChanged() {
    setState(() {
      _currentPage = 1;
      _loadData();
    });
  }

  Future<void> _updateRole(AdminUserItem user, String newRole) async {
    if (_processingUserIds.contains(user.id) || user.role == newRole) {
      return;
    }

    setState(() {
      _processingUserIds.add(user.id);
    });

    try {
      await _userService.updateUserRole(userId: user.id, role: newRole);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Updated ${user.name} to $newRole'),
          backgroundColor: Colors.green,
        ),
      );
      await _refreshData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update role: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _processingUserIds.remove(user.id);
        });
      }
    }
  }

  Future<void> _toggleUserStatus(AdminUserItem user) async {
    if (_processingUserIds.contains(user.id)) {
      return;
    }

    setState(() {
      _processingUserIds.add(user.id);
    });

    try {
      await _userService.updateUserStatus(
        userId: user.id,
        isActive: !user.isActive,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            !user.isActive ? 'User activated successfully' : 'User deactivated successfully',
          ),
          backgroundColor: Colors.green,
        ),
      );
      await _refreshData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _processingUserIds.remove(user.id);
        });
      }
    }
  }

  Future<void> _toggleUserVerification(AdminUserItem user) async {
    if (_processingUserIds.contains(user.id)) {
      return;
    }

    setState(() {
      _processingUserIds.add(user.id);
    });

    try {
      await _userService.updateUserVerification(
        userId: user.id,
        isVerified: !user.isVerified,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            !user.isVerified ? 'User verified successfully' : 'User unverified successfully',
          ),
          backgroundColor: Colors.green,
        ),
      );
      await _refreshData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update verification: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _processingUserIds.remove(user.id);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: const Color(0xFFFF6600),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 12),
            const Text(
              'User Statistics',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            FutureBuilder<Map<String, dynamic>>(
              future: _userStatsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const _StatCardSkeleton();
                }

                final stats = snapshot.data ?? {};
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _MiniStatChip(label: 'Total', value: '${stats['totalUsers'] ?? 0}', color: Colors.blue),
                    _MiniStatChip(label: 'Admin', value: '${stats['adminUsers'] ?? 0}', color: Colors.purple),
                    _MiniStatChip(label: 'User', value: '${stats['regularUsers'] ?? 0}', color: Colors.teal),
                    _MiniStatChip(label: 'Active', value: '${stats['activeUsers'] ?? 0}', color: Colors.green),
                    _MiniStatChip(label: 'Inactive', value: '${stats['inactiveUsers'] ?? 0}', color: Colors.red),
                    _MiniStatChip(label: 'Verified', value: '${stats['verifiedUsers'] ?? 0}', color: Colors.orange),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Search & Filter',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search by name, email, phone',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildFilterDropdown(
                    label: 'Role',
                    value: _selectedRole,
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All roles')),
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                      DropdownMenuItem(value: 'user', child: Text('User')),
                    ],
                    onChanged: (value) {
                      _selectedRole = value ?? 'all';
                      _onFilterChanged();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildFilterDropdown(
                    label: 'Status',
                    value: _selectedStatus,
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All status')),
                      DropdownMenuItem(value: 'active', child: Text('Active')),
                      DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                    ],
                    onChanged: (value) {
                      _selectedStatus = value ?? 'all';
                      _onFilterChanged();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildFilterDropdown(
              label: 'Verification',
              value: _selectedVerified,
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All verification')),
                DropdownMenuItem(value: 'verified', child: Text('Verified')),
                DropdownMenuItem(value: 'unverified', child: Text('Unverified')),
              ],
              onChanged: (value) {
                _selectedVerified = value ?? 'all';
                _onFilterChanged();
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'Users',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            FutureBuilder<AdminUsersPage>(
              future: _usersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const _StatCardSkeleton();
                }

                if (snapshot.hasError) {
                  return _ErrorBox(message: 'Failed to load users: ${snapshot.error}');
                }

                final pageData = snapshot.data;
                final users = pageData?.users ?? [];

                if (users.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('No users found for this filter.'),
                  );
                }

                return Column(
                  children: [
                    ...users.map((user) => _buildUserCard(user)).toList(),
                    const SizedBox(height: 12),
                    _buildPagination(pageData!),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        isDense: true,
      ),
      items: items,
      onChanged: onChanged,
    );
  }

  Widget _buildUserCard(AdminUserItem user) {
    final isProcessing = _processingUserIds.contains(user.id);
    final selectedRole = user.role == 'admin' || user.role == 'user' ? user.role : 'user';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: user.isActive ? Colors.orange.shade100 : Colors.grey.shade300,
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: user.isActive ? const Color(0xFFFF6600) : Colors.grey.shade700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email,
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _StatusTag(
                          label: user.isActive ? 'Active' : 'Inactive',
                          color: user.isActive ? Colors.green : Colors.red,
                        ),
                        _StatusTag(
                          label: user.isVerified ? 'Verified' : 'Unverified',
                          color: user.isVerified ? Colors.orange : Colors.grey,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isProcessing)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'user', child: Text('User')),
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  ],
                  onChanged: isProcessing
                      ? null
                      : (value) {
                          if (value != null) {
                            _updateRole(user, value);
                          }
                        },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isProcessing ? null : () => _toggleUserStatus(user),
                  icon: Icon(
                    user.isActive ? Icons.block : Icons.check_circle,
                    color: user.isActive ? Colors.red : Colors.green,
                  ),
                  label: Text(
                    user.isActive ? 'Deactivate' : 'Activate',
                    style: TextStyle(color: user.isActive ? Colors.red : Colors.green),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isProcessing ? null : () => _toggleUserVerification(user),
                  icon: Icon(
                    user.isVerified ? Icons.verified_outlined : Icons.verified,
                    color: user.isVerified ? Colors.grey.shade700 : Colors.orange,
                  ),
                  label: Text(
                    user.isVerified ? 'Unverify' : 'Verify',
                    style: TextStyle(color: user.isVerified ? Colors.grey.shade700 : Colors.orange),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPagination(AdminUsersPage pageData) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Page ${pageData.page}/${pageData.totalPages} • ${pageData.total} users',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: pageData.hasPreviousPage
                ? () {
                    setState(() {
                      _currentPage -= 1;
                      _loadData();
                    });
                  }
                : null,
            child: const Text('Prev'),
          ),
          TextButton(
            onPressed: pageData.hasNextPage
                ? () {
                    setState(() {
                      _currentPage += 1;
                      _loadData();
                    });
                  }
                : null,
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }
}

class _MiniStatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 18, color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _StatusTag extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusTag({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;

  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Text(
        message,
        style: TextStyle(color: Colors.red.shade700),
      ),
    );
  }
}

class _StatCardSkeleton extends StatelessWidget {
  const _StatCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      height: 80,
    );
  }
}
