// ignore_for_file: deprecated_member_use, avoid_print, use_build_context_synchronously

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

  // Progress Statis
  int _streak = 0;
  int _points = 0;
  double _dailych = 0.0;

  // --- LOGIC RANK BARU ---
  String _nextRankMessage = "Memuat data...";
  String? _nextBadgeUrl;
  // -----------------------
  
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
    _getUserProgress(); // Logic Streak & Rank jalan di sini
    _startAutoScroll();
  }

  /// FUNGSI UTAMA: Update Streak & Ambil Data Rank
  Future<void> _getUserProgress() async {
    final user = Supabase.instance.client.auth.currentUser;
    final supabase = Supabase.instance.client;

    if (user != null) {
      try {
        // 1. Ambil data progress user (termasuk tanggal terakhir login)
        final progressResponse = await supabase
            .from('user_progress')
            .select('streak, points, dailych, last_active_date')
            .eq('id', user.id)
            .single();

        // --- LOGIC HITUNG STREAK (START) ---
        int currentStreak = progressResponse['streak'] ?? 0;
        String? lastDateString = progressResponse['last_active_date']; // Format: YYYY-MM-DD
        
        // Ambil tanggal hari ini (tanpa jam/menit)
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
        
        bool needUpdate = false;

        if (lastDateString == null) {
          // Kasus 1: User baru pertama kali login seumur hidup / data tanggal kosong
          currentStreak = 1;
          needUpdate = true;
        } else {
          // Parse tanggal dari database
          final lastDate = DateTime.parse(lastDateString);
          
          // Hitung selisih hari (Hari ini - Tanggal Terakhir)
          final difference = today.difference(lastDate).inDays;

          if (difference == 0) {
            // Kasus 2: Login di hari yang sama -> Gak usah diapa-apain
          } else if (difference == 1) {
            // Kasus 3: Login besoknya (Berurutan) -> Streak Nambah!
            currentStreak += 1;
            needUpdate = true;
          } else if (difference > 1) {
            // Kasus 4: Bolong lebih dari sehari -> RESET jadi 1
            currentStreak = 1;
            needUpdate = true;
          }
          // Note: Kalo difference negatif (user ganti tanggal HP mundur), kita abaikan biar gak error
        }

        // Simpan perubahan streak ke Database kalo ada update
        if (needUpdate) {
          await supabase.from('user_progress').update({
            'streak': currentStreak,
            'last_active_date': todayStr, // Update jadi tanggal hari ini
          }).eq('id', user.id);
        }
        // --- LOGIC HITUNG STREAK (END) ---

        // 2. Ambil data Rank Detail (Buat widget Next Rank)
        final rankResponse = await supabase
            .from('profiles')
            .select('''
              user_rank (
                points, 
                ranks (
                  id,
                  name,
                  max_points
                )
              )
            ''')
            .eq('id', user.id)
            .single();

        if (mounted) {
          setState(() {
            // Update UI dengan data terbaru
            _streak = currentStreak; 
            _points = progressResponse['points'] ?? 0;
            _dailych = (progressResponse['dailych'] ?? 0).toDouble();

            // --- LOGIC TAMPILAN RANK ---
            final userRank = rankResponse['user_rank'];
            
            if (userRank != null) {
              final rankData = userRank['ranks'];
              final int currentPoints = userRank['points'];
              final int rankId = rankData['id'];
              final String rankName = rankData['name'];
              final int rankMaxPoint = rankData['max_points'];
              
              // Hitung sisa poin message
              if (rankName == 'Ocean Sovereign' && rankId == 5) {
                _nextRankMessage = 'Max Rank Tercapai!';
              } else {
                final int pointsNeeded = rankMaxPoint + 1 - currentPoints;
                _nextRankMessage = 'Hanya dalam $pointsNeeded poin lagi!';
              }

              // Tentukan gambar Badge Selanjutnya
              String nextRankImage;
              if(rankId == 1) nextRankImage = 'rank_2_star_voyager.png';
              else if(rankId == 2) nextRankImage = 'rank_3_apex_swimmer.png';
              else if(rankId == 3) nextRankImage = 'rank_4_abyss_guardian.png';
              else nextRankImage = 'rank_5_ocean_sovereign.png';

              _nextBadgeUrl = supabase.storage
                  .from('aquaverse')
                  .getPublicUrl('assets/images/ranks/$nextRankImage');
            }
          });
        }
      } catch (e) {
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
    _getUserProgress(); // Refresh progress juga pas tarik layar
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
                      // Pake padding yang aman buat semua device (Responsive)
                      padding: const EdgeInsets.only(left: 24, right: 24, top: 60, bottom: 24),
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
                              
                              // Expanded agar text tidak overflow ke kanan
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // FittedBox bikin font mengecil otomatis kalo namanya kepanjangan
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        'Hi, $userName',
                                        style: const TextStyle(
                                          fontFamily: "Montserrat",
                                          fontSize: 38,
                                          fontWeight: FontWeight.bold,
                                          color: Color.fromARGB(255, 56, 56, 56),
                                        ),
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
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

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
                            child: IntrinsicHeight(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  Expanded(
                                    child: Column(
                                      children: [
                                        const Icon(Icons.sailing, color: Color.fromRGBO(10, 78, 236, 1), size: 40),
                                        const SizedBox(height: 4),
                                        Text('$_streak Days', style: const TextStyle(fontSize: 22, fontFamily: 'Montserrat', fontWeight: FontWeight.w600)),
                                        const Text('Sails Streak', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Color.fromARGB(255, 120, 120, 120))),
                                      ],
                                    ),
                                  ),
                                  const VerticalDivider(color: Colors.grey, thickness: 1),
                                  Expanded(
                                    child: Column(
                                      children: [
                                        const Icon(Icons.star, color: Color.fromRGBO(10, 78, 236, 1), size: 40),
                                        const SizedBox(height: 4),
                                        Text('$_points', style: const TextStyle(fontSize: 22, fontFamily: 'Montserrat', fontWeight: FontWeight.w700)),
                                        const Text('Points', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Color.fromARGB(255, 120, 120, 120))),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
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
                                widget.onTabChange!(1); 
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
                      margin: const EdgeInsets.all(14),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(148, 215, 247, 1),
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
                              size: 40,
                              color: Color.fromARGB(255, 0, 0, 0),
                            ),
                          ),
                          const SizedBox(width: 16),

                          Expanded( 
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  "Your Progress",
                                  style: TextStyle(
                                    fontSize: 18, 
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 0, 0, 0),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                
                                ClipRRect(
                                  borderRadius: const BorderRadius.all(Radius.circular(4)),
                                  child: LinearProgressIndicator(
                                    value: _dailych / 100,
                                    minHeight: 8,
                                    backgroundColor: const Color.fromARGB(255, 204, 229, 243),
                                    valueColor: const AlwaysStoppedAnimation<Color>(
                                      Color.fromARGB(255, 22, 114, 227),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),

                                const Text(
                                  "Read 5 news articles to complete this challenge.",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color.fromARGB(255, 0, 0, 0),
                                  ),
                                  maxLines: 2, 
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            )
                          )
                        ],
                      ),
                    ),

                    // ===== SECTION TUNGGU APA LAGI (LEVEL UP) =====
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        "TUNGGU APA LAGI?!",
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ),

                    // WIDGET LEVEL UP / RANK UP
                    if (_nextBadgeUrl != null)
                      Container(
                        margin: const EdgeInsets.all(14),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), 
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(148, 214, 245, 1),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              offset: const Offset(0, 4),
                              blurRadius: 8,
                            )
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Naikkan Rank!',
                                    style: TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontWeight: FontWeight.bold,
                                      color: Color.fromRGBO(63, 68, 102, 1),
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Container(
                                    width: 150,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    _nextRankMessage,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontStyle: FontStyle.italic,
                                      color: Color.fromARGB(255, 40, 40, 40),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Badge Next Rank
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: NetworkImage(_nextBadgeUrl!),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            )
                          ],
                        ),
                      )
                    else
                      // Loading State
                      Container(
                        height: 90,
                        margin: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(child: CircularProgressIndicator()),
                      ),

                    const SizedBox(height: 40), // Spacer bawah
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