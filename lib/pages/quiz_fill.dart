import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; 

class QuizFill extends StatefulWidget {
  const QuizFill({super.key}); 

  @override
  State<QuizFill> createState() => _QuizFillState(); 
}


class _QuizFillState extends State<QuizFill> {
  final supabase = Supabase.instance.client; 

  late final String quizBackgroundUrl; 

  @override
  void initState(){
    super.initState(); 

    quizBackgroundUrl = supabase.storage
      .from('aquaverse')
      .getPublicUrl('assets/images/quiz/QuizFill-Background.png'); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [

          Container(
            color: const Color.fromRGBO(217, 246, 252, 1),
          ), 

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
                  fit: BoxFit.cover
                ),

                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40), 
                  bottomRight: Radius.circular(40)
                ),

                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    offset: const Offset(0, 4),
                    blurRadius: 8,
                  )
                ],
              ),
            )
          ), 

          const FrostedGlass(),

          Positioned(
            top: 150,
            left: 20, 
            right: 20, 
            child: ProgressAndQuestionCard(),
          ), 

          Positioned(
            top: 130, 
            left: 20, 
            right: 20, 
            child: QuestionNumber(),
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

class ProgressAndQuestionCard extends StatelessWidget{
  const ProgressAndQuestionCard({super.key}); 

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 210, 
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
    ); 
  }
}

class QuestionNumber extends StatelessWidget {
  const QuestionNumber({super.key}); 

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      width: 40, 
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40), 
        color: Colors.red
      ),
    );
  }
}