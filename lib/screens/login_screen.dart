import 'dart:async';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/notifikasi_service.dart';
import 'admin_dashboard_screen.dart';
import 'member_home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _loading = false;
  String? _errorMessage;

  void _handleLogin() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final user = await _authService.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    setState(() => _loading = false);

    if (user == null) {
      setState(() => _errorMessage = "Email atau password salah");
      return;
    }

    if (!mounted) return;

    // Daftarkan perangkat untuk push notification (meminta izin jika perlu).
    unawaited(NotifikasiService.instance.daftarkan(minta: true));

    // Routing berdasarkan role
    if (user["role"] == "admin") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MemberHomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.coffee, size: 56),
              const SizedBox(height: 16),
              const Text("Masuk", style: TextStyle(fontSize: 22)),
              const SizedBox(height: 24),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "Email"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Password"),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _handleLogin,
                  child: _loading
                      ? const CircularProgressIndicator()
                      : const Text("Masuk"),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                ),
                child: const Text("Belum punya akun? Daftar"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
