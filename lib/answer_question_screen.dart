import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AnswerQuestionScreen extends StatefulWidget {
  final String question;
  final int questionId;
  final String questionNumber;


  AnswerQuestionScreen({required this.question, required this.questionId, required this.questionNumber});

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
    _loadUserId();
    _loadFamilyId();
  }

  Future<void> _loadUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getInt('user_id');
      print('userId loaded: $userId');
    });
  }

  Future<void> _loadFamilyId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      familyId = prefs.getInt('family_id');
      print('Family ID loaded: $familyId');
    });
  }

  Future<void> _fetchAnswers() async {
    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/get_answer/${widget.questionId}/'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body); // JSON 배열로 파싱

        setState(() {
          answers = data.map((item) => item['answer'] as String? ?? '')
              .toList(); // null 체크 후 기본값으로 대체
          userNicknames =
              data.map((item) => item['user_nickname'] as String? ?? '')
                  .toList(); // null 체크 후 기본값으로 대체
          answerIds =
              data.map((item) => item['id'] as int).toList(); // answer ID 추가
          userIds =
              data.map((item) => item['user_id'] as int).toList(); // user ID 추가

          // 추가 디버깅: 각 데이터 항목을 출력
          for (var item in data) {
            print("Parsed answer: ${item['answer'] ?? 'null'}");
            print("Parsed user_nickname: ${item['user_nickname'] ?? 'null'}");
            print("Parsed question_id: ${item['question_id'] ?? 'null'}");
            print("Parsed answer_id: ${item['id'] ?? 'null'}"); // answer ID 확인
            print("Parsed user_id: ${item['user_id'] ?? 'null'}"); // user ID 확인
          }

          isLoading = false;
        });
      } else {
        print('Failed to fetch answers: ${response.reasonPhrase}');
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


  Future<void> _saveAnswerToDB(int userId, int familyId) async {
    final answerText = _answerController.text.trim();
    if (answerText.isEmpty) {
      _showAlertDialog('알림', '답변을 작성해 주세요.');
      return;
    }

    // 이미 답변했는지 확인
    bool answerExists = await _checkAnswerExists(widget.questionId, userId);
    if (answerExists) {
      _showAlertDialog('알림', '답변을 이미 하셨어요.');
      return;
    }

    try {
      print('Sending answer to server...');
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/api/save_answer/'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'question_id': widget.questionId,
          'answer': _answerController.text,
          'user_id': userId,
          'family_id': familyId,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Answer saved successfully');
        _fetchAnswers(); // 새로 등록된 답변 포함하여 다시 불러오기
        _answerController.clear(); // 답변 입력창 초기화
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