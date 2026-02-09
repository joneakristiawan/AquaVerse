/*
 /$$      /$$  /$$$$$$  /$$$$$$$  /$$   /$$ /$$$$$$ /$$   /$$  /$$$$$$  /$$   
| $$  /$ | $$ /$$__  $$| $$__  $$| $$$ | $$|_  $$_/| $$$ | $$ /$$__  $$| $$
| $$ /$$$| $$| $$  \ $$| $$  \ $$| $$$$| $$  | $$  | $$$$| $$| $$  \__/| $$
| $$/$$ $$ $$| $$$$$$$$| $$$$$$$/| $$ $$ $$  | $$  | $$ $$ $$| $$ /$$$$| $$
| $$$$_  $$$$| $$__  $$| $$__  $$| $$  $$$$  | $$  | $$  $$$$| $$|_  $$|__/
| $$$/ \  $$$| $$  | $$| $$  \ $$| $$\  $$$  | $$  | $$\  $$$| $$  \ $$    
| $$/   \  $$| $$  | $$| $$  | $$| $$ \  $$ /$$$$$$| $$ \  $$|  $$$$$$/ /$$
|__/     \__/|__/  |__/|__/  |__/|__/  \__/|______/|__/  \__/ \______/ |__/

 /$$$$$$$  /$$$$$$$$  /$$$$$$  /$$$$$$$        /$$      /$$ /$$$$$$$$ /$$
| $$__  $$| $$_____/ /$$__  $$| $$__  $$      | $$$    /$$$| $$_____/| $$
| $$  \ $$| $$      | $$  \ $$| $$  \ $$      | $$$$  /$$$$| $$      | $$
| $$$$$$$/| $$$$$   | $$$$$$$$| $$  | $$      | $$ $$/$$ $$| $$$$$   | $$
| $$__  $$| $$__/   | $$__  $$| $$  | $$      | $$  $$$| $$| $$__/   |__/
| $$  \ $$| $$      | $$  | $$| $$  | $$      | $$\  $ | $$| $$          
| $$  | $$| $$$$$$$$| $$  | $$| $$$$$$$/      | $$ \/  | $$| $$$$$$$$ /$$
|__/  |__/|________/|__/  |__/|_______/       |__/     |__/|________/|__/

***************************PAGE INI DIGUNAKAN UNTUK DISPLAY KE main.dart|***************************
*/

/*
****************************NOTES!****************************
PAGE INI DIGUNAKAN UNTUK DISPLAY KE main.dart
--------------------------------------------------------------
Cara penamaan section dibawah ini:
MAIN {angka}: Container utama
SECTION: Bagian dalam container utama
SUBSECTION: Bagian dalam section
ONSUB: Bagian dalam subsection
--------------------------------------------------------------
  ___ __  __ ___  ___  ___ _____ _   _  _ _____ 
 |_ _|  \/  | _ \/ _ \| _ \_   _/_\ | \| |_   _|
  | || |\/| |  _/ (_) |   / | |/ _ \| .` | | |  
 |___|_|  |_|_|  \___/|_|_\ |_/_/ \_\_|\_| |_|  
 
Jika ada penambahan penamaan, mohon dicantumkan dalam NOTES!
--------------------------------------------------------------
*/

import '../../pages/dive_page.dart';
import 'quiz_page.dart';
import '../../pages/home_page.dart';
import '../../pages/news_page.dart';
import '../../pages/profile_page.dart';
import 'package:flutter/material.dart';
import '../../components/navbar.dart';
import '../../components/sidebar.dart';

class DisplayPage extends StatefulWidget {
  const DisplayPage({super.key});

  @override
  State<DisplayPage> createState() => _DisplayPageState();
}

class _DisplayPageState extends State<DisplayPage> {
  
  int _selectedIndex = 0;

  void navigateBottomBar(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Pages to display
  List<Widget> get _pages => [
    // Pas panggil HomePage, kita oper fungsi navigateBottomBar
    HomePage(
      onTabChange: (index) => navigateBottomBar(index),
    ),
    const NewsPage(),
    const DivePage(),
    const QuizPage(),
    const ProfilePage()
  ];
  
  @override
  Widget build(BuildContext context) {
    bool isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: isLandscape 
        ? AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.black),
          )
        : null,

      drawer: isLandscape 
        ? SideMenu(
            onTabChange: (index) => navigateBottomBar(index),
            selectedIndex: _selectedIndex,
          )
        : null,
      
      body: _pages[_selectedIndex],

      bottomNavigationBar: isLandscape
          ? null
          : Navbar(
              onTabChange: (index) => navigateBottomBar(index),
              selectedIndex: _selectedIndex,
            ),
    );
  }
}