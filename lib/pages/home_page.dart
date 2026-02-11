// ignore_for_file: deprecated_member_use, avoid_print

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
  String userName = "Diver";

  int _streak = 0;
  int _explored = 0;
  double _dailych = 0.0;
  
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
    _getUserInfo(); 
    _getUserProgress();
    _startAutoScroll();
  }

  Future<void> _getUserProgress() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user != null) {
      try{
        final response = await Supabase.instance.client
            .from('user_progress')
            .select('streak, explored, dailych')
            .eq('id', user.id)
            .single();

        if (mounted){
          setState(() {
            _streak = response['streak'] ?? 0;
            _explored = response['explored'] ?? 0;
            _dailych = (response['dailych'] ?? 0).toDouble();
          });
        }
      } catch (e){
        print('Error fetching user progress: $e');
      }
    }
    
  }

  void _getUserInfo() {
    final user = Supabase.instance.client.auth.currentUser;
    
    if (user != null && user.userMetadata != null) {
      final String? fullName = user.userMetadata!['name'];
      
      if (fullName != null && fullName.isNotEmpty) {
        setState(() {
          userName = fullName.split(' ')[0];
        });
      }
    }
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_newsCache != null && _newsCache!.isNotEmpty) {
        if (_currentPage < _newsCache!.length - 1) {
          _currentPage++;
        } else {
          _currentPage = 0;
        }
        if (_pageController.hasClients) {
          _pageController.animateToPage(
            _currentPage,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
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
      extendBody: true,
      extendBodyBehindAppBar: true,
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
                        color: const Color.fromARGB(255, 255, 255, 255),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(35),
                          bottomRight: Radius.circular(-35),
                        ),
                        image: DecorationImage(
                          image: NetworkImage(
                            "https://ccuigpzseuhwietjcyyi.supabase.co/storage/v1/object/public/aquaverse/assets/images/home/Banner-no-logo.jpg"
                          ),
                          fit: BoxFit.cover,
                          opacity: 0.75,
                          colorFilter: ColorFilter.mode(
                            const Color.fromARGB(255, 75, 172, 251).withOpacity(0.5), 
                            BlendMode.srcOver
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(
                                radius: 30,
                                backgroundColor: Color.fromARGB(255, 155, 155, 155),
                                child: CircleAvatar(
                                  radius: 26,
                                  backgroundColor: Color.fromARGB(255, 223, 223, 223),
                                  child: Icon(
                                    Icons.person,
                                    size: 30,
                                    color: Color.fromARGB(255, 93, 93, 93),
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
                                      color: Color.fromARGB(255, 255, 255, 255),
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
                              children: [
                                Column(
                                  children: [
                                    const Icon(Icons.waves, color: Color.fromARGB(255, 3, 112, 255), size: 30),
                                    const SizedBox(height: 4),
                                    Text('$_streak Days', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                                    const Text('Sails Streak', style: TextStyle(fontSize: 10, color: Color.fromARGB(255, 120, 120, 120))),
                                  ],
                                ),
                                const SizedBox(
                                  height: 50,
                                  child: VerticalDivider(color: Colors.grey),
                                ),
                                Column(
                                  children: [
                                    const Icon(Icons.sailing_sharp, color: Color.fromARGB(255, 3, 112, 255), size: 30),
                                    const SizedBox(height: 4),
                                    Text('$_explored%', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                                    const Text('Explored', style: TextStyle(fontSize: 10, color: Color.fromARGB(255, 120, 120, 120))),
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
                            "LATEST NEWS",
                            style: TextStyle(
                              fontFamily: "Montserrat",
                              fontSize: 24, 
                              fontWeight: FontWeight.bold),
                              
                          ),
                          
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

                              // DOT INDICATOR
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
                      height: 110,
                      margin: const EdgeInsets.all(14),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 156, 216, 250),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.book,
                              size: 50,
                              color: Color.fromARGB(255, 0, 0, 0),
                            ),
                          ),
                          const SizedBox(width: 16),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Your Progress",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 0, 0, 0),
                                  ),
                                ),
                                SizedBox(height: 8),
                                
                                ClipRRect(
                                  borderRadius: BorderRadius.all(Radius.circular(4)),
                                  child: LinearProgressIndicator(
                                    value: _dailych / 100,
                                    minHeight: 8,
                                    backgroundColor: Color.fromARGB(255, 204, 229, 243),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Color.fromARGB(255, 22, 114, 227),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 8),

                                Text(
                                  "Read 5 news articles to complete this challenge.",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color.fromARGB(255, 0, 0, 0),
                                  ),
                                ),
                              ],
                            )
                          )
                        ],
                      ),
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