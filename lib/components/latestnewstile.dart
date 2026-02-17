import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../class/news_class.dart'; 

class LatestNewsTile extends StatelessWidget {
  final News news; 

  const LatestNewsTile({super.key, required this.news});

  @override
  Widget build(BuildContext context) {

    return Container(
      width: 280, 
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.withValues(alpha: 0.2), blurRadius: 5, offset: Offset(0, 3))
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // BAGIAN GAMBAR UTAMA BERITA
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            child: CachedNetworkImage(
              imageUrl: news.imageUrl,
              height: 130,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                height: 120,
                color: Colors.grey[200],
                child: Center(
                  child: CircularProgressIndicator(
                    color: Colors.blueAccent, 
                    strokeWidth: 2
                  )
                ),
              ),
              errorWidget: (context, url, error) => Container(
                height: 120,
                color: Colors.grey[300],
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image, color: Colors.grey),
                    SizedBox(height: 4),
                    Text("No Image", style: TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ),
            ),
          ),
          
          // BAGIAN TEXT & AUTHOR
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  news.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                SizedBox(height: 12), // Kasih jarak dikit biar gak nempel
                
                // === INI BAGIAN BARU BUAT AVATAR USER ===
                Row(
                  children: [
                    // Logic: Kalau ada foto, tampilin foto. Kalau ga ada, tampilin icon anonim.
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[200], // Background buat yg anonim
                      ),
                      child: ClipOval(
                        child: CachedNetworkImage(
                                imageUrl: news.userImageUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(color: Colors.grey[200]),
                                errorWidget: (context, url, error) => Icon(Icons.person, size: 16, color: Colors.grey),
                              )
                      ),
                    ),
                    
                    SizedBox(width: 10), // Jarak antara foto dan nama
                    
                    Expanded(
                      child: Text(
                        news.author,
                        style: TextStyle(color: Colors.grey[700], fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                // === SELESAI BAGIAN BARU ===
                
              ],
            ),
          )
        ],
      ),
    );
  }
}