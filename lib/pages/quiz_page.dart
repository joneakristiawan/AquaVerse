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
            nextRankMessage = 'Kau sudah berada di Rank tertinggi!'; 
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
                          coinsUrl: coinsUrl
                        ), 
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

  const PodiumPeringkatHarian({
    super.key, 
    required this.coinsUrl
  }); 

  @override 
  Widget build(BuildContext context){

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
                child: Text('🏆 Kamu ada di Peringkat 3!', style: TextStyle(
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
                  width: 100, 
                  height: 220,
                  decoration: BoxDecoration(
                    color: Colors.green, 
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30), 
                      topRight: Radius.circular(30)
                    )
                  ),
                )
              ],
            ),
          ), 
          
          // Podium 1 
          Positioned(
            top: 180, 
            left: 0, 
            right: 10,
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
                        ),
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
            left: 230,
            bottom: 0, 
            child: Column(
              children: [
                Container(
                  width: 110, 
                  height: 170,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30), 
                      topRight: Radius.circular(30)
                    )
                  ),
                )
              ],
            ),
          )
        ],
    ); 
  }
}

class PodiumItem extends StatelessWidget {
  final int rank;
  final double height;
  final String percent;

  const PodiumItem({
    super.key,
    required this.rank,
    required this.height,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        CircleAvatar(
          radius: 30,
          child: Text("$rank"),
        ),
        const SizedBox(height: 8),
        Container(
          height: height,
          decoration: BoxDecoration(
            color: Colors.blue.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "$rank",
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(percent),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
