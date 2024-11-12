import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
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
    _loadUserIdAndFamilyId();
  }

  Future<void> _loadUserIdAndFamilyId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getInt('user_id');
      familyId = prefs.getInt('family_id');
      print('User ID loaded: $userId');
      print('Family ID loaded: $familyId');
    });
    await fetchQuestionFromServer(); // familyId를 로드한 후에 호출
  }

  // Access token 가져오기 함수
  Future<String?> getAccessToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<void> fetchQuestionFromServer() async {
    final accessToken = await getAccessToken();

    if (accessToken == null || familyId == null) {
      setState(() {
        question = '로그인 토큰 또는 Family ID가 없습니다.';
      });
      return;
    }

    try {
      // 첫 번째 서버 요청: 가족의 질문이 있는지 확인하기
      final checkResponse = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/check_question_db?family_id=$familyId'), // 가족의 질문 확인 API
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken', // Authorization 헤더에 access_token 추가
        },
      );

      if (checkResponse.statusCode == 200) {
        var checkData = jsonDecode(checkResponse.body);
        bool hasQuestions = checkData['has_questions'] ?? false;

        // 해당 가족의 질문이 없는 경우 기본 질문 설정 및 DB에 저장
        if (!hasQuestions) {
          setState(() {
            question = "어떤 일에 가장 큰 열정을 가지고 계시나요?";
          });
          await _saveQuestionToDB(question, familyId); // 기본 질문을 DB에 저장
          return;
        }

        // 질문이 있는 경우, 순차적으로 export, process, generate 명령 호출
        await exportAnswers(familyId!);
        await processJsonData(familyId!);
        await generateQuestion(familyId!);

      } else {
        setState(() {
          question = '질문을 확인하는 중 오류 발생';
        });
      }
    } catch (e) {
      setState(() {
        question = '질문을 불러오는 중 오류 발생';
      });
      print('Error fetching question: $e');
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

  // Export answers API 호출
  Future<void> exportAnswers(int familyId) async {
    final accessToken = await getAccessToken(); // access_token 불러오기
    if (accessToken == null) {
      print("Access Token이 없습니다.");
      return;
    }

    final url = Uri.parse('http://127.0.0.1:8000/api/export_answers/');
    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $accessToken", // Authorization 헤더에 access_token 추가
      },
      body: jsonEncode({"family_id": familyId}),
    );

    if (response.statusCode == 200) {
      print("JSON 파일 생성 및 RAG 처리 성공: ${jsonDecode(response.body)['message']}");
    } else {
      print("오류 발생: ${jsonDecode(response.body)['error']}");
    }
  }

  // Process JSON data API 호출
  Future<void> processJsonData(int familyId) async {
    final accessToken = await getAccessToken(); // access_token 불러오기
    if (accessToken == null) {
      print("Access Token이 없습니다.");
      return;
    }

    final url = Uri.parse('http://127.0.0.1:8000/api/process_json_data/');
    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $accessToken", // Authorization 헤더에 access_token 추가
      },
      body: jsonEncode({"family_id": familyId}),
    );

    if (response.statusCode == 200) {
      print("JSON 데이터 처리 성공: ${jsonDecode(response.body)['message']}");
    } else {
      print("오류 발생: ${jsonDecode(response.body)['error']}");
    }
  }

  // Generate question API 호출
  Future<void> generateQuestion(int familyId) async {
    final accessToken = await getAccessToken(); // access_token 불러오기
    if (accessToken == null) {
      print("Access Token이 없습니다.");
      return;
    }

    final url = Uri.parse('http://127.0.0.1:8000/api/generate_question/');
    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $accessToken", // Authorization 헤더에 access_token 추가
      },
      body: jsonEncode({"family_id": familyId}),
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      setState(() {
        question = data['question'];  // 서버에서 반환된 질문을 할당
        questionId = data['question_id'].toString(); // 서버에서 반환된 question_id를 설정
      });
      print("가족 맞춤형 질문 생성 성공: ${data['message']}");
    } else {
      print("오류 발생: ${jsonDecode(response.body)['error']}");
    }
  }




  Future<void> _saveAnswerToDB(String answer) async {
    if (userId == null) {
      print("Error: userId is null.");
    }
    if (familyId == null) {
      print("Error: familyId is null.");
    }
    if (questionId.isEmpty) {
      print("Error: questionId is empty.");
    }


    if (userId == null || familyId == null || questionId.isEmpty) {
      print("User ID, Family ID, or Question ID is null. Cannot save answer.");
      return;
    }

    // 답변이 비어있는지 확인하고 알림 띄우기
    if (answer.trim().isEmpty) {
      _showTemporarySnackBar('답변을 작성해 주세요');
      return;
    }

    final response = await http.post(
      Uri.parse('http://127.0.0.1:8000/api/save_answer/'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'question_id': questionId, 'answer': answer, 'user_id': userId, 'family_id': familyId}),
    );

    if (response.statusCode == 200  || response.statusCode ==201) {
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

  void _showTemporarySnackBar(String message) {
    final snackBar = SnackBar(
      content: Text(message),
      duration: Duration(seconds: 1), // 1초 동안 표시
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('오늘의 질문'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (answer.trim().isEmpty) {
              _showTemporarySnackBar('답변을 작성해 주세요.');
            } else {
              Navigator.of(context).pop(); // 답변이 작성된 경우에만 뒤로 이동
            }
          },
        ),
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
                print('Answer: $answer');  // answer 값 확인

                // answer가 비어있는지 확인
                if (answer.trim().isEmpty) {
                  _showTemporarySnackBar('답변을 작성해 주세요.');
                  return;
                }

                // answer가 비어있지 않을 경우에만 _saveAnswerToDB 호출
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

