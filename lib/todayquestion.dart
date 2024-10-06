import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
//import 'package:openai_client/openai_client.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class TodayQuestion extends StatefulWidget {
  @override
  _TodayQuestionState createState() => _TodayQuestionState();
}

class _TodayQuestionState extends State<TodayQuestion> {
  String question = "...Loading?"; // 질문
  String answer = ""; // 답변

  @override
  void initState() {
    super.initState();
    _openAi();
  }


  Future<void> _openAi() async {
    final apiKey = dotenv.env['OPENAI_API_KEY']!;
    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-3.5-turbo',
        'messages': [
          {'role': 'system', 'content': 'You are a helpful assistant. Ask your users short, thought-provoking questions in korean'},
          // {'role': 'user', 'content': 'What is Seoul?'}
        ],
        'max_tokens': 100,
      }),
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(utf8.decode(response.bodyBytes)); //한국어로 변경
      setState(() {
        question = data['choices'][0]['message']['content'];
      });
    } else {
      setState(() {
        question = 'Error: ${response.reasonPhrase}';
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('#두 번째 질문'),
        backgroundColor: Colors.white,
        elevation: 0, // 앱바의 그림자를 제거
        iconTheme: IconThemeData(
          color: Colors.orange, // 앱바 아이콘 색상
        ),
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              'Q. $question',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.left,
            ),
            SizedBox(height: 40),
            Text(
              'A.',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.left,
            ),
            SizedBox(height: 10),
            TextField(
              onChanged: (text) {
                setState(() {
                  answer = text;
                });
              },
              maxLines: 10,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(color: Colors.orange),
                ),
              ),
            ),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                // 답변 저장 로직 추가 가능
                // 예: 서버로 전송 또는 로컬 저장
                print('Question: $question');
                print('Answer: $answer');

                // 알림을 표시하고 TodayQuestion과 QuestionNotification 화면을 pop하여 HomeScreen으로 전환
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
                            Navigator.pushNamedAndRemoveUntil(context, '/home', (route)=>false); // HomeScreen으로 돌아가기
                          },
                          child: Text('확인'),
                        ),
                      ],
                    );
                  },
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
                '답변 등록하기',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),


          ],

        ),
      ),
    );
  }
}