import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TodayQuestion extends StatefulWidget {
  @override
  _TodayQuestionState createState() => _TodayQuestionState();
}

class _TodayQuestionState extends State<TodayQuestion> {
  String question = "...Loading?"; // 질문
  String answer = ""; // 답변
  String questionId = ""; // 질문 ID
  int? familyId; // family_id 변수 추가
  int? userId; // user_id 변수 추가

  @override
  void initState() {
    super.initState();
    _loadUserIdAndFamilyId().then((_) {
      _openAi(); // userId와 familyId가 로드된 후에 질문을 생성
    });
  }

  Future<void> _loadUserIdAndFamilyId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getInt('user_id');
      familyId = prefs.getInt('family_id');
      print('User ID loaded: $userId');
      print('Family ID loaded: $familyId');
    });
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
          {'role': 'system', 'content': 'Ask your users short, thought-provoking questions in Korean. Just one sentence.'}
        ],
        'max_tokens': 100,
      }),
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(utf8.decode(response.bodyBytes));
      setState(() {
        question = data['choices'][0]['message']['content'] ?? '질문을 불러오는 데 실패했습니다';
        print('API success: $question');
      });
      await _saveQuestionToDB(question, familyId); // 질문을 DB에 저장
    } else {
      setState(() {
        question = 'Error: ${response.reasonPhrase}';
        print('API fail: ${response.reasonPhrase}');
      });
    }
  }

  Future<void> _saveQuestionToDB(String question , int? familyId) async {
    if (familyId == null) {
      print("Family ID is null. Cannot save question.");
      return;
    }

    final response = await http.post(
      Uri.parse('http://127.0.0.1:8000/api/save_question/'), // Django 서버 URL로 변경
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'question': question, 'family_id': familyId}),
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      setState(() {
        questionId = data['id'].toString(); // 서버에서 반환한 question_id를 저장
      });
      print('Question saved successfully with ID: $questionId');
    } else {
      print('Failed to save question: ${response.reasonPhrase}');
    }
  }

  Future<void> _saveAnswerToDB(String answer) async {
    if (userId == null || familyId == null || questionId.isEmpty) {
      print("User ID, Family ID, or Question ID is null. Cannot save answer.");
      return;
    }

    final response = await http.post(
      Uri.parse('http://127.0.0.1:8000/api/save_answer/'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'question_id': questionId, 'answer': answer, 'user_id': userId, 'family_id': familyId}),
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      if (mounted) {  // mounted가 true일 때만 setState() 호출
        setState(() {
          questionId = data['id'].toString();
        });
        print('Answer saved successfully with ID: $questionId');
      }
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
        elevation: 0,
        iconTheme: IconThemeData(
          color: Colors.black,
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
              onPressed: () async {
                print('Question: $question');
                print('Answer: $answer');
                await _saveAnswerToDB(answer);

                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('알림'),
                      content: Text('답변이 등록되었습니다.'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
                          },
                          child: Text('확인'),
                        ),
                      ],
                    );
                  },
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 255, 207, 102),
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
