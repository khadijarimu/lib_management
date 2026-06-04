import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const kRed = Color(0xFFE53935);
const kRedDark = Color(0xFFB71C1C);
const kRedLight = Color(0xFFFFEBEE);
const List<String> kBookCategories = [
  'Science',
  'Technology',
  'Mathematics',
  'History',
  'Literature',
  'Fiction',
  'Philosophy',
  'Religion',
  'Arts',
  'Business',
  'Medicine',
  'Law',
  'Education',
  'Other',
];

const List<String> kBookLanguages = ['Bengali', 'English', 'Both'];

class ManageBooks extends StatefulWidget {
  const ManageBooks({super.key});

  @override
  State<ManageBooks> createState() => _ManageBooksState();
}

class _ManageBooksState extends State<ManageBooks> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _books = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _fetchBooks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchBooks() async {
    setState(() => _isLoading = true);
    try {
      final res = await _supabase
          .from('books')
          .select()
          .order('title', ascending: true);

      setState(() {
        _books = List<Map<String, dynamic>>.from(res);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to load books');
    }
  }

  List<Map<String, dynamic>> get _filteredBooks {
    if (_searchQuery.isEmpty) return _books;
    final q = _searchQuery.toLowerCase();
    return _books.where((b) {
      final title = (b['title'] ?? '').toString().toLowerCase();
      final author = (b['author'] ?? '').toString().toLowerCase();
      return title.contains(q) || author.contains(q);
    }).toList();
  }

  Future<void> _addBook(Map<String, String> data) async {
    try {
      final totalCopies = int.tryParse(data['total_copies'] ?? '1') ?? 1;
      await _supabase.from('books').insert({
        'title': data['title'],
        'author': data['author'],
        'isbn': data['isbn'],
        'category': data['category'],
        'description': data['description'],
        'total_copies': totalCopies,
        'available_copies': totalCopies,
        'edition': data['edition'],
        'language': data['language'] ?? 'Bengali',
        'year': int.tryParse(data['year'] ?? '') ?? DateTime.now().year,
        'added_by': _supabase.auth.currentUser?.id,
      });

      _showSuccess('Book added successfully');
      _fetchBooks();
    } catch (e) {
      _showError('Failed to add book: $e');
    }
  }

  Future<void> _editBook(String bookId, Map<String, String> data) async {
    try {
      await _supabase
          .from('books')
          .update({
            'title': data['title'],
            'author': data['author'],
            'isbn': data['isbn'],
            'category': data['category'],
            'description': data['description'],
            'total_copies': int.tryParse(data['total_copies'] ?? '1') ?? 1,
            'edition': data['edition'],
            'language': data['language'] ?? 'Bengali',
            'year': int.tryParse(data['year'] ?? '') ?? DateTime.now().year,
          })
          .eq('id', bookId);

      _showSuccess('Book updated successfully');
      _fetchBooks();
    } catch (e) {
      _showError('Failed to update book');
    }
  }

  Future<void> _deleteBook(String bookId, String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete Book',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text('"$title" will be permanently deleted. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: kRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await _supabase.from('books').delete().eq('id', bookId);
      _showSuccess('Book deleted');
      _fetchBooks();
    } catch (e) {
      _showError('Failed to delete book');
    }
  }

