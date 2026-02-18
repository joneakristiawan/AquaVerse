import 'package:flutter/material.dart'; 
import 'package:supabase_flutter/supabase_flutter.dart'; 
import 'quiz_fill.dart'; 
import 'display_page.dart'; 
import '../class_service/quest_service.dart';

class QuizResult extends StatefulWidget {
  final int totalQuestions;
  final int score; 

  const QuizResult({
    super.key,
    required this.totalQuestions,
    required this.score, 
  });

  @override
  State<QuizResult> createState() => _QuizResultState(); 
}


class _QuizResultState extends State<QuizResult> {
  final supabase = Supabase.instance.client;
  bool _hasInserted = false;

  @override
  void initState() {
    super.initState();
    _saveQuizAttempt();
  }

  Future<void> _saveQuizAttempt() async {
    if (_hasInserted) return;
    _hasInserted = true;

    final user = supabase.auth.currentUser;
    if (user == null) return;

    final percentageScore = (widget.score / widget.totalQuestions * 100).round();

    // Insert ke quiz_attempts
    try {
      await supabase.from('quiz_attempts').insert({
        'user_id': user.id,
        'score': percentageScore,
        'correct_count': widget.score,
        'total_questions': widget.totalQuestions,
      });
      debugPrint('Quiz attempt berhasil disimpan.');
    } catch (e) {
      debugPrint('Gagal menambahkan quiz_attempts: $e');
    }

    // Increment points & update rank
    try {
      final result = await supabase.rpc('increment_points_and_update_rank', params: {
        'p_user_id': user.id,
        'p_add_points': widget.score,
      });

      debugPrint('Points baru: $result');
    } catch (e, st) {
      debugPrint('Gagal menambahkan poin!: $e');
      debugPrint('$st');
    }

    try {
      await QuestService().trackPlayQuiz();
      debugPrint('Daily Quest Quiz berhasil di-update!');
    } catch (e) {
      debugPrint('Gagal update daily quest: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final String backgroundImgUrl = supabase.storage
      .from('aquaverse')
      .getPublicUrl('assets/images/quiz/QuizResult-Background.png');  
    
    final int incorrectScore = widget.totalQuestions - widget.score; 
    final int percentageScore = widget.score * 10; 

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Container(
            color: const Color.fromRGBO(217, 246, 252, 1),
          ),

          DisplayHeaderResult(
            percentageScore: percentageScore, 
            backgroundImgUrl: backgroundImgUrl
          ), 
          const FrostedGlass(), 

          ResultCard(
            totalQuestions: widget.totalQuestions, 
            incorrectScore: incorrectScore, 
            score: widget.score,
          ), 

          const SizedBox(height: 20), 

          Padding(
            padding: EdgeInsetsGeometry.only(top: 580),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity, 
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context, 
                      MaterialPageRoute(builder: (_) => QuizFill())
                    ); 
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromRGBO(148, 215, 247, 1), 
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  ),
                  child: Text('Kerjakan Ulang Kuis', style: TextStyle(
                    fontFamily: 'Afacad', 
                    fontSize: 20, 
                    height: 1.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black
                  )),
                ),
              ),
            ),
          ), 

          Padding(
            padding: EdgeInsetsGeometry.only(top: 655),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity, 
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DisplayPageWithQuizSelected(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white, 
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  ),
                  child: Text('Kembali ke Halaman Kuis', style: TextStyle(
                    fontFamily: 'Afacad', 
                    fontSize: 20, 
                    fontWeight: FontWeight.bold,
                    height: 1.0,
                    color: Colors.black
                  )),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

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

class DisplayHeaderResult extends StatelessWidget {
  final int percentageScore; 
  final String backgroundImgUrl; 

  const DisplayHeaderResult ({
    super.key, 
    required this.percentageScore, 
    required this.backgroundImgUrl
  }); 

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: 350,
      child: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(backgroundImgUrl),
            fit: BoxFit.cover,
            alignment: Alignment.bottomCenter
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(40),
            bottomRight: Radius.circular(40),
          ),
        ), 
        child: Center(
          child: Container(
            padding: EdgeInsets.all(15),
            height: 200, 
            width: 200, 
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6), 
              borderRadius: BorderRadius.circular(210)
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white, 
                borderRadius: BorderRadius.circular(210)
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center, 
                crossAxisAlignment: CrossAxisAlignment.center, 
                children: [
                  Text('Hasil', style: TextStyle(
                    fontSize: 28, 
                    fontFamily: 'Afacad', 
                    fontWeight: FontWeight.w600, 
                    height: 1.0,
                    color: Color.fromRGBO(28, 133, 153, 1)
                  )), 
                  // const SizedBox(height: 10), 
                  Text('$percentageScore%', style: TextStyle(
                    fontSize: 64, 
                    fontFamily: 'Afacad', 
                    height: 1.0,
                    fontWeight: FontWeight.bold,
                    color: Color.fromRGBO(28, 133, 153, 1)
                  )), 
                ],
              ),
            ),
          ),
        ),
      ),
    ); 
  }
}

