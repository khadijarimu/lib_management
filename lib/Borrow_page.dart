import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:project_1/BookDetails_page.dart'; // ✅ NEW

const kRed = Color(0xFFE53935);
const kRedLight = Color(0xFFFFEBEE);

class BorrowPage extends StatefulWidget {
  const BorrowPage({super.key});

  @override
  State<BorrowPage> createState() => _BorrowPageState();
}

class _BorrowPageState extends State<BorrowPage> {
  final _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _borrows = [];
  bool _loading = true;

  final List<List<Color>> _gradients = [
    [Color(0xFFE53935), Color(0xFFB71C1C)],
    [Color(0xFF1565C0), Color(0xFF0D47A1)],
    [Color(0xFF2E7D32), Color(0xFF1B5E20)],
    [Color(0xFF6A1B9A), Color(0xFF4A148C)],
    [Color(0xFFE65100), Color(0xFFBF360C)],
    [Color(0xFF00838F), Color(0xFF006064)],
  ];

  @override
  void initState() {
    super.initState();
    _fetchBorrows();
  }

  Future<void> _fetchBorrows() async {
    setState(() => _loading = true);
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final data = await _supabase
          .from('borrows')
          .select('*, books(title, author)')
          .eq('user_id', userId)
          .inFilter('status', [
            'pending',
            'active',
            'return_requested',
            'renew_requested',
            'overdue',
          ])
          .order('borrow_date', ascending: false);

      setState(() {
        _borrows = List<Map<String, dynamic>>.from(data);
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

  double _calcFine(Map<String, dynamic> borrow) {
    if (borrow['due_date'] == null) return 0;
    final due = DateTime.parse(borrow['due_date']);
    final now = DateTime.now();
    if (now.isAfter(due)) {
      final days = now.difference(due).inDays;
      return days * 5.0;
    }
    return 0;
  }

  Future<void> _requestRenew(Map<String, dynamic> borrow) async {
    final renewCount = borrow['renew_count'] ?? 0;
    if (renewCount >= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Maximum 2 renewals allowed!'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ),
      );
      return;
    }
    try {
      await _supabase
          .from('borrows')
          .update({'status': 'renew_requested'})
          .eq('id', borrow['id']);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Renew request sent! Waiting for admin approval.',
          ),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ),
      );
      _fetchBorrows();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _requestReturn(Map<String, dynamic> borrow) async {
    try {
      await _supabase
          .from('borrows')
          .update({'status': 'return_requested'})
          .eq('id', borrow['id']);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Return request sent! Waiting for admin approval.',
          ),
          backgroundColor: const Color(0xFF1565C0),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ),
      );
      _fetchBorrows();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Map<String, dynamic> _statusInfo(String status) {
    switch (status) {
      case 'pending':
        return {
          'label': 'Pending Approval',
          'color': const Color(0xFFF57F17),
          'bg': const Color(0xFFFFFDE7),
        };
      case 'active':
        return {
          'label': 'Active',
          'color': const Color(0xFF2E7D32),
          'bg': const Color(0xFFE8F5E9),
        };
      case 'overdue':
        return {
          'label': 'Overdue',
          'color': Colors.red,
          'bg': const Color(0xFFFFEBEE),
        };
      case 'return_requested':
        return {
          'label': 'Return Requested',
          'color': const Color(0xFF1565C0),
          'bg': const Color(0xFFE3F2FD),
        };
      case 'renew_requested':
        return {
          'label': 'Renew Requested',
          'color': const Color(0xFF6A1B9A),
          'bg': const Color(0xFFF3E5F5),
        };
      default:
        return {
          'label': status,
          'color': Colors.grey,
          'bg': const Color(0xFFF5F5F5),
        };
    }
  }

  void _openBookDetail(Map<String, dynamic> borrow) {
    final bookId = borrow['book_id'];
    if (bookId == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookDetailPage(bookId: bookId.toString()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: kRed));
    }

    if (_borrows.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book_rounded, size: 54, color: Color(0xFFDDDDDD)),
            SizedBox(height: 12),
            Text(
              'No active borrows',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: kRed,
      onRefresh: _fetchBorrows,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        itemCount: _borrows.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final borrow = _borrows[i];
          final book = borrow['books'] as Map<String, dynamic>? ?? {};
          final title = book['title'] ?? 'Unknown';
          final author = book['author'] ?? '';
          final status = borrow['status'] ?? 'pending';
          final statusInfo = _statusInfo(status);
          final fine = _calcFine(borrow);
          final renewCount = borrow['renew_count'] ?? 0;
          final gradient = _gradients[i % _gradients.length];

          String dueText = '';
          if (borrow['due_date'] != null) {
            final due = DateTime.parse(borrow['due_date']);
            dueText = 'Due: ${due.day} ${_month(due.month)} ${due.year}';
          }

          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F9F9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFEEEEEE)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => _openBookDetail(borrow),
                      child: Container(
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
                    ),
                    const SizedBox(width: 12),

                    Expanded(
                      child: GestureDetector(
                        onTap: () => _openBookDetail(borrow),
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
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              author,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Status badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: statusInfo['bg'],
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: (statusInfo['color'] as Color)
                                      .withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                statusInfo['label'],
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: statusInfo['color'],
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),

                            if (dueText.isNotEmpty)
                              Text(
                                dueText,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF888888),
                                ),
                              ),

                            if (renewCount > 0)
                              Text(
                                'Renewed: $renewCount/2 times',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF888888),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Fine display
                if (fine > 0) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
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
                          'Fine: ৳${fine.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: kRed,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          '(৳5/day overdue)',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // Action buttons
                if (status == 'active' || status == 'overdue') ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: renewCount >= 2
                                ? Colors.grey
                                : const Color(0xFF6A1B9A),
                            side: BorderSide(
                              color: renewCount >= 2
                                  ? Colors.grey
                                  : const Color(0xFF6A1B9A),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          onPressed: renewCount >= 2
                              ? null
                              : () => _requestRenew(borrow),
                          child: Text(
                            renewCount >= 2 ? 'Max Renewed' : 'Renew',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kRed,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            elevation: 0,
                          ),
                          onPressed: () => _requestReturn(borrow),
                          child: const Text(
                            'Return',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else if (status == 'pending') ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey,
                        side: const BorderSide(
                          color: Color(0xFFDDDDDD),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: null,
                      child: const Text(
                        'Waiting for Admin Approval',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ] else if (status == 'return_requested' ||
                    status == 'renew_requested') ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey,
                        side: const BorderSide(
                          color: Color(0xFFDDDDDD),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: null,
                      child: Text(
                        status == 'return_requested'
                            ? 'Return Pending Approval'
                            : 'Renew Pending Approval',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
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
