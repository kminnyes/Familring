

//매일 질문 생성되도록 하는 코드
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'answer_question_screen.dart';

class QuestionListScreen extends StatefulWidget {
  @override
  _QuestionListScreenState createState() => _QuestionListScreenState();
}

class _QuestionListScreenState extends State<QuestionListScreen> {
  List<Map<String, String>> questionsAndAnswers = [];

  @override
  void initState() {
    super.initState();
    fetchDailyQuestion();  // 앱 시작 시 매일 질문을 가져오는 함수 호출
  }

  // 서버에서 질문을 받아와 리스트에 추가하는 함수
  Future<void> fetchDailyQuestion() async {
    final response = await http.get(Uri.parse('http://localhost:8000/generate_question/'));

    if (response.statusCode == 200) {
      setState(() {
        // 서버에서 받아온 질문을 리스트에 추가
        questionsAndAnswers.add({
          'question': json.decode(response.body)['question'],
          'answer': ''  // 아직 답변은 비워둠
        });
      });
    } else {
      print('Failed to load question. Status code: ${response.statusCode}');
    }
  }

  void addQuestionAnswerPair(String question, String answer) {
    setState(() {
      questionsAndAnswers.add({'question': question, 'answer': answer});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Familring List'),
        backgroundColor: Colors.orange,
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