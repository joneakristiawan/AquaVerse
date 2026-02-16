import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; 
import 'quiz_fill.dart'; 
import 'package:intl/intl.dart'; 

class QuizPage extends StatefulWidget {
  const QuizPage({super.key});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  final supabase = Supabase.instance.client;

  late final String aquaVerseLogoUrl;
  late final String quizLogoUrl; 
  late final String coinsUrl; 
  late final String startQuizBgPicUrl; 
  late final String playButtonUrl; 

  late final Future<Map<String, dynamic>> userFuture;

  @override
  void initState() {
    super.initState();

    userFuture = _waitForSessionAndFetch();

    aquaVerseLogoUrl = supabase.storage
        .from('aquaverse')
        .getPublicUrl('assets/images/logo/Logo-AquaVerse.png');

    quizLogoUrl = supabase.storage
        .from('aquaverse')
        .getPublicUrl('assets/images/quiz/Text-AquaVerseQuiz.png');

    coinsUrl = supabase.storage
      .from('aquaverse')
      .getPublicUrl('assets/images/quiz/Coins.png'); 

    startQuizBgPicUrl = supabase.storage
      .from('aquaverse')
      .getPublicUrl('assets/images/quiz/Quiz_Background.jpg'); 

    playButtonUrl = supabase.storage
      .from('aquaverse')
      .getPublicUrl('assets/images/quiz/PlayButton.png'); 
  }

  Future<Map<String, dynamic>> _waitForSessionAndFetch() async {
  final client = Supabase.instance.client;

  // tunggu sampai session siap
  while (client.auth.currentUser == null) {
    await Future.delayed(const Duration(milliseconds: 100));
  }

  return fetchUserData();
}

  Future<Map<String, dynamic>> fetchUserData() async {
    
    final res = await supabase
        .from('profiles')
        .select('''
          username,
          name,
          user_rank (
            points, 
            ranks (
              id,
              name,
              min_points, 
              max_points,
              image_url
            )
          )
        ''')
        .eq('id', supabase.auth.currentUser!.id)
        .single();

    return res;
  }

  Future<List<Map<String, dynamic>>> fetchLeaderboardData() async {
    
    final res = await supabase
        .from('daily_leaderboard_view')
        .select(); 

    return res;
  }

  Future<Map<String, dynamic>> fetchAllData() async {
    final results = await Future.wait([
      fetchUserData(), 
      fetchLeaderboardData()
    ]); 

    return {
      'user': results[0], 
      'leaderboard': results[1]
    }; 
  }

  @override
  Widget build(BuildContext context) {
    Intl.defaultLocale = 'id_ID'; 
    DateTime now = DateTime.now(); 
    String formattedDate = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(now); 

    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchAllData(),
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(
              child: Text('Gagal memuat data pengguna'),
            );
          }

          final userData = snapshot.data!['user'] as Map<String, dynamic>;
          final username = userData['username'];
          final name = userData['name']; 
          final points = userData['user_rank']['points']; 

          final rankData = userData['user_rank']['ranks']; 
          final rankId = rankData['id']; 
          final rankName = rankData['name']; 
          final rankMaxPoint = rankData['max_points'] ?? 0; 
          final rankMinPoint = rankData['min_points']; 
          final imageFile = rankData['image_url']; 
          final String nextRankMessage; 
          final String pointIndicator; 
          final int nextRankPoint; 

          final double userProgress; 
          if(rankName == 'Ocean Sovereign' && rankId == 5){
            userProgress = 1; 
            nextRankMessage = 'Kau sudah di Rank tertinggi!'; 
            pointIndicator = '100++';  
          }
          else{
            userProgress = (points - rankMinPoint) / (rankMaxPoint - rankMinPoint + 1); 
            nextRankPoint = rankMaxPoint+1-points; 
            nextRankMessage = 'Hanya dalam $nextRankPoint poin lagi!'; 
            pointIndicator = '$points/$rankMaxPoint'; 
          }

          final leaderboardData = snapshot.data!['leaderboard'] as List<Map<String, dynamic>>; 

          final badgeUrl = supabase.storage
              .from('aquaverse')
              .getPublicUrl('assets/images/ranks/$imageFile'); 

