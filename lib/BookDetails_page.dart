import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const kRed = Color(0xFFE53935);
const kRedDark = Color(0xFFB71C1C);
const kRedLight = Color(0xFFFFEBEE);

const Map<String, List<Color>> _categoryColors = {
  'Science': [Color(0xFF1565C0), Color(0xFF42A5F5)],
  'Math': [Color(0xFF6A1B9A), Color(0xFFAB47BC)],
  'Literature': [Color(0xFF2E7D32), Color(0xFF66BB6A)],
  'History': [Color(0xFFE65100), Color(0xFFFFA726)],
  'Technology': [Color(0xFF00695C), Color(0xFF26A69A)],
  'Religion': [Color(0xFF4527A0), Color(0xFF7E57C2)],
  'Fiction': [Color(0xFFC62828), Color(0xFFEF5350)],
  'Medical': [Color(0xFF00838F), Color(0xFF26C6DA)],
};

Color _coverC1(String? cat) => _categoryColors[cat]?[0] ?? kRedDark;
Color _coverC2(String? cat) => _categoryColors[cat]?[1] ?? kRed;

class BookDetailPage extends StatefulWidget {
  final String bookId;
  const BookDetailPage({super.key, required this.bookId});

  @override
  State<BookDetailPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends State<BookDetailPage> {
  final _supabase = Supabase.instance.client;

  Map<String, dynamic>? _book;
  bool _fetching = true;
  bool _loading = false;
  bool _isBorrowed = false;
  bool _isReserved = false;
  bool _isWishlisted = false;
  bool _wishlistLoading = false;
  String? _borrowStatus;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      final book = await _supabase
          .from('books')
          .select()
          .eq('id', widget.bookId)
          .single();

      bool isBorrowed = false;
      bool isReserved = false;
      bool isWishlisted = false;
      String? borrowStatus;

      if (userId != null) {
        final borrow = await _supabase
            .from('borrows')
            .select('status')
            .eq('user_id', userId)
            .eq('book_id', widget.bookId)
            .inFilter('status', [
              'pending',
              'active',
              'return_requested',
              'renew_requested',
            ])
            .maybeSingle();

        final reserve = await _supabase
            .from('reservations')
            .select()
            .eq('user_id', userId)
            .eq('book_id', widget.bookId)
            .inFilter('status', ['pending', 'ready'])
            .maybeSingle();

        final wishlist = await _supabase
            .from('wishlists')
            .select()
            .eq('user_id', userId)
            .eq('book_id', widget.bookId)
            .maybeSingle();

        isBorrowed = borrow != null;
        borrowStatus = borrow?['status'];
        isReserved = reserve != null;
        isWishlisted = wishlist != null;
      }

      if (mounted) {
        setState(() {
          _book = book;
          _isBorrowed = isBorrowed;
          _isReserved = isReserved;
          _isWishlisted = isWishlisted;
          _borrowStatus = borrowStatus;
          _fetching = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _fetching = false);
    }
  }

  Future<void> _borrow() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return _snack('Please login first', Colors.red);

    setState(() => _loading = true);
    try {
      final due = DateTime.now().add(const Duration(days: 14));
      await _supabase.from('borrows').insert({
        'user_id': userId,
        'book_id': widget.bookId,
        'borrow_date': DateTime.now().toIso8601String(),
        'due_date': due.toIso8601String(),
        'status': 'pending',
        'renew_count': 0,
      });
      if (mounted) {
        setState(() {
          _isBorrowed = true;
          _borrowStatus = 'pending';
        });
        _snack(
          'Borrow request sent! Waiting for admin approval.',
          const Color(0xFF2E7D32),
        );
      }
    } catch (e) {
      if (mounted) _snack('Failed: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reserve() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return _snack('Please login first', Colors.red);

    setState(() => _loading = true);
    try {
      await _supabase.from('reservations').insert({
        'user_id': userId,
        'book_id': widget.bookId,
        'reserved_at': DateTime.now().toIso8601String(),
        'expires_at': DateTime.now()
            .add(const Duration(days: 3))
            .toIso8601String(),
        'status': 'pending',
      });
      if (mounted) {
        setState(() => _isReserved = true);
        _snack(
          'Reserved! We\'ll notify you when available.',
          const Color(0xFFE65100),
        );
      }
    } catch (e) {
      if (mounted) _snack('Failed: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleWishlist() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return _snack('Please login first', Colors.red);

    setState(() => _wishlistLoading = true);
    try {
      if (_isWishlisted) {
        await _supabase
            .from('wishlists')
            .delete()
            .eq('user_id', userId)
            .eq('book_id', widget.bookId);
        if (mounted) {
          setState(() => _isWishlisted = false);
          _snack('Removed from wishlist', const Color(0xFF555555));
        }
      } else {
        await _supabase.from('wishlists').insert({
          'user_id': userId,
          'book_id': widget.bookId,
          'added_at': DateTime.now().toIso8601String(),
        });
        if (mounted) {
          setState(() => _isWishlisted = true);
          _snack('Added to wishlist!', kRed);
        }
      }
    } catch (e) {
      if (mounted) _snack('Failed: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _wishlistLoading = false);
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Map<String, dynamic> _borrowStatusInfo() {
    switch (_borrowStatus) {
      case 'pending':
        return {
          'label': 'Borrow Request Sent',
          'icon': Icons.hourglass_top_rounded,
          'fg': const Color(0xFFF57F17),
          'bg': const Color(0xFFFFFDE7),
        };
      case 'active':
        return {
          'label': 'Currently Borrowed',
          'icon': Icons.check_circle_outline_rounded,
          'fg': const Color(0xFF2E7D32),
          'bg': const Color(0xFFE8F5E9),
        };
      case 'return_requested':
        return {
          'label': 'Return Requested',
          'icon': Icons.assignment_return_outlined,
          'fg': const Color(0xFF1565C0),
          'bg': const Color(0xFFE3F2FD),
        };
      case 'renew_requested':
        return {
          'label': 'Renew Requested',
          'icon': Icons.autorenew_rounded,
          'fg': const Color(0xFF6A1B9A),
          'bg': const Color(0xFFF3E5F5),
        };
      default:
        return {
          'label': 'Request Sent',
          'icon': Icons.hourglass_top_rounded,
          'fg': const Color(0xFF2E7D32),
          'bg': const Color(0xFFE8F5E9),
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_fetching) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F5F5),
        body: Center(child: CircularProgressIndicator(color: kRed)),
      );
    }

    if (_book == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: kRed, size: 48),
              const SizedBox(height: 12),
              const Text('Book not found'),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back', style: TextStyle(color: kRed)),
              ),
            ],
          ),
        ),
      );
    }

