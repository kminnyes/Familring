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
  List<String> answers = [];  // 답변 리스트
  List<String> userNicknames = [];  // 닉네임 리스트
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
    _fetchAnswers();  // 여러 답변을 가져오는 함수로 이름 변경
    _loadUserId();
    _loadFamilyId();

  }


  Future<void> _loadUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getInt('user_id');  // SharedPreferences에서 userId 불러오기
      print('userId loaded: $userId');  // 디버깅 로그 추가
    });
  }


  Future<void> saveUserInfo(String accessToken, String refreshToken, int userId, List<int> familyIds) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', accessToken);
    await prefs.setString('refresh_token', refreshToken);
    await prefs.setInt('user_id', userId);
    await prefs.setStringList('family_ids', familyIds.map((id) => id.toString()).toList());
    print('User ID saved: $userId');
    print('Family IDs saved: ${familyIds}');
  }


  Future<void> _loadFamilyId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      familyId = prefs.getInt('family_id'); // Directly load the stored family_id
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
        final List<dynamic> data = jsonDecode(response.body);  // JSON 배열로 파싱
        setState(() {
          answers = data.map((item) => item['answer'] as String).toList();
          userNicknames = data.map((item) => item['user_nickname'] as String).toList();
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
        Uri.parse('http://127.0.0.1:8000/api/check_answer_exists/$questionId/$userId/'),
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
        _fetchAnswers();  // 새로 등록된 답변 포함하여 다시 불러오기
        _answerController.clear();  // 답변 입력창 초기화
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
                      SizedBox(height: 10),
                    ],
                  );
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
              onPressed: isLoading ? null : () async {
                setState(() {
                  isLoading = true;
                });
                print('버튼이 눌렸습니다'); // 디버깅
                print('userId: $userId, familyId: $familyId'); // userId와 familyId 값 확인

                if (userId == null || familyId == null) {
                  await _showAlertDialog('알림', '유저 ID 또는 가족 ID가 로드되지 않았습니다.');
                  setState(() {
                    isLoading = false;
                  });
                  return;
                }

                if (_answerController.text.trim().isEmpty) {
                  await _showAlertDialog('알림', '답변을 작성해 주세요.');
                } else if (userId != null) {
                  print('확인 알림을 띄웁니다'); // 디버깅
                  bool confirmed = await _showConfirmationDialog('답변 등록', '답변을 등록하시겠습니까?');
                  if (confirmed) {
                    print('답변이 확인되었습니다'); // 디버깅
                    _saveAnswerToDB(userId!, familyId!);
                  }
                }
                setState(() {
                  isLoading = false;
                });
              },
              child: isLoading ? CircularProgressIndicator() : Text('답변 등록하기'),
            ),
          ],
        ),
      ),
    );
  }
}
