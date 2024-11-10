import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:async'; //타이머 패키지


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

  String questionId=""; //질문 ID를 저장할 변수 추가
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
          {'role': 'system', 'content': 'Ask your users short, thought-provoking questions in korean. just one sentence'},
          // {'role': 'user', 'content': 'What is Seoul?'}
        ],
        'max_tokens': 100,
      }),
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(utf8.decode(response.bodyBytes)); //한국어로 변경
      setState(() {
        question = data['choices'][0]['message']['content'] ?? '질문을 불러오는 데 실패했습니다';
        questionId = data['choices'][0]['id'] ?? 'UnknownID'; //questionId를 데이터에서 받아와서 저장
        print('API sucess: $question'); // 로그 추가
      });
      await _saveQuestionToDB(question);
    } else {
      setState(() {
        question = 'Error: ${response.reasonPhrase}';
        print('API fail: ${response.reasonPhrase}'); // 로그 추가
      });
    }
  }


  Future<void> _saveQuestionToDB(String question) async {
    final response = await http.post(
      Uri.parse('http://127.0.0.1:8000/api/save_question/'), // Django 서버 URL로 변경
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'question': question}),
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      print('Question saved successfully with ID: ${data['id']}');
    } else {
      print('Failed to save question: ${response.reasonPhrase}');
    }
  }

  Future<void> _saveAnswerToDB(String question, String answer) async {
    final response = await http.post(
      Uri.parse('http://127.0.0.1:8000/api/save_answer/'), // Django 서버의 URL로 수정
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'question_id': questionId, 'answer': answer}),
    );

    if (response.statusCode == 200) {
      print('Answer saved successfully');
    } else {
      print('Failed to save answer: ${response.reasonPhrase}');
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
          color: Colors.black, // 앱바 아이콘 색상
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
                  borderSide: BorderSide(color: Color.fromARGB(255, 255, 207, 102)),
                ),
              ),
            ),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: () async { // async를 추가한 람다 함수
                print('Question: $question');
                print('Answer: $answer');

                // 서버로 답변 저장 요청
                await _saveAnswerToDB(questionId, answer);

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
                            Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false); // HomeScreen으로 돌아가기
                          },
                          child: Text('확인'),
                        ),
                      ],
                    );
                  },
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 255, 207, 102), // 버튼 색상
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
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
