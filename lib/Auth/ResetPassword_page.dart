import 'package:flutter/material.dart';
import 'package:project_1/widgets/input_field.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const kRed = Color.fromRGBO(229, 57, 53, 1);
const kRedDark = Color(0xFFB71C1C);

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  final _supabase = Supabase.instance.client;
  bool _isLoading = false;

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: _passwordController.text.trim()),
      );
      await _supabase.auth.signOut();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password updated! Please login with new password.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on AuthApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: kRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Something went wrong. Please try again.'),
            backgroundColor: kRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SingleChildScrollView(
        child: Column(children: [_buildHeader(), _buildFormCard()]),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kRedDark, kRed],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_outline,
              size: 38,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Set New Password',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your new password must be at least 6 characters',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
      child: Card(
        color: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create New Password',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Enter and confirm your new password',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 24),
                InputField(
                  controller: _passwordController,
                  label: 'New Password',
                  hint: 'Min 6 characters',
                  icon: Icons.lock_outline,
                  obscureText: true,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password required';
                    if (v.length < 6) return 'Min 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                InputField(
                  controller: _confirmController,
                  label: 'Confirm New Password',
                  hint: 'Re-enter new password',
                  icon: Icons.lock_outline,
                  obscureText: true,
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Please confirm password';
                    }
                    if (v != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 26),
                SizedBox(
                  height: 45,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _updatePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kRed,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          )
                        : const Text(
                            'Update Password',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
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
    );
  }
}
