import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AnswerQuestionScreen extends StatefulWidget {
  final String question;
  final int questionId;

  AnswerQuestionScreen({required this.question, required this.questionId});

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
      String? accessToken = prefs.getString('access_token');  // 저장된 access_token 불러오기

      if (accessToken == null) {
        print("Token is null. Please login again.");
        return;
      }

      print("Sending token: $accessToken");  // 토큰 값 확인용

      final response = await http.put(
        Uri.parse('http://127.0.0.1:8000/api/update_answer/$answerId/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',  // access_token 추가
        },
        body: jsonEncode({'answer': updatedAnswer}),
      );

      print('Response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        print('Answer updated successfully');
        _fetchAnswers();
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
            isLoading
                ? CircularProgressIndicator()
                : Expanded(
              child: ListView.builder(
                itemCount: answers.length,
                itemBuilder: (context, index) {
                  if (index < answers.length &&
                      index < userNicknames.length &&
                      index < answerIds.length &&
                      index < userIds.length) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'A. ${answers[index]}',
                          style: TextStyle(fontSize: 16),
                        ),
                        Text(
                          '작성자: ${userNicknames[index]}',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        if (userIds[index] == userId) // 현재 사용자의 답변인지 확인
                          Row(
                            children: [
                              TextButton(
                                onPressed: () {
                                  _showUpdateDialog(
                                      answerIds[index], answers[index]);
                                },
                                child: Text('수정하기'),
                              ),
                            ],
                          ),
                        SizedBox(height: 10),
                      ],
                    );
                  } else {
                    return SizedBox.shrink(); // 조건이 맞지 않을 때 빈 위젯 반환
                  }
                },
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _answerController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: '답변을 입력해주세요...',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                setState(() {
                  isLoading = true;
                });
                print('버튼이 눌렸습니다'); // 디버깅
                print(
                    'userId: $userId, familyId: $familyId'); // userId와 familyId 값 확인

                if (userId == null || familyId == null) {
                  await _showAlertDialog(
                      '알림', '유저 ID 또는 가족 ID가 로드되지 않았습니다.');
                  setState(() {
                    isLoading = false;
                  });
                  return;
                }

                if (_answerController.text
                    .trim()
                    .isEmpty) {
                  await _showAlertDialog('알림', '답변을 작성해 주세요.');
                } else {
                  print('확인 알림을 띄웁니다'); // 디버깅
                  bool confirmed = await _showConfirmationDialog(
                      '답변 등록', '답변을 등록하시겠습니까?');
                  if (confirmed) {
                    print('답변이 확인되었습니다'); // 디버깅
                    await _saveAnswerToDB(userId!, familyId!);
                  }
                }
                setState(() {
                  isLoading = false;
                });
              },
              child: isLoading
                  ? CircularProgressIndicator()
                  : Text('답변 등록하기'),
            ),
          ],
        ),
      ),
    );
  }

}