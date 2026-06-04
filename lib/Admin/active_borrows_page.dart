import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const kRed = Color(0xFFE53935);
const kRedDark = Color(0xFFB71C1C);
const kRedLight = Color(0xFFFFEBEE);

class ActiveBorrowsPage extends StatefulWidget {
  const ActiveBorrowsPage({super.key});

  @override
  State<ActiveBorrowsPage> createState() => _ActiveBorrowsPageState();
}

class _ActiveBorrowsPageState extends State<ActiveBorrowsPage> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _borrows = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBorrows();
  }

  Future<void> _fetchBorrows() async {
    setState(() => _isLoading = true);
    try {
      final res = await _supabase
          .from('borrows')
          .select(
            '*, users(name, student_id, department), books(title, author)',
          )
          .eq('status', 'active')
          .order('due_date', ascending: true);
      setState(() {
        _borrows = List<Map<String, dynamic>>.from(res);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  String _fmt(String? s) {
    if (s == null) return '-';
    final d = DateTime.parse(s);
    return '${d.day}/${d.month}/${d.year}';
  }

  String _dueDays(String? dueStr) {
    if (dueStr == null) return '';
    final due = DateTime.parse(dueStr);
    final nowDate = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final dueDate = DateTime(due.year, due.month, due.day);
    final diff = dueDate.difference(nowDate).inDays;
    if (nowDate.isAfter(dueDate))
      return '${nowDate.difference(dueDate).inDays} days overdue';
    if (diff == 0) return 'Due today';
    return '$diff remaining days';
  }

  // Check overdue by date only, no UTC needed for Bangladesh
  bool _isOverdue(String? dueStr) {
    if (dueStr == null) return false;
    final due = DateTime.parse(dueStr);
    final nowDate = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final dueDate = DateTime(due.year, due.month, due.day);
    return nowDate.isAfter(dueDate);
  }

  // Calculate fine by date difference, 5 taka per day
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
                      'Active Borrows',
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
                          '${_borrows.length} active',
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
            : _borrows.isEmpty
            ? _buildEmpty()
            : RefreshIndicator(
                onRefresh: _fetchBorrows,
                color: kRed,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _borrows.length,
                  itemBuilder: (ctx, i) => _buildCard(_borrows[i]),
                ),
              ),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> b) {
    final overdue = _isOverdue(b['due_date']);
    final fine = _calcFine(b['due_date']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: overdue
            ? const Border(left: BorderSide(color: kRed, width: 4))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
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
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: Color(0xFF2E7D32),
                  size: 22,
                ),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: overdue ? kRedLight : const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  overdue ? 'Overdue' : 'Active',
                  style: TextStyle(
                    fontSize: 11,
                    color: overdue ? kRed : const Color(0xFF2E7D32),
                    fontWeight: FontWeight.bold,
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

          // Borrow and due date row
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Borrowed: ${_fmt(b['borrow_date'])}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.event_outlined,
                      size: 14,
                      color: overdue ? kRed : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Due: ${_fmt(b['due_date'])}',
                      style: TextStyle(
                        fontSize: 12,
                        color: overdue ? kRed : Colors.grey[600],
                        fontWeight: overdue
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),
          Text(
            _dueDays(b['due_date']),
            style: TextStyle(
              fontSize: 12,
              color: overdue ? kRed : const Color(0xFF2E7D32),
              fontWeight: FontWeight.w500,
            ),
          ),

          // Fine display only — no toggle, admin handles payment in return requests page
          if (fine > 0) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: kRedLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFEF9A9A)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: kRed,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Fine: ${fine.toStringAsFixed(0)} taka (5 taka/day)',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: kRed,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmpty() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.book_outlined, size: 60, color: Colors.grey[300]),
        const SizedBox(height: 12),
        Text(
          'No active borrowings',
          style: TextStyle(color: Colors.grey[500], fontSize: 15),
        ),
      ],
    ),
  );
}