  void _showBookForm({Map<String, dynamic>? existingBook}) {
    // Edit mode এ existing data দিয়ে controller গুলো pre-fill করা হবে।
    final titleCtrl = TextEditingController(text: existingBook?['title'] ?? '');
    final authorCtrl = TextEditingController(
      text: existingBook?['author'] ?? '',
    );
    final isbnCtrl = TextEditingController(text: existingBook?['isbn'] ?? '');
    final descCtrl = TextEditingController(
      text: existingBook?['description'] ?? '',
    );
    final copiesCtrl = TextEditingController(
      text: '${existingBook?['total_copies'] ?? ''}',
    );
    final editionCtrl = TextEditingController(
      text: existingBook?['edition'] ?? '',
    );
    final yearCtrl = TextEditingController(
      text: '${existingBook?['year'] ?? ''}',
    );
    String selectedCategory =
        existingBook?['category'] ?? kBookCategories.first;
    String selectedLanguage = existingBook?['language'] ?? kBookLanguages.first;
    if (!kBookCategories.contains(selectedCategory)) {
      selectedCategory = 'Other';
    }
    if (!kBookLanguages.contains(selectedLanguage)) {
      selectedLanguage = 'Bengali';
    }
    final formKey = GlobalKey<FormState>();
    final isEdit = existingBook != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Text(
                      isEdit ? 'Edit Book' : 'Add New Book',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: const Icon(Icons.close, color: Colors.grey),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    16,
                    20,

                    MediaQuery.of(ctx).viewInsets.bottom + 16,
                  ),
                  child: Form(
                    key: formKey,
                    child: Column(
                      children: [
                        _buildFormField(
                          controller: titleCtrl,
                          label: 'Book Title *',
                          validator: (v) =>
                              v!.isEmpty ? 'Please enter a title' : null,
                        ),
                        const SizedBox(height: 14),
                        _buildFormField(
                          controller: authorCtrl,
                          label: 'Author Name *',
                          validator: (v) => v!.isEmpty
                              ? 'Please enter the author name'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        _buildDropdownField(
                          label: 'Category *',
                          value: selectedCategory,
                          items: kBookCategories,
                          onChanged: (val) {
                            if (val != null) {
                              setSheetState(() => selectedCategory = val);
                            }
                          },
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _buildFormField(
                                controller: copiesCtrl,
                                label: 'Total Copies *',
                                keyboardType: TextInputType.number,
                                validator: (v) =>
                                    v!.isEmpty ? 'Required' : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildFormField(
                                controller: yearCtrl,
                                label: 'Year',
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        Row(
                          children: [
                            Expanded(
                              child: _buildFormField(
                                controller: isbnCtrl,
                                label: 'ISBN',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildFormField(
                                controller: editionCtrl,
                                label: 'Edition',
                                hint: 'e.g. 3rd',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        _buildDropdownField(
                          label: 'Language',
                          value: selectedLanguage,
                          items: kBookLanguages,
                          onChanged: (val) {
                            if (val != null) {
                              setSheetState(() => selectedLanguage = val);
                            }
                          },
                        ),
                        const SizedBox(height: 14),
                        _buildFormField(
                          controller: descCtrl,
                          label: 'Description',
                          maxLines: 3,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              if (!formKey.currentState!.validate()) return;

                              final data = {
                                'title': titleCtrl.text.trim(),
                                'author': authorCtrl.text.trim(),
                                'isbn': isbnCtrl.text.trim(),
                                'category': selectedCategory,
                                'description': descCtrl.text.trim(),
                                'total_copies': copiesCtrl.text.trim(),
                                'edition': editionCtrl.text.trim(),
                                'language': selectedLanguage,
                                'year': yearCtrl.text.trim(),
                              };
                              Navigator.pop(ctx);
                              if (isEdit) {
                                _editBook(existingBook['id'], data);
                              } else {
                                _addBook(data);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kRed,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              isEdit ? 'Update Book' : 'Add Book',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
        filled: true,
        fillColor: const Color(0xFFF8F8F8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kRed, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kRed),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      onChanged: onChanged,
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
        filled: true,
        fillColor: const Color(0xFFF8F8F8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kRed, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
      dropdownColor: Colors.white,
      style: const TextStyle(color: Colors.black87, fontSize: 14),
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
    );
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: kRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            expandedHeight: 130,
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
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 56),
                child: Row(
                  children: [
                    const Text(
                      'Book Management',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),

                    if (!_isLoading)
                      Text(
                        '${_books.length} books',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search by title or author...',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Colors.grey,
                      size: 20,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                            child: const Icon(
                              Icons.close,
                              color: Colors.grey,
                              size: 18,
                            ),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
          ),
        ],
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: kRed))
            : _filteredBooks.isEmpty
            ? _buildEmpty()
            : RefreshIndicator(
                onRefresh: _fetchBooks,
                color: kRed,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredBooks.length,
                  itemBuilder: (ctx, i) => _buildBookCard(_filteredBooks[i]),
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showBookForm(),
        backgroundColor: kRed,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add),
        label: const Text(
          'Add Book',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildBookCard(Map<String, dynamic> book) {
    final availableCopies = (book['available_copies'] as int?) ?? 0;
    final totalCopies = (book['total_copies'] as int?) ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 70,
            decoration: BoxDecoration(
              color: kRedLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.menu_book_rounded, color: kRed, size: 28),
          ),
          const SizedBox(width: 12),

          // বইয়ের details — title, author, category badge, availability।
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book['title'] ?? 'Unknown',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),

                Text(
                  book['author'] ?? '-',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: kRedLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        book['category'] ?? '-',
                        style: const TextStyle(
                          fontSize: 11,
                          color: kRed,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: availableCopies > 0
                            ? const Color(0xFFE8F5E9)
                            : kRedLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$availableCopies/$totalCopies available',
                        style: TextStyle(
                          fontSize: 11,
                          color: availableCopies > 0
                              ? const Color(0xFF2E7D32)
                              : kRed,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              GestureDetector(
                onTap: () => _showBookForm(existingBook: book),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.edit_outlined,
                    color: Color(0xFF1565C0),
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              GestureDetector(
                onTap: () => _deleteBook(book['id'], book['title'] ?? ''),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kRedLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: kRed,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: constraints.maxHeight,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.library_books_outlined,
                  size: 60,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 12),
                Text(
                  _searchQuery.isNotEmpty ? 'No books found' : 'No books yet',
                  style: TextStyle(color: Colors.grey[500], fontSize: 15),
                ),
                if (_searchQuery.isEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Tap the + button below to add a book',
                    style: TextStyle(color: Colors.grey[400], fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
