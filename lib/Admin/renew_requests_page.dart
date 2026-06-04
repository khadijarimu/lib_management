import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const kRed = Color(0xFFE53935);
const kRedDark = Color(0xFFB71C1C);
const kRedLight = Color(0xFFFFEBEE);

class RenewRequestsPage extends StatefulWidget {
  const RenewRequestsPage({super.key});

  @override
  State<RenewRequestsPage> createState() => _RenewRequestsPageState();
}

class _RenewRequestsPageState extends State<RenewRequestsPage> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    setState(() => _isLoading = true);
    try {
      final res = await _supabase
          .from('borrows')
          .select(
            '*, users(name, student_id, department), books(title, author)',
          )
          .eq('status', 'renew_requested')
          .order('borrow_date', ascending: false);
      setState(() {
        _requests = List<Map<String, dynamic>>.from(res);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _approveRenew(Map<String, dynamic> borrow) async {
    try {
      final newDue = DateTime.parse(
        borrow['due_date'],
      ).add(const Duration(days: 14));
      final renewCount = (borrow['renew_count'] as int?) ?? 0;

      await _supabase
          .from('borrows')
          .update({
            'status': 'active',
            'due_date': newDue.toIso8601String(),
            'renew_count': renewCount + 1,
          })
          .eq('id', borrow['id']);

      _showSuccess(
        'The renewal has been approved. New due date: ${newDue.day}/${newDue.month}/${newDue.year}',
      );
      _fetchRequests();
    } catch (e) {
      _showError('Unable to approve renewal');
    }
  }

  Future<void> _rejectRenew(String borrowId) async {
    try {
      await _supabase
          .from('borrows')
          .update({'status': 'active'})
          .eq('id', borrowId);
      _showSuccess('The renewal has been rejected');
      _fetchRequests();
    } catch (e) {
      _showError('Unable to reject');
    }
  }

  String _fmt(String? s) {
    if (s == null) return '-';
    final d = DateTime.parse(s);
    return '${d.day}/${d.month}/${d.year}';
  }

  String _newDuePreview(String? dueStr) {
    if (dueStr == null) return '-';
    final newDue = DateTime.parse(dueStr).add(const Duration(days: 14));
    return '${newDue.day}/${newDue.month}/${newDue.year}';
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
                      'Renew Requests',
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
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_requests.length} pending',
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
            : _requests.isEmpty
            ? _buildEmpty()
            : RefreshIndicator(
                onRefresh: _fetchRequests,
                color: kRed,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _requests.length,
                  itemBuilder: (ctx, i) => _buildCard(_requests[i]),
                ),
              ),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> b) {
    final renewCount = (b['renew_count'] as int?) ?? 0;

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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: kRedLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.person_outline, color: kRed, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      b['users']?['name'] ?? 'Unknown',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      'ID: ${b['users']?['student_id'] ?? '-'} | ${b['users']?['department'] ?? '-'}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: kRedLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$renewCount/2 renew',
                  style: const TextStyle(
                    fontSize: 11,
                    color: kRed,
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
                  b['books']?['title'] ?? 'Unknown',
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
              b['books']?['author'] ?? '-',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ),

          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.event_outlined, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                'Current due: ${_fmt(b['due_date'])}',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.update, size: 16, color: Color(0xFF2E7D32)),
                const SizedBox(width: 6),
                Text(
                  'Approval will set a new due date: ${_newDuePreview(b['due_date'])}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF2E7D32),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _rejectRenew(b['id']),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text('Reject'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _approveRenew(b),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    elevation: 0,
                  ),
                  child: const Text('Approve (+14 days)'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.autorenew_outlined, size: 60, color: Colors.grey[300]),
        const SizedBox(height: 12),
        Text(
          'No pending renewal requests',
          style: TextStyle(color: Colors.grey[500], fontSize: 15),
        ),
      ],
    ),
  );
}
