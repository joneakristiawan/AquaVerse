import 'package:flutter/material.dart';

import '/pages/login_page.dart'; 

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
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => LoginPage(), 
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(105, 202, 249, 1), 
      body: SizedBox(
        height: double.infinity,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Center(
              child: AnimatedScale(
                duration: Duration(milliseconds: 600),
                curve: Cubic(0.58, -0.30, 0.365, 1),
                scale: _isScalTheCircle ? 10 : 1,

                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.white,
                  child: Center(
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: _isScalTheCircle
                          ? Colors.white
                          : Color.fromRGBO(105, 202, 249, 1), 
                    ),
                  ),
                ),
              ),
            ),
            AnimatedPositioned(
              duration: Duration(milliseconds: 1100),
              curve: Cubic(.47, -1.26, .36, 1),
              left:
                  (MediaQuery.of(context).size.width / 2) -
                  40 -
                  (_isDotCenter ? -20 : 80),

              child: CircleAvatar(radius: 20, backgroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}