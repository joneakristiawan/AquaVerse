import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../pages/login_page.dart';
import '../pages/display_page.dart'; // Sesuaikan sama lokasi file lu

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    final session = Supabase.instance.client.auth.currentSession;
    
    if (!mounted) return;

    if (session != null) {
      // Kalo session ada (berarti udah pernah login), langsung lempar ke DisplayPage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DisplayPage()),
      );
    } else {
      // Kalo kosong (belom login/udah logout), baru suruh ke LoginPage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ini tampilan transisi pas app baru dibuka (bisa lu ganti logo AquaVerse biar makin kece)
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: CircularProgressIndicator(
          color: Color.fromRGBO(105, 202, 249, 1),
        ),
      ),
    );
  }
}