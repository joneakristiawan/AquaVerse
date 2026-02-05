import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class NewsPage extends StatelessWidget {
  const NewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFEFEFEF),
      body: Stack(
        children: [
          // Top Search Bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(left: 20, top: 10),
            height: 170,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4A90E2), Color(0xFF50E3C2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.all(
                Radius.circular(8),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CachedNetworkImage(
                  imageUrl: 'https://ccuigpzseuhwietjcyyi.supabase.co/storage/v1/object/public/aquaverse/assets/images/logo/Logo-AquaVerse.png',
                  height: 60,
                ),
                Text(
                  "AquaVerse News"
                  ,style: TextStyle(
                    fontFamily: 'Agbalumo',
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            )
          ),
        ],
      ),
    );
  }
}
