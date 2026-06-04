import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const kRed = Color(0xFFE53935);
const kRedDark = Color(0xFFB71C1C);
const kRedLight = Color(0xFFFFEBEE);

class ManageReservations extends StatefulWidget {
  const ManageReservations({super.key});

  @override
  State<ManageReservations> createState() => _ManageReservationsState();
}

class _ManageReservationsState extends State<ManageReservations> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _reservations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchReservations();
  }

  Future<void> _fetchReservations() async {
    setState(() => _isLoading = true);
    try {
      final res = await _supabase
          .from('reservations')
          .select(
            '*, users(name, student_id), books(title, author, available_copies)',
          )
          .eq('status', 'active')
          .order('reserved_at', ascending: false);
      setState(() {
        _reservations = List<Map<String, dynamic>>.from(res);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to load reservations');
    }
  }

  Future<void> _markReady(String id) async {
    try {
      await _supabase
          .from('reservations')
          .update({'status': 'ready'})
          .eq('id', id);
      _showSuccess('Status set to ready');
      _fetchReservations();
    } catch (e) {
      _showError('Unable to mark as ready');
    }
  }

  Future<void> _cancelReservation(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Cancel Reservation',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to cancel this reservation?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('No', style: TextStyle(color: Colors.grey[600])),
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
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _supabase
          .from('reservations')
          .update({'status': 'cancelled'})
          .eq('id', id);
      _showSuccess('Reservation cancelled.');
      _fetchReservations();
    } catch (e) {
      _showError('Unable to cancel reservation');
    }
  }

  String _fmtStr(String? s) {
    if (s == null) return '-';
    final d = DateTime.parse(s);
    return '${d.day}/${d.month}/${d.year}';
  }

  bool _isExpired(String? s) =>
      s != null && DateTime.now().isAfter(DateTime.parse(s));

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
            expandedHeight: 120,
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
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(
                  children: [
                    const Text(
                      'Manage Reservations',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (!_isLoading)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_reservations.length} active',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: kRed))
            : _reservations.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.event_available_outlined,
                      size: 60,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No active reservation found',
                      style: TextStyle(color: Colors.grey[500], fontSize: 15),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: _fetchReservations,
                color: kRed,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _reservations.length,
                  itemBuilder: (ctx, i) => _buildCard(_reservations[i]),
                ),
              ),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> r) {
    final user = r['users'] as Map<String, dynamic>?;
    final book = r['books'] as Map<String, dynamic>?;
    final expired = _isExpired(r['expires_at']);
    final copies = (book?['available_copies'] as int?) ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: expired ? Border.all(color: kRed.withOpacity(0.3)) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E5F5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: Color(0xFF6A1B9A),
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?['name'] ?? 'Unknown',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      'ID: ${user?['student_id'] ?? '-'}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              if (expired)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: kRedLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Expired',
                    style: TextStyle(
                      color: kRed,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const Divider(height: 20),

          Row(
            children: [
              const Icon(Icons.menu_book_rounded, size: 16, color: kRed),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  book?['title'] ?? 'Unknown',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 22, top: 2),
            child: Text(
              book?['author'] ?? '-',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reserved',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                    Text(
                      _fmtStr(r['reserved_at']),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Expires',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                    Text(
                      _fmtStr(r['expires_at']),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: expired ? kRed : null,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Available',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                  Text(
                    '$copies copies',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: copies > 0 ? const Color(0xFF2E7D32) : kRed,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _cancelReservation(r['id']),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: copies > 0 ? () => _markReady(r['id']) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6A1B9A),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[200],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Mark Ready',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
