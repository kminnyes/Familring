import 'package:flutter/material.dart';
import 'answer_question_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class QuestionListScreen extends StatefulWidget {
  @override
  _QuestionListScreenState createState() => _QuestionListScreenState();
}

class _QuestionListScreenState extends State<QuestionListScreen> {
  List<Map<String, dynamic>> questionsAndAnswers = [];

  @override
  void initState() {
    super.initState();
    fetchQuestions();
  }

  // Django 서버에서 질문 리스트 가져오는 함수
  Future<void> fetchQuestions() async {
    try {
      final response = await http.get(Uri.parse('http://127.0.0.1:8000/api/question_list/')); // Django 서버의 실제 IP 사용

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        setState(() {
          questionsAndAnswers = data
              .map((question) => {'question': question['question'], 'answer': ''})
              .toList();
        });
      } else {
        print('Failed to load questions: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error fetching questions: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 18.0, top: 10.0),
          child: SizedBox(
            width: 42,
            height: 42,
            child: Image.asset(
              'images/appbaricon.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: questionsAndAnswers.length,
          itemBuilder: (context, index) {
            final qa = questionsAndAnswers[index];
            return ListTile(
              title: Text(
                '#${index + 1} ${qa['question']}',
                style: TextStyle(color: Colors.orange),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AnswerQuestionScreen(question: qa['question']!),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
