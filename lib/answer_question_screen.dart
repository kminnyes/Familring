import 'package:flutter/material.dart';

class AnswerQuestionScreen extends StatelessWidget {
  final String question;

  AnswerQuestionScreen({required this.question});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 18.0, top: 10.0), // 위쪽 여백 추가
          child: SizedBox(
            width: 42, // 이미지 크기 조정
            height: 42,
            child: Image.asset(
              'images/appbaricon.png', // 이미지 파일 경로
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Q. $question',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            TextField(
              decoration: InputDecoration(
                hintText: '답변을 입력해주세요...',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // 답변 제출 로직
              },
              child: Text('답변 등록하기'),
              style: ElevatedButton.styleFrom(backgroundColor: Color.fromARGB(255, 255, 207, 102),
            ),
            )],
        ),
      ),
    );
  }
}

