import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const kRed = Color(0xFFE53935);
const kRedDark = Color(0xFFB71C1C);
const kRedLight = Color(0xFFFFEBEE);

class PersonalInfoPage extends StatefulWidget {
  const PersonalInfoPage({super.key});

  @override
  State<PersonalInfoPage> createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<PersonalInfoPage> {
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _studentIdCtrl = TextEditingController();
  final _deptCtrl = TextEditingController();
  String _avatarInitials = '??';
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _studentIdCtrl.dispose();
    _deptCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;
      final data = await _supabase
          .from('users')
          .select('name, email, student_id, department')
          .eq('id', userId)
          .single();
      _nameCtrl.text = data['name'] ?? '';
      _emailCtrl.text = data['email'] ?? '';
      _studentIdCtrl.text = data['student_id'] ?? '';
      _deptCtrl.text = data['department'] ?? '';
      final name = data['name'] ?? '';
      _avatarInitials = name.isNotEmpty
          ? name
                .trim()
                .split(' ')
                .where((w) => w.isNotEmpty)
                .take(2)
                .map((w) => w[0].toUpperCase())
                .join()
          : '??';
    } catch (e) {
      if (mounted) {
        _showSnack('Data load error: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final newEmail = _emailCtrl.text.trim();
      final currentEmail = _supabase.auth.currentUser?.email ?? '';
      await _supabase
          .from('users')
          .update({
            'name': _nameCtrl.text.trim(),
            'student_id': _studentIdCtrl.text.trim(),
            'department': _deptCtrl.text.trim(),
            'email': newEmail,
          })
          .eq('id', userId);
      if (newEmail != currentEmail) {
        await _supabase.auth.updateUser(UserAttributes(email: newEmail));
      }
      final name = _nameCtrl.text.trim();
      setState(() {
        _avatarInitials = name.isNotEmpty
            ? name
                  .trim()
                  .split(' ')
                  .where((w) => w.isNotEmpty)
                  .take(2)
                  .map((w) => w[0].toUpperCase())
                  .join()
            : '??';
        _isEditing = false;
      });

      _showSnack('Profile successfully updated ✓');
    } catch (e) {
      _showSnack('Save error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red.shade700 : kRedDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F2),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kRed))
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildAppBar(),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildAvatar(),
                          const SizedBox(height: 20),
                          _buildInfoCard(),
                          const SizedBox(height: 20),
                          _buildActionButton(),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: kRed,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
      actions: [
        if (!_isEditing)
          GestureDetector(
            onTap: () => setState(() => _isEditing = true),
            child: Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.edit_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        if (_isEditing)
          GestureDetector(
            onTap: () {
              setState(() => _isEditing = false);
              _loadUserData();
            },
            child: Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        const SizedBox(width: 4),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Personal Info',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [kRedDark, kRed],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [kRed, kRedDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: kRed.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: Text(
          _avatarInitials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildEditableField(
            icon: Icons.person_outline_rounded,
            label: 'Full Name',
            controller: _nameCtrl,
            isFirst: true,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Enter name' : null,
          ),
          _buildDivider(),
          _buildEditableField(
            icon: Icons.badge_outlined,
            label: 'Student ID',
            controller: _studentIdCtrl,
            keyboardType: TextInputType.text,
            validator: (v) => null,
          ),
          _buildDivider(),
          _buildEditableField(
            icon: Icons.email_outlined,
            label: 'Email',
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Enter email';
              if (!v.contains('@')) return 'Enter valid email';
              return null;
            },
          ),
          _buildDivider(),
          _buildEditableField(
            icon: Icons.school_outlined,
            label: 'Department',
            controller: _deptCtrl,
            isLast: true,
            validator: (v) => null,
          ),
        ],
      ),
    );
  }

  Widget _buildEditableField({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    bool isFirst = false,
    bool isLast = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 20,
        vertical: _isEditing ? 10 : 16,
      ),
      decoration: BoxDecoration(
        color: _isEditing
            ? kRedLight.withValues(alpha: 0.4)
            : Colors.transparent,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isFirst ? 25 : 0),
          topRight: Radius.circular(isFirst ? 25 : 0),
          bottomLeft: Radius.circular(isLast ? 25 : 0),
          bottomRight: Radius.circular(isLast ? 25 : 0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _isEditing ? kRedLight : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              color: _isEditing ? kRed : const Color(0xFFAAAAAA),
              size: 18,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _isEditing
                ? TextFormField(
                    controller: controller,
                    keyboardType: keyboardType,
                    validator: validator,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                    decoration: InputDecoration(
                      labelText: label,
                      labelStyle: const TextStyle(
                        fontSize: 11,
                        color: kRed,
                        fontWeight: FontWeight.w500,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF999999),
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        controller.text.isEmpty ? '—' : controller.text,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ],
                  ),
          ),
          if (_isEditing)
            const Icon(Icons.edit_outlined, color: kRed, size: 16)
          else
            const SizedBox(width: 16),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      color: Color(0xFFF5F5F5),
      indent: 20,
      endIndent: 20,
    );
  }

  Widget _buildActionButton() {
    return GestureDetector(
      onTap: _isSaving
          ? null
          : _isEditing
          ? _saveChanges
          : () => setState(() => _isEditing = true),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [kRed, kRedDark],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: kRed.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Center(
          child: _isSaving
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isEditing ? Icons.check_rounded : Icons.edit_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isEditing ? 'Save Changes' : 'Edit Profile',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
