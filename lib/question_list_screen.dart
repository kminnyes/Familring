import 'package:flutter/material.dart';
import 'answer_question_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class QuestionListScreen extends StatefulWidget {
  @override
  _QuestionListScreenState createState() => _QuestionListScreenState();
}

class _QuestionListScreenState extends State<QuestionListScreen> {
  List<Map<String, dynamic>> questionsAndAnswers = [];
  Map<String, dynamic>? latestQuestion;
  int? familyId;
  get index => null; // 가장 최근의 질문을 저장

  @override
  void initState() {
    super.initState();
    fetchQuestions();
    _loadFamilyId();
  }

  Future<void> _loadFamilyId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      familyId = prefs.getInt('family_id'); // SharedPreferences에서 family_id 불러오기
    });
    print("Family ID loaded: $familyId"); // family_id 확인을 위한 로그
    if (familyId != null) {
      fetchQuestions(); // familyId를 불러온 후에 질문 가져오기
    }
  }

  // Django 서버에서 질문 리스트 가져오는 함수
  Future<void> fetchQuestions() async {
    if (familyId == null) {
      print("Family ID is null. Cannot fetch questions.");
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/question_list/$familyId/'),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);

        if (mounted) {
          setState(() {
            if (data.isNotEmpty) {
              // id 기준으로 정렬
              data.sort((a, b) => b['id'].compareTo(a['id']));

              latestQuestion = {
                'id': data.first['id'], // 가장 최근 질문
                'question': data.first['question'],
                'answer': ''
              };

              // 나머지 질문들을 "이전의 질문"으로 설정
              questionsAndAnswers = data.sublist(1).map((question) => {
                'id': question['id'],
                'question': question['question'],
                'answer': ''
              }).toList();
            }
          });
        }
      } else {
        print('Failed to load questions: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error fetching questions: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 18.0, top: 10.0),
          child: SizedBox(
            width: 42,
            height: 42,
            child: Image.asset(
              'images/appbaricon.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 오늘의 질문 섹션
            if (latestQuestion != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '오늘의 질문',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Container(
                    width: 500, // 원하는 너비로 고정
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Color(0xFFFFF5E1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(left: 10.0, top: 10.0),
                          child: SingleChildScrollView( // 길이가 길 경우 스크롤 가능
                            scrollDirection: Axis.vertical,
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Q. ',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange,
                                    ),
                                  ),
                                  TextSpan(
                                    text: latestQuestion!['question'],
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 10), // 버튼과 텍스트 사이 여백
                        Center(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AnswerQuestionScreen(
                                    question: latestQuestion!['question'],
                                    questionId: latestQuestion!['id'] ?? 0,
                                    questionNumber: "${questionsAndAnswers.length + 1}", // 최신 질문의 번호 설정
                                    familyId: familyId ?? 0,
                                  ),
                                ),
                              );
                            },

                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color.fromARGB(255, 255, 186, 81),
                              foregroundColor: Colors.white,
                              minimumSize: Size(300, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              "가족의 답변 확인하러 가기",
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 30),
                ],
              ),
            // 이전의 질문 섹션
            Text(
              '이전의 질문',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: questionsAndAnswers.length,
                itemBuilder: (context, index) {
                  final qa = questionsAndAnswers[index];
                  return ListTile(
                    leading: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${(questionsAndAnswers.length - index).toString().padLeft(3, '0')}', // 숫자 부분
                            style: TextStyle(
                              fontSize: 15, // 원하는 숫자 크기
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    title: Text(
                      qa['question'],
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AnswerQuestionScreen(
                            question: qa['question'],
                            questionId: qa['id'] ?? 0,
                            questionNumber: "#${(index + 1)}",
                            familyId: familyId ?? 0,
                          ),
                        ),
                      );
                    },
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