    final book = _book!;
    final available = (book['available_copies'] ?? 0) > 0;
    final c1 = _coverC1(book['category']);
    final c2 = _coverC2(book['category']);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFEEEEEE)),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Book Details',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _wishlistLoading ? null : _toggleWishlist,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _isWishlisted
                            ? kRedLight
                            : const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _isWishlisted ? kRed : const Color(0xFFEEEEEE),
                        ),
                      ),
                      child: _wishlistLoading
                          ? const Padding(
                              padding: EdgeInsets.all(8),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: kRed,
                              ),
                            )
                          : Icon(
                              _isWishlisted
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              size: 18,
                              color: _isWishlisted
                                  ? kRed
                                  : const Color(0xFFAAAAAA),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                      child: Column(
                        children: [
                          Container(
                            width: 130,
                            height: 185,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [c1, c2],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: c1.withValues(alpha: 0.35),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: book['cover_url'] != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Image.network(
                                      book['cover_url'],
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          _coverFallback(book['title']),
                                    ),
                                  )
                                : _coverFallback(book['title']),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: available
                                  ? const Color(0xFFE8F5E9)
                                  : const Color(0xFFFFEBEE),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: available
                                    ? const Color(0xFF2E7D32)
                                    : kRed,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: available
                                        ? const Color(0xFF2E7D32)
                                        : kRed,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  available ? 'Available' : 'Unavailable',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: available
                                        ? const Color(0xFF2E7D32)
                                        : kRed,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            book['title'] ?? 'Unknown Title',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            book['author'] ?? 'Unknown Author',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF888888),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 7,
                            runSpacing: 6,
                            alignment: WrapAlignment.center,
                            children: [
                              if (book['category'] != null)
                                _chip(book['category'], kRed, kRedLight),
                              if (book['edition'] != null)
                                _chip(
                                  book['edition'],
                                  const Color(0xFF555555),
                                  const Color(0xFFF5F5F5),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _stat(
                            '${book['available_copies'] ?? 0}/${book['total_copies'] ?? 0}',
                            'Copies',
                            Icons.library_books_outlined,
                          ),
                          _vDivider(),
                          _stat(
                            book['year']?.toString() ?? 'N/A',
                            'Year',
                            Icons.calendar_today_outlined,
                          ),
                          _vDivider(),
                          _stat(
                            book['language'] ?? 'N/A',
                            'Language',
                            Icons.language_outlined,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (book['description'] != null)
                      Container(
                        width: double.infinity,
                        color: Colors.white,
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'About this book',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              book['description'],
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF555555),
                                height: 1.7,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
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
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: kRed))
            : _isBorrowed
            ? _statusBar(_borrowStatusInfo())
            : _isReserved
            ? _statusBar({
                'label': 'Reserved',
                'icon': Icons.bookmark_rounded,
                'fg': const Color(0xFFE65100),
                'bg': const Color(0xFFFFF8E1),
              })
            : Row(
                children: [
                  // Show Borrow + Reserve when copies available, only Reserve when unavailable
                  if (available) ...[
                    Expanded(
                      child: _actionBtn('Borrow', filled: true, onTap: _borrow),
                    ),
                  ] else ...[
                    Expanded(
                      child: _actionBtn(
                        'Reserve',
                        filled: true,
                        onTap: _reserve,
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _coverFallback(String? title) => Padding(
    padding: const EdgeInsets.all(14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.auto_stories, color: Colors.white, size: 22),
        const Spacer(),
        Text(
          title ?? '',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            height: 1.35,
          ),
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );

  Widget _chip(String label, Color fg, Color bg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
    ),
  );

  Widget _stat(String val, String label, IconData icon) => Column(
    children: [
      Icon(icon, color: kRed, size: 18),
      const SizedBox(height: 5),
      Text(
        val,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 2),
      Text(
        label,
        style: const TextStyle(fontSize: 10, color: Color(0xFF888888)),
      ),
    ],
  );

  Widget _vDivider() =>
      Container(width: 1, height: 38, color: const Color(0xFFEEEEEE));

  Widget _actionBtn(
    String label, {
    required bool filled,
    required VoidCallback onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 50,
      decoration: BoxDecoration(
        color: filled ? kRed : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kRed, width: 1.5),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: filled ? Colors.white : kRed,
          ),
        ),
      ),
    ),
  );

  Widget _statusBar(Map<String, dynamic> info) => Container(
    height: 50,
    decoration: BoxDecoration(
      color: info['bg'] as Color,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(info['icon'] as IconData, color: info['fg'] as Color, size: 18),
        const SizedBox(width: 8),
        Text(
          info['label'] as String,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: info['fg'] as Color,
          ),
        ),
      ],
    ),
  );
}
