import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AnswerQuestionScreen extends StatefulWidget {
  final String question;
  final int questionId;
  final String questionNumber;
  final int familyId;


  AnswerQuestionScreen({required this.question, required this.questionId, required this.questionNumber,  required this.familyId});

  @override
  _AnswerQuestionScreenState createState() => _AnswerQuestionScreenState();
}

class _AnswerQuestionScreenState extends State<AnswerQuestionScreen> {
  List<String> answers = []; // 답변 리스트
  List<String> userNicknames = []; // 닉네임 리스트
  List<int> answerIds = []; // 각 답변의 ID를 저장할 리스트
  List<int> userIds = []; // 각 답변 작성자의 ID 리스트
  bool isLoading = true;
  int? userId;
  int? familyId;
  TextEditingController _answerController = TextEditingController();

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fetchAnswers();
    _loadUserAndFamilyIds();
  }

  Future<void> _loadUserAndFamilyIds() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getInt('user_id');
      familyId = prefs.getInt('family_id');
      print('userId loaded: $userId');
      print('familyId loaded: $familyId');
    });
  }

  Future<void> _fetchAnswers() async {

    try {
      // questionId와 familyId 확인
      print('Fetching answers for questionId: ${widget.questionId}, familyId: ${widget.familyId}');

      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/get_answer/${widget.questionId}/${widget.familyId}/'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('Parsed data length: ${data.length}'); // 데이터 배열 길이 확인
        print('Parsed data content: $data'); // 전체 데이터 출력

        setState(() {
          answers = data.map((item) {
            print('Parsing answer: ${item['answer']}'); // 각 답변 출력
            return item['answer'] as String? ?? '';
          }).toList();

          userNicknames = data.map((item) {
            print('Parsing user nickname: ${item['user_nickname']}'); // 닉네임 출력
            return item['user_nickname'] as String? ?? '';
          }).toList();

          answerIds = data.map((item) {
            print('Parsing answer ID: ${item['id']}'); // 답변 ID 출력
            return item['id'] as int;
          }).toList();

          userIds = data.map((item) {
            print('Parsing user ID: ${item['user_id']}'); // 사용자 ID 출력
            return item['user_id'] as int;
          }).toList();

          isLoading = false;
        });
      } else {
        print('Failed to fetch answers: ${response.reasonPhrase}');
        print('Response status code: ${response.statusCode}'); // 상태 코드 확인
        print('Response body on failure: ${response.body}'); // 실패 시 응답 본문 출력
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching answers: $e');
      setState(() {
        isLoading = false;
      });
    }
  }


  Future<bool> _checkAnswerExists(int questionId, int userId) async {
    try {
      final response = await http.get(
        Uri.parse(
            'http://127.0.0.1:8000/api/check_answer_exists/$questionId/$userId/'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['answer_exists'];
      } else {
        print('Failed to check answer existence: ${response.reasonPhrase}');
        return false;
      }
    } catch (e) {
      print('Error checking answer existence: $e');
      return false;
    }
  }


  Future<void> _saveAnswerToDB() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? userId = prefs.getInt('user_id'); // SharedPreferences에서 user_id 불러오기
    int? familyId = prefs.getInt('family_id'); // SharedPreferences에서 family_id 불러오기

    // SharedPreferences에서 불러온 값이 null인 경우 로그 출력
    if (userId == null || familyId == null) {
      print("Error: userId or familyId is null. Cannot save answer.");
      _showAlertDialog('알림', '유저 ID 또는 가족 ID가 없습니다.');
      return;
    }

    final answerText = _answerController.text.trim();
    try {
      print('Sending answer to server with user_id: $userId and family_id: $familyId');
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/api/save_answer/'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'question_id': widget.questionId,
          'answer': answerText,
          'user_id': userId,  // user_id 추가
          'family_id': familyId,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Answer saved successfully');
        _fetchAnswers();
        _answerController.clear();
        _showAlertDialog('알림', '답변이 등록되었습니다.');
      } else {
        print('Failed to save answer: ${response.reasonPhrase}');
        print('Response data: ${response.body}');
      }
    } catch (e) {
      print('Error saving answer: $e');
    }
  }


  //답변 등록 관련 팝업창
  Future<void> _showAlertDialog(String title, String message) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('확인'),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _showConfirmationDialog(String title, String message) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text('취소'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text('확인'),
            ),
          ],
        );
      },
    ) ?? false;
  }


  Future<void> _updateAnswerToDB(int answerId, String updatedAnswer) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString('access_token');
      String? refreshToken = prefs.getString('refresh_token');

      if (refreshToken == null) {
        print("Refresh token is missing. Please log in again.");
        return;
      }

      if (accessToken == null) {
        print("Token is null. Please login again.");
        return;
      }

      print("Sending token: $accessToken");

      // API 요청을 시도합니다.
      var response = await http.put(
        Uri.parse('http://127.0.0.1:8000/api/update_answer/$answerId/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({'answer': updatedAnswer}),
      );

      if (response.statusCode == 200) {
        print('Answer updated successfully');
        _fetchAnswers();
      } else if (response.statusCode == 401) {
        print('Access token expired. Refreshing token...');

        final refreshResponse = await http.post(
          Uri.parse('http://127.0.0.1:8000/api/token/refresh/'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'refresh': refreshToken}),
        );

        if (refreshResponse.statusCode == 200) {
          var data = jsonDecode(refreshResponse.body);
          String newAccessToken = data['access'];

          await prefs.setString('access_token', newAccessToken);
          print("Access token refreshed successfully: $newAccessToken");

          // 갱신된 토큰으로 다시 요청을 시도합니다.
          response = await http.put(
            Uri.parse('http://127.0.0.1:8000/api/update_answer/$answerId/'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $newAccessToken',
            },
            body: jsonEncode({'answer': updatedAnswer}),
          );

          if (response.statusCode == 200) {
            print('Answer updated successfully on retry');
            _fetchAnswers();
          } else {
            print('Failed to update answer on retry: ${response.reasonPhrase}');
          }
        } else {
          print('Failed to refresh token: ${refreshResponse.body}');
        }
      } else {
        print('Failed to update answer: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error updating answer: $e');
    }
  }




  Future<void> _showUpdateDialog(int answerId, String currentAnswer) async {
    _answerController.text = currentAnswer;

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('답변 수정하기'),
          content: TextField(
            controller: _answerController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: '답변을 수정하세요...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('취소'),
            ),
            TextButton(
              onPressed: () async {
                final updatedAnswer = _answerController.text.trim();
                if (updatedAnswer.isNotEmpty) {
                  await _updateAnswerToDB(answerId, updatedAnswer);
                  Navigator.of(context).pop();
                }
              },
              child: Text('수정하기'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false, // Remove default back button
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${widget.questionNumber} 번째 질문', // Use the question number here
              style: TextStyle(
                fontSize: 16,
                color: Colors.amber,
                fontWeight: FontWeight.bold,
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'X',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Q. ${widget.question}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            isLoading
                ? Center(child: CircularProgressIndicator())
                : Expanded(
              child: ListView.builder(
                itemCount: answers.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onLongPress: () {
                      if (userIds[index] == userId) {
                        _showUpdateDialog(answerIds[index], answers[index]);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${userNicknames[index]}님의 답변',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 8),
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.orange),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'A. ${answers[index]}',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}