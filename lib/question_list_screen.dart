import 'package:flutter/material.dart';
import 'answer_question_screen.dart';

class QuestionListScreen extends StatefulWidget {
  @override
  _QuestionListScreenState createState() => _QuestionListScreenState();
}

class _QuestionListScreenState extends State<QuestionListScreen> {
  List<Map<String, String>> questionsAndAnswers = [
    {'question': '가장 최근에 읽은 책은?', 'answer': ''},
    {'question': '가장 좋아하는 과일은?', 'answer': ''},
    {'question': '가장 여행 가고 싶은 나라는?', 'answer': ''},
  ];

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
