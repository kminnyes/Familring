import 'package:flutter/material.dart';
import 'answer_question_screen.dart';

class QuestionListScreen extends StatefulWidget {
  @override
  _QuestionListScreenState createState() => _QuestionListScreenState();
}

class _QuestionListScreenState extends State<QuestionListScreen> {
  List<Map<String, String>> questionsAndAnswers = [
    {'question': '가장 최근에 읽은 책은?', 'answer': ''},
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