          String nextBadgeUrl; 
          if(rankId == 1){
            nextBadgeUrl = supabase.storage
              .from('aquaverse')
              .getPublicUrl('assets/images/ranks/rank_2_star_voyager.png'); 
          }
          else if(rankId == 2){
            nextBadgeUrl = supabase.storage
              .from('aquaverse')
              .getPublicUrl('assets/images/ranks/rank_3_apex_swimmer.png'); 
          }
          else if(rankId == 3){
            nextBadgeUrl = supabase.storage
              .from('aquaverse')
              .getPublicUrl('assets/images/ranks/rank_4_abyss_guardian.png'); 
          }
          else{
            nextBadgeUrl = supabase.storage
              .from('aquaverse')
              .getPublicUrl('assets/images/ranks/rank_5_ocean_sovereign.png'); 
          }

          // Buat tau urutan leaderboard User 

          final user = Supabase.instance.client.auth.currentUser; 
          final currentUserId = user?.id; 
          final userIndex = leaderboardData.indexWhere(
            (user) => user['user_id'] == currentUserId, 
          ); 

          final int userRank = userIndex == -1 ? -1 : (userIndex + 1); 
          final String leaderboardMessage = userRank != -1 ? 
            "🏆 Kamu ada di Peringkat $userRank!" : "⌛ Ayo Segera Kerjakan Kuis!"; 
          
          return Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 115,
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
                  child: Row(
                    children: [
                      const SizedBox(width: 20),
                      Image.network(aquaVerseLogoUrl, height: 55),
                      const SizedBox(width: 15),
                      Image.network(quizLogoUrl, height: 27),
                    ],
                  ),
                ),
              ),

              const FrostedGlass(),

              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(top: 91),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 35),

                        ProfilPrestasi(
                          rankId: rankId,
                          username: username,
                          name: name,
                          points: points,
                          rankName: rankName,
                          rankMaxPoint: rankMaxPoint,
                          userProgress: userProgress,
                          badgeUrl: badgeUrl,
                          coinsUrl: coinsUrl, 
                          pointIndicator: pointIndicator,
                        ),
                        
                        const SizedBox(height: 20,), 

                        TingkatkanPoin(
                          nextBadgeUrl: nextBadgeUrl, 
                          nextRankMessage: nextRankMessage
                        ), 

                        const SizedBox(height: 15,), 
                        
                        Padding(
                          padding: EdgeInsetsGeometry.symmetric(horizontal: 20),
                          child: const Text("Selesaikan Kuis", style: TextStyle(
                            fontSize: 28, 
                            fontFamily: 'Montserrat',
                            height: 1.4,
                            fontWeight: FontWeight.bold, 
                            color: Color.fromRGBO(63, 68, 102, 1), 
                          ),), 
                        ),
                        
                        Padding(
                          padding: EdgeInsetsGeometry.symmetric(horizontal: 20), 
                          child: const Text("Raih Banyak Poin!", style: TextStyle(
                            fontSize: 22, 
                            fontFamily: 'Montserrat',
                            height: 1.0,
                            fontWeight: FontWeight.bold, 
                            color: Colors.black
                          ),),
                        ),

                        const SizedBox(height: 20,), 

                        MulaiKuis(
                          startQuizBgPicUrl: startQuizBgPicUrl, 
                          playButtonUrl: playButtonUrl
                        ), 
                        
                        Padding(
                          padding: EdgeInsetsGeometry.symmetric(horizontal: 20),
                          child: const Text("Peringkat Harian", style: TextStyle(
                            fontSize: 28, 
                            fontFamily: 'Montserrat',
                            height: 1.4,
                            fontWeight: FontWeight.bold, 
                            color: Color.fromRGBO(63, 68, 102, 1), 
                          ),), 
                        ),
                        
                        Padding(
                          padding: EdgeInsetsGeometry.symmetric(horizontal: 20), 
                          child: Text(formattedDate, style: TextStyle(
                            fontSize: 22, 
                            fontFamily: 'Montserrat',
                            height: 1.0,
                            fontWeight: FontWeight.bold, 
                            color: Colors.black
                          ),),
                        ),

                        const SizedBox(height: 25,), 

                        PodiumPeringkatHarian(
                          coinsUrl: coinsUrl, 
                          leaderboardData: leaderboardData, 
                          leaderboardMessage: leaderboardMessage
                        ), 

                        RunnerUpPeringkatHarian(
                          leaderboardData: leaderboardData, 
                        )
                      ],
                    ),
                  ),
                ),
              ),

            ],
          );
        },
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

