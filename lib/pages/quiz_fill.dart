import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; 
import 'dart:async'; // Buat timer 
import 'quiz_result.dart'; 

class QuizFill extends StatefulWidget {
  const QuizFill({super.key}); 

  @override
  State<QuizFill> createState() => _QuizFillState(); 
}


class _QuizFillState extends State<QuizFill> {
  final supabase = Supabase.instance.client; 

  late final String quizBackgroundUrl; 

  late List<Map<String, dynamic>> questions;
  late final Future<List<Map<String, dynamic>>> quizFuture; 

  @override
  void initState(){
    super.initState(); 

    quizFuture = fetchQuizData(); 

    quizBackgroundUrl = supabase.storage
      .from('aquaverse')
      .getPublicUrl('assets/images/quiz/QuizFill-Background.png'); 
  }

  Future<List<Map<String, dynamic>>> fetchQuizData() async {
    final res = await supabase.rpc(
      'get_random_quiz_questions',
      params: {
        'quiz_uuid': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
        'question_limit': 10,
      },
    );

    questions = List<Map<String, dynamic>>.from(res);
    return questions; 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white, 
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: quizFuture, 
          builder: (context, snapshot) {
            if(snapshot.connectionState == ConnectionState.waiting){
              return const Center(child: CircularProgressIndicator()); 
            }
            if(snapshot.hasError){
              return Center(child: Text(snapshot.error.toString())); 
            }
            if(snapshot.hasError || !snapshot.hasData){
              return const Center(
                child: Text('Gagal memuat data kuis'),
              ); 
            }

            final quizData = snapshot.data!; 

            if(quizData.isEmpty){
              return const Center(
                child: Text('Soal tidak ditemukan!'),
              );
            }

            return BuildQuizUI(
              quizData: quizData, 
              total: questions.length, 
              quizBackgroundUrl: quizBackgroundUrl
            );
          }
        ),
    ); 
  }
}

class BuildQuizUI extends StatefulWidget {
  final List<dynamic> quizData; 
  final int total; 
  final String quizBackgroundUrl; 

  const BuildQuizUI({
    super.key, 
    required this.quizData, 
    required this.total, 
    required this.quizBackgroundUrl
  }); 

  @override
  State<BuildQuizUI> createState ()=> _BuildQuizState(); 
}

class _BuildQuizState extends State<BuildQuizUI> {
  int currentIndex = 0; 
  int? selectedChoiceIndex; 
  bool hasAnswered = false; 
  int score = 0; 
  bool isProcessing=false; 

  late int totalTime; 
  late ValueNotifier<int> remainingTimeNotifier; 
  Timer? timer; 

  @override
  void initState(){
    super.initState(); 
    _startQuestion(); 
  }

  void _startQuestion(){
    final question = widget.quizData[currentIndex]; 
    totalTime = question['time_limit'];
    remainingTimeNotifier = ValueNotifier<int>(totalTime); 

    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if(!mounted) return; 

      if(remainingTimeNotifier.value > 0){
        remainingTimeNotifier.value--; 
      }else{
        t.cancel(); 
        _submitAnswer(auto: true); 
      }
    });
  }

  void _submitAnswer({bool auto = false}) {
    // Update skor hanya jika user submit (auto=false)
    if (!auto && selectedChoiceIndex != null) {
      final selectedChoice =
          widget.quizData[currentIndex]['quiz_choices'][selectedChoiceIndex];
      if (selectedChoice['is_correct'] == true) score++;
    }

    timer?.cancel();

    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;

      if (currentIndex + 1 < widget.quizData.length) {
        setState(() {
          currentIndex++;
          selectedChoiceIndex = null;
          hasAnswered = false;
          isProcessing = false; 
        });
        _startQuestion(); // reset timer untuk soal baru
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => QuizResult(
              totalQuestions: widget.quizData.length,
              score: score,
            ),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel(); 
    remainingTimeNotifier.dispose(); 
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.quizData[currentIndex];
    final questionText = question['question_text'];
    final quizBackgroundUrl = widget.quizBackgroundUrl;
    final choices = question['quiz_choices'] ?? [];

    return SafeArea(
      child: Stack(
        children: [
          Container(color: const Color.fromRGBO(217, 246, 252, 1)),

          // Background image
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 260,
            child: Container(
              padding: const EdgeInsets.only(top: 40),
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(quizBackgroundUrl),
                  fit: BoxFit.cover,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
            ),
          ),

          const FrostedGlass(),

          // Content scrollable
          Positioned.fill(
            top: 55,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.topCenter,
                    clipBehavior: Clip.none,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 45),
                        child: ProgressAndQuestionCard(
                          questionText: questionText,
                          currentIndex: currentIndex,
                        ),
                      ),
                      Positioned(
                        top: 0,
                        child: ValueListenableBuilder<int>(
                          valueListenable: remainingTimeNotifier,
                          builder: (context, remainingTime, child) {
                            final progress = remainingTime / totalTime;
                            return QuestionNumber(
                              currentIndex: currentIndex,
                              progress: progress,
                              remainingTime: remainingTime,
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  ChoiceCard(
                    choices: choices,
                    selectedIndex: selectedChoiceIndex,
                    hasAnswered: hasAnswered,
                    onChoiceSelected: (index) {
                      if (!hasAnswered) {
                        setState(() {
                          selectedChoiceIndex = index;
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: () {
                      if (selectedChoiceIndex == null || isProcessing) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Pilih jawaban terlebih dahulu!')),
                        );
                        return;
                      }

                      setState(() {
                        hasAnswered = true;
                        isProcessing = true;
                      });

                      _submitAnswer();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 40, vertical: 7),
                    ),
                    child: const Text(
                      'Cek Jawaban',
                      style: TextStyle(
                        fontSize: 24,
                        fontFamily: 'Afacad',
                        fontWeight: FontWeight.w700,
                        color: Color.fromRGBO(118, 181, 193, 1),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
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

class ProgressAndQuestionCard extends StatelessWidget{
  final String questionText; 
  final int currentIndex; 

  const ProgressAndQuestionCard({
    super.key, 
    required this.questionText, 
    required this.currentIndex
  }); 

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, 
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(30), 
        boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: 0.15), 
          offset: const Offset(0, 4), 
          blurRadius: 8
        )]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center, 
        children: [
          const SizedBox(height: 60,), 
          
          Text('Soal No. ${currentIndex + 1}/10', style: TextStyle(
            fontSize: 20, 
            fontWeight: FontWeight.w400,
            fontFamily: "Afacad", 
            color: Color.fromRGBO(118, 181, 193, 1)
            )
          ),

          const SizedBox(height: 10,), 

          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20), 
            child: Text(questionText, textAlign: TextAlign.center, style: TextStyle(
              fontSize: 22, 
              fontWeight: FontWeight.w400,
              color: Colors.black
              )
            ),
          ), 

          const SizedBox(height: 25,)

        ],
      ),
    ); 
  }
}

class QuestionNumber extends StatelessWidget {
  final int currentIndex; 
  final double progress; 
  final int remainingTime; 

  const QuestionNumber({
    super.key, 
    required this.currentIndex, 
    required this.progress,
    required this.remainingTime
  }); 

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      width: 90, 
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(90), 
        color: const Color.fromRGBO(217, 246, 252, 1)
      ),
      child: Stack(
        alignment: Alignment.center, 
        children: [
          SizedBox(
            height: 70, 
            width: 70, 
            child: CircularProgressIndicator(
              value: progress, 
              strokeWidth: 5, 
              backgroundColor: Colors.white,
              valueColor: const AlwaysStoppedAnimation(
                Color.fromRGBO(63, 68, 102, 1)
              ),
            ), 
          ),
          Container(
            height: 34,
            width: 34,
            decoration: BoxDecoration(
              color: Colors.transparent,
              shape: BoxShape.circle,
            ),
          ),
          Text(
            '$remainingTime',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color.fromRGBO(63, 68, 102, 1), 
            ),
          ),
        ],
      ),
    );
  }
}

