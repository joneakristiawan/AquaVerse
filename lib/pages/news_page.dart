import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// Pastikan path ini sesuai sama lokasi file class lu
import '../class/news_class.dart'; 

class NewsPage extends StatefulWidget {
  @override
  _NewsPageState createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  // Config storage sesuai settings Supabase lu
  final String _storageBucket = 'aquaverse';
  final String _storageFolder = 'assets/images/news';

  // Stream data, diurutkan berdasarkan publishTime terbaru
  final _newsStream = Supabase.instance.client
      .from('news')
      .stream(primaryKey: ['id'])
      .order('publishTime', ascending: false); 

  // --- LOGIC: Popup Detail Berita ---
  void _showNewsDetail(BuildContext context, News item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Biar tinggi sheet fleksibel
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.9, // Tinggi 90% layar
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle (Garis Swipe)
              Center(
                child: Container(
                  margin: EdgeInsets.symmetric(vertical: 12),
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              // Konten Detail
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Gambar Besar di Popup
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: item.imageUrl.isNotEmpty
                            ? Image.network(
                                item.imageUrl,
                                width: double.infinity,
                                height: 220,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => 
                                    Container(height: 220, color: Colors.grey[200], child: Icon(Icons.broken_image, color: Colors.grey)),
                              )
                            : Container(height: 220, color: Colors.grey[200], child: Icon(Icons.image, color: Colors.grey)),
                      ),
                      SizedBox(height: 20),
                      
                      // Chip Kategori
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.category,
                          style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      SizedBox(height: 12),

                      // Judul
                      Text(item.title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, height: 1.3)),
                      SizedBox(height: 8),

                      // Info Author & Tanggal
                      Row(
                        children: [
                          Icon(Icons.person_outline, size: 16, color: Colors.grey),
                          SizedBox(width: 4),
                          Text(item.author, style: TextStyle(color: Colors.grey, fontSize: 12)),
                          SizedBox(width: 10),
                          Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey),
                          SizedBox(width: 4),
                          Text(
                            "${item.publishTime.day}/${item.publishTime.month}/${item.publishTime.year}",
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                      
                      Divider(height: 40, thickness: 1),

                      // Isi Berita
                      Text(
                        item.content.isNotEmpty ? item.content : "Tidak ada konten berita.",
                        style: TextStyle(fontSize: 16, height: 1.8, color: Colors.black87),
                        textAlign: TextAlign.justify,
                      ),
                      SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Background agak abu dikit biar Card putihnya "pop out"
      appBar: AppBar(
        title: Text(
          "AquaVerse News", 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
        ),
        iconTheme: IconThemeData(color: Colors.white), // Biar tombol back/drawer jadi putih
        elevation: 0,
        // --- GRADIENT BACKGROUND ---
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0D47A1), Color(0xFF42A5F5)], // Biru Tua ke Biru Laut
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_none, color: Colors.white), 
            onPressed: () {}
          )
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Telusuri: Berita Kelautan...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white, // Search bar putih
                contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                // Tambahin shadow dikit di search bar biar manis
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
              ),
            ),
          ),
          
          // List Berita
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _newsStream,
              builder: (context, snapshot) {
                // 1. Loading
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                // 2. Error
                if (snapshot.hasError) {
                  return Center(child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text("Error: ${snapshot.error}", textAlign: TextAlign.center),
                  ));
                }
                // 3. Kosong
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text("Belum ada berita."));
                }

                // --- LOGIC FIX IMAGE URL ---
                final newsList = snapshot.data!.map((data) {
                  String rawUrl = (data['image_url'] ?? '').toString();
                  // Cek apakah URL masih mentah (nama file doang)
                  if (rawUrl.isNotEmpty && !rawUrl.startsWith('http')) {
                    final publicUrl = Supabase.instance.client
                        .storage
                        .from(_storageBucket)
                        .getPublicUrl('$_storageFolder/$rawUrl');
                    data['image_url'] = publicUrl;
                  }
                  return News.fromJson(data);
                }).toList();
                // ---------------------------

                return ListView.builder(
                  padding: EdgeInsets.only(bottom: 20),
                  itemCount: newsList.length,
                  itemBuilder: (context, index) {
                    final item = newsList[index];
                    
                    // --- CARD DESIGN (Float & Rounded) ---
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 3, // Bayangan biar ngambang
                      shadowColor: Colors.blue.withOpacity(0.1), // Bayangan agak biru dikit
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      color: Colors.white,
                      child: InkWell(
                        onTap: () => _showNewsDetail(context, item),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Gambar Kiri
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: item.imageUrl.isNotEmpty
                                    ? Image.network(
                                        item.imageUrl, 
                                        width: 90, 
                                        height: 90, 
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Container(width: 90, height: 90, color: Colors.grey[200], child: Icon(Icons.broken_image, color: Colors.grey)), 
                                      )
                                    : Container(width: 90, height: 90, color: Colors.grey[200], child: Icon(Icons.image, color: Colors.grey)),
                              ),
                              SizedBox(width: 16),
                              
                              // Konten Kanan
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Kategori
                                    Text(
                                      item.category, 
                                      style: TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.w700)
                                    ),
                                    SizedBox(height: 4),
                                    // Judul
                                    Text(
                                      item.title, 
                                      maxLines: 2, 
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)
                                    ),
                                    SizedBox(height: 8),
                                    // Author & Tanggal
                                    Row(
                                      children: [
                                        Icon(Icons.person_outline, size: 14, color: Colors.grey),
                                        SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            item.author,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                          ),
                                        ),
                                        Text("• ", style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                                        Text(
                                          "${item.publishTime.day}/${item.publishTime.month}",
                                          style: TextStyle(fontSize: 11, color: Colors.grey[600])
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}