class ProfilPrestasi extends StatelessWidget {
  final int rankId;
  final String username;
  final String name;
  final int points;
  final String rankName;
  final int rankMaxPoint;
  final double userProgress;
  final String badgeUrl;
  final String coinsUrl; 
  final String pointIndicator; 

  const ProfilPrestasi({
    super.key,
    required this.rankId,
    required this.username,
    required this.name,
    required this.points,
    required this.rankName,
    required this.rankMaxPoint,
    required this.userProgress,
    required this.badgeUrl,
    required this.coinsUrl, 
    required this.pointIndicator
  });

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width; 

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        height: 220,
        decoration: BoxDecoration(
          color: const Color.fromRGBO(217, 246, 252, 1),
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              offset: const Offset(0, 4),
              blurRadius: 8,
            )
          ]
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Row(
              children: const [
                SizedBox(width: 10),
                Icon(Icons.bar_chart_rounded,
                    size: 40,
                    color:
                        Color.fromRGBO(63, 68, 102, 1)),
                SizedBox(width: 8),
                Text(
                  "Profil Prestasi",
                  style: TextStyle(
                    fontSize: 22,
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.bold,
                    color:
                        Color.fromRGBO(63, 68, 102, 1),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 5),

            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20),
              child: Container(
                height: 145,
                padding: EdgeInsets.only(
                  left: 8, 
                  right: 10
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),

                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                  children: [

                    /// BADGE
                    Container(
                      height: 110,
                      width: 110,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image:
                              NetworkImage(badgeUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    /// INFO
                    Expanded(
                      child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
                          decoration: BoxDecoration(
                            color: Color.fromRGBO(148, 214, 245, 1),
                            borderRadius: BorderRadius.circular(10), 
                            
                          ),
                          child: Text('USN: $username',
                            style: const TextStyle(
                                fontSize: 13,
                                )),
                        ), 
                        const SizedBox(height: 1,), 
                        Text(name, style: TextStyle(
                          fontSize: 18, 
                          fontWeight: FontWeight.bold, 
                          )
                        ),
                        const SizedBox(height: 1,), 
                        Text('"$rankName"', style: TextStyle(
                          fontStyle: FontStyle.italic, 
                        ),),
                        const SizedBox(height: 8,), 

      
                        Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                        children: <Widget>[
                          Row(
                            children: [
                              Container(
                            width: 20, 
                            height: 20,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: NetworkImage(coinsUrl)
                              )
                            ),
                          ), 
                          Text('$points'), 
                            ],
                          ), 
                          Text(pointIndicator, style: TextStyle(
                            color: Color.fromRGBO(63, 68, 102, 1), 
                            fontWeight: FontWeight.bold
                          ),)
                        ],
                      ),
                        const SizedBox(height: 5,), 
                        SizedBox(
                          width: screenWidth * 0.42,
                          child: LinearProgressIndicator(
                            value: userProgress,
                            backgroundColor: Color.fromRGBO(148, 214, 245, 1), 
                            valueColor: AlwaysStoppedAnimation(Color.fromRGBO(30, 134, 185, 1)), 
                            minHeight: 10,
                          )
                        ), 
                      ],
                    ),
                    )
                  ],
                ),

              ),
            )
          ],
        ),
      ),
    ); 
  }
}

class TingkatkanPoin extends StatelessWidget {
  final String nextBadgeUrl; 
  final String nextRankMessage; 

