import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const kRed = Color(0xFFE53935);
const kRedDark = Color(0xFFB71C1C);
const kRedLight = Color(0xFFFFEBEE);

class ReturnRequestsPage extends StatefulWidget {
  const ReturnRequestsPage({super.key});

  @override
  State<ReturnRequestsPage> createState() => _ReturnRequestsPageState();
}

class _ReturnRequestsPageState extends State<ReturnRequestsPage> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;

  // Tracks which borrow IDs have been marked as fine paid locally
  final Set<String> _finePaidSet = {};

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
          .eq('status', 'return_requested')
          .order('borrow_date', ascending: false);
      setState(() {
        _requests = List<Map<String, dynamic>>.from(res);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // Calculate fine by date only, no UTC needed for Bangladesh
  double _calcFine(String? dueStr) {
    if (dueStr == null) return 0;
    final due = DateTime.parse(dueStr);
    final nowDate = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final dueDate = DateTime(due.year, due.month, due.day);
    if (nowDate.isAfter(dueDate)) {
      final days = nowDate.difference(dueDate).inDays;
      return days * 5.0;
    }
    return 0;
  }

  // Confirm return — saves status, return_date, fine_amount, and fine_paid
  Future<void> _confirmReturn(Map<String, dynamic> borrow) async {
    try {
      final fine = _calcFine(borrow['due_date']);
      final borrowId = borrow['id'].toString();
      final finePaid = _finePaidSet.contains(borrowId);

      final nowDate = DateTime.now();
      final dateOnly =
          '${nowDate.year}-${nowDate.month.toString().padLeft(2, '0')}-${nowDate.day.toString().padLeft(2, '0')}';

      await _supabase
          .from('borrows')
          .update({
            'status': 'returned',
            'return_date': dateOnly,
            'fine_amount': fine,
            'fine_paid': finePaid,
          })
          .eq('id', borrow['id']);

      final book = await _supabase
          .from('books')
          .select('available_copies')
          .eq('id', borrow['book_id'])
          .single();
      await _supabase
          .from('books')
          .update({'available_copies': (book['available_copies'] as int) + 1})
          .eq('id', borrow['book_id']);

      final msg = fine > 0
          ? 'Return confirmed. Fine: ${fine.toStringAsFixed(0)} taka${finePaid ? ' (Paid)' : ' (Unpaid)'}'
          : 'Return confirmed successfully.';
      _showSnack(msg, const Color(0xFF2E7D32));
      _finePaidSet.remove(borrowId);
      _fetchRequests();
    } catch (e) {
      _showSnack('Unable to confirm return.', kRed);
    }
  }

  String _fmt(String? s) {
    if (s == null) return '-';
    final d = DateTime.parse(s);
    return '${d.day}/${d.month}/${d.year}';
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                      'Return Requests',
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
    final fine = _calcFine(b['due_date']);
    final isOverdue = fine > 0;
    final borrowId = b['id'].toString();
    final finePaid = _finePaidSet.contains(borrowId);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info row
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
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'ID: ${b['users']?['student_id'] ?? '-'} | ${b['users']?['department'] ?? '-'}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: kRedLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: kRed.withValues(alpha: 0.3)),
                ),
                child: const Text(
                  'Return Req.',
                  style: TextStyle(
                    fontSize: 11,
                    color: kRed,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const Divider(height: 20),

          // Book info
          Row(
            children: [
              const Icon(Icons.menu_book_rounded, size: 16, color: kRed),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  b['books']?['title'] ?? 'Unknown',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 22, top: 2),
            child: Text(
              b['books']?['author'] ?? '-',
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ),

          const SizedBox(height: 10),

          // Borrow and due date row
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 13,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Borrowed: ${_fmt(b['borrow_date'])}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.event_outlined,
                      size: 13,
                      color: isOverdue ? kRed : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Due: ${_fmt(b['due_date'])}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isOverdue ? kRed : Colors.grey[600],
                        fontWeight: isOverdue
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Fine section — unpaid shows Mark Paid button, paid shows green box only
          if (isOverdue) ...[
            const SizedBox(height: 10),
            if (!finePaid)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: kRedLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFEF9A9A)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 16,
                      color: kRed,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fine: ${fine.toStringAsFixed(0)} taka (5 taka/day)',
                            style: const TextStyle(
                              fontSize: 12,
                              color: kRed,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Not yet paid',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    // Mark paid button — once pressed turns green, no undo
                    GestureDetector(
                      onTap: () {
                        setState(() => _finePaidSet.add(borrowId));
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Mark Paid',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              // Green box shown after marking paid — no button
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF81C784)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 16,
                      color: Color(0xFF2E7D32),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fine: ${fine.toStringAsFixed(0)} taka (5 taka/day)',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF2E7D32),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Fine has been paid',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],

          const SizedBox(height: 12),

          // Confirm return button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _confirmReturn(b),
              style: ElevatedButton.styleFrom(
                backgroundColor: kRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 0,
              ),
              child: const Text(
                'Confirm Return',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.assignment_return_outlined,
          size: 60,
          color: Colors.grey[300],
        ),
        const SizedBox(height: 12),
        Text(
          'No pending return requests',
          style: TextStyle(color: Colors.grey[500], fontSize: 15),
        ),
      ],
    ),
  );
}
