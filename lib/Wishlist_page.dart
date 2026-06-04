import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const kRed = Color(0xFFE53935);
const kRedLight = Color(0xFFFFEBEE);

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  final _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _wishlist = [];
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
    _fetchWishlist();
  }

  Future<void> _fetchWishlist() async {
    setState(() => _loading = true);
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final data = await _supabase
          .from('wishlists')
          .select('*, books(id, title, author, available_copies, category)')
          .eq('user_id', userId)
          .order('added_at', ascending: false);

      setState(() {
        _wishlist = List<Map<String, dynamic>>.from(data);
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

  Future<void> _removeFromWishlist(Map<String, dynamic> item) async {
    try {
      await _supabase.from('wishlists').delete().eq('id', item['id']);

      final book = item['books'] as Map<String, dynamic>? ?? {};
      final title = book['title'] ?? 'Book';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"$title" removed from wishlist.'),
          backgroundColor: const Color(0xFF555555),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ),
      );
      _fetchWishlist();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _borrowBook(Map<String, dynamic> item) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      final book = item['books'] as Map<String, dynamic>? ?? {};
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
          content: Text('Borrow request sent for "$title"!'),
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

    if (_wishlist.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border_rounded,
              size: 54,
              color: Color(0xFFDDDDDD),
            ),
            SizedBox(height: 12),
            Text(
              'Your wishlist is empty',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            SizedBox(height: 4),
            Text(
              'Tap ♡ on any book to add it here',
              style: TextStyle(color: Color(0xFFBBBBBB), fontSize: 12),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: kRed,
      onRefresh: _fetchWishlist,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        itemCount: _wishlist.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final item = _wishlist[i];
          final book = item['books'] as Map<String, dynamic>? ?? {};
          final title = book['title'] ?? 'Unknown';
          final author = book['author'] ?? '';
          final category = book['category'] ?? '';
          final availableCopies = book['available_copies'] ?? 0;
          final isAvailable = availableCopies > 0;
          final gradient = _gradients[i % _gradients.length];
          String addedDate = '';
          if (item['added_at'] != null) {
            final d = DateTime.parse(item['added_at']);
            addedDate = 'Added ${d.day} ${_month(d.month)} ${d.year}';
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
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _removeFromWishlist(item),
                                child: const Icon(
                                  Icons.favorite_rounded,
                                  color: kRed,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            author,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          if (category.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              category,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFFAAAAAA),
                              ),
                            ),
                          ],
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: isAvailable
                                      ? const Color(0xFFE8F5E9)
                                      : const Color(0xFFFFEBEE),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isAvailable
                                        ? const Color(0xFFA5D6A7)
                                        : const Color(0xFFEF9A9A),
                                  ),
                                ),
                                child: Text(
                                  isAvailable ? 'Available' : 'Not Available',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isAvailable
                                        ? const Color(0xFF2E7D32)
                                        : kRed,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          if (addedDate.isNotEmpty)
                            Text(
                              addedDate,
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
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isAvailable
                          ? kRed
                          : Colors.grey.shade300,
                      foregroundColor: isAvailable ? Colors.white : Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      elevation: 0,
                    ),
                    onPressed: isAvailable ? () => _borrowBook(item) : null,
                    child: Text(
                      isAvailable ? 'Borrow Now' : 'Currently Unavailable',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
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
