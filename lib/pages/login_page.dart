import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'display_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  final supabase = Supabase.instance.client;
  bool _isLoading = false;

  late final String backgroundHomeUrl;
  late final String textAquaVerseUrl;

  @override
  void initState() {
    super.initState();
    backgroundHomeUrl = Supabase.instance.client.storage
        .from('aquaverse')
        .getPublicUrl('assets/images/login/background-login.jpeg');

    textAquaVerseUrl = Supabase.instance.client.storage
        .from('aquaverse')
        .getPublicUrl('assets/images/login/Text-AquaVerse.png');
  }

  Future<void> _login() async {
    final input = _identifierController.text.trim();
    final password = _passwordController.text.trim();

    // 1. Validasi Input Dasar
    if (input.isEmpty || password.isEmpty || password.length < 6) {
      _showError('Harap isi Email/Username dan Password (min 6 karakter)');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // await supabase.auth.signOut();

      String emailToLogin = input;

      if (!input.contains('@')) {
        try {
          final result = await supabase
              .from('profiles')
              .select('email')
              .eq('username', input)
              .maybeSingle();

          if (result == null) {
            throw AuthException('Username tidak ditemukan!');
          }

          emailToLogin = result['email'];
        } catch (e) {
          if (e is AuthException) rethrow;

          print('Error lookup username: $e');
          throw AuthException(
            'Gagal memverifikasi username. Gunakan Email saja.',
          );
        }
      }

      final response = await supabase.auth.signInWithPassword(
        email: emailToLogin,
        password: password,
      );

      if (response.user != null) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DisplayPage()),
        );
      }
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError("Terjadi kesalahan sistem. Coba lagi nanti.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(color: Colors.white),

          ClipPath(
            clipper: WaveClipper(),
            child: Container(
              height: 240,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(backgroundHomeUrl),
                  fit: BoxFit.cover,
                  alignment: const Alignment(0, -0.93),
                ),
              ),
              child: Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  height: 200,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(textAquaVerseUrl),
                      fit: BoxFit.fitWidth,
                    ),
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            top: 140,
            left: 0,
            right: 0, 
            bottom: 0,
            child: Center(
              child: Container(
              width: double.infinity,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 15),
                      const Text(
                        "Selamat Datang",
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Gunakan akun terdaftar Anda untuk memasuki AquaVerse dan telusuri rahasia dalam laut! ",
                        style: TextStyle(
                          fontSize: 13,
                          color: Color.fromRGBO(45, 45, 45, 1),
                        ),
                      ),
                      const SizedBox(height: 20),

                      const Text("E-mail / Username"),
                      const SizedBox(height: 5),
                      TextField(
                        controller: _identifierController,
                        decoration: InputDecoration(
                          hintText: "Masukkan E-mail atau Username...",
                          filled: true,
                          fillColor: Colors.grey[200],
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 13),
                      const Text("Password"),
                      const SizedBox(height: 5),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: "Masukkan password di sini...",
                          filled: true,
                          fillColor: Colors.grey[200],
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        "Atau Registrasi untuk AquaAccount. Dengan Registrasi, Anda setuju dengan Syarat dan Ketentuan.",
                        style: TextStyle(
                          fontSize: 13,
                          color: Color.fromRGBO(45, 45, 45, 1),
                        ),
                      ),
                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 45,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromRGBO(39, 46, 94, 1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: _isLoading ? null : _login,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  "Masuk",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Belum punya akun? ",
                            style: TextStyle(
                              fontSize: 13,
                              color: Color.fromRGBO(45, 45, 45, 1),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const RegisterPage(),
                                ),
                              );
                            },
                            child: const Text(
                              "Registrasi",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color.fromRGBO(105, 202, 249, 1), // Warna biru muda khas AquaVerse
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),
            ),
          ),
        ],
      ),
    );
  }
}

class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 40);
    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2, size.height - 40);
    var secondControlPoint = Offset(3 * size.width / 4, size.height - 80);
    var secondEndPoint = Offset(size.width, size.height - 40);
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );
    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
