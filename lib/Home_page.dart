import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:project_1/Category_page.dart';
import 'package:project_1/MyLibrary_page.dart';
import 'package:project_1/Profile_page.dart';
import 'package:project_1/BookDetails_page.dart';

const kRed = Color(0xFFE53935);
const kRedDark = Color(0xFFB71C1C);
const kRedLight = Color(0xFFFFEBEE);

const Map<String, List<Color>> _categoryColors = {
  'Science': [Color(0xFF1565C0), Color(0xFF42A5F5)],
  'Math': [Color(0xFF6A1B9A), Color(0xFFAB47BC)],
  'Literature': [Color(0xFF2E7D32), Color(0xFF66BB6A)],
  'History': [Color(0xFFE65100), Color(0xFFFFA726)],
  'Technology': [Color(0xFF00695C), Color(0xFF26A69A)],
  'Fiction': [Color(0xFFC62828), Color(0xFFEF5350)],
  'Medical': [Color(0xFF00838F), Color(0xFF26C6DA)],
};

Color _c1(String? cat) => _categoryColors[cat]?[0] ?? kRedDark;
Color _c2(String? cat) => _categoryColors[cat]?[1] ?? kRed;

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _supabase = Supabase.instance.client;
  int _currentIndex = 0;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  List<Map<String, dynamic>> _recommendedBooks = [];
  List<Map<String, dynamic>> _recentBooks = [];
  bool _loading = true;

  final List<Map<String, dynamic>> _categories = [
    {'icon': Icons.science_outlined, 'name': 'Science'},
    {'icon': Icons.business_center_outlined, 'name': 'Business'},
    {'icon': Icons.bookmark_outline, 'name': 'Literature'},
    {'icon': Icons.history_edu_outlined, 'name': 'History'},
    {'icon': Icons.computer_outlined, 'name': 'Bangla'},
  ];

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBooks() async {
    try {
      final recommended = await _supabase
          .from('books')
          .select()
          .gt('available_copies', 0)
          .limit(12);
      final recent = await _supabase
          .from('books')
          .select()
          .order('id', ascending: false)
          .limit(12);
      if (mounted) {
        setState(() {
          _recommendedBooks = List<Map<String, dynamic>>.from(recommended);
          _recentBooks = List<Map<String, dynamic>>.from(recent);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> _filterBooks(List<Map<String, dynamic>> books) {
    if (_searchQuery.isEmpty) return books;
    final q = _searchQuery.toLowerCase();
    return books.where((b) {
      final title = (b['title'] ?? '').toString().toLowerCase();
      final author = (b['author'] ?? '').toString().toLowerCase();
      return title.contains(q) || author.contains(q);
    }).toList();
  }

  bool get _isSearching => _searchQuery.isNotEmpty;
  List<Map<String, dynamic>> get _allFilteredBooks {
    final Map<dynamic, Map<String, dynamic>> merged = {};
    for (final b in [
      ..._filterBooks(_recommendedBooks),
      ..._filterBooks(_recentBooks),
    ]) {
      merged[b['id']] = b;
    }
    return merged.values.toList();
  }

  void _openCategory(String name) {
    const supported = [
      'Science',
      'Business',
      'Literature',
      'History',
      'Bangla',
    ];
    if (supported.contains(name)) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CategoryPage(category: name)),
      );
    }
  }

  void _openBookDetail(Map<String, dynamic> book) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookDetailPage(bookId: book['id'].toString()),
      ),
    );
  }

  void _openSeeAll(String section) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CategoryPage(category: 'Science')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            return w >= 768 ? _buildWebLayout(w) : _buildMobileLayout(w);
          },
        ),
      ),
    );
  }

  Widget _buildWebLayout(double totalW) {
    const sidebarW = 220.0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: sidebarW,
          height: double.infinity,
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: kRed,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.local_library,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Smart\nLibrary',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              _sidebarItem(Icons.home_rounded, 'Home', 0),
              _sidebarItem(
                Icons.collections_bookmark_outlined,
                'My Library',
                1,
              ),
              _sidebarItem(Icons.person_outline_rounded, 'Profile', 2),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.notifications_outlined,
                            size: 18,
                            color: Color(0xFF555555),
                          ),
                        ),
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: kRed,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Notifications',
                      style: TextStyle(fontSize: 13, color: Color(0xFF555555)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(width: 1, color: const Color(0xFFEEEEEE)),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: _buildWebContent(totalW - sidebarW - 1),
          ),
        ),
      ],
    );
  }

  Widget _sidebarItem(IconData icon, String label, int index) {
    final active = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        if (index == 0) {
          setState(() => _currentIndex = 0);
        } else if (index == 1)
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MyLibraryPage()),
          );
        else if (index == 2)
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfilePage()),
          );
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 2, 12, 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: active ? kRedLight : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: active ? kRed : const Color(0xFF888888),
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: active ? kRed : const Color(0xFF555555),
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebContent(double w) {
    const hPad = 28.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildWebTopBar(hPad),
        if (!_isSearching) ...[
          _buildHeroBanner(w, hPad, isWeb: true),
          _buildWebCategories(w, hPad),
        ],
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 60),
            child: Center(child: CircularProgressIndicator(color: kRed)),
          )
        else if (_isSearching)
          _buildWebSearchResults(w, hPad)
        else ...[
          _buildWebBookSection(
            'Recommended Books for You',
            _recommendedBooks,
            w,
            hPad,
          ),
          _buildWebBookSection('Recently Added Books', _recentBooks, w, hPad),
        ],
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildWebTopBar(double hPad) {
    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, 24, hPad, 0),
      child: Row(
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back! 👋',
                style: TextStyle(fontSize: 13, color: Color(0xFF888888)),
              ),
              SizedBox(height: 4),
              Text(
                'Find your next read',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const Spacer(),
          Container(
            width: 280,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search books, authors...',
                hintStyle: const TextStyle(
                  color: Color(0xFFAAAAAA),
                  fontSize: 13,
                ),
                prefixIcon: const Icon(Icons.search, color: kRed, size: 18),
                suffixIcon: _searchQuery.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        child: const Icon(
                          Icons.close,
                          color: Color(0xFFAAAAAA),
                          size: 18,
                        ),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 13),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebCategories(double w, double hPad) {
    final availableW = w - hPad * 2;
    const gaps = 4 * 12.0;
    final cardW = ((availableW - gaps) / 5).clamp(100.0, 160.0);
    final cardH = cardW * 0.85;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          'Explore by Categories',
          hPad,
          onSeeAll: () => _openSeeAll('categories'),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad),
          child: Row(
            children: _categories.asMap().entries.map((entry) {
              final i = entry.key;
              final cat = entry.value;
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                    right: i < _categories.length - 1 ? 12 : 0,
                  ),
                  height: cardH,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _openCategory(cat['name'] as String),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: cardW * 0.35,
                          height: cardW * 0.35,
                          decoration: BoxDecoration(
                            color: kRedLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            cat['icon'] as IconData,
                            color: kRed,
                            size: cardW * 0.18,
                          ),
                        ),
                        SizedBox(height: cardH * 0.08),
                        Text(
                          cat['name'] as String,
                          style: TextStyle(
                            fontSize: (cardW * 0.09).clamp(11.0, 15.0),
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF333333),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildWebSearchResults(double w, double hPad) {
    final books = _allFilteredBooks;
    if (books.isEmpty) return _buildNoResult(hPad);

    final availableW = w - hPad * 2;
    final colCount = (availableW / 200).floor().clamp(3, 6);
    const gap = 16.0;
    final cardW = (availableW - gap * (colCount - 1)) / colCount;
    final coverH = cardW * (4 / 3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 12),
          child: Text(
            '${books.length} result${books.length == 1 ? '' : 's'} for "$_searchQuery"',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: colCount,
              crossAxisSpacing: gap,
              mainAxisSpacing: gap,
              childAspectRatio: cardW / (coverH + 52),
            ),
            itemCount: books.length,
            itemBuilder: (_, i) => _buildWebBookCard(books[i], cardW, coverH),
          ),
        ),
      ],
    );
  }

  Widget _buildWebBookSection(
    String title,
    List<Map<String, dynamic>> books,
    double w,
    double hPad,
  ) {
    if (books.isEmpty) return const SizedBox();
    final availableW = w - hPad * 2;
    final colCount = (availableW / 200).floor().clamp(3, 6);
    const gap = 16.0;
    final cardW = (availableW - gap * (colCount - 1)) / colCount;
    final coverH = cardW * (4 / 3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(title, hPad, onSeeAll: () => _openSeeAll(title)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: colCount,
              crossAxisSpacing: gap,
              mainAxisSpacing: gap,
              childAspectRatio: cardW / (coverH + 52),
            ),
            itemCount: books.length,
            itemBuilder: (_, i) => _buildWebBookCard(books[i], cardW, coverH),
          ),
        ),
      ],
    );
  }

  Widget _buildWebBookCard(
    Map<String, dynamic> book,
    double cardW,
    double coverH,
  ) {
    final c1 = _c1(book['category']);
    final c2 = _c2(book['category']);
    return GestureDetector(
      onTap: () => _openBookDetail(book),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [c1, c2],
                ),
                boxShadow: [
                  BoxShadow(
                    color: c1.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: book['cover_url'] != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        book['cover_url'],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _cardFallback(book['title'], cardW),
                      ),
                    )
                  : _cardFallback(book['title'], cardW),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            book['title'] ?? '',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF222222),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            book['author'] ?? '',
            style: const TextStyle(fontSize: 11, color: Color(0xFF999999)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(double w) {
    final hPad = w < 360 ? 14.0 : 18.0;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMobileTopBar(hPad),
                _buildMobileSearchBar(hPad),
                if (!_isSearching) ...[
                  _buildHeroBanner(w, hPad, isWeb: false),
                  _buildMobileCategories(w, hPad),
                ],
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: CircularProgressIndicator(color: kRed),
                    ),
                  )
                else if (_isSearching)
                  _buildMobileSearchResults(w, hPad)
                else ...[
                  _buildMobileBookSection(
                    'Recommended Books for You',
                    _recommendedBooks,
                    w,
                    hPad,
                  ),
                  _buildMobileBookSection(
                    'Recently Added Books',
                    _recentBooks,
                    w,
                    hPad,
                  ),
                ],
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        _buildMobileBottomNav(),
      ],
    );
  }

  Widget _buildMobileTopBar(double hPad) {
    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 0),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: kRed,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.local_library,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Smart Library',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const Spacer(),
          Stack(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFEEEEEE)),
                ),
                child: const Icon(
                  Icons.notifications_outlined,
                  color: Color(0xFF555555),
                  size: 20,
                ),
              ),
              Positioned(
                top: 7,
                right: 7,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: kRed,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileSearchBar(double hPad) {
    return Container(
      margin: EdgeInsets.fromLTRB(hPad, 14, hPad, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Search any books...',
          hintStyle: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 13),
          prefixIcon: const Icon(Icons.search, color: kRed, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                  child: const Icon(
                    Icons.close,
                    color: Color(0xFFAAAAAA),
                    size: 18,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onChanged: (val) => setState(() => _searchQuery = val.trim()),
      ),
    );
  }

  Widget _buildMobileSearchResults(double w, double hPad) {
    final books = _allFilteredBooks;
    if (books.isEmpty) return _buildNoResult(hPad);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 10),
          child: Text(
            '${books.length} result${books.length == 1 ? '' : 's'} for "$_searchQuery"',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: hPad),
          itemCount: books.length,
          itemBuilder: (_, i) => _buildMobileResultCard(books[i]),
        ),
      ],
    );
  }

  Widget _buildMobileResultCard(Map<String, dynamic> book) {
    final c1 = _c1(book['category']);
    final c2 = _c2(book['category']);
    final available = (book['available_copies'] ?? 0) > 0;

    return GestureDetector(
      onTap: () => _openBookDetail(book),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 70,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [c1, c2],
                ),
              ),
              child: book['cover_url'] != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        book['cover_url'],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _cardFallback(book['title'], 52),
                      ),
                    )
                  : _cardFallback(book['title'], 52),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book['title'] ?? '',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    book['author'] ?? '',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF777777),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (book['category'] != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: c1.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            book['category'],
                            style: TextStyle(
                              fontSize: 9,
                              color: c1,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: available
                              ? const Color(0xFFE8F5E9)
                              : kRedLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          available ? 'Available' : 'Unavailable',
                          style: TextStyle(
                            fontSize: 9,
                            color: available ? const Color(0xFF2E7D32) : kRed,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFCCCCCC),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResult(double hPad) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: kRedLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                color: kRed,
                size: 28,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              '"$_searchQuery" No records found',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF333333),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              'Please try a different keyword',
              style: TextStyle(fontSize: 12, color: Color(0xFF888888)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileCategories(double w, double hPad) {
    final gaps = 10.0 * (_categories.length - 1);
    final cardW = ((w - hPad * 2 - gaps) / _categories.length).clamp(
      60.0,
      90.0,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          'Explore by Categories',
          hPad,
          onSeeAll: () => _openSeeAll('categories'),
        ),
        SizedBox(
          height: 95,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: hPad),
            physics: const BouncingScrollPhysics(),
            itemCount: _categories.length,
            itemBuilder: (_, i) {
              final cat = _categories[i];
              return GestureDetector(
                onTap: () => _openCategory(cat['name'] as String),
                child: Container(
                  width: cardW,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: kRedLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          cat['icon'] as IconData,
                          color: kRed,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        cat['name'] as String,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF333333),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMobileBookSection(
    String title,
    List<Map<String, dynamic>> books,
    double w,
    double hPad,
  ) {
    if (books.isEmpty) return const SizedBox();
    const gaps = 2 * 12.0;
    final cardW = ((w - hPad * 2 - gaps) / 3).clamp(85.0, 130.0);
    final coverH = cardW * 1.27;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(title, hPad, onSeeAll: () => _openSeeAll(title)),
        SizedBox(
          height: coverH + 48,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: hPad),
            physics: const BouncingScrollPhysics(),
            itemCount: books.length,
            itemBuilder: (_, i) {
              final book = books[i];
              final c1 = _c1(book['category']);
              final c2 = _c2(book['category']);
              return GestureDetector(
                onTap: () => _openBookDetail(book),
                child: Container(
                  width: cardW,
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: cardW,
                        height: coverH,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [c1, c2],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: c1.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: book['cover_url'] != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  book['cover_url'],
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _cardFallback(book['title'], cardW),
                                ),
                              )
                            : _cardFallback(book['title'], cardW),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        book['title'] ?? '',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF222222),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        book['author'] ?? '',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF999999),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMobileBottomNav() {
    final items = [
      {'icon': Icons.home_rounded, 'label': 'Home'},
      {'icon': Icons.collections_bookmark_outlined, 'label': 'My Library'},
      {'icon': Icons.person_outline_rounded, 'label': 'Profile'},
    ];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFEEEEEE))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          final active = _currentIndex == i;
          return GestureDetector(
            onTap: () {
              if (i == 0) {
                setState(() => _currentIndex = 0);
              } else if (i == 1)
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyLibraryPage()),
                );
              else if (i == 2)
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfilePage()),
                );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              decoration: BoxDecoration(
                color: active ? kRedLight : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    items[i]['icon'] as IconData,
                    color: active ? kRed : const Color(0xFFBBBBBB),
                    size: 22,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    items[i]['label'] as String,
                    style: TextStyle(
                      color: active ? kRed : const Color(0xFFBBBBBB),
                      fontSize: 10,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildHeroBanner(double w, double hPad, {required bool isWeb}) {
    final padding = isWeb ? 28.0 : 22.0;
    final titleSize = isWeb ? 24.0 : 18.0;
    final subtitleSize = isWeb ? 12.5 : 10.0;
    final bookW = isWeb ? 58.0 : 42.0;
    final bookMaxH = isWeb ? 110.0 : 80.0;
    final minH = isWeb ? 160.0 : 140.0;

    return Container(
      margin: EdgeInsets.fromLTRB(hPad, 16, hPad, 0),
      constraints: BoxConstraints(minHeight: minH),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kRedDark, kRed],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.07),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(padding),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Unlock a\nWorld of\nKnowledge',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: titleSize,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                      SizedBox(height: isWeb ? 10 : 6),
                      Text(
                        'Discover books tailored to your interests.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.80),
                          fontSize: subtitleSize,
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: isWeb ? 14 : 10),
                      Row(
                        children: [
                          _dot(true),
                          const SizedBox(width: 4),
                          _dot(false),
                          const SizedBox(width: 4),
                          _dot(false),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: bookW + 28,
                  height: bookMaxH,
                  child: Stack(
                    children: [
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: _bookRect(
                          const Color(0xFFFFCDD2),
                          bookW,
                          bookMaxH * 0.80,
                        ),
                      ),
                      Positioned(
                        right: bookW * 0.18,
                        bottom: 0,
                        child: _bookRect(
                          const Color(0xFFEF9A9A),
                          bookW,
                          bookMaxH * 0.88,
                        ),
                      ),
                      Positioned(
                        right: bookW * 0.36,
                        bottom: 0,
                        child: _bookRect(Colors.white, bookW, bookMaxH),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(bool active) => Container(
    width: active ? 18 : 6,
    height: 3,
    decoration: BoxDecoration(
      color: active ? Colors.white : Colors.white.withOpacity(0.35),
      borderRadius: BorderRadius.circular(2),
    ),
  );

  Widget _bookRect(Color color, double w, double h) => Container(
    width: w,
    height: h,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(6),
    ),
  );

  Widget _cardFallback(String? title, double cardW) => Padding(
    padding: const EdgeInsets.all(10),
    child: Text(
      title ?? '',
      style: TextStyle(
        color: Colors.white,
        fontSize: (cardW * 0.1).clamp(10.0, 14.0),
        fontWeight: FontWeight.w700,
        height: 1.4,
      ),
    ),
  );

  Widget _sectionHeader(String title, double hPad, {VoidCallback? onSeeAll}) {
    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: onSeeAll,
            child: const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Text(
                'See All',
                style: TextStyle(
                  color: kRed,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
