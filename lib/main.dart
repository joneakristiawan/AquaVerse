import 'package:flutter/material.dart'; 
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/login_page.dart';
import 'pages/display_page.dart';
import 'dbkey/dbkey.dart';
import 'pages/splash_screen.dart'; 


Future<void> main() async{ 
  WidgetsFlutterBinding.ensureInitialized(); 
  
  await Supabase.initialize(
    url: DBKey.url,
    anonKey: DBKey.anonKey
  );
  
  runApp(const MyApp()); 
}

class MyApp extends StatelessWidget {
  const MyApp({super.key}); 

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      debugShowCheckedModeBanner: false, 
      home: const SplashScreen()
    ); 
  }
}