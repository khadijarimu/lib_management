import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const kRed = Color(0xFFE53935);

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _history = [];
  bool _loading = true;

  final List<List<Color>> _gradients = [
    [Color(0xFF1B5E20), Color(0xFF388E3C)],
    [Color(0xFF0D47A1), Color(0xFF1976D2)],
    [Color(0xFF4A148C), Color(0xFF7B1FA2)],
    [Color(0xFFE53935), Color(0xFFB71C1C)],
    [Color(0xFF00838F), Color(0xFF006064)],
    [Color(0xFFE65100), Color(0xFFBF360C)],
  ];

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() => _loading = true);
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final data = await _supabase
          .from('borrows')
          .select('*, books(id, title, author)')
          .eq('user_id', userId)
          .eq('status', 'returned')
          .order('return_date', ascending: false);

      setState(() {
        _history = List<Map<String, dynamic>>.from(data);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _borrowAgain(Map<String, dynamic> borrow) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      final book = borrow['books'] as Map<String, dynamic>? ?? {};
      final bookId = book['id'];
      final title = book['title'] ?? 'Book';

      if (userId == null || bookId == null) return;

      await _supabase.from('borrows').insert({
        'user_id': userId,
        'book_id': bookId,
        'status': 'pending',
        'borrow_date': DateTime.now().toIso8601String(),
        'renew_count': 0,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Borrow request sent for "$title"'),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: kRed));
    }

    if (_history.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_rounded, size: 54, color: Color(0xFFDDDDDD)),
            SizedBox(height: 12),
            Text(
              'No borrow history',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: kRed,
      onRefresh: _fetchHistory,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        itemCount: _history.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final borrow = _history[i];
          final book = borrow['books'] as Map<String, dynamic>? ?? {};
          final title = book['title'] ?? 'Unknown';
          final author = book['author'] ?? '';
          final gradient = _gradients[i % _gradients.length];
          String dateRange = '';
          if (borrow['borrow_date'] != null && borrow['return_date'] != null) {
            final b = DateTime.parse(borrow['borrow_date']);
            final r = DateTime.parse(borrow['return_date']);
            dateRange =
                '${b.day} ${_month(b.month)} → ${r.day} ${_month(r.month)}';
          }
          final fineAmount = (borrow['fine_amount'] ?? 0).toDouble();
          final finePaid = borrow['fine_paid'] ?? false;

          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFEEEEEE)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 54,
                  height: 72,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradient,
                    ),
                  ),
                  padding: const EdgeInsets.all(6),
                  child: Text(
                    title.split(' ').take(2).join('\n'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        author,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (dateRange.isNotEmpty)
                        Text(
                          dateRange,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF888888),
                          ),
                        ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          '✓ Returned',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ),
                      if (fineAmount > 0) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: finePaid
                                ? const Color(0xFFE8F5E9)
                                : const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            finePaid
                                ? '✓ Fine Paid: ৳${fineAmount.toStringAsFixed(0)}'
                                : '⚠ Fine: ৳${fineAmount.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: finePaid ? const Color(0xFF2E7D32) : kRed,
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: kRed,
                            side: const BorderSide(color: kRed, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          onPressed: () => _borrowAgain(borrow),
                          child: const Text(
                            'Borrow Again',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _month(int m) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[m - 1];
  }
}
