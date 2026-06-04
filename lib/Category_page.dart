import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:project_1/BookDetails_page.dart';

const kRed = Color(0xFFE53935);
const kRedLight = Color(0xFFFFEBEE);
const Map<String, List<Color>> _categoryColors = {
  'Science': [Color(0xFF1565C0), Color(0xFF42A5F5)],
  'Math': [Color(0xFF6A1B9A), Color(0xFFAB47BC)],
  'Literature': [Color(0xFF2E7D32), Color(0xFF66BB6A)],
  'History': [Color(0xFFE65100), Color(0xFFFFA726)],
  'Technology': [Color(0xFF00695C), Color(0xFF26A69A)],
  'Fiction': [Color(0xFFC62828), Color(0xFFEF5350)],
  'Medical': [Color(0xFF00838F), Color(0xFF26C6DA)],
  'Bangla': [Color(0xFF006064), Color(0xFF00838F)],
  'Business': [Color(0xFF4E342E), Color(0xFF795548)],
};
Color _c1(String? cat) => _categoryColors[cat]?[0] ?? const Color(0xFFB71C1C);
Color _c2(String? cat) => _categoryColors[cat]?[1] ?? kRed;

class CategoryPage extends StatefulWidget {
  final String category;
  const CategoryPage({super.key, required this.category});
  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  final _supabase = Supabase.instance.client;
  final _search = TextEditingController();
  String _sort = 'A to Z';

  List<Map<String, dynamic>> _books = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    try {
      final data = await _supabase
          .from('books')
          .select()
          .eq('category', widget.category);

      if (mounted) {
        setState(() {
          _books = List<Map<String, dynamic>>.from(data);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    var list = List<Map<String, dynamic>>.from(_books);
    final q = _search.text.toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where(
            (b) =>
                (b['title'] ?? '').toLowerCase().contains(q) ||
                (b['author'] ?? '').toLowerCase().contains(q),
          )
          .toList();
    }

    // Sort
    if (_sort == 'A to Z') {
      list.sort((a, b) => (a['title'] ?? '').compareTo(b['title'] ?? ''));
    }
    if (_sort == 'Z to A') {
      list.sort((a, b) => (b['title'] ?? '').compareTo(a['title'] ?? ''));
    }
    if (_sort == 'Available first') {
      list.sort(
        (a, b) =>
            (b['available_copies'] ?? 0).compareTo(a['available_copies'] ?? 0),
      );
    }

    return list;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final books = _filtered;
    final availCount = _books
        .where((b) => (b['available_copies'] ?? 0) > 0)
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Column(
                children: [
                  Row(
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.category} Books',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '$availCount available',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF888888),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFEEEEEE)),
                    ),
                    child: TextField(
                      controller: _search,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'Search title or author...',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: Color(0xFFAAAAAA),
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: kRed,
                          size: 20,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 12, 2),
              child: Row(
                children: [
                  Text(
                    '${books.length} results',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  DropdownButton<String>(
                    value: _sort,
                    underline: const SizedBox(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: kRed,
                    ),
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: kRed,
                      size: 18,
                    ),
                    items: ['A to Z', 'Z to A', 'Available first']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) => setState(() => _sort = v!),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: kRed))
                  : books.isEmpty
                  ? const Center(
                      child: Text(
                        'No books found',
                        style: TextStyle(color: Color(0xFF888888)),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                      physics: const BouncingScrollPhysics(),
                      itemCount: books.length,
                      itemBuilder: (_, i) => _card(books[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(Map<String, dynamic> b) {
    final available = (b['available_copies'] ?? 0) > 0;
    final c1 = _c1(b['category']);
    final c2 = _c2(b['category']);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BookDetailPage(bookId: b['id'].toString()),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 62,
              height: 84,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [c1, c2],
                ),
              ),
              padding: const EdgeInsets.all(7),
              child: Text(
                (b['title'] ?? '').split(' ').take(3).join('\n'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8.5,
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
                    b['title'] ?? '',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    b['author'] ?? '',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF888888),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 5,
                    runSpacing: 4,
                    children: [
                      _statusBadge(available),
                      if (b['edition'] != null) _badge(b['edition']),
                      if (b['category'] != null) _badge(b['category']),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${b['available_copies'] ?? 0}/${b['total_copies'] ?? 0} copies available',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF888888),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(bool available) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: available ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      available ? 'Available' : 'Unavailable',
      style: TextStyle(
        fontSize: 9.5,
        fontWeight: FontWeight.w700,
        color: available ? const Color(0xFF2E7D32) : kRed,
      ),
    ),
  );

  Widget _badge(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: const Color(0xFFF5F5F5),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFEEEEEE)),
    ),
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 9.5,
        fontWeight: FontWeight.w600,
        color: Color(0xFF666666),
      ),
    ),
  );
}
