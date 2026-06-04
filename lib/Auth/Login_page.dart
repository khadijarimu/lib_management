import 'package:flutter/material.dart';
import 'package:project_1/Admin/admin_dashboard.dart';
import 'package:project_1/Auth/Register_page.dart';
import 'package:project_1/Auth/ResetPassword_page.dart';
import 'package:project_1/Home_page.dart';
import 'package:project_1/widgets/input_field.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const kRed = Color(0xFFE53935);
const kRedDark = Color(0xFFB71C1C);

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final response = await _supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (response.user == null) return;
      final userData = await _supabase
          .from('users')
          .select('role')
          .eq('id', response.user!.id)
          .maybeSingle();
      final role =
          userData?['role']?.toString().trim().toLowerCase() ?? 'student';

      if (!mounted) return;
      if (role == 'admin') {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AdminDashboard()),
          (route) => false,
        );
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomePage()),
          (route) => false,
        );
      }
    } on AuthApiException catch (e) {
      // Supabase Auth এর specific error দেখাও
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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SingleChildScrollView(
        child: Column(children: [_buildHeader(), _buildLoginCard()]),
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
              Icons.local_library,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Smart Library',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Welcome back! Please login to continue.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginCard() {
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
                  'Login',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Enter your credentials to access your account',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 24),
                InputField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  label: 'Email',
                  hint: 'Enter your email',
                  icon: Icons.email_outlined,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Email required' : null,
                ),
                const SizedBox(height: 16),
                InputField(
                  controller: _passwordController,
                  keyboardType: TextInputType.text,
                  label: 'Password',
                  hint: 'Enter your password',
                  icon: Icons.lock_outline,
                  obscureText: true,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Password required' : null,
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ResetPasswordPage(),
                      ),
                    ),
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: kRed,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 45,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
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
                            'Login',
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
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterPage()),
                  ),
                  child: Center(
                    child: RichText(
                      text: const TextSpan(
                        text: "Don't have an account? ",
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                        children: [
                          TextSpan(
                            text: 'Register',
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
