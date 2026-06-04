import 'package:flutter/material.dart';
import 'package:project_1/Admin/admin_dashboard.dart';
import 'package:project_1/Auth/Login_page.dart';
import 'package:project_1/Auth/ResetPassword_page.dart';
import 'package:project_1/Home_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  String? _cachedRole;
  String? _cachedUserId;
  bool _isPasswordRecovery = false;
  Future<String> _getUserRole(String userId) async {
    if (_cachedRole != null && _cachedUserId == userId) {
      return _cachedRole!;
    }

    try {
      final response = await Supabase.instance.client
          .from('users')
          .select('role')
          .eq('id', userId)
          .maybeSingle();

      final role = response?['role']?.toString().trim().toLowerCase() ?? 'user';

      debugPrint('DEBUG role fetched: "$role"');

      _cachedRole = role;
      _cachedUserId = userId;

      return role;
    } catch (e) {
      debugPrint('DEBUG role error: $e');
      return 'user';
    }
  }

  void _clearCache() {
    _cachedRole = null;
    _cachedUserId = null;
    _isPasswordRecovery = false;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFFE53935)),
            ),
          );
        }

        final event = snapshot.data?.event;
        debugPrint('DEBUG auth event: $event');
        if (event == AuthChangeEvent.signedOut) {
          _clearCache();
        }
        if (event == AuthChangeEvent.passwordRecovery) {
          _isPasswordRecovery = true;
          return const ResetPasswordPage();
        }
        if (event == AuthChangeEvent.signedIn && _isPasswordRecovery) {
          return const ResetPasswordPage();
        }
        final session = Supabase.instance.client.auth.currentSession;
        if (session == null) {
          return const LoginPage();
        }
        if (_isPasswordRecovery) {
          return const ResetPasswordPage();
        }
        return FutureBuilder<String>(
          future: _getUserRole(session.user.id),
          builder: (context, roleSnapshot) {
            if (!roleSnapshot.hasData) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(color: Color(0xFFE53935)),
                ),
              );
            }

            final role = roleSnapshot.data!;
            debugPrint('DEBUG navigating to role: "$role"');
            if (role == 'admin') {
              return const AdminDashboard();
            } else {
              return const HomePage();
            }
          },
        );
      },
    );
  }
}
