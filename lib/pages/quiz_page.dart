import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:supabase_flutter/supabase_flutter.dart'; 
import 'quiz_fill.dart'; 


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

    userFuture = fetchUserData();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<Map<String, dynamic>>(
        future: userFuture,
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(
              child: Text('Gagal memuat data pengguna'),
            );
          }

          final userData = snapshot.data!;
          final username = userData['username'];
          final name = userData['name']; 
          final points = userData['user_rank']['points']; 

          final rankData = userData['user_rank']['ranks']; 
          final rankId = rankData['id']; 
          final rankName = rankData['name']; 
          final rankMaxPoint = rankData['max_points']; 
          final rankMinPoint = rankData['min_points']; 
          final imageFile = rankData['image_url']; 
          final String nextRankMessage; 
          final int nextRankPoint; 

          final double userProgress; 
          if(rankName == 'Ocean Sovereign' && rankId == 5){
            userProgress = 1; 
            nextRankMessage = 'Kau sudah berada di Rank tertinggi!'; 
          }
          else{
            userProgress = (points - rankMinPoint) / (rankMaxPoint - rankMinPoint + 1); 
            nextRankPoint = rankMaxPoint+1-points; 
            nextRankMessage = 'Hanya dalam $nextRankPoint poin lagi!'; 
          }


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
                          coinsUrl: coinsUrl
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
                            fontSize: 32, 
                            fontFamily: 'Montserrat',
                            height: 1.4,
                            fontWeight: FontWeight.bold, 
                            color: Color.fromRGBO(63, 68, 102, 1), 
                          ),), 
                        ),
                        
                        Padding(
                          padding: EdgeInsetsGeometry.symmetric(horizontal: 20), 
                          child: const Text("Raih Banyak Poin!", style: TextStyle(
                            fontSize: 24, 
                            fontFamily: 'Montserrat',
                            height: 1.0,
                            fontWeight: FontWeight.bold, 
                            color: Colors.black
                          ),),
                        ),

                        const SizedBox(height: 15,), 

                        MulaiKuis(
                          startQuizBgPicUrl: startQuizBgPicUrl, 
                          playButtonUrl: playButtonUrl
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
  });

  @override
  Widget build(BuildContext context) {
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
                    fontSize: 25,
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
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 20),

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
                    Column(
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
                                fontSize: 14,
                                )),
                        ), 
                        const SizedBox(height: 1,), 
                        Text(name, style: TextStyle(
                          fontSize: 20, 
                          fontWeight: FontWeight.bold, 
                          )
                        ),
                        const SizedBox(height: 1,), 
                        Text('"$rankName"', style: TextStyle(
                          fontStyle: FontStyle.italic, 
                        ),),
                        const SizedBox(height: 8,), 
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end, 
                          children: <Widget>[
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
                            const SizedBox(width: 100,), 
                            Text('$points/$rankMaxPoint', style: TextStyle(
                              color: Color.fromRGBO(63, 68, 102, 1), 
                              fontWeight: FontWeight.bold
                            ),)
                          ],
                        ),
                        const SizedBox(height: 5,), 
                        SizedBox(
                          width: 162,
                          child: LinearProgressIndicator(
                            value: userProgress,
                            backgroundColor: Color.fromRGBO(148, 214, 245, 1), 
                            valueColor: AlwaysStoppedAnimation(Color.fromRGBO(30, 134, 185, 1)), 
                            minHeight: 10,
                          )
                        ), 
                      ],
                    ),
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
    required this.nextRankMessage
  }); 

  @override
  Widget build(BuildContext context) {
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
              children: [
                const SizedBox(width: 43,),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center, 
                  children: [
                    const Text('Naikkan Rank!', style: TextStyle(
                      fontFamily: 'Montserrat', 
                      fontWeight: FontWeight.bold, 
                      color: Color.fromRGBO(63, 68, 102, 1), 
                      fontSize: 20, 
                    ),),

                    SizedBox(
                      width: 180, 
                      height: 5, 
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.5), 
                          borderRadius: BorderRadius.circular(5)
                        ),
                      ),
                    ), 

                    Text(nextRankMessage, style: TextStyle(
                      fontSize: 15, 
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
        height: 250,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10), 
          image: DecorationImage(
            image: NetworkImage(startQuizBgPicUrl),  
            fit: BoxFit.cover
          )
        ),

        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 30),
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
                  height: 72,
                  width: 227,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Container(
                      height: 55,
                      width: 210,
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
                            height: 35,
                            width: 35,
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            "MULAI",
                            style: TextStyle(
                              fontSize: 26,
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