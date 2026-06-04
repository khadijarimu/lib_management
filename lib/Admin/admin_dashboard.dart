import 'package:flutter/material.dart';
import 'package:project_1/Admin/manage_books.dart';
import 'package:project_1/Admin/manage_requests.dart';
import 'package:project_1/Admin/manage_reservations.dart';
import 'package:project_1/Admin/manage_users_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:project_1/Auth/Login_page.dart';

const kRed = Color(0xFFE53935);
const kRedDark = Color(0xFFB71C1C);
const kRedLight = Color(0xFFFFEBEE);

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final _supabase = Supabase.instance.client;

  int? totalBooks;
  int? availableBooks;
  int? borrowedBooks;
  int? overdueBooks;
  int? pendingRequests;
  int? returnRequests;
  int? renewRequests;
  int? totalUsers;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStatistics();
  }

  Future<void> _fetchStatistics() async {
    setState(() => _isLoading = true);
    try {
      final booksRes = await _supabase.from('books').select('id');
      final availableRes = await _supabase
          .from('books')
          .select('id')
          .gt('available_copies', 0);
      final borrowedRes = await _supabase
          .from('borrows')
          .select('id')
          .eq('status', 'active');
      final overdueRes = await _supabase
          .from('borrows')
          .select('id')
          .eq('status', 'active')
          .lt('due_date', DateTime.now().toIso8601String());
      final pendingRes = await _supabase
          .from('borrows')
          .select('id')
          .eq('status', 'pending');
      final returnRes = await _supabase
          .from('borrows')
          .select('id')
          .eq('status', 'return_requested');
      final renewRes = await _supabase
          .from('borrows')
          .select('id')
          .eq('status', 'renew_requested');
      final usersRes = await _supabase.from('users').select('id');

      setState(() {
        totalBooks = (booksRes as List).length;
        availableBooks = (availableRes as List).length;
        borrowedBooks = (borrowedRes as List).length;
        overdueBooks = (overdueRes as List).length;
        pendingRequests = (pendingRes as List).length;
        returnRequests = (returnRes as List).length;
        renewRequests = (renewRes as List).length;
        totalUsers = (usersRes as List).length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load data: $e'),
            backgroundColor: kRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    await _supabase.auth.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Logout',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('Log out from the admin panel.?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: RefreshIndicator(
        onRefresh: _fetchStatistics,
        color: kRed,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Text(
                  'Library Overview',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                delegate: SliverChildListDelegate([
                  _buildStatCard(
                    label: 'Total Books',
                    value: totalBooks,
                    icon: Icons.menu_book_rounded,
                    color: const Color(0xFF1565C0),
                    bgColor: const Color(0xFFE3F2FD),
                  ),
                  _buildStatCard(
                    label: 'Available',
                    value: availableBooks,
                    icon: Icons.check_circle_outline_rounded,
                    color: const Color(0xFF2E7D32),
                    bgColor: const Color(0xFFE8F5E9),
                  ),
                  _buildStatCard(
                    label: 'Borrowed',
                    value: borrowedBooks,
                    icon: Icons.library_books_rounded,
                    color: const Color(0xFFE65100),
                    bgColor: const Color(0xFFFFF3E0),
                  ),
                  _buildStatCard(
                    label: 'Overdue',
                    value: overdueBooks,
                    icon: Icons.warning_amber_rounded,
                    color: kRed,
                    bgColor: kRedLight,
                  ),
                  _buildStatCard(
                    label: 'Total Users',
                    value: totalUsers,
                    icon: Icons.people_outline_rounded,
                    color: const Color(0xFF6A1B9A),
                    bgColor: const Color(0xFFF3E5F5),
                  ),
                ]),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.5,
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildActionCard(
                    label: 'Manage Requests',
                    subtitle: 'Manage borrow, return, and renew requests.',
                    icon: Icons.bookmark_add_outlined,

                    count:
                        (pendingRequests ?? 0) +
                        (returnRequests ?? 0) +
                        (renewRequests ?? 0),
                    color: const Color(0xFF1565C0),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ManageRequests()),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildActionCard(
                    label: 'Manage Reservations',
                    subtitle: 'Manage active reservations.',
                    icon: Icons.event_available_outlined,
                    count: null,
                    color: const Color(0xFF6A1B9A),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ManageReservations(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildActionCard(
                    label: 'Manage Books',
                    subtitle: 'Add, edit, or delete books.',
                    icon: Icons.library_add_outlined,
                    count: null,
                    color: kRedDark,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ManageBooks()),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildActionCard(
                    label: 'Manage Users',
                    subtitle: 'View user list, block or unblock users.',
                    icon: Icons.people_outline_rounded,
                    count: null,
                    color: const Color(0xFF2E7D32),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ManageUsersPage(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [kRedDark, kRed],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20,
        right: 20,
        bottom: 28,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Admin Panel',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Smart Library Management',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
              GestureDetector(
                onTap: _showLogoutDialog,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(
                Icons.admin_panel_settings,
                color: Colors.white70,
                size: 16,
              ),
              const SizedBox(width: 6),
              const Text(
                'Dashboard',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _fetchStatistics,
                child: const Row(
                  children: [
                    Icon(
                      Icons.refresh_rounded,
                      color: Colors.white70,
                      size: 16,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Refresh',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required int? value,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                _isLoading
                    ? Container(
                        height: 20,
                        width: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      )
                    : Text(
                        '${value ?? 0}',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String label,
    required String subtitle,
    required IconData icon,
    required int? count,
    required Color color,
    required VoidCallback onTap,
  }) {
    final hasBadge = count != null && count > 0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (hasBadge)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: kRed,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey[400],
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}
