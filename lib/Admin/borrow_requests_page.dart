import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const kRed = Color(0xFFE53935);
const kRedDark = Color(0xFFB71C1C);
const kRedLight = Color(0xFFFFEBEE);

class BorrowRequestsPage extends StatefulWidget {
  const BorrowRequestsPage({super.key});

  @override
  State<BorrowRequestsPage> createState() => _BorrowRequestsPageState();
}

class _BorrowRequestsPageState extends State<BorrowRequestsPage> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    setState(() => _isLoading = true);
    try {
      final res = await _supabase
          .from('borrows')
          .select(
            '*, users(name, student_id, department), books(title, author)',
          )
          .eq('status', 'pending')
          .order('borrow_date', ascending: false);
      setState(() {
        _requests = List<Map<String, dynamic>>.from(res);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to load data');
    }
  }

  Future<void> _approveBorrow(Map<String, dynamic> borrow) async {
    try {
      await _supabase
          .from('borrows')
          .update({'status': 'active'})
          .eq('id', borrow['id']);

      final book = await _supabase
          .from('books')
          .select('available_copies')
          .eq('id', borrow['book_id'])
          .single();

      await _supabase
          .from('books')
          .update({'available_copies': (book['available_copies'] as int) - 1})
          .eq('id', borrow['book_id']);

      _showSuccess('The borrow has been approved');
      _fetchRequests();
    } catch (e) {
      _showError('Unable to approve');
    }
  }

  Future<void> _rejectBorrow(String borrowId) async {
    try {
      await _supabase
          .from('borrows')
          .update({'status': 'rejected'})
          .eq('id', borrowId);
      _showSuccess('Rejected');
      _fetchRequests();
    } catch (e) {
      _showError('Unable to reject');
    }
  }

  String _fmt(String? s) {
    if (s == null) return '-';
    final d = DateTime.parse(s);
    return '${d.day}/${d.month}/${d.year}';
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: kRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F2),
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            expandedHeight: 120,
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
                child: Row(
                  children: [
                    const Text(
                      'Pending Borrows',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),

                    if (!_isLoading)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_requests.length} pending',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: kRed))
            : _requests.isEmpty
            ? _buildEmpty()
            : RefreshIndicator(
                onRefresh: _fetchRequests,
                color: kRed,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _requests.length,
                  itemBuilder: (ctx, i) => _buildCard(_requests[i]),
                ),
              ),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> b) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: kRedLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.person_outline, color: kRed, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      b['users']?['name'] ?? 'Unknown',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      'ID: ${b['users']?['student_id'] ?? '-'} | ${b['users']?['department'] ?? '-'}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              // Pending badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Pending',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFFE65100),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const Divider(height: 20),
          Row(
            children: [
              const Icon(Icons.menu_book_rounded, size: 16, color: kRed),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  b['books']?['title'] ?? 'Unknown',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 22, top: 2),
            child: Text(
              b['books']?['author'] ?? '-',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ),

          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: Colors.grey,
              ),
              const SizedBox(width: 6),
              Text(
                'Request date: ${_fmt(b['borrow_date'])}',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ],
          ),

          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _rejectBorrow(b['id']),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text('Reject'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _approveBorrow(b),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    elevation: 0,
                  ),
                  child: const Text('Approve'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.pending_actions_outlined, size: 60, color: Colors.grey[300]),
        const SizedBox(height: 12),
        Text(
          'No pending borrows.',
          style: TextStyle(color: Colors.grey[500], fontSize: 15),
        ),
      ],
    ),
  );
}
