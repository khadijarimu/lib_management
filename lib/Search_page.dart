import 'package:flutter/material.dart';

const kRed = Color(0xFFE53935);
const kRedLight = Color(0xFFFFEBEE);

class SearchBook {
  final String title;
  final String subtitle;
  final String authors;
  final String status;
  final String dueInfo;
  final Color coverColor1;
  final Color coverColor2;
  final String coverLabel;

  const SearchBook({
    required this.title,
    required this.subtitle,
    required this.authors,
    required this.status,
    this.dueInfo = '',
    required this.coverColor1,
    required this.coverColor2,
    required this.coverLabel,
  });
}

const _allBooks = [
  SearchBook(
    title: 'Clean Code',
    subtitle: '(1st Ed)',
    authors: 'by Robert C. Martin',
    status: 'available',
    coverColor1: Color(0xFF1565C0),
    coverColor2: Color(0xFF1976D2),
    coverLabel: 'Clean\nCode',
  ),
  SearchBook(
    title: 'Introduction to Algorithms',
    subtitle: '(4th Ed)',
    authors: 'by Cormen, Leiserson, Rivest',
    status: 'checked_out',
    dueInfo: 'due back in 7 days',
    coverColor1: Color(0xFF212121),
    coverColor2: Color(0xFF424242),
    coverLabel: 'CLRS\nAlgorithms',
  ),
  SearchBook(
    title: 'The Pragmatic Programmer',
    subtitle: '(20th Ed)',
    authors: 'by Hunt & Thomas',
    status: 'available',
    coverColor1: Color(0xFF4A148C),
    coverColor2: Color(0xFF6A1B9A),
    coverLabel: 'Pragmatic\nProgrammer',
  ),
  SearchBook(
    title: 'Designing Data-Intensive Apps',
    subtitle: '(1st Ed)',
    authors: 'by Martin Kleppmann',
    status: 'available',
    coverColor1: Color(0xFF00695C),
    coverColor2: Color(0xFF00897B),
    coverLabel: 'DDIA',
  ),
  SearchBook(
    title: 'Computer Networks',
    subtitle: '(5th Ed)',
    authors: 'by Tanenbaum & Wetherall',
    status: 'checked_out',
    dueInfo: 'due back in 3 days',
    coverColor1: Color(0xFF37474F),
    coverColor2: Color(0xFF546E7A),
    coverLabel: 'Computer\nNetworks',
  ),
  SearchBook(
    title: 'A Brief History of Time',
    subtitle: '(Updated Ed)',
    authors: 'by Stephen Hawking',
    status: 'available',
    coverColor1: Color(0xFF0D47A1),
    coverColor2: Color(0xFF1565C0),
    coverLabel: 'Brief\nHistory',
  ),
  SearchBook(
    title: 'The Selfish Gene',
    subtitle: '(40th Ed)',
    authors: 'by Richard Dawkins',
    status: 'available',
    coverColor1: Color(0xFF1B5E20),
    coverColor2: Color(0xFF2E7D32),
    coverLabel: 'Selfish\nGene',
  ),
  SearchBook(
    title: 'Sapiens',
    subtitle: '(1st Ed)',
    authors: 'by Yuval Noah Harari',
    status: 'checked_out',
    dueInfo: 'due back in 10 days',
    coverColor1: Color(0xFF827717),
    coverColor2: Color(0xFFF9A825),
    coverLabel: 'Sapiens',
  ),
  SearchBook(
    title: 'Atomic Habits',
    subtitle: '(1st Ed)',
    authors: 'by James Clear',
    status: 'available',
    coverColor1: Color(0xFFBF360C),
    coverColor2: Color(0xFFE64A19),
    coverLabel: 'Atomic\nHabits',
  ),
  SearchBook(
    title: 'Zero to One',
    subtitle: '(1st Ed)',
    authors: 'by Peter Thiel',
    status: 'available',
    coverColor1: Color(0xFF212121),
    coverColor2: Color(0xFF37474F),
    coverLabel: 'Zero\nto One',
  ),
  SearchBook(
    title: 'The Lean Startup',
    subtitle: '(1st Ed)',
    authors: 'by Eric Ries',
    status: 'checked_out',
    dueInfo: 'due back in 5 days',
    coverColor1: Color(0xFF006064),
    coverColor2: Color(0xFF00838F),
    coverLabel: 'Lean\nStartup',
  ),
  SearchBook(
    title: 'The Story of Art',
    subtitle: '(16th Ed)',
    authors: 'by E.H. Gombrich',
    status: 'available',
    coverColor1: Color(0xFF4A148C),
    coverColor2: Color(0xFF7B1FA2),
    coverLabel: 'Story\nof Art',
  ),
  SearchBook(
    title: 'Guns, Germs, and Steel',
    subtitle: '(1st Ed)',
    authors: 'by Jared Diamond',
    status: 'available',
    coverColor1: Color(0xFF33691E),
    coverColor2: Color(0xFF558B2F),
    coverLabel: 'Guns\nGerms\nSteel',
  ),
  SearchBook(
    title: 'The Silk Roads',
    subtitle: '(1st Ed)',
    authors: 'by Peter Frankopan',
    status: 'checked_out',
    dueInfo: 'due back in 14 days',
    coverColor1: Color(0xFF880E4F),
    coverColor2: Color(0xFFC2185B),
    coverLabel: 'Silk\nRoads',
  ),
];

