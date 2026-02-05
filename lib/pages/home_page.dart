import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../class/news_class.dart';
import '../../components/latestnewstile.dart';


class HomePage extends StatefulWidget {
  final Function(int)? onTabChange;
  const HomePage({super.key, this.onTabChange});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String userName = "{User}";
  late Future<List<News>> _newsFuture = fetchNews();

  final PageController _pageController = PageController(
    viewportFraction: 0.88,
  );
  int _currentPage = 0;
  Timer? _timer;
  List<News>? _newsCache;

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_newsCache != null && _newsCache!.isNotEmpty) {
        if (_currentPage < _newsCache!.length - 1) {
          _currentPage++;
        } else {
          _currentPage = 0;
        }
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<List<News>> fetchNews() async {
    try {
      final supabase = Supabase.instance.client;

      final response = await supabase
          .from('news')
          .select('id, author, title, image_url, content, publishTime, userpicture')
          .order('id', ascending: false)
          .limit(3);

      final List<dynamic> data = response;

      const bucket = 'aquaverse';
      const folderPrefix = 'assets/images/news';

      return data.map((row) {
        final map = Map<String, dynamic>.from(row as Map);
        String file = (map['image_url'] ?? '').toString();

        if (file.isNotEmpty && !file.startsWith('http')) {
          String filePath;
          if (file.contains(folderPrefix)) {
            filePath = file;
          } else {
            filePath = '$folderPrefix/$file';
          }
          map['image_url'] = supabase.storage.from(bucket).getPublicUrl(filePath);
        }

        return News.fromJson(map);
      }).toList();
    } catch (e) {
      throw Exception('Gagal load berita: $e');
    }
  }

  Future<void> _refreshData() async {
    _newsFuture = fetchNews();
    setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: Stack(
        children: [
          Positioned.fill(child: Container(color: const Color(0xFFFFFFFF))),

          SafeArea(
            top: false,
            bottom: false,
            child: RefreshIndicator(
              onRefresh: _refreshData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ===== SECTION BASE PROFILE =====
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(24, 50, 24, 24),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 225, 251, 254),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(35),
                          bottomRight: Radius.circular(-35),
                        ),
                        image: const DecorationImage(
                          image: NetworkImage(
                            "https://ccuigpzseuhwietjcyyi.supabase.co/storage/v1/object/public/aquaverse/assets/images/home/Banner-no-logo.jpg"
                          ),
                          fit: BoxFit.cover,
                          opacity: 0.75,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(
                                radius: 30,
                                backgroundColor: Color.fromARGB(255, 253, 203, 255),
                                child: CircleAvatar(
                                  radius: 26,
                                  backgroundColor: Color.fromARGB(255, 253, 228, 254),
                                  child: Icon(
                                    Icons.person,
                                    size: 30,
                                    color: Color.fromARGB(255, 199, 136, 255),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Hi, $userName',
                                    style: const TextStyle(
                                      fontFamily: "Montserrat",
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Color.fromARGB(255, 56, 56, 56),
                                    ),
                                  ),
                                  const Text(
                                    'Divers',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color.fromARGB(255, 120, 120, 120),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 25),

                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.2),
                                  blurRadius: 3,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: const [
                                Column(
                                  children: [
                                    Icon(Icons.waves, color: Color.fromARGB(255, 3, 112, 255), size: 30),
                                    SizedBox(height: 4),
                                    Text('5 Days', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                                    Text('Sails Streak', style: TextStyle(fontSize: 10, color: Color.fromARGB(255, 120, 120, 120))),
                                  ],
                                ),
                                SizedBox(
                                  height: 50,
                                  child: VerticalDivider(color: Colors.grey),
                                ),
                                Column(
                                  children: [
                                    Icon(Icons.sailing_sharp, color: Color.fromARGB(255, 3, 112, 255), size: 30),
                                    SizedBox(height: 4),
                                    Text('12%', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                                    Text('Explored', style: TextStyle(fontSize: 10, color: Color.fromARGB(255, 120, 120, 120))),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ===== SECTION LATEST NEWS TITLE + VIEW ALL =====
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 5, 14, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Latest News",
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          
                          // << ADDED VIEW ALL BUTTON >>
                          TextButton(
                            onPressed: () {
                              if (widget.onTabChange != null) {
                                widget.onTabChange!(1); // Navigate to News Page
                              }
                            },
                            child: const Text(
                              "View All",
                              style: TextStyle(fontSize: 14, color: Colors.blue),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ===== SECTION LATEST NEWS CAROUSEL =====
                    SizedBox(
                      height: 270,
                      child: FutureBuilder<List<News>>(
                        future: _newsFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          if (snapshot.hasError) {
                            return const Center(child: Text("Failed to Fetch News"));
                          }

                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Center(child: Text("Belum ada berita terbaru"));
                          }

                          _newsCache = snapshot.data!;

                          return Column(
                            children: [
                              Expanded(
                                child: PageView.builder(
                                  controller: _pageController,
                                  itemCount: snapshot.data!.length,
                                  onPageChanged: (index) => setState(() => _currentPage = index),
                                  itemBuilder: (context, index) {
                                    final news = snapshot.data![index];
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                      child: LatestNewsTile(news: news),
                                    );
                                  },
                                ),
                              ),

                              const SizedBox(height: 6),

                              // << ADDED: DOT INDICATOR >>
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  snapshot.data!.length,
                                  (index) => AnimatedContainer(
                                    duration: const Duration(milliseconds: 500),
                                    margin: const EdgeInsets.symmetric(horizontal: 3),
                                    width: _currentPage == index ? 22 : 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: _currentPage == index 
                                          ? Colors.blue 
                                          : Colors.grey.shade400,
                                      borderRadius: BorderRadius.circular(50),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),

                    // ===== SECTION DAILY CHALLENGES =====
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        "Daily Challenges",
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ),

                    Container(
                      height: 100,
                      margin: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(child: Text("Coming Soon!")),
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        "TUNGGU APA LAGI?!",
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ),

                    Container(
                      height: 100,
                      margin: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(child: Text("Coming Soon!")),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
