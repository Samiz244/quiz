import 'dart:async';
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
  late Timer timer;
  int timeRemaining = 15;

  // Pre-shuffled options for each question
  List<List<String>> options = [];

  @override
  void initState() {
    super.initState();
    fetchQuestions();
  }

  Future<void> fetchQuestions() async {
    final url =
        'https://opentdb.com/api.php?amount=${widget.numberOfQuestions}&category=${widget.category}&difficulty=${widget.difficulty}&type=${widget.type}';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          questions = data['results'];

          // Pre-shuffle the options for each question
          options = questions.map<List<String>>((question) {
            final List<String> allOptions = List<String>.from(question['incorrect_answers']);
            allOptions.add(question['correct_answer']);
            allOptions.shuffle(); // Shuffle only once when questions are fetched
            return allOptions;
          }).toList();
        });
        startTimer();
      } else {
        throw Exception('Failed to load questions.');
      }
    } catch (e) {
      print('Error fetching questions: $e');
    }
  }

  void startTimer() {
    timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (timeRemaining > 0) {
          timeRemaining--;
        } else {
          timer.cancel();
          timeUp();
        }
      });
    });
  }

  void timeUp() {
    setState(() {
      feedback = 'Time\'s up! The correct answer is ${questions[currentQuestionIndex]['correct_answer']}.';
      showFeedback = true;
    });

    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        showFeedback = false;
        if (currentQuestionIndex < questions.length - 1) {
          currentQuestionIndex++;
          timeRemaining = 15;
          startTimer();
        } else {
          feedback = 'Quiz Completed! Final Score: $score/${questions.length}';
        }
      });
    });
  }

  void checkAnswer(String selectedOption) {
    timer.cancel();
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
          timeRemaining = 15;
          startTimer();
        } else {
          feedback = 'Quiz Completed! Final Score: $score/${questions.length}';
        }
      });
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
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
    final List<String> currentOptions = options[currentQuestionIndex];

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
            Text('Time Remaining: $timeRemaining seconds', style: TextStyle(fontSize: 20, color: Colors.red)),
            SizedBox(height: 20),
            Text(currentQuestion['question'], style: TextStyle(fontSize: 18)),
            SizedBox(height: 20),
            ...currentOptions.map((option) {
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