const _chips = ['Physiology', 'Art', 'Business', 'Chemistry', 'History'];
const _myChips = ['CSE', 'Science', 'Business', 'Art', 'History'];

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  int _selectedChip = 0;
  String _query = '';

  List<SearchBook> get _filtered {
    final cat = _myChips[_selectedChip];
    var list = _allBooks.where((b) {
      switch (cat) {
        case 'CSE':
          return [
            'Clean Code',
            'Introduction to Algorithms',
            'The Pragmatic Programmer',
            'Designing Data-Intensive Apps',
            'Computer Networks',
          ].contains(b.title);
        case 'Science':
          return [
            'A Brief History of Time',
            'The Selfish Gene',
            'Sapiens',
          ].contains(b.title);
        case 'Business':
          return [
            'Atomic Habits',
            'Zero to One',
            'The Lean Startup',
          ].contains(b.title);
        case 'Art':
          return ['The Story of Art'].contains(b.title);
        case 'History':
          return ['Guns, Germs, and Steel', 'The Silk Roads'].contains(b.title);
        default:
          return true;
      }
    }).toList();

    if (_query.isNotEmpty) {
      list = list
          .where(
            (b) =>
                b.title.toLowerCase().contains(_query.toLowerCase()) ||
                b.authors.toLowerCase().contains(_query.toLowerCase()),
          )
          .toList();
    }
    return list;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            _buildChips(),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            Expanded(
              child: _filtered.isEmpty
                  ? _emptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      physics: const BouncingScrollPhysics(),
                      itemCount: _filtered.length,
                      separatorBuilder: (_, __) => const Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                        color: Color(0xFFF0F0F0),
                      ),
                      itemBuilder: (_, i) => _bookTile(_filtered[i]),
                    ),
            ),
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: TextField(
                controller: _controller,
                onChanged: (v) => setState(() => _query = v),
                style: const TextStyle(fontSize: 13, color: Color(0xFF1A1A1A)),
                decoration: const InputDecoration(
                  hintText: 'Search books, authors or journals...',
                  hintStyle: TextStyle(color: Color(0xFFAAAAAA), fontSize: 13),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Color(0xFFAAAAAA),
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 13),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: const Icon(Icons.tune, color: Color(0xFF555555), size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildChips() {
    return SizedBox(
      height: 42,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        physics: const BouncingScrollPhysics(),
        itemCount: _myChips.length + 1,
        itemBuilder: (_, i) {
          if (i == _myChips.length) {
            return Padding(
              padding: const EdgeInsets.only(left: 4, right: 4),
              child: Center(
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: const Icon(
                    Icons.keyboard_arrow_down,
                    size: 18,
                    color: Color(0xFF555555),
                  ),
                ),
              ),
            );
          }
          final selected = _selectedChip == i;
          return GestureDetector(
            onTap: () => setState(() => _selectedChip = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? kRed : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? kRed : const Color(0xFFE0E0E0),
                ),
              ),
              child: Text(
                _myChips[i],
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFF555555),
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _bookTile(SearchBook book) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Container(
              width: 70,
              height: 95,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [book.coverColor1, book.coverColor2],
                ),
              ),
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      book.coverLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: book.title,
                        style: const TextStyle(
                          color: Color(0xFF1A1A1A),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                      TextSpan(
                        text: ' ${book.subtitle}',
                        style: const TextStyle(
                          color: Color(0xFF888888),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),

                Text(
                  book.authors,
                  style: const TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),

                _statusWidget(book),
              ],
            ),
          ),

          const SizedBox(width: 8),
          const Icon(Icons.bookmark_border, color: Color(0xFFCCCCCC), size: 22),
        ],
      ),
    );
  }

  Widget _statusWidget(SearchBook book) {
    switch (book.status) {
      case 'available':
        return Row(
          children: const [
            Icon(Icons.circle, color: Color(0xFF43A047), size: 8),
            SizedBox(width: 4),
            Text(
              'Available for borrow',
              style: TextStyle(
                color: Color(0xFF43A047),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      case 'checked_out':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Checked out',
              style: TextStyle(
                color: kRed,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (book.dueInfo.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                book.dueInfo,
                style: const TextStyle(color: Color(0xFF888888), fontSize: 11),
              ),
            ],
          ],
        );
      default:
        return const Text(
          'Unavailable',
          style: TextStyle(color: Color(0xFF888888), fontSize: 12),
        );
    }
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: kRedLight, shape: BoxShape.circle),
            child: const Icon(Icons.search_off, color: kRed, size: 32),
          ),
          const SizedBox(height: 16),
          const Text(
            'No books found',
            style: TextStyle(
              color: Color(0xFF1A1A1A),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Try a different search or category',
            style: TextStyle(color: Color(0xFF888888), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    final items = [
      {
        'icon': Icons.home_outlined,
        'activeIcon': Icons.home_rounded,
        'label': 'Home',
      },
      {'icon': Icons.search, 'activeIcon': Icons.search, 'label': 'Search'},
      {
        'icon': Icons.collections_bookmark_outlined,
        'activeIcon': Icons.collections_bookmark,
        'label': 'My Books',
      },
      {
        'icon': Icons.person_outline_rounded,
        'activeIcon': Icons.person_rounded,
        'label': 'Profile',
      },
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          // Search tab (index 1) is active on this screen
          final active = i == 1;
          return GestureDetector(
            onTap: () {
              if (i == 0) Navigator.pop(context);
              // other nav actions
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  active
                      ? items[i]['activeIcon'] as IconData
                      : items[i]['icon'] as IconData,
                  color: active ? kRed : const Color(0xFFBBBBBB),
                  size: 24,
                ),
                const SizedBox(height: 3),
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
          );
        }),
      ),
    );
  }
}
