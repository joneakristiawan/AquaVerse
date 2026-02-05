import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SideMenu extends StatelessWidget {
  final void Function(int)? onTabChange;
  final int selectedIndex;

  const SideMenu({
    super.key, 
    required this.onTabChange, 
    required this.selectedIndex
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      
      child: ListView(
        padding: EdgeInsets.zero, 
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Colors.white, 
            ),
            child: 
              CachedNetworkImage(
              imageUrl: 'https://ccuigpzseuhwietjcyyi.supabase.co/storage/v1/object/public/aquaverse/assets/images/logo/logo1000.png',
              placeholder: (context, url) => const Center(
                child:SizedBox(
                  width:20,
                  height:20,
                  child: CircularProgressIndicator()
                )
              ),
              errorWidget: (context, url, error) => const Icon(Icons.error),
              width: 100,
              height: 100,
              fit: BoxFit.contain,
            ),
          ),

          // List Menu (Langsung aja jejerin di sini)
          _buildItem(context, 0, "Home", Icons.home),
          _buildItem(context, 1, "News", Icons.newspaper),
          _buildItem(context, 2, "Fish", FontAwesomeIcons.fishFins, isFa: true),
          _buildItem(context, 3, "Game", FontAwesomeIcons.gamepad, isFa: true),
          _buildItem(context, 4, "Profile", Icons.person),
          
          // Opsional: Spacer buat jaga-jaga kalo listnya dikit biar gak error
          const SizedBox(height: 20), 
        ],
      ),
    );
  }

  Widget _buildItem(BuildContext context, int index, String label, IconData icon, {bool isFa = false}) {
    bool isSelected = selectedIndex == index;
    Color activeColor = const Color.fromARGB(255, 0, 77, 211);
    
    return ListTile(
      leading: isFa 
        ? FaIcon(icon, color: isSelected ? activeColor : Colors.grey) 
        : Icon(icon, color: isSelected ? activeColor : Colors.grey),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? activeColor : Colors.grey[700],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onTap: () {
        onTabChange!(index); 
        Navigator.pop(context);
      },
    );
  }
}