  const TingkatkanPoin({
    super.key, 
    required this.nextBadgeUrl, 
    required this.nextRankMessage, 
  }); 

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width; 
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 40),
      child: Container(
            height: 70, 
            width: double.infinity, 
            decoration: BoxDecoration(
              color: Color.fromRGBO(148, 214, 245, 1), 
              borderRadius: BorderRadius.circular(15), 
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  offset: const Offset(0, 4),
                  blurRadius: 8,
                )
              ]
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center, 
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center, 
                  children: [
                    const Text('Naikkan Rank!', style: TextStyle(
                      fontFamily: 'Montserrat', 
                      fontWeight: FontWeight.bold, 
                      color: Color.fromRGBO(63, 68, 102, 1), 
                      fontSize: 18, 
                    ),),

                    SizedBox(
                      width: screenWidth * 0.43, 
                      height: 5, 
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.5), 
                          borderRadius: BorderRadius.circular(5)
                        ),
                      ),
                    ), 

                    Text(nextRankMessage, style: TextStyle(
                      fontSize: 13, 
                      fontStyle: FontStyle.italic
                    ),)
                  ],
                ), 
                const SizedBox(width: 15,),
                Container(
                  width: 60, 
                  height: 60, 
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(nextBadgeUrl), 
                      fit: BoxFit.cover
                    )
                  ),
                )
              ],
            ),
          ), 
    );
                
                
  }
}

class MulaiKuis extends StatelessWidget {
  final String startQuizBgPicUrl; 
  final String playButtonUrl; 

