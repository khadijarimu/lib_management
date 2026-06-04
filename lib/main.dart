import 'package:flutter/material.dart';
import 'package:project_1/Auth/auth_gate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://uliuivkmcdzthbxfoxsj.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVsaXVpdmttY2R6dGhieGZveHNqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU5NzUxOTAsImV4cCI6MjA5MTU1MTE5MH0.4e_UIDTssI4rmFMRl2MG7BDGrx8prDHfkx1PdFOtRGE',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      home: const AuthGate(),
    );
  }
}
