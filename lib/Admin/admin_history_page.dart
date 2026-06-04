import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const kRed = Color(0xFFE53935);
const kRedDark = Color(0xFFB71C1C);
const kRedLight = Color(0xFFFFEBEE);

class AdminHistoryPage extends StatefulWidget {
  const AdminHistoryPage({super.key});

  @override
  State<AdminHistoryPage> createState() => _AdminHistoryPageState();
}

class _AdminHistoryPageState extends State<AdminHistoryPage> {
  final _supabase = Supabase.instance.client;
  final _searchController = TextEditingController();

  List<Map<String, dynamic>> _allRecords = [];
  List<Map<String, dynamic>> _filteredRecords = [];
  String _selectedFilter = 'All';
  bool _isLoading = true;

  int _totalCount = 0;
  int _returnedCount = 0;
  int _overdueCount = 0;
  int _rejectedCount = 0;

  final List<String> _filters = [
    'All',
    'Returned',
    'Active',
    'Overdue',
    'Pending',
    'Rejected',
    'Renew',
    'Return Req',
  ];

  // Month names used for formatting dates without intl package
  static const _months = [
    '',
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

  @override
  void initState() {
    super.initState();
    _fetchHistory();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchHistory() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('borrows')
          .select('''
            id, borrow_date, due_date, return_date,
            status, renew_count, admin_note, fine_amount, fine_paid,
            users ( id, name, student_id, department ),
            books ( id, title, author )
          ''')
          .order('borrow_date', ascending: false);

      final records = List<Map<String, dynamic>>.from(response);

      setState(() {
        _allRecords = records;
        _totalCount = records.length;
        _returnedCount = records.where((r) => r['status'] == 'returned').length;
        _overdueCount = records.where((r) => r['status'] == 'overdue').length;
        _rejectedCount = records.where((r) => r['status'] == 'rejected').length;
        _isLoading = false;
      });

      _applyFilters();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load history: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: kRed,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase().trim();
    List<Map<String, dynamic>> result = _allRecords;

    if (_selectedFilter != 'All') {
      result = result.where((r) {
        final status = r['status'] as String? ?? '';
        switch (_selectedFilter) {
          case 'Returned':
            return status == 'returned';
          case 'Active':
            return status == 'active';
          case 'Overdue':
            return status == 'overdue';
          case 'Pending':
            return status == 'pending';
          case 'Rejected':
            return status == 'rejected';
          case 'Renew':
            return status == 'renew_requested';
          case 'Return Req':
            return status == 'return_requested';
          default:
            return true;
        }
      }).toList();
    }

    if (query.isNotEmpty) {
      result = result.where((r) {
        final user = r['users'] as Map<String, dynamic>? ?? {};
        final book = r['books'] as Map<String, dynamic>? ?? {};
        final name = (user['name'] as String? ?? '').toLowerCase();
        final sid = (user['student_id'] as String? ?? '').toLowerCase();
        final title = (book['title'] as String? ?? '').toLowerCase();
        final author = (book['author'] as String? ?? '').toLowerCase();
        return name.contains(query) ||
            sid.contains(query) ||
            title.contains(query) ||
            author.contains(query);
      }).toList();
    }

    setState(() => _filteredRecords = result);
  }

  // Format "2025-05-13" to "13 May 2025" without intl package
  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final d = DateTime.parse(dateStr);
      return '${d.day} ${_months[d.month]} ${d.year}';
    } catch (_) {
      return dateStr;
    }
  }

  int _overdueDays(String? dueDateStr) {
    if (dueDateStr == null) return 0;
    try {
      final due = DateTime.parse(dueDateStr);
      final today = DateTime.now();
      final diff = today.difference(due).inDays;
      return diff > 0 ? diff : 0;
    } catch (_) {
      return 0;
    }
  }

  Map<String, dynamic> _statusStyle(String status) {
    switch (status) {
      case 'returned':
        return {
          'label': 'Returned',
          'bg': const Color(0xFFEAF3DE),
          'fg': const Color(0xFF3B6D11),
        };
      case 'active':
        return {
          'label': 'Active',
          'bg': const Color(0xFFE1F5EE),
          'fg': const Color(0xFF0F6E56),
        };
      case 'overdue':
        return {
          'label': 'Overdue',
          'bg': kRedLight,
          'fg': const Color(0xFFB71C1C),
        };
      case 'pending':
        return {
          'label': 'Pending',
          'bg': const Color(0xFFFAEEDA),
          'fg': const Color(0xFF854F0B),
        };
      case 'rejected':
        return {
          'label': 'Rejected',
          'bg': const Color(0xFFF1EFE8),
          'fg': const Color(0xFF5F5E5A),
        };
      case 'return_requested':
        return {
          'label': 'Return Req',
          'bg': const Color(0xFFE6F1FB),
          'fg': const Color(0xFF185FA5),
        };
      case 'renew_requested':
        return {
          'label': 'Renew Req',
          'bg': const Color(0xFFFBEAF0),
          'fg': const Color(0xFF993556),
        };
      default:
        return {
          'label': status,
          'bg': const Color(0xFFF1EFE8),
          'fg': const Color(0xFF5F5E5A),
        };
    }
  }

  String _initials(String? name) {
    if (name == null || name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts[0][0].toUpperCase();
  }

  Color _avatarBg(String? name) {
    final colors = [
      const Color(0xFFE6F1FB),
      const Color(0xFFE1F5EE),
      const Color(0xFFFAEEDA),
      const Color(0xFFEEEDFE),
      const Color(0xFFFBEAF0),
    ];
    if (name == null || name.isEmpty) return colors[0];
    return colors[name.codeUnitAt(0) % colors.length];
  }

  Color _avatarFg(String? name) {
    final colors = [
      const Color(0xFF185FA5),
      const Color(0xFF0F6E56),
      const Color(0xFF854F0B),
      const Color(0xFF534AB7),
      const Color(0xFF993556),
    ];
    if (name == null || name.isEmpty) return colors[0];
    return colors[name.codeUnitAt(0) % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F2),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: kRed))
                : RefreshIndicator(
                    color: kRed,
                    onRefresh: _fetchHistory,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
                      children: [
                        // Stat cards row
                        _buildStatRow(),
                        const SizedBox(height: 10),

                        // Search bar
                        _buildSearchBar(),
                        const SizedBox(height: 10),

                        // Filter chips in a white card
                        _buildFilterCard(),
                        const SizedBox(height: 12),

                        // Record list or empty state
                        if (_filteredRecords.isEmpty)
                          _buildEmpty()
                        else
                          ..._filteredRecords.map(_buildRecordCard),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // Minimal red header with only back, title, refresh
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [kRed, kRedDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 15,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Borrow History',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _fetchHistory,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.refresh,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Four stat cards: Total, Returned, Overdue, Rejected
  Widget _buildStatRow() {
    return Row(
      children: [
        _statCard('Total', _totalCount, const Color(0xFF222222)),
        const SizedBox(width: 8),
        _statCard('Returned', _returnedCount, const Color(0xFF2E7D32)),
        const SizedBox(width: 8),
        _statCard('Overdue', _overdueCount, kRed),
        const SizedBox(width: 8),
        _statCard('Rejected', _rejectedCount, const Color(0xFFE65100)),
      ],
    );
  }

  Widget _statCard(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEEEEEE), width: 0.5),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE), width: 0.5),
      ),
      child: TextField(
        controller: _searchController,
        decoration: const InputDecoration(
          hintText: 'Search student, book...',
          hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
          prefixIcon: Icon(Icons.search, color: Colors.grey, size: 18),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        ),
      ),
    );
  }

  // Filter chips inside a white card below the search bar
  Widget _buildFilterCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEEE), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter by status',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _filters.map((f) {
              final isActive = _selectedFilter == f;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedFilter = f);
                  _applyFilters();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: isActive ? kRedLight : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(20),
                    border: isActive
                        ? Border.all(color: const Color(0xFFFFCDD2), width: 1)
                        : null,
                  ),
                  child: Text(
                    f,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isActive ? kRed : const Color(0xFF888888),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordCard(Map<String, dynamic> record) {
    final user = record['users'] as Map<String, dynamic>? ?? {};
    final book = record['books'] as Map<String, dynamic>? ?? {};
    final status = record['status'] as String? ?? '';
    final style = _statusStyle(status);
    final name = user['name'] as String?;
    final fineAmount = (record['fine_amount'] as num?)?.toDouble() ?? 0.0;
    final finePaid = record['fine_paid'] as bool? ?? false;
    final renewCount = record['renew_count'] as int? ?? 0;
    final adminNote = record['admin_note'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Student row
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _avatarBg(name),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _initials(name),
                    style: TextStyle(
                      color: _avatarFg(name),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${user['department'] ?? ''} · ${user['student_id'] ?? ''}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: style['bg'] as Color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  style['label'] as String,
                  style: TextStyle(
                    color: style['fg'] as Color,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: Color(0xFFF0F0F0)),
          ),

          // Book row
          Row(
            children: [
              Container(
                width: 32,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [kRed, kRedDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.book, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book['title'] ?? 'Unknown Book',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      book['author'] ?? '',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              // Renew count badge
              if (renewCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBEAF0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Renewed $renewCount×',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF993556),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 9),

          // Dates row — dd MMM yyyy format
          Wrap(
            spacing: 12,
            runSpacing: 5,
            children: [
              _dateChip(
                Icons.calendar_today_outlined,
                'Borrowed',
                _formatDate(record['borrow_date'] as String?),
              ),
              _dateChip(
                Icons.event_outlined,
                'Due',
                _formatDate(record['due_date'] as String?),
              ),
              if (record['return_date'] != null)
                _dateChip(
                  Icons.check_circle_outline,
                  'Returned',
                  _formatDate(record['return_date'] as String?),
                  valueColor: const Color(0xFF2E7D32),
                ),
              if ((status == 'overdue') && record['return_date'] == null)
                _dateChip(
                  Icons.warning_amber_outlined,
                  'Overdue',
                  '+${_overdueDays(record['due_date'] as String?)} days',
                  valueColor: kRed,
                ),
            ],
          ),

          // Fine row
          if (fineAmount > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: finePaid ? const Color(0xFFEAF3DE) : kRedLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    finePaid
                        ? Icons.check_circle_outline
                        : Icons.warning_amber_outlined,
                    size: 13,
                    color: finePaid
                        ? const Color(0xFF3B6D11)
                        : const Color(0xFFB71C1C),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Fine: ৳${fineAmount.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: finePaid
                          ? const Color(0xFF3B6D11)
                          : const Color(0xFFB71C1C),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    finePaid ? 'Paid' : 'Not paid',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: finePaid
                          ? const Color(0xFF3B6D11)
                          : const Color(0xFFB71C1C),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Admin note row
          if (adminNote != null && adminNote.isNotEmpty) ...[
            const SizedBox(height: 7),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Note: $adminNote',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _dateChip(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: valueColor ?? Colors.grey),
        const SizedBox(width: 3),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: valueColor ?? const Color(0xFF444444),
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          Icon(Icons.history_outlined, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 10),
          Text(
            'No records found',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade400,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try a different filter or search',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}