  const MulaiKuis({
    super.key, 
    required this.startQuizBgPicUrl, 
    required this.playButtonUrl
  }); 

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsGeometry.symmetric(horizontal: 20), 
      child: Container(
        width: double.infinity, 
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10), 
          image: DecorationImage(
            image: NetworkImage(startQuizBgPicUrl),  
            fit: BoxFit.cover, 
          )
        ),

        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 45),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const QuizFill(),
                    ),
                  );
                },
                child: Container(
                  height: 55,
                  width: 177,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Container(
                      height: 40,
                      width: 160,
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(148, 214, 245, 1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.network(
                            playButtonUrl,
                            height: 25,
                            width: 25,
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            "MULAI",
                            style: TextStyle(
                              fontSize: 24,
                              fontFamily: "Montserrat",
                              fontWeight: FontWeight.bold,
                              color: Color.fromRGBO(63, 68, 102, 1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

      ),
    ); 
  }
}

class PodiumPeringkatHarian extends StatelessWidget {
  final String coinsUrl; 
  final List<Map<String, dynamic>> leaderboardData; 
  final String leaderboardMessage; 

  const PodiumPeringkatHarian({
    super.key, 
    required this.coinsUrl, 
    required this.leaderboardData, 
    required this.leaderboardMessage
  }); 

  @override 
  Widget build(BuildContext context){

    final String firstPlaceUsername = leaderboardData[0]['username']; 
    final String secondPlaceUsername = leaderboardData[1]['username']; 
    final String thirdPlaceUsername = leaderboardData[2]['username']; 

    final int firstPlaceScore = leaderboardData[0]['score']; 
    final int secondPlaceScore = leaderboardData[1]['score']; 
    final int thirdPlaceScore = leaderboardData[2]['score']; 

    String badgePlaceholder = leaderboardData[0]['rank_img_url']; 
    final String firstPlaceBadgeUrl = Supabase.instance.client.storage
      .from('aquaverse').getPublicUrl('assets/images/ranks/$badgePlaceholder'); 

    badgePlaceholder = leaderboardData[1]['rank_img_url']; 
    final String secondPlaceBadgeUrl = Supabase.instance.client.storage
      .from('aquaverse').getPublicUrl('assets/images/ranks/$badgePlaceholder'); 
    
    badgePlaceholder = leaderboardData[2]['rank_img_url']; 
    final String thirdPlaceBadgeUrl = Supabase.instance.client.storage
      .from('aquaverse').getPublicUrl('assets/images/ranks/$badgePlaceholder'); 
    
    final leaderboardBubblesUrl = Supabase.instance.client.storage
      .from('aquaverse').getPublicUrl('assets/images/quiz/Leaderboard_Bubbles.png');


    return Stack(
        children: [
          Container(
            height: 450, 
            width: double.infinity, 
            decoration: BoxDecoration(
              color: const Color.fromRGBO(217, 246, 252, 1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30), 
                topRight: Radius.circular(30) 
              )
            ),
          ), 

          Padding(
            padding: EdgeInsetsGeometry.all(20), 
            child: Align(
              alignment: AlignmentGeometry.topRight, 
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white, 
                  borderRadius: BorderRadius.circular(10)
                ),
                child: Text(leaderboardMessage, style: TextStyle(
                  fontSize: 18, 
                  fontFamily: "Afacad", 
                  color: Colors.black
                ),),
              ), 
            ),
          ), 
          
          // Podium 2 
          Positioned(
            top: 230, 
            left: 0, 
            right: 240,
            bottom: 0, 
            child: Column(
              children: [
                Container(
                  width: 110, 
                  height: 220,
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(148, 214, 245, 1), 
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30), 
                      topRight: Radius.circular(30)
                    )
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: AlignmentGeometry.topCenter,
                    children: [
                      Positioned(
                        top: -50, 
                        child: Container(
                          height: 100, 
                          width: 100, 
                          decoration: BoxDecoration(
                            color: Colors.white, 
                            borderRadius: BorderRadius.circular(100)
                          ),
                          child: Center(
                            child: Container(
                              height: 90, 
                              width: 90, 
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: NetworkImage(secondPlaceBadgeUrl), 
                                  fit: BoxFit.cover
                                )
                              )
                            )
                          )
                        ),
                      ), 

                      Positioned(
                        top: -80, 
                        child: Text(secondPlaceUsername, style: TextStyle(
                          fontSize: 18, 
                          fontFamily: 'Afacad', 
                          color: Colors.black.withValues(alpha: 0.7)
                        ),),
                      ), 

                      Positioned(
                        top: 50, 
                        child: Text('2', style: TextStyle(
                          fontSize: 64, 
                          fontFamily: 'Montserrat', 
                          fontWeight: FontWeight.bold, 
                          color: Colors.white
                        ),),
                      ), 

                      Positioned(
                        top: 135, 
                        child: Text('$secondPlaceScore%', style: TextStyle(
                          fontSize: 24, 
                          fontFamily: 'Afacad', 
                          fontWeight: FontWeight.bold, 
                          color: Colors.white
                        ),),
                      )
                    ],
                  ),
                ), 
              ],
            ),
          ), 
          
          // Podium 1 
          Positioned(
            top: 180, 
            left: 0, 
            right: 0,
            bottom: 0, 
            child: Column(
              children: [
                Container(
                  width: 110, 
                  height: 270,
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(148, 214, 245, 1), 
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30), 
                      topRight: Radius.circular(30)
                    )
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: AlignmentGeometry.topCenter,
                    children: [
                      Positioned(
                        top: -50, 
                        child: Container(
                          height: 100, 
                          width: 100, 
                          decoration: BoxDecoration(
                            color: Colors.white, 
                            borderRadius: BorderRadius.circular(100)
                          ),
                          child: Center(
                            child: Container(
                              height: 90, 
                              width: 90, 
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: NetworkImage(firstPlaceBadgeUrl), 
                                  fit: BoxFit.cover
                                )
                              )
                            )
                          )
                        ),
                      ), 

                      Positioned(
                        top: -80, 
                        child: Text(firstPlaceUsername, style: TextStyle(
                          fontSize: 18, 
                          fontFamily: 'Afacad', 
                          color: Colors.black.withValues(alpha: 0.7)
                        ),),
                      ), 

                      Positioned(
                        top: 50, 
                        child: Text('1', style: TextStyle(
                          fontSize: 64, 
                          fontFamily: 'Montserrat', 
                          fontWeight: FontWeight.bold, 
                          color: Colors.white
                        ),),
                      ), 

                      Positioned(
                        top: 135, 
                        child: Text('$firstPlaceScore%', style: TextStyle(
                          fontSize: 24, 
                          fontFamily: 'Afacad', 
                          fontWeight: FontWeight.bold, 
                          color: Colors.white
                        ),),
                      )
                    ],
                  ),
                ), 
            
              ],
            ),
          ), 

          // Podium 3 
          Positioned(
            top: 280, 
            right: 0, 
            left: 240,
            bottom: 0, 
            child: Column(
              children: [
                Container(
                  width: 110, 
                  height: 170,
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(148, 214, 245, 1), 
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30), 
                      topRight: Radius.circular(30)
                    )
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: AlignmentGeometry.topCenter,
                    children: [
                      Positioned(
                        top: -50, 
                        child: Container(
                          height: 100, 
                          width: 100, 
                          decoration: BoxDecoration(
                            color: Colors.white, 
                            borderRadius: BorderRadius.circular(100)
                          ),
                          child: Center(
                            child: Container(
                              height: 90, 
                              width: 90, 
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: NetworkImage(thirdPlaceBadgeUrl), 
                                  fit: BoxFit.cover
                                )
                              )
                            )
                          )
                        ),
                      ), 

                      Positioned(
                        top: -80, 
                        child: Text(thirdPlaceUsername, style: TextStyle(
                          fontSize: 18, 
                          fontFamily: 'Afacad', 
                          color: Colors.black.withValues(alpha: 0.8)
                        ),),
                      ), 

                      Positioned(
                        top: 40, 
                        child: Text('3', style: TextStyle(
                          fontSize: 64, 
                          fontFamily: 'Montserrat', 
                          fontWeight: FontWeight.bold, 
                          color: Colors.white
                        ),),
                      ), 

                      Positioned(
                        top: 125, 
                        child: Text('$thirdPlaceScore%', style: TextStyle(
                          fontSize: 24, 
                          fontFamily: 'Afacad', 
                          fontWeight: FontWeight.bold, 
                          color: Colors.white
                        ),),
                      ), 
                    ],
                  ),
                ), 
              ],
            ),
          ), 

          Positioned(
            top: 30, 
            left: 10, 
            child: Container(
              height: 80, 
              width: 80, 
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(leaderboardBubblesUrl), 
                  fit: BoxFit.cover
                )
              ),
            ),
          )
        ],
    ); 
  }
}

