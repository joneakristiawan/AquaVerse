// file: components/bottom_navbar.dart
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class Navbar extends StatelessWidget {
  final void Function(int)? onTabChange;
  final int selectedIndex; // Tambahin ini bro buat nerima state

  const Navbar({
    super.key, 
    required this.onTabChange, 
    required this.selectedIndex
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, boxShadow: [
        BoxShadow(blurRadius: 20, color: Colors.black.withOpacity(.1))
      ]),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 6),
          child: GNav(
            selectedIndex: selectedIndex, // Pasang di sini
            tabBorderRadius: 16,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            gap: 6,
            activeColor: Colors.white,
            color: Colors.grey[600],
            backgroundColor: const Color.fromARGB(255, 255, 255, 255),
            tabBackgroundColor: const Color.fromARGB(255, 0, 77, 211),
            padding: EdgeInsets.all(10),
            onTabChange: onTabChange,
            tabs: const [
              GButton(icon: Icons.home), // Gw saranin kasih text dikit biar GNav-nya cantik
              GButton(icon: Icons.newspaper),
              GButton(icon: FontAwesomeIcons.fishFins),
              GButton(icon: FontAwesomeIcons.dice),
              GButton(icon: Icons.person),
            ],
          ),
        ),
      ),
    );
  }
}