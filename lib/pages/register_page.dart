import 'package:flutter/material.dart'; 
import 'package:supabase_flutter/supabase_flutter.dart'; 

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key}); 

  @override
  State<RegisterPage> createState() => _RegisterPageState(); 
}

class _RegisterPageState extends State<RegisterPage> {

  final _usernameController = TextEditingController(); 
  final _nameController = TextEditingController(); 
  final _emailController = TextEditingController(); 
  final _passwordController = TextEditingController(); 

  final supabase = Supabase.instance.client; 
  bool _isLoading = false; 

  Future<void> _register() async {
    if(_usernameController.text.isEmpty) {
      _showError('Username tidak boleh kosong!'); 
      return; 
    }
    else if(_nameController.text.isEmpty){
      _showError('Nama tidak boleh kosong!'); 
      return; 
    }
    else if(_emailController.text.isEmpty){
      _showError('E-mail tidak boleh kosong!'); 
      return; 
    }
    else if(_passwordController.text.isEmpty){
      _showError('Password tidak boleh kosong'); 
      return; 
    }
    else if(_passwordController.text.length < 6){
      _showError('Password tidak valid! Password minimal 6 karakter!'); 
      return; 
    }

    setState(() => _isLoading = true);

    try {
      await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        data: {
          'username': _usernameController.text.trim(), 
          'name': _nameController.text.trim(), 
        }
      ); 

      if(!mounted) return; 

      Navigator.pop(context, _emailController.text.trim()); 

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registrasi berhasil! Silakan login.'),
        )
      );
    } on AuthException catch (e) {
      if(e.message.toLowerCase().contains('username')){
        _showError('Username sudah digunakan!'); 
        return; 
      }
      else{
        _showError(e.message); 
        return; 
      }
      // if(!mounted) return; 
      // _showError(e.toString()); 
    } catch(e){
      _showError('Terjadi kesalahan. Silakan coba lagi.'); 
      return; 
    }
    finally {
      if(!mounted) return; 
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
    _usernameController.dispose(); 
    _nameController.dispose(); 
    _emailController.dispose();
    _passwordController.dispose(); 
    super.dispose();
  }

  late final String backgroundHomeUrl; 
  
  @override 
  void initState(){
    super.initState(); 
    backgroundHomeUrl = Supabase.instance.client.storage
    .from('aquaverse')
    .getPublicUrl('assets/images/login/background-login.jpeg'); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.red, 
        body: Stack(
          children: [
            Container(color: Colors.white), 

            ClipPath(
              clipper: WaveClipper(), 
              child: SizedBox(
                height: 200,
                  child: Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(backgroundHomeUrl), 
                        fit: BoxFit.cover, 
                        alignment: Alignment(0, -0.93)
                      )
                    ),
                  ),
              ),
            ), 

            Positioned(
              top: 40, 
              left: 16, 
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context), 
                child: Icon(Icons.arrow_back),
                
              ),
            ),

            Align(
              alignment: Alignment.bottomCenter, 
              child: Container(
                height: 710, 
                width: double.infinity,
                color: Colors.white, 
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25), 
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Registrasi", 
                      style: TextStyle(
                        fontSize: 40, 
                        fontWeight: FontWeight.bold, 
                      )
                    ), 
                      const SizedBox(height: 10,), 
                      const Text('Daftarkan AquaAccount sekarang. Jelajahi dan bongkar rahasia paling gelap dalam laut dalam!', 
                        style: TextStyle(
                          fontSize: 15, 
                          color: Color.fromRGBO(45, 45, 45, 1)
                        ),
                      ),
                      const SizedBox(height: 30,), 
                      const Text('Username'), 
                      const SizedBox(height: 5,), 
                      TextField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                          hintText: 'Masukkan Username di sini...', 
                          filled: true, 
                          fillColor: Colors.grey[200], 
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10), 
                            borderSide: BorderSide.none
                          )
                        )
                      ), 
                      const SizedBox(height: 15,), 
                      const Text('Nama'), 
                      const SizedBox(height: 5,), 
                      TextField(
                        controller: _nameController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                          hintText: 'Masukkan Nama di sini...', 
                          filled: true, 
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10), 
                            borderSide: BorderSide.none
                          )
                        ),
                      ), 
                      const SizedBox(height: 15,), 
                      const Text('E-mail'), 
                      const SizedBox(height: 5,),
                      TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                          hintText: 'Masukkan E-mail di sini...', 
                          filled: true, 
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10), 
                            borderSide: BorderSide.none
                          )
                        ),
                      ), 
                      const SizedBox(height: 15,), 
                      const Text('Password'), 
                      const SizedBox(height: 5,), 
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                          hintText: 'Masukkan Password di sini...',
                          filled: true, 
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10), 
                            borderSide: BorderSide.none
                          )
                        ),
                      ), 
                      
                      const SizedBox(height: 55,), 
                      SizedBox(
                        width: double.infinity, 
                        height: 45,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color.fromRGBO(105, 202, 249, 1), 
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)
                            )
                          ),
                          onPressed: _isLoading ? null : _register,
                          child: Text(
                            'Daftarkan', 
                            style: TextStyle(
                              fontSize: 15, 
                              color: Colors.black
                            ),
                          ),
                        ),
                      ), 
                      const SizedBox(height: 35,), 
                      const Center(
                        child: Text(
                          'Copyright © 2025 AquaVerse. All rights reserved', 
                          style: TextStyle(
                            fontSize: 13, 
                            color: Color.fromRGBO(45, 45, 45, 1)
                          ),
                        ),
                      )
                    ]
                  ),
                ),
              ),
            )
          ],
        )
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