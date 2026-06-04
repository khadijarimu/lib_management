import 'package:flutter/material.dart';
import 'package:project_1/Admin/active_borrows_page.dart';
import 'package:project_1/Admin/admin_history_page.dart';
import 'package:project_1/Admin/borrow_requests_page.dart';
import 'package:project_1/Admin/renew_requests_page.dart';
import 'package:project_1/Admin/return_requests_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const kRed = Color(0xFFE53935);
const kRedDark = Color(0xFFB71C1C);
const kRedLight = Color(0xFFFFEBEE);

class ManageRequests extends StatefulWidget {
  const ManageRequests({super.key});

  @override
  State<ManageRequests> createState() => _ManageRequestsState();
}

class _ManageRequestsState extends State<ManageRequests> {
  final _supabase = Supabase.instance.client;
  int _pendingCount = 0;
  int _activeCount = 0;
  int _returnCount = 0;
  int _renewCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCounts();
  }

  Future<void> _fetchCounts() async {
    setState(() => _isLoading = true);
    try {
      final pending = await _supabase
          .from('borrows')
          .select('id')
          .eq('status', 'pending');

      final active = await _supabase
          .from('borrows')
          .select('id')
          .eq('status', 'active');

      final ret = await _supabase
          .from('borrows')
          .select('id')
          .eq('status', 'return_requested');

      final renew = await _supabase
          .from('borrows')
          .select('id')
          .eq('status', 'renew_requested');

      setState(() {
        _pendingCount = (pending as List).length;
        _activeCount = (active as List).length;
        _returnCount = (ret as List).length;
        _renewCount = (renew as List).length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F2),
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            expandedHeight: 130,
            pinned: true,
            backgroundColor: kRed,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kRedDark, kRed],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                alignment: Alignment.bottomLeft,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: const Text(
                  'Manage Requests',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: kRed))
            : RefreshIndicator(
                onRefresh: _fetchCounts,
                color: kRed,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildCard(
                      icon: Icons.pending_actions_outlined,
                      iconBg: const Color(0xFFFFF3E0),
                      iconColor: const Color(0xFFE65100),
                      title: 'Pending Borrows',
                      subtitle: 'Approve or reject new borrow requests',
                      count: _pendingCount,
                      countColor: const Color(0xFFE65100),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BorrowRequestsPage(),
                          ),
                        );
                        _fetchCounts();
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildCard(
                      icon: Icons.book_outlined,
                      iconBg: const Color(0xFFE8F5E9),
                      iconColor: const Color(0xFF2E7D32),
                      title: 'Active Borrows',
                      subtitle: 'See which books are currently borrowed',
                      count: _activeCount,
                      countColor: const Color(0xFF2E7D32),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ActiveBorrowsPage(),
                          ),
                        );
                        _fetchCounts();
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildCard(
                      icon: Icons.assignment_return_outlined,
                      iconBg: const Color(0xFFE3F2FD),
                      iconColor: const Color(0xFF1565C0),
                      title: 'Return Requests',
                      subtitle: 'Please confirm return and calculate fine',
                      count: _returnCount,
                      countColor: const Color(0xFF1565C0),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ReturnRequestsPage(),
                          ),
                        );
                        _fetchCounts();
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildCard(
                      icon: Icons.autorenew_outlined,
                      iconBg: kRedLight,
                      iconColor: kRed,
                      title: 'Renew Requests',
                      subtitle:
                          'On approval of renewal, the due date will be extended by 14 days.',
                      count: _renewCount,
                      countColor: kRed,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RenewRequestsPage(),
                          ),
                        );
                        _fetchCounts();
                      },
                    ),
                    const SizedBox(height: 12),

                    // History card - navigates to full borrow history log
                    _buildHistoryCard(),
                  ],
                ),
              ),
      ),
    );
  }

  // History card has no count badge since it shows all records, not pending only
  Widget _buildHistoryCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminHistoryPage()),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: kRedLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.history, color: kRed, size: 26),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Borrow History',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'All records: returned, rejected, overdue, renewed',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required int count,
    required Color countColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: count > 0
                        ? countColor.withValues(alpha: 0.12)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: count > 0 ? countColor : Colors.grey[400],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
