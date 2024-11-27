import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'quiz_summary_screen.dart';

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
  List<Map<String, dynamic>> questionResults = [];

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
    final currentQuestion = questions[currentQuestionIndex];
    questionResults.add({
      'question': currentQuestion['question'],
      'userAnswer': 'No Answer',
      'correctAnswer': currentQuestion['correct_answer'],
      'isCorrect': false,
    });

    moveToNextQuestion();
  }

  void checkAnswer(String selectedOption) {
    timer.cancel();
    final currentQuestion = questions[currentQuestionIndex];
    final correctAnswer = currentQuestion['correct_answer'];
    final isCorrect = selectedOption == correctAnswer;

    setState(() {
      if (isCorrect) score++;
      feedback = isCorrect ? 'Correct!' : 'Incorrect! The correct answer is $correctAnswer.';
      showFeedback = true;

      // Store result
      questionResults.add({
        'question': currentQuestion['question'],
        'userAnswer': selectedOption,
        'correctAnswer': correctAnswer,
        'isCorrect': isCorrect,
      });
    });

    Future.delayed(Duration(seconds: 2), moveToNextQuestion);
  }

  void moveToNextQuestion() {
    setState(() {
      showFeedback = false;

      if (currentQuestionIndex < questions.length - 1) {
        currentQuestionIndex++;
        timeRemaining = 15;
        startTimer();
      } else {
        timer.cancel();
        navigateToSummary();
      }
    });
  }

  void navigateToSummary() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => QuizSummaryScreen(
          score: score,
          questionResults: questionResults,
          onRetakeQuiz: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => QuizScreen(
                  numberOfQuestions: widget.numberOfQuestions,
                  category: widget.category,
                  difficulty: widget.difficulty,
                  type: widget.type,
                ),
              ),
            );
          },
          onGoToSetup: () {
            Navigator.pop(context);
          },
        ),
      ),
    );
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

    // Calculate progress
    double progress = (currentQuestionIndex + 1) / questions.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress Indicator
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            SizedBox(height: 10),
            Text(
              'Question ${currentQuestionIndex + 1} of ${questions.length}',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),

            // Score and Timer
            Text('Score: $score', style: TextStyle(fontSize: 20)),
            SizedBox(height: 10),
            Text('Time Remaining: $timeRemaining seconds', style: TextStyle(fontSize: 20, color: Colors.red)),
            SizedBox(height: 20),

            // Question
            Text(currentQuestion['question'], style: TextStyle(fontSize: 18)),
            SizedBox(height: 20),

            // Options
            ...currentOptions.map((option) {
              return ElevatedButton(
                onPressed: () => checkAnswer(option),
                child: Text(option),
              );
            }).toList(),

            // Feedback
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
