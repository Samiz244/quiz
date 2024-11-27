import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'quiz_screen.dart';

class QuizSetupScreen extends StatefulWidget {
  @override
  _QuizSetupScreenState createState() => _QuizSetupScreenState();
}

class _QuizSetupScreenState extends State<QuizSetupScreen> {
  List<dynamic> categories = [];
  String? selectedCategory;
  String? selectedDifficulty = 'easy';
  String? selectedType = 'multiple';
  int selectedNumberOfQuestions = 5;

  Future<void> fetchCategories() async {
    try {
      final url = Uri.parse('https://opentdb.com/api_category.php');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          categories = data['trivia_categories'];
          selectedCategory = categories.isNotEmpty ? categories.first['id'].toString() : null;
        });
      } else {
        throw Exception('Failed to load categories: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  void startQuiz() {
    print('Number of Questions: $selectedNumberOfQuestions');
    print('Category: $selectedCategory');
    print('Difficulty: $selectedDifficulty');
    print('Type: $selectedType');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizScreen(
          numberOfQuestions: selectedNumberOfQuestions,
          category: selectedCategory,
          difficulty: selectedDifficulty,
          type: selectedType,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Quiz Setup')),
      body: categories.isEmpty
          ? Center(
              child: Text(
                'Loading categories...',
                style: TextStyle(fontSize: 16),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Number of Questions
                  Text('Number of Questions:', style: TextStyle(fontSize: 16)),
                  DropdownButton<int>(
                    value: selectedNumberOfQuestions,
                    onChanged: (value) {
                      setState(() {
                        selectedNumberOfQuestions = value!;
                      });
                    },
                    items: [5, 10, 15]
                        .map((num) => DropdownMenuItem(value: num, child: Text('$num')))
                        .toList(),
                  ),
                  SizedBox(height: 16),

                  // Category
                  Text('Category:', style: TextStyle(fontSize: 16)),
                  DropdownButton<String>(
                    value: selectedCategory,
                    onChanged: (value) {
                      setState(() {
                        selectedCategory = value!;
                      });
                    },
                    items: categories.map((cat) {
                      return DropdownMenuItem(
                        value: cat['id'].toString(),
                        child: Text(cat['name']),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 16),

                  // Difficulty
                  Text('Difficulty:', style: TextStyle(fontSize: 16)),
                  DropdownButton<String>(
                    value: selectedDifficulty,
                    onChanged: (value) {
                      setState(() {
                        selectedDifficulty = value!;
                      });
                    },
                    items: ['easy', 'medium', 'hard']
                        .map((diff) => DropdownMenuItem(value: diff, child: Text(diff)))
                        .toList(),
                  ),
                  SizedBox(height: 16),

                  // Question Type
                  Text('Question Type:', style: TextStyle(fontSize: 16)),
                  DropdownButton<String>(
                    value: selectedType,
                    onChanged: (value) {
                      setState(() {
                        selectedType = value!;
                      });
                    },
                    items: ['multiple', 'boolean']
                        .map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(type == 'multiple' ? 'Multiple Choice' : 'True/False'),
                            ))
                        .toList(),
                  ),
                  SizedBox(height: 24),

                  ElevatedButton(onPressed: startQuiz, child: Text('Start Quiz')),
                ],
              ),
            ),
    );
  }
}
