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
  final _emailController = TextEditingController(); 
  final _passwordController = TextEditingController(); 

  final supabase = Supabase.instance.client; 
  bool _isLoading = false; 

  Future<void> _login() async {
    if (_emailController.text.isEmpty || 
        _passwordController.text.isEmpty ||
        _passwordController.text.length < 6) {
      _showError('Email atau password tidak valid');
      return;
    }

    setState(() {
      _isLoading = true; 
    });

    try {
      final response = await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim()
      ); 
      if (response.user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DisplayPage()),
        );
      }
      } catch (e) {
        _showError(e.toString());
      } finally {
        setState(() => _isLoading = false);
      }

    } 

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

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


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Stack(
        children: [

          Container(color: Colors.white,), 

          ClipPath(
            clipper: WaveClipper(), 
            child: Container(
              height: 280,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(backgroundHomeUrl), 
                  fit: BoxFit.cover, 
                  alignment: Alignment(0, -0.93)
                )
                
              ),
              child: Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.8, 
                  height: 200, 
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(textAquaVerseUrl), 
                      fit: BoxFit.fitWidth
                    )
                  ),
                )
              ),
            ),
          ),

          Align(
            alignment: Alignment.bottomCenter, 
            child: Container(
              height: 650, 
              width: double.infinity,
              color: Colors.white, 
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25), 
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, 
                  children: [
                    const SizedBox(height: 40,), 
                    const Text("Selamat Datang", 
                      style: TextStyle(
                        fontSize: 40, 
                        fontWeight: FontWeight.bold, 
                      ),
                    ), 
                    const SizedBox(height: 10,),
                    const Text("Gunakan akun terdaftar Anda untuk memasuki AquaVerse dan telusuri rahasia dalam laut! ", 
                      style: TextStyle(
                        fontSize: 14, 
                        color: Color.fromRGBO(45, 45, 45, 1)
                      ),
                    ),
                    const SizedBox(height: 20,), 
                    const Text("E-mail"), 
                    const SizedBox(height: 5,), 
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        hintText: "Masukkan E-mail di sini...",
                        filled: true, 
                        fillColor: Colors.grey[200], 
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10), 
                          borderSide: BorderSide.none
                        )
                        ),
                    ),
                    const SizedBox(height: 15,), 
                    const Text("Password"), 
                    const SizedBox(height: 5,), 
                    TextField(
                      controller: _passwordController, 
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: "Masukkan password di sini...", 
                        filled: true, 
                        fillColor: Colors.grey[200], 
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10), 
                          borderSide: BorderSide.none, 
                        )
                      ),
                    ), 
                    const SizedBox(height: 22,), 
                    const Text(
                      "Atau Registrasi untuk AquaAccount. Dengan Registrasi, Anda setuju dengan Syarat dan Ketentuan.", 
                      style: TextStyle(
                        fontSize: 14,
                        color: Color.fromRGBO(45, 45, 45, 1)
                      ),
                    ),
                    const SizedBox(height: 23,), 
                    SizedBox(
                      width: double.infinity, 
                      height: 45, 
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromRGBO(105, 202, 249, 1), 
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10), 
                          )
                        ),
                        onPressed: (){
                          Navigator.push(context, MaterialPageRoute(builder: (_) => RegisterPage()),);
                        },
                        child: const Text(
                          "Registrasi", 
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black
                          ),
                        ),
                      ),
                    ), 
                    const SizedBox(height: 10,), 
                    SizedBox(
                      width: double.infinity, 
                      height: 45, 
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromRGBO(39, 46, 94, 1),  
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10), 
                          )
                        ),
                        onPressed: _isLoading ? null : _login,
                        child: Text(
                          "Masuk",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),

        ],),
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
        firstControlPoint.dx, firstControlPoint.dy, firstEndPoint.dx, firstEndPoint.dy);

    path.quadraticBezierTo(
        secondControlPoint.dx, secondControlPoint.dy, secondEndPoint.dx, secondEndPoint.dy);

    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}