class ChoiceCard extends StatelessWidget {
  final List<dynamic> choices;  
  final int? selectedIndex; 
  final void Function(int index) onChoiceSelected; 
  final bool hasAnswered; 
  
  const ChoiceCard({
    super.key, 
    required this.choices, 
    required this.selectedIndex, 
    required this.onChoiceSelected, 
    required this.hasAnswered
  }); 

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 360, 
      width: double.infinity, 
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(30), 
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            offset: const Offset(0, 4),
            blurRadius: 8,
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(choices.length, (index) {
            // Konversi nilai DB menjadi bool murni
            final bool isCorrect = choices[index]['is_correct'] == true;

            return Padding(
              padding: EdgeInsets.only(
                bottom: index == choices.length - 1 ? 0 : 12,
              ),
              child: ChoiceTile(
                text: choices[index]['choice_text'],
                isSelected: selectedIndex == index,
                onTap: () => onChoiceSelected(index),
                hasAnswered: hasAnswered,
                isCorrect: isCorrect,        // jawaban ini benar menurut DB
              ),
            );
          }),
        ),
      ),
    );
  }
}

class ChoiceTile extends StatelessWidget {
  final String text; 
  final bool isSelected; 
  final VoidCallback onTap; 
  final bool hasAnswered; 
  final bool isCorrect; 

  const ChoiceTile({
    super.key, 
    required this.text, 
    required this.isSelected,
    required this.onTap,
    this.hasAnswered=false, 
    this.isCorrect=false,
  });

  @override
  Widget build(BuildContext context) {
    Color circleColor = Colors.white; 
    Color borderColor = Color.fromRGBO(118, 181, 193, 1); 

    if (hasAnswered) {
      if (isSelected) {
        circleColor = isCorrect ? Colors.green : Colors.red; 
        borderColor = isCorrect ? Colors.green : Colors.red; 
      } else if (isCorrect) {
        circleColor = Colors.green; 
        borderColor = Colors.green; 
      } else {
        circleColor = Colors.white;
        borderColor = Color.fromRGBO(118, 181, 193, 1);
      }
    } else if (isSelected) {
      // user pilih tapi belum dicek
      circleColor = const Color.fromRGBO(118, 181, 193, 1);
      borderColor = const Color.fromRGBO(118, 181, 193, 1);
    }

    return GestureDetector(
      onTap: hasAnswered ? null : onTap, 
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: borderColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    text,
                    softWrap: true,
                    style: const TextStyle(
                      fontSize: 20,
                      height: 1.2,
                      fontWeight: FontWeight.w400,
                      fontFamily: "Afacad",
                      color: Colors.black,
                    ),
                  ),
                ), 
                const SizedBox(width: 10), 
                Container(
                  height: 30, 
                  width: 30, 
                  padding: EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: borderColor,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250), 
                    curve: Curves.easeInOut, 
                    width: double.infinity, 
                    height: 5,
                    decoration: BoxDecoration(
                      color: circleColor,
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