class RunnerUpPeringkatHarian extends StatelessWidget {
  final List<Map<String, dynamic>> leaderboardData; 

  const RunnerUpPeringkatHarian({
    super.key, 
    required this.leaderboardData
  }); 

  @override
  Widget build(BuildContext context) {
    final bool hasRunnerUp = leaderboardData.length > 3; 

    final List<Map<String, dynamic>> remainings = hasRunnerUp ? 
      leaderboardData.sublist(3) : []; 

    return Stack(
      children: [
        Container(
          color: const Color.fromRGBO(217, 246, 252, 1),
          width: double.infinity, 
          height: 40,
        ), 
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity, 
              // height: 200,
              decoration: BoxDecoration(
                color: Colors.white, 
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30), 
                  topRight: Radius.circular(30)
                )
              ),
              padding: const EdgeInsets.all(10),
              child: hasRunnerUp ? 
                ListView.builder(
                  shrinkWrap: true, 
                  physics: NeverScrollableScrollPhysics(), 
                  itemCount: remainings.length, 
                  itemBuilder: (context, index) {
                    final item = remainings[index]; 
                    final String badgePlaceholder = item['rank_img_url']; 
                    final badgeUrl = Supabase.instance.client.storage
                      .from('aquaverse').getPublicUrl('assets/images/ranks/$badgePlaceholder'); 

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        // color: const Color(0xFFF5F5F5),
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Text(
                            "${index + 4}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20, 
                              fontFamily: 'Montserrat', 
                              color: Colors.black
                            ),
                          ),
                          const SizedBox(width: 15),

                          Container(
                            height: 55, 
                            width: 55, 
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: NetworkImage(badgeUrl)
                              )
                            ),
                          ), 

                          const SizedBox(width: 15), 

                          Expanded(
                            child: Text(item['username'] ?? '-', style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20, 
                              fontFamily: 'Afacad', 
                              color: Colors.black
                            ),),
                          ),
                          Container(
                            height: 35, 
                            width: 75, 
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color.fromRGBO(148, 214, 245, 1), 
                              borderRadius: BorderRadius.circular(20)
                            ),
                            child: Text("${item['score'] ?? 0}%", style: TextStyle(
                              fontSize: 20, 
                              fontFamily: 'Afacad', 
                              color: Colors.black
                          )),
                          )
                        ],
                      ),
                    ); 
                  },
                ) : 
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      "Tidak ada Runner Up pada Hari Ini",
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                        color: Colors.grey,
                      )
                    )
                  )
                )
            )
          ],
        )
      ],
    ); 
  }
}