class ResultCard extends StatelessWidget {
  final int totalQuestions, incorrectScore, score; 

  const ResultCard({
    super.key, 
    required this.totalQuestions, 
    required this.incorrectScore, 
    required this.score
  }); 

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      top: 255, 
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
        child: Container(
          padding: EdgeInsets.only(
            left: 20, 
            right: 20
          ),
          height: 240, 
          width: double.infinity, 
          decoration: BoxDecoration(
            color: Colors.white, 
            borderRadius: BorderRadius.circular(30), 
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15), 
                offset: const Offset(0, 4), 
                blurRadius: 8
              )
            ]
          ),
          child: Padding(
            padding: EdgeInsetsGeometry.only(left: 23), 
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, 
              crossAxisAlignment: CrossAxisAlignment.center,
              
              children: [
                Row(
                  children: [
                    Container(
                      height: 30, 
                      width: 30, 
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(28, 133, 153, 1), 
                        borderRadius: BorderRadius.circular(30)
                      ),
                    ),
                    const SizedBox(width: 15), 
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center, 
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('+$score', style: TextStyle(
                            fontSize: 32, 
                            fontFamily: 'Afacad', 
                            height: 1.0,
                            fontWeight: FontWeight.bold,
                            color: Color.fromRGBO(28, 133, 153, 1)
                          )), 
                          const SizedBox(height: 5), 
                          Text('Poin', style: TextStyle(
                            fontSize: 24, 
                            fontFamily: 'Afacad', 
                            height: 1.0,
                            fontWeight: FontWeight.w400,
                            color: Colors.black
                          )), 
                        ],
                      ),
                    ), 
                    
                    const SizedBox(width: 50,), 

                    Container(
                      height: 30, 
                      width: 30, 
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(28, 133, 153, 1), 
                        borderRadius: BorderRadius.circular(30)
                      ),
                    ),
                    const SizedBox(width: 15), 
                    Expanded(
                      child:   Column(
                        mainAxisAlignment: MainAxisAlignment.center, 
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$totalQuestions', style: TextStyle(
                            fontSize: 32, 
                            fontFamily: 'Afacad', 
                            height: 1.0,
                            fontWeight: FontWeight.bold,
                            color: Color.fromRGBO(28, 133, 153, 1)
                          )), 
                          const SizedBox(height: 5), 
                          Text('Soal', style: TextStyle(
                            fontSize: 24, 
                            fontFamily: 'Afacad', 
                            height: 1.0,
                            fontWeight: FontWeight.w400,
                            color: Colors.black
                          )), 
                        ],
                      )
                    )
                    
                  ],
                ), 
                const SizedBox(height: 30), 
                Row(
                  children: [
                    Container(
                      height: 30, 
                      width: 30, 
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(31, 132, 53, 1), 
                        borderRadius: BorderRadius.circular(30)
                      ),
                    ),
                    const SizedBox(width: 15), 
                    Expanded(
                      child:   Column(
                        mainAxisAlignment: MainAxisAlignment.center, 
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$score', style: TextStyle(
                            fontSize: 32, 
                            fontFamily: 'Afacad', 
                            height: 1.0,
                            fontWeight: FontWeight.bold,
                            color: Color.fromRGBO(31, 132, 53, 1), 
                          )), 
                          const SizedBox(height: 5), 
                          Text('Benar', style: TextStyle(
                            fontSize: 24, 
                            fontFamily: 'Afacad', 
                            height: 1.0,
                            fontWeight: FontWeight.w400,
                            color: Colors.black
                          )), 
                        ],
                      ),
                    ),
                    const SizedBox(width: 50,), 
                    Container(
                      height: 30, 
                      width: 30, 
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(208, 90, 4, 1), 
                        borderRadius: BorderRadius.circular(30)
                      ),
                    ),
                    const SizedBox(width: 15), 
                    Expanded(
                      child:   Column(
                        mainAxisAlignment: MainAxisAlignment.center, 
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$incorrectScore', style: TextStyle(
                            fontSize: 32, 
                            fontFamily: 'Afacad', 
                            height: 1.0,
                            fontWeight: FontWeight.bold,
                            color: Color.fromRGBO(208, 90, 4, 1)
                          )), 
                          const SizedBox(height: 5), 
                          Text('Salah', style: TextStyle(
                            fontSize: 24, 
                            fontFamily: 'Afacad', 
                            height: 1.0,
                            fontWeight: FontWeight.w400,
                            color: Colors.black
                          )), 
                        ],
                      ),
                    )
                  ],
                )
              ],
            ),
          )
        ),
      ),
    ); 
  }
}