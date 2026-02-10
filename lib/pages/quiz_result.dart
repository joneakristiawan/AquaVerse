import 'package:flutter/material.dart';
import 'quiz_page.dart'; 

class QuizResult extends StatelessWidget {
  final int totalQuestions;
  final int score;

  const QuizResult({
    super.key,
    required this.totalQuestions,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Quiz Selesai!',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text(
              'Skor kamu: $score / $totalQuestions',
              style: TextStyle(fontSize: 28, color: Colors.green),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => Navigator.pushReplacement(
                context, 
                MaterialPageRoute(
                  builder: (_) => QuizPage()
                )
              ), // kembali ke halaman utama
              child: const Text('Kembali ke Home'),
            )
          ],
        ),
      ),
    );
  }
}
