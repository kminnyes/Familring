import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AnswerQuestionScreen extends StatefulWidget {
  final String question;
  final int questionId;

  AnswerQuestionScreen({required this.question, required this.questionId});

  @override
  _AnswerQuestionScreenState createState() => _AnswerQuestionScreenState();
}

class _AnswerQuestionScreenState extends State<AnswerQuestionScreen> {
  String answer = "";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAnswer();  // 화면 초기화 시 답변 불러오기
  }

  Future<void> _fetchAnswer() async {
    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/get_answer/${widget.questionId}/'), // Django 서버 URL
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          answer = data['answer'];
          isLoading = false;
        });
      } else {
        print('Failed to fetch answer: ${response.reasonPhrase}');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching answer: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _saveAnswerToDB() async {
    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/api/save_answer/'), // Django 서버 URL
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'question_id': widget.questionId,
          'answer': answer,
        }),
      );

      if (response.statusCode == 200) {
        print('Answer saved successfully');
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('알림'),
              content: Text('답변이 등록되었습니다.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // 다이얼로그 닫기
                    Navigator.pop(context); // 이전 화면으로 돌아가기
                  },
                  child: Text('확인'),
                ),
              ],
            );
          },
        );
      } else {
        print('Failed to save answer: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error saving answer: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('질문에 답하기'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Q. ${widget.question}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            TextField(
              onChanged: (text) {
                setState(() {
                  answer = text;
                });
              },
              maxLines: 5,
              decoration: InputDecoration(
                hintText: '답변을 입력해주세요...',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _saveAnswerToDB();
              },
              child: Text('답변 등록하기'),
            ),
            SizedBox(height:40),
            isLoading
                ? CircularProgressIndicator()  // 로딩 중일 때 로딩 표시
                : Text(
              'A. $answer',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}