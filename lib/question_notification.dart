import 'package:familring2/todayquestion.dart';
import 'package:flutter/material.dart';


class QuestionNotification extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('오늘의 질문'),
        backgroundColor: Colors.white,
        elevation: 0, // 앱바의 그림자를 제거
        iconTheme: IconThemeData(
          color: Colors.black, // 앱바 아이콘 색상
        ),
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('images/question.png'), // 이미지 경로
            SizedBox(height: 20),
            Text(
              '오늘의 질문이 도착 했어요!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            Text(
              '하루의 하나, 질문에 답변 하면서\n가족을 더욱 알아 가는 시간을 가져 보세요.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TodayQuestion()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange, // 버튼 색상
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                '답변 하러 가기',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}