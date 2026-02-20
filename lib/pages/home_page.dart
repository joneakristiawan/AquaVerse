import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../class/news_class.dart';
import '../../components/latestnewstile.dart';
import '../class_service/quest_service.dart';
import '../class/geopify_api.dart';

class HomePage extends StatefulWidget {
  final Function(int)? onTabChange;
  const HomePage({super.key, this.onTabChange});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String userName = "Diver";
  String _rankName = "Shore Beginner";
  String? _currentBadgeUrl;

  int _streak = 0;
  int _points = 0;
  double _dailych = 0.0;
  double _rankProgress = 0.0; 
  String _nextRankMessage = "Memuat data...";
  String? _nextBadgeUrl;
  
  late Future<List<News>> _newsFuture = fetchNews();

  final PageController _pageController = PageController(
    viewportFraction: 0.88,
  );
  int _currentPage = 0;
  Timer? _timer;
  List<News>? _newsCache; 

  final supabase = Supabase.instance.client; 

  void _showNewsDetail(BuildContext context, News item) {
    final String imageUrl = item.imageUrl; 
    final String userImageUrl = item.userImageUrl; 
    
    QuestService().trackReadNews();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
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
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: imageUrl.isNotEmpty
                            ? Image.network(
                                imageUrl,
                                width: double.infinity,
                                height: 220,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => 
                                    Container(height: 220, color: Colors.grey[200], child: const Icon(Icons.broken_image, color: Colors.grey)),
                              )
                            : Container(height: 220, color: Colors.grey[200], child: const Icon(Icons.image, color: Colors.grey)),
                      ),
                      const SizedBox(height: 20),
                      
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.category,
                          style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Judul
                      Text(item.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, height: 1.3)),
                      const SizedBox(height: 8),

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
                                          const Icon(Icons.person, size: 18, color: Colors.grey),
                                    )
                                  : const Icon(Icons.person, size: 18, color: Colors.grey),
                            ),
                          ),

                          const SizedBox(width: 8),
                          Text(item.author, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          const SizedBox(width: 15),
                          const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            "${item.publishTime.day}/${item.publishTime.month}/${item.publishTime.year}",
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                      
                      const Divider(height: 40, thickness: 1),

                      // Isi Berita
                      Text(
                        item.content.isNotEmpty ? item.content : "Tidak ada konten berita.",
                        style: const TextStyle(fontSize: 16, height: 1.8, color: Colors.black87),
                        textAlign: TextAlign.justify,
                      ),
                      const SizedBox(height: 40),
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

  Map<String, dynamic> _questData = {};

  Future<void> _getUserProgress() async {
    final user = Supabase.instance.client.auth.currentUser;
    final supabase = Supabase.instance.client;

    final questData = await QuestService().getDailyQuest();

    if (user != null) {
      try {
        final progressResponse = await supabase
            .from('user_progress')
            .select('streak, last_active_date') 
            .eq('user_id', user.id)
            .maybeSingle();

        int currentStreak = 0;
        String? lastDateString;
        
        if (progressResponse != null) {
          currentStreak = progressResponse['streak'] ?? 0;
          lastDateString = progressResponse['last_active_date'];
        }

        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
        
        bool needUpdate = false;

        if (lastDateString == null) {
          currentStreak = 1;
          needUpdate = true;
        } else {
          final lastDate = DateTime.parse(lastDateString);
          final dateOnlyLast = DateTime(lastDate.year, lastDate.month, lastDate.day);
          final difference = today.difference(dateOnlyLast).inDays;

          if (difference == 1) {
            currentStreak += 1;
            needUpdate = true;
          } else if (difference > 1) {
            currentStreak = 1;
            needUpdate = true;
          }
        }

        if (needUpdate) {
          await supabase.from('user_progress').upsert({
            'user_id': user.id,
            'streak': currentStreak,
            'last_active_date': todayStr,
          }, onConflict: 'user_id');
        }

        final rankResponse = await supabase
            .from('user_rank')
            .select('''
              points, 
              ranks (
                id,
                name,
                min_points, 
                max_points,
                image_url
              )
            ''')
            .eq('user_id', user.id)
            .maybeSingle();

        if (mounted) {
          setState(() {
            _questData = questData;
            _streak = currentStreak;
            
            int newsTarget = questData['news_target'] ?? 0;
            int quizTarget = questData['quiz_target'] ?? 0;
            int fishTarget = questData['fish_target'] ?? 0;

            int newsDone = questData['news_read'] ?? 0;      // FIX: news_read
            int quizDone = questData['quiz_played'] ?? 0;    // FIX: quiz_played
            int fishDone = questData['fish_scanned'] ?? 0;   // FIX: fish_scanned

            int totalTarget = newsTarget + quizTarget + fishTarget;
            int totalDone = newsDone + quizDone + fishDone;

            if (totalTarget == 0) {
              _dailych = 0.0;
            } else {
              int cappedNews = newsDone > newsTarget ? newsTarget : newsDone;
              int cappedQuiz = quizDone > quizTarget ? quizTarget : quizDone;
              int cappedFish = fishDone > fishTarget ? fishTarget : fishDone;
              
              int cappedTotalDone = cappedNews + cappedQuiz + cappedFish;

              double percent = (cappedTotalDone / totalTarget) * 100;
              _dailych = percent > 100 ? 100 : percent;
            }
            
            if (rankResponse != null) {
              _points = rankResponse['points'] ?? 0;
              
              final rankData = rankResponse['ranks'];
              if (rankData != null) {
                final int rankId = rankData['id'] ?? 0; 
                final String fetchedRankName = rankData['name'];
                final int rankMinPoint = rankData['min_points'] ?? 0;
                final int rankMaxPoint = rankData['max_points'] ?? 10000;

                final String? imageFile = rankData['image_url'];
                if (imageFile != null) {
                  _currentBadgeUrl = supabase.storage
                      .from('aquaverse')
                      .getPublicUrl('assets/images/ranks/$imageFile');
                }

                _rankName = fetchedRankName; 

                // --- HITUNG PROGRESS RANK ---
                int range = rankMaxPoint - rankMinPoint;
                if (range <= 0) range = 1; // Cegah bagi 0
                
                double progress = (_points - rankMinPoint) / range;
                _rankProgress = progress.clamp(0.0, 1.0);
                // ----------------------------

                if (fetchedRankName == 'Ocean Sovereign' && rankId == 5) {
                  _nextRankMessage = 'Max Rank Tercapai!';
                  _rankProgress = 1.0; // Penuh
                } else {
                  final int pointsNeeded = rankMaxPoint + 1 - _points;
                  _nextRankMessage = 'Hanya dalam $pointsNeeded poin lagi!';
                }

                String nextRankImage;
                if(rankId == 1) nextRankImage = 'rank_2_star_voyager.png';
                else if(rankId == 2) nextRankImage = 'rank_3_apex_swimmer.png';
                else if(rankId == 3) nextRankImage = 'rank_4_abyss_guardian.png';
                else nextRankImage = 'rank_5_ocean_sovereign.png';

                _nextBadgeUrl = supabase.storage
                    .from('aquaverse')
                    .getPublicUrl('assets/images/ranks/$nextRankImage');
              }
            }
          });
        }
      } catch (e) {
        debugPrint('Error fetching user progress: $e');
      }
    }
  }

  Future<void> _getUserInfo() async {
    final user = Supabase.instance.client.auth.currentUser;
    final supabase = Supabase.instance.client;
    
    if (user != null) {
      String? fetchedName;

      try {
        final response = await supabase
            .from('profiles')
            .select('name')
            .eq('id', user.id)
            .maybeSingle();

        if (response != null && response['name'] != null) {
          fetchedName = response['name'];
        }
      } catch (e) {
        debugPrint("Gagal ambil dari tabel profiles, mencoba metadata... Error: $e");
      }

      if (fetchedName == null && user.userMetadata != null) {
        fetchedName = user.userMetadata!['name'];
      }

      if (fetchedName != null && fetchedName.isNotEmpty) {
        if (mounted) {
          setState(() {
            userName = fetchedName!.split(' ')[0];
          });
        }
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
          .select('id, author, title, image_url, content, publishTime, userpicture, category')
          .order('id', ascending: false)
          .limit(3);

      final List<dynamic> data = response;

      return data.map((row) {
        final map = Map<String, dynamic>.from(row as Map);
        return News.fromJson(map);
      }).toList();
    } catch (e) {
      throw Exception('Gagal load berita: $e');
    }
  }

  Future<void> _refreshData() async {
    _newsFuture = fetchNews();
    _getUserProgress();
    _getUserInfo();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _getUserInfo(); 
    _getUserProgress();
    _startAutoScroll();
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
                      padding: const EdgeInsets.only(left: 24, right: 24, top: 60, bottom: 24),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 255, 255, 255),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(35),
                          bottomRight: Radius.circular(-35),
                        ),
                        image: DecorationImage(
                          image: const NetworkImage(
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
                              _currentBadgeUrl != null
                                  ? Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color.fromARGB(0, 255, 255, 255),
                                        image: DecorationImage(
                                          image: NetworkImage(_currentBadgeUrl!),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    )
                                  : const CircleAvatar(
                                      radius: 30,
                                      backgroundColor: Color.fromARGB(255, 255, 255, 255),
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
                              
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
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
                                    Text(
                                      _rankName,
                                      style: TextStyle(
                                        fontSize: 13,
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
                                  color: Colors.grey.withValues(alpha: 0.2),
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
                                        Text('$_streak Hari', style: const TextStyle(fontSize: 22, fontFamily: 'Montserrat', fontWeight: FontWeight.w700)),
                                        const Text('Berlayar Terus', textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Color.fromARGB(255, 120, 120, 120))),
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
                                        const Text('Poin', textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Color.fromARGB(255, 120, 120, 120))),
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
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            "Berita Populer",
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
                              "Lihat Semua",
                              style: TextStyle(fontSize: 13, color: Colors.blue),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ===== SECTION LATEST NEWS CAROUSEL =====
                    SizedBox(
                      height: 280, 
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
                                      child: InkWell(
                                        onTap: () => _showNewsDetail(context, news), 
                                        borderRadius: BorderRadius.circular(16), 
                                        child: LatestNewsTile(news: news),
                                      ),
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

                    const SizedBox(height: 10,), 

                    // ===== SECTION DAILY CHALLENGES =====
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        "Tantangan Harian",
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
                            width: 70,
                            height: 70,
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
                                  "Progress Anda",
                                  style: TextStyle(
                                    fontSize: 18, 
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 0, 0, 0),
                                    height: 1.2
                                  ),
                                ),
                                const SizedBox(height: 5),
                                
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
                                const SizedBox(height: 5),

                                Builder(
                                  builder: (context) {
                                    if (_dailych >= 100 && _questData.isNotEmpty) {
                                      return const Text(
                                      "Selamat! Misi hari ini selesai!",
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                      );
                                        }
        
                                    // Ambil data real dari _questData
                                    int nTarget = _questData['news_target'] ?? 0;
                                    int qTarget = _questData['quiz_target'] ?? 0;
                                    int fTarget = _questData['fish_target'] ?? 0;

                                    int nDone = _questData['news_read'] ?? 0;
                                    int qDone = _questData['quiz_played'] ?? 0;
                                    int fDone = _questData['fish_scanned'] ?? 0;

                                    String missionText = "Misi Selesai!";

                                    // Cek mana yang aktif (karena pasti cuma 1 yang targetnya > 0)
                                    if (nTarget > 0) {
                                      if (nDone >= nTarget) {
                                          missionText = "✅ Misi Berita Selesai!";
                                      } else {
                                          missionText = "🎯 Misi Hari Ini: Baca ${nTarget - nDone} Berita lagi.";
                                      }
                                    } 
                                    else if (qTarget > 0) {
                                      if (qDone >= qTarget) {
                                          missionText = "✅ Misi Kuis Selesai!";
                                      } else {
                                          missionText = "🎯 Misi Hari Ini: Main ${qTarget - qDone} Kuis lagi.";
                                      }
                                    } 
                                    else if (fTarget > 0) {
                                      if (fDone >= fTarget) {
                                          missionText = "✅ Misi Scan Selesai!";
                                      } else {
                                          missionText = "🎯 Misi Hari Ini: Scan ${fTarget - fDone} Ikan lagi.";
                                      }
                                    }

                                    return Text(
                                      missionText,
                                      style: const TextStyle(fontSize: 13, height: 1.2, fontWeight: FontWeight.w500),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    );
                                  },
                                ),
                              ],
                            )
                          )
                        ],
                      ),
                    ),

                    // ===== SECTION TUNGGU APA LAGI =====
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        "TUNGGU APA LAGI?!",
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ),

                    LocationCard(
                      onDiveNow: () {
                        if (widget.onTabChange != null) {
                          widget.onTabChange!(2);
                        }
                      },
                    ),

                    if (_nextBadgeUrl != null)
                      Container(
                        margin: const EdgeInsets.all(14),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), 
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(148, 214, 245, 1),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
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

                                  // --- PROGRESS BAR RANK (ANIMATED) ---
                                  SizedBox(
                                    width: 150,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(5),
                                      child: LinearProgressIndicator(
                                        value: _rankProgress, // Udah idup!
                                        minHeight: 6,
                                        // ignore: deprecated_member_use
                                        backgroundColor: Colors.white.withOpacity(0.5),
                                        valueColor: const AlwaysStoppedAnimation<Color>(
                                          Color(0xFF29B6F6),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // ------------------------------------
                                  
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