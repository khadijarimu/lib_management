import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:project_1/Auth/Login_page.dart';
import 'package:project_1/Home_page.dart';
import 'package:project_1/MyLibrary_page.dart';
import 'package:project_1/widgets/PersonalInfo_page.dart';

const kRed = Color(0xFFE53935);
const kRedDark = Color(0xFFB71C1C);
const kRedLight = Color(0xFFFFEBEE);

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _supabase = Supabase.instance.client;

  String _name = '';
  String _email = '';
  String _department = '';
  String _studentId = '';
  String _avatarInitials = '??';

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final data = await _supabase
          .from('users')
          .select('name, email, department, student_id')
          .eq('id', userId)
          .single();

      _name = data['name'] ?? '';
      _email = data['email'] ?? '';
      _department = data['department'] ?? '';
      _studentId = data['student_id'] ?? '';

      _avatarInitials = _name.isNotEmpty
          ? _name
                .trim()
                .split(' ')
                .where((w) => w.isNotEmpty)
                .take(2)
                .map((w) => w[0].toUpperCase())
                .join()
          : '??';
    } catch (e) {
      debugPrint('Profile data load error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Log Out',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Log Out',
              style: TextStyle(color: kRed, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _supabase.auth.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F2),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: kRed))
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [_header(), _menuList(context)],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _logoutBtn(context),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
      ),
      bottomNavigationBar: const _BottomNav(currentIndex: 2),
    );
  }

  Widget _header() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [kRedDark, kRed],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      child: Column(
        children: [
          // Avatar circle
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                _avatarInitials,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: kRed,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Name
          Text(
            _name.isEmpty ? 'Loading...' : _name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),

          // Email
          Text(
            _email,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 8),

          // Department + Student ID badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: Text(
              '${_department.isEmpty ? 'Student' : _department}'
              '${_studentId.isNotEmpty ? ' · $_studentId' : ''}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuList(BuildContext context) {
    final items = [
      {
        'icon': Icons.person_outline_rounded,
        'title': 'Personal Info',
        'sub': 'Name, email, department',
        'color': kRed,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PersonalInfoPage()),
        ).then((_) => _loadUserData()),
      },
      {
        'icon': Icons.collections_bookmark_outlined,
        'title': 'My Borrows',
        'sub': 'Active borrowed books',
        'color': const Color(0xFF1E88E5),
        'onTap': () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const MyLibraryPage(fromProfile: true),
          ),
        ),
      },
      {
        'icon': Icons.history_rounded,
        'title': 'Reading History',
        'sub': 'All past borrowed books',
        'color': const Color(0xFF43A047),
        'onTap': () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const MyLibraryPage(fromProfile: true),
          ),
        ),
      },
      {
        'icon': Icons.notifications_outlined,
        'title': 'Notifications',
        'sub': 'Due dates, reminders',
        'color': const Color(0xFFFB8C00),
        'onTap': () => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Notifications coming soon!'),
            backgroundColor: kRed,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 1),
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      },
      {
        'icon': Icons.settings_outlined,
        'title': 'Settings',
        'sub': 'App preferences',
        'color': const Color(0xFF757575),
        'onTap': () => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Settings coming soon!'),
            backgroundColor: kRed,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 1),
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      },
    ];

    return Column(
      children: List.generate(items.length, (i) {
        final isLast = i == items.length - 1;
        final itemColor = items[i]['color'] as Color;

        return GestureDetector(
          onTap: items[i]['onTap'] as VoidCallback,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isLast ? Colors.transparent : const Color(0xFFF5F5F5),
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: itemColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    items[i]['icon'] as IconData,
                    color: itemColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        items[i]['title'] as String,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        items[i]['sub'] as String,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF888888),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFFBBBBBB),
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _logoutBtn(BuildContext context) {
    return GestureDetector(
      onTap: _confirmLogout,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: kRedLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFCDD2)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: kRed, size: 18),
            SizedBox(width: 8),
            Text(
              'Log Out',
              style: TextStyle(
                color: kRed,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  const _BottomNav({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final items = [
      {'icon': Icons.home_rounded, 'label': 'Home'},
      {'icon': Icons.collections_bookmark_outlined, 'label': 'My Library'},
      {'icon': Icons.person_outline_rounded, 'label': 'Profile'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFEEEEEE))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          final active = currentIndex == i;
          return GestureDetector(
            onTap: () {
              if (i == currentIndex) return;
              if (i == 0) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const HomePage()),
                  (r) => false,
                );
              } else if (i == 1) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MyLibraryPage(fromProfile: false),
                  ),
                );
              } else if (i == 2) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfilePage()),
                );
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              decoration: BoxDecoration(
                color: active ? kRedLight : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    items[i]['icon'] as IconData,
                    color: active ? kRed : const Color(0xFFBBBBBB),
                    size: 22,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    items[i]['label'] as String,
                    style: TextStyle(
                      color: active ? kRed : const Color(0xFFBBBBBB),
                      fontSize: 10,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
