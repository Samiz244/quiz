import 'package:flutter/material.dart';

class QuizSummaryScreen extends StatelessWidget {
  final int score;
  final List<Map<String, dynamic>> questionResults;
  final VoidCallback onRetakeQuiz;
  final VoidCallback onGoToSetup;

  QuizSummaryScreen({
    required this.score,
    required this.questionResults,
    required this.onRetakeQuiz,
    required this.onGoToSetup,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Quiz Summary')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Score: $score/${questionResults.length}',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(
              'Summary:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: questionResults.length,
                itemBuilder: (context, index) {
                  final result = questionResults[index];
                  final isCorrect = result['isCorrect'];
                  return ListTile(
                    title: Text(result['question']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Your Answer: ${result['userAnswer']}'),
                        Text('Correct Answer: ${result['correctAnswer']}'),
                      ],
                    ),
                    trailing: Icon(
                      isCorrect ? Icons.check : Icons.close,
                      color: isCorrect ? Colors.green : Colors.red,
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: onRetakeQuiz,
                  child: Text('Retake Quiz'),
                ),
                ElevatedButton(
                  onPressed: onGoToSetup,
                  child: Text('Adjust Settings'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
