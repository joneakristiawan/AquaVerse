import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Jangan lupa import Supabase

import '/pages/login_page.dart'; 
import '/pages/display_page.dart'; // Import halaman utama lu juga

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isDotCenter = false;
  bool _isScalTheCircle = false;

  @override
  void initState(){
    super.initState(); 
    _startAnimation(); 
  }

  void _startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 620)); 
    if(!mounted) return; 
    setState(() => _isDotCenter = true); 

    await Future.delayed(const Duration(milliseconds: 1000)); 
    if(!mounted) return; 
    setState(() => _isScalTheCircle = true); 

    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    final session = Supabase.instance.client.auth.currentSession;

    if (session != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const DisplayPage(), 
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginPage(), 
        ),
      );
    }
    // -------------------------------------
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(105, 202, 249, 1), 
      body: SizedBox(
        height: double.infinity,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Center(
              child: AnimatedScale(
                duration: const Duration(milliseconds: 600),
                curve: const Cubic(0.58, -0.30, 0.365, 1),
                scale: _isScalTheCircle ? 10 : 1,
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.white,
                  child: Center(
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: _isScalTheCircle
                          ? Colors.white
                          : const Color.fromRGBO(105, 202, 249, 1), 
                    ),
                  ),
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 1100),
              curve: const Cubic(.47, -1.26, .36, 1),
              left:
                  (MediaQuery.of(context).size.width / 2) -
                  40 -
                  (_isDotCenter ? -20 : 80),

              child: const CircleAvatar(radius: 20, backgroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}