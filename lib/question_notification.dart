import 'package:familring2/todayquestion.dart';
import 'package:flutter/material.dart';

class QuestionNotification extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0, // 앱바의 그림자를 제거
        iconTheme: IconThemeData(
          color: Colors.black, // 앱바 아이콘 색상
        ),
      ),
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 70.0), // 이미지에 좌우 여백 추가
                  child: Image.asset(
                    'images/main_icon.png',
                    fit: BoxFit.contain,
                    width: 200,  // 이미지의 고정 너비
                    height: 200, // 이미지의 고정 높이
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  '오늘의 질문이 도착 했어요!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    text: '하루의 하나, ',
                    style: TextStyle(fontSize: 19, color: Colors.amber, fontWeight: FontWeight.bold),
                    children: [
                      TextSpan(
                        text: '질문에 답변 하면서 가족을\n 더욱 알아 가는 시간을 가져 보세요.',
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.normal),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 60),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => TodayQuestion()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 255, 207, 102), // 버튼 색상
                    padding: EdgeInsets.symmetric(horizontal: 70, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    '답변 하러 가기',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
