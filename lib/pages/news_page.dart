import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../class/news_class.dart'; 
import 'package:intl/intl.dart'; 
import 'dart:async'; // untuk Timer 

class NewsPage extends StatefulWidget {
  const NewsPage({super.key}); 

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  // Config storage sesuai settings Supabase lu
  final supabase = Supabase.instance.client; 

  // --- LOGIC: Popup Detail Berita ---
  void _showNewsDetail(BuildContext context, News item) {
    final String imageUrl = item.imageUrl; 
    final String userImageUrl = item.userImageUrl; 
    debugPrint(imageUrl); 
    debugPrint(userImageUrl); 

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
                        child: imageUrl.isNotEmpty
                            ? Image.network(
                                imageUrl,
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
                          Container(
                            height: 25,
                            width: 25,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey[200],
                            ),
                            child: ClipOval(
                              child: userImageUrl.isNotEmpty
                                  ? Image.network(
                                      userImageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          Icon(Icons.person, size: 18, color: Colors.grey),
                                    )
                                  : Icon(Icons.person, size: 18, color: Colors.grey),
                            ),
                          ),

                          SizedBox(width: 8),
                          Text(item.author, style: TextStyle(color: Colors.grey, fontSize: 12)),
                          SizedBox(width: 15),
                          Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey),
                          SizedBox(width: 8),
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

  List<News> _newsList = []; 
  bool _isLoading = false; 
  String _searchQuery = ''; 
  Timer? _debounce; 

  bool get isSearching => _searchQuery.isNotEmpty;


  Future<void> _fetchNews({String query = ''}) async {
    setState(() => _isLoading = true);
    try {
      final response = query.isEmpty
          ? await supabase.from('news').select().order('publishTime', ascending: false)
          : await supabase.from('news').select().ilike('title', '%${query.trim()}%').order('publishTime', ascending: false);
      
      debugPrint("RAW RESPONSE:");
      debugPrint(response.toString());

      final news = (response as List)
          .map((item) => News.fromJson(item))
          .toList();
      
      if(!mounted) return; 

      setState(() {
        _newsList = news;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetch news: $e");
      if(!mounted) return; 
      setState(() => _isLoading = false);
    }
  }

  @override
  void initState(){
    super.initState(); 
    _fetchNews(); 
  }

  @override
  void dispose(){
    _debounce?.cancel(); 
    super.dispose(); 
  }

  @override
  Widget build(BuildContext context) {
    
    final aquaVerseLogoUrl = supabase.storage
      .from('aquaverse')
      .getPublicUrl('assets/images/logo/Logo-AquaVerse.png'); 

    final newsLogoUrl = supabase.storage
      .from('aquaverse')
      .getPublicUrl('assets/images/news/Text-AquaVerseNews.png'); 

    Intl.defaultLocale = 'id_ID'; 
    DateTime now = DateTime.now(); 
    String formattedDate = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(now); 


    return Scaffold(
      backgroundColor: Colors.grey[50], // Background agak abu dikit biar Card putihnya "pop out"
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 180,
            child: Container(
              padding: const EdgeInsets.only(top: 40),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(148, 214, 245, 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    offset: const Offset(0, 4),
                    blurRadius: 8,
                  )
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const SizedBox(width: 20),
                      Image.network(aquaVerseLogoUrl, height: 55),
                      const SizedBox(width: 15),
                      Image.network(newsLogoUrl, height: 27),
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                      top: 15,
                      left: 15, 
                      right: 15
                    ),
                    child: TextField(
                      onChanged: (value) {
                        if (_debounce?.isActive ?? false) _debounce!.cancel();
                          _debounce = Timer(const Duration(milliseconds: 500), () {
                            setState(() {
                              _searchQuery = value; 
                            });
                            _fetchNews(query: value);
                          });
                      },
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

                ],
              )
            ),
          ),

          const FrostedGlass(),

          SafeArea(
            child: Padding(
              padding: EdgeInsets.only(top: 160),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, 
                  children: [
                    const SizedBox(height: 10,),  

                    if(!isSearching)...[
                        Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: const Text("Berita Populer", style: TextStyle(
                          fontSize: 28, 
                          fontFamily: 'Montserrat',
                          height: 1.4,
                          fontWeight: FontWeight.bold, 
                          color: Color.fromRGBO(63, 68, 102, 1), 
                        ),), 
                      ),
                      
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20), 
                        child: Text(formattedDate, style: TextStyle(
                          fontSize: 22, 
                          fontFamily: 'Montserrat',
                          height: 1.0,
                          fontWeight: FontWeight.bold, 
                          color: Colors.black
                        ),),
                      ),
                    ],

                    const SizedBox(height: 10,), 

                    // Loading Berita 
                    if (_isLoading) 
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    
                    if (isSearching && _newsList.isEmpty) 
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text("Tidak ada berita yang sesuai!"),
                        ),
                      ), 

                    if(isSearching)...[
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: const Text("Hasil Pencarian", style: TextStyle(
                          fontSize: 28, 
                          fontFamily: 'Montserrat',
                          height: 1.4,
                          fontWeight: FontWeight.bold, 
                          color: Color.fromRGBO(63, 68, 102, 1), 
                        ),), 
                      ),
                        
                      Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20), 
                          child: Text('Untuk: $_searchQuery', style: TextStyle(
                            fontSize: 22, 
                            fontFamily: 'Montserrat',
                            height: 1.0,
                            fontWeight: FontWeight.bold, 
                            color: Colors.black
                          ),),
                      ),
                    ],

                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 20),
                      itemCount: _newsList.length,
                      itemBuilder: (context, index) {
                        final item = _newsList[index]; 

                        final monthShort =
                            DateFormat('MMMM', 'id_ID').format(item.publishTime);

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          elevation: 3,
                          shadowColor: Colors.blue.withValues(alpha: 0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          color: Colors.white,
                          child: InkWell(
                            onTap: () => _showNewsDetail(context, item),
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // IMAGE
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    
                                    child: item.imageUrl.isNotEmpty
                                        ? Image.network(
                                            item.imageUrl,
                                            width: 90,
                                            height: 90,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) =>
                                                Container(
                                              width: 90,
                                              height: 90,
                                              color: Colors.grey[200],
                                              child: const Icon(Icons.broken_image,
                                                  color: Colors.grey),
                                            ),
                                          )
                                        : Container(
                                            width: 90,
                                            height: 90,
                                            color: Colors.grey[200],
                                            child:
                                                const Icon(Icons.image, color: Colors.grey),
                                          ),
                                  ),
                                  const SizedBox(width: 16),

                                  // CONTENT
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.category,
                                          style: TextStyle(
                                            color: Colors.black.withValues(alpha: 0.5),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),

                                        Text(
                                          item.title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 8),

                                        Row(
                                          children: [
                                            Container(
                                              height: 22,
                                              width: 22,
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(100),
                                                image: DecorationImage(
                                                  image: NetworkImage(item.userImageUrl),
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),

                                            Expanded(
                                              child: Text(
                                                item.author,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey[600]),
                                              ),
                                            ),

                                            Text(
                                              "| ",
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey[600]),
                                            ),

                                            Text(
                                              "${item.publishTime.day} $monthShort",
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey[600]),
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
                    ), 
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

/// Frosted Glass 
class FrostedGlass extends StatelessWidget {
  const FrostedGlass({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: ClipRect(
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withValues(alpha: 0.75),
                Colors.white.withValues(alpha: 0.7),
                Colors.white.withValues(alpha: 0.1),
                Colors.white.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}