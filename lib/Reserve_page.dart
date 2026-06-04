import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const kRed = Color(0xFFE53935);
const kRedLight = Color(0xFFFFEBEE);

class ReservePage extends StatefulWidget {
  const ReservePage({super.key});

  @override
  State<ReservePage> createState() => _ReservePageState();
}

class _ReservePageState extends State<ReservePage> {
  final _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _reservations = [];
  bool _loading = true;

  final List<List<Color>> _gradients = [
    [Color(0xFFE65100), Color(0xFFF4511E)],
    [Color(0xFF880E4F), Color(0xFFC2185B)],
    [Color(0xFF1565C0), Color(0xFF0D47A1)],
    [Color(0xFF2E7D32), Color(0xFF1B5E20)],
    [Color(0xFF6A1B9A), Color(0xFF4A148C)],
  ];

  @override
  void initState() {
    super.initState();
    _fetchReservations();
  }

  Future<void> _fetchReservations() async {
    setState(() => _loading = true);
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final data = await _supabase
          .from('reservations')
          .select('*, books(title, author)')
          .eq('user_id', userId)
          .inFilter('status', ['pending', 'ready'])
          .order('reserved_at', ascending: false);

      setState(() {
        _reservations = List<Map<String, dynamic>>.from(data);
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

  Future<void> _cancelReservation(Map<String, dynamic> reservation) async {
    try {
      await _supabase
          .from('reservations')
          .update({'status': 'cancelled'})
          .eq('id', reservation['id']);

      final title = (reservation['books'] as Map?)?.get('title') ?? 'Book';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reservation for "$title" cancelled.'),
          backgroundColor: const Color(0xFF555555),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ),
      );
      _fetchReservations();
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

    if (_reservations.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_border_rounded,
              size: 54,
              color: Color(0xFFDDDDDD),
            ),
            SizedBox(height: 12),
            Text(
              'No active reservations',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: kRed,
      onRefresh: _fetchReservations,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        itemCount: _reservations.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final reservation = _reservations[i];
          final book = reservation['books'] as Map<String, dynamic>? ?? {};
          final title = book['title'] ?? 'Unknown';
          final author = book['author'] ?? '';
          final status = reservation['status'] ?? 'pending';
          final isReady = status == 'ready';
          final gradient = _gradients[i % _gradients.length];

          // Format expires_at
          String dateText = '';
          if (isReady) {
            dateText = 'Ready now';
          } else if (reservation['expires_at'] != null) {
            final exp = DateTime.parse(reservation['expires_at']);
            dateText = 'Est. ${_month(exp.month)} ${exp.day}, ${exp.year}';
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
                    // Book cover
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
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isReady
                                      ? const Color(0xFFE8F5E9)
                                      : const Color(0xFFF5F5F5),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isReady
                                        ? const Color(0xFFA5D6A7)
                                        : const Color(0xFFEEEEEE),
                                  ),
                                ),
                                child: Text(
                                  isReady ? 'Ready to Pick Up' : 'Waiting',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isReady
                                        ? const Color(0xFF2E7D32)
                                        : const Color(0xFF888888),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          if (dateText.isNotEmpty)
                            Text(
                              dateText,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF888888),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Buttons
                Row(
                  children: [
                    if (isReady) ...[
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
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  'Please collect from the library desk!',
                                ),
                                backgroundColor: const Color(0xFF2E7D32),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                margin: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  16,
                                ),
                              ),
                            );
                          },
                          child: const Text(
                            'Collect Now',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF555555),
                          side: const BorderSide(
                            color: Color(0xFFDDDDDD),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: () => _cancelReservation(reservation),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
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

extension SafeMap on Map {
  dynamic get(String key) => this[key];
}
