import 'package:flutter/material.dart';
import 'package:project_1/Auth/Login_page.dart';
import 'package:project_1/widgets/input_field.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const kRed = Color(0xFFE53935);
const kRedDark = Color(0xFFB71C1C);

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _departmentController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  final _supabase = Supabase.instance.client;

  bool _isLoading = false;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await _supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (response.user != null) {
        await _supabase.from('users').insert({
          'id': response.user!.id,
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'student_id': _studentIdController.text.trim(),
          'department': _departmentController.text.trim(),
          'role': 'student',
          'is_blocked': false,
        });
        await _supabase.auth.signOut();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created successfully. Please login.'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
          );
        }
      }
    } on AuthApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: kRed),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Something went wrong. Please try again.'),
            backgroundColor: kRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _studentIdController.dispose();
    _departmentController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SingleChildScrollView(
        child: Column(children: [_buildHeader(), _buildRegisterCard()]),
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
              Icons.person_add_outlined,
              size: 38,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Create Account',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Join Smart Library today!',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterCard() {
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
                  'Register',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Fill in your details to create an account',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 24),
                InputField(
                  controller: _nameController,
                  label: 'Full Name',
                  hint: 'Enter your full name',
                  icon: Icons.person_outline,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Name required' : null,
                ),
                const SizedBox(height: 14),
                InputField(
                  controller: _studentIdController,
                  label: 'Student ID',
                  hint: 'Enter your student ID',
                  icon: Icons.badge_outlined,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Student ID required' : null,
                ),
                const SizedBox(height: 14),
                InputField(
                  controller: _departmentController,
                  label: 'Department',
                  hint: 'e.g. CSE, EEE, BBA',
                  icon: Icons.school_outlined,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Department required' : null,
                ),
                const SizedBox(height: 14),
                InputField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  label: 'Email',
                  hint: 'Enter your email',
                  icon: Icons.email_outlined,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Email required';
                    if (!v.contains('@')) return 'Enter valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                InputField(
                  controller: _passwordController,
                  label: 'Password',
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
                  label: 'Confirm Password',
                  hint: 'Re-enter your password',
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
                    onPressed: _isLoading ? null : _register,
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
                            'Create Account',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Center(
                    child: RichText(
                      text: const TextSpan(
                        text: 'Already have an account? ',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                        children: [
                          TextSpan(
                            text: 'Login',
                            style: TextStyle(
                              color: kRed,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
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
      ),
    );
  }
}
