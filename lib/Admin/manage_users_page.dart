import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const Color kRed = Color(0xFFE53935);
const Color kRedDark = Color(0xFFB71C1C);
const Color kRedLight = Color(0xFFFFEBEE);

class ManageUsersPage extends StatefulWidget {
  const ManageUsersPage({super.key});

  @override
  State<ManageUsersPage> createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends State<ManageUsersPage> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      final response = await _supabase
          .from('users')
          .select('id, name, student_id, email, role, is_blocked, department')
          .neq('id', currentUserId ?? '')
          .order('name', ascending: true);

      setState(() {
        // Fetch kora data list e store kora
        _users = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading users: $e'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  Future<void> _toggleBlock(String userId, bool currentlyBlocked) async {
    try {
      await _supabase
          .from('users')
          .update({'is_blocked': !currentlyBlocked})
          .eq('id', userId);
      setState(() {
        final index = _users.indexWhere((u) => u['id'] == userId);
        if (index != -1) {
          _users[index]['is_blocked'] = !currentlyBlocked;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(currentlyBlocked ? 'User unblocked' : 'User blocked'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: currentlyBlocked
                ? Colors.green.shade700
                : Colors.red.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  Future<void> _toggleAdminRole(String userId, String currentRole) async {
    final newRole = currentRole == 'admin' ? 'student' : 'admin';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          newRole == 'admin' ? 'Make Admin?' : 'Remove Admin?',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        content: Text(
          newRole == 'admin'
              ? 'This user will get full admin access to the library system.'
              : 'This user will lose all admin privileges.',
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.black54),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              newRole == 'admin' ? 'Make Admin' : 'Remove Admin',
              style: TextStyle(
                color: newRole == 'admin' ? kRed : Colors.orange.shade800,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _supabase.from('users').update({'role': newRole}).eq('id', userId);
      setState(() {
        final index = _users.indexWhere((u) => u['id'] == userId);
        if (index != -1) {
          _users[index]['role'] = newRole;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newRole == 'admin'
                  ? 'Student promoted to admin'
                  : 'Admin role removed',
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: kRedDark,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  String _getInitials(String name) {
    // Name split kore prothom letter gulo newa
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      // Du word hole duto prothom letter
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      // Ek word hole prothom letter
      return parts[0][0].toUpperCase();
    }
    return '?';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F2),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: kRed))
                : _users.isEmpty
                ? const Center(
                    child: Text(
                      'No users found',
                      style: TextStyle(color: Colors.black45, fontSize: 15),
                    ),
                  )
                : RefreshIndicator(
                    color: kRed,
                    onRefresh: _fetchUsers,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      itemCount: _users.length,
                      itemBuilder: (context, index) {
                        // Protita user er jonno card build kora
                        return _buildUserCard(_users[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [kRed, kRedDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(width: 14),

              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Manage Users',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Block, unblock & manage admin roles',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    // User er properties extract kora null safety sathe
    final String userId = user['id'] ?? '';
    final String name = user['name'] ?? 'Unknown';
    final String studentId = user['student_id'] ?? '';
    final String role = user['role'] ?? 'user';
    final bool isBlocked = user['is_blocked'] ?? false;
    final bool isAdmin = role == 'admin';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        // borderRadius 25, app er design system
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            // Subtle shadow, elevation 6 effect
            color: Colors.black.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Opacity(
        opacity: isBlocked ? 0.75 : 1.0,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: isAdmin ? kRedLight : const Color(0xFFE3F2FD),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        _getInitials(name),
                        style: TextStyle(
                          // Admin hole red text, user hole blue text
                          color: isAdmin ? kRedDark : const Color(0xFF1565C0),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF212121),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'ID: $studentId',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black45,
                          ),
                        ),
                        const SizedBox(height: 5),
                        if (isAdmin)
                          _buildBadge(
                            icon: Icons.shield_rounded,
                            label: 'Admin',
                            bgColor: kRedLight,
                            textColor: const Color(0xFFC62828),
                          )
                        else if (isBlocked)
                          _buildBadge(
                            icon: Icons.block_rounded,
                            label: 'Blocked',
                            bgColor: const Color(0xFFECEFF1),
                            textColor: const Color(0xFF546E7A),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1, color: Color(0xFFF0F0F0)),
              ),
              Row(
                children: [
                  if (isAdmin) ...[
                    _buildActionButton(
                      label: 'Remove Admin',
                      icon: Icons.gpp_bad_rounded,
                      bgColor: const Color(0xFFFFF3E0),
                      textColor: const Color(0xFFE65100),
                      onTap: () => _toggleAdminRole(userId, role),
                    ),
                  ] else if (isBlocked) ...[
                    _buildActionButton(
                      label: 'Unblock',
                      icon: Icons.check_circle_outline_rounded,
                      bgColor: const Color(0xFFE8F5E9),
                      textColor: const Color(0xFF2E7D32),
                      onTap: () => _toggleBlock(userId, isBlocked),
                    ),
                  ] else ...[
                    _buildActionButton(
                      label: 'Make Admin',
                      icon: Icons.shield_rounded,
                      bgColor: kRed,
                      textColor: Colors.white,
                      onTap: () => _toggleAdminRole(userId, role),
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      label: 'Block',
                      icon: Icons.block_rounded,
                      bgColor: kRedLight,
                      textColor: const Color(0xFFC62828),
                      onTap: () => _toggleBlock(userId, isBlocked),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color bgColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
