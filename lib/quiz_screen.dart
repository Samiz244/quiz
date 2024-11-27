import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class QuizScreen extends StatefulWidget {
  final int numberOfQuestions;
  final String? category;
  final String? difficulty;
  final String? type;

  QuizScreen({
    required this.numberOfQuestions,
    required this.category,
    required this.difficulty,
    required this.type,
  });

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<dynamic> questions = [];
  int currentQuestionIndex = 0;
  int score = 0;
  String feedback = '';
  bool showFeedback = false;

  Future<void> fetchQuestions() async {
    final url =
        'https://opentdb.com/api.php?amount=${widget.numberOfQuestions}&category=${widget.category}&difficulty=${widget.difficulty}&type=${widget.type}';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          questions = data['results'];
        });
      } else {
        throw Exception('Failed to load questions.');
      }
    } catch (e) {
      print('Error fetching questions: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchQuestions();
  }

  void checkAnswer(String selectedOption) {
    final correctAnswer = questions[currentQuestionIndex]['correct_answer'];
    setState(() {
      if (selectedOption == correctAnswer) {
        score++;
        feedback = 'Correct!';
      } else {
        feedback = 'Incorrect! The correct answer is $correctAnswer.';
      }
      showFeedback = true;
    });

    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        showFeedback = false;
        if (currentQuestionIndex < questions.length - 1) {
          currentQuestionIndex++;
        } else {
          feedback = 'Quiz Completed! Final Score: $score/${questions.length}';
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('Quiz')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final currentQuestion = questions[currentQuestionIndex];
    final List<String> options = List<String>.from(currentQuestion['incorrect_answers']);

    // Add the correct answer and shuffle the options
    options.add(currentQuestion['correct_answer']);
    options.shuffle();

    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Score: $score', style: TextStyle(fontSize: 20)),
            SizedBox(height: 20),
            Text(currentQuestion['question'], style: TextStyle(fontSize: 18)),
            SizedBox(height: 20),
            ...options.map((option) {
              return ElevatedButton(
                onPressed: () => checkAnswer(option),
                child: Text(option),
              );
            }).toList(),
            if (showFeedback)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(
                  feedback,
                  style: TextStyle(
                    fontSize: 16,
                    color: feedback.startsWith('Correct') ? Colors.green : Colors.red,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
