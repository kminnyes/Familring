import 'package:flutter/material.dart';
import 'answer_question_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class QuestionListScreen extends StatefulWidget {
  @override
  _QuestionListScreenState createState() => _QuestionListScreenState();
}

class _QuestionListScreenState extends State<QuestionListScreen> {
  List<Map<String, dynamic>> questionsAndAnswers = [];
  Map<String, dynamic>? latestQuestion;

  get index => null; // 가장 최근의 질문을 저장

  @override
  void initState() {
    super.initState();
    fetchQuestions();
  }

  // Django 서버에서 질문 리스트 가져오는 함수
  Future<void> fetchQuestions() async {
    try {
      final response = await http.get(Uri.parse('http://127.0.0.1:8000/api/question_list/')); // 실제 서버 주소로 변경 필요

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);

        setState(() {
          if (data.isNotEmpty) {
            // 가장 최근의 질문을 최신순으로 가져온 리스트의 첫 번째 항목으로 설정
            latestQuestion = {
              'id': data[0]['id'],
              'question': data[0]['question'],
              'answer': ''
            };
            // 나머지 질문은 일반 질문 리스트에 추가
            questionsAndAnswers = data.skip(1).map((question) => {
              'id': question['id'],
              'question': question['question'],
              'answer': ''
            }).toList();
            questionsAndAnswers.sort((a, b) => b['id'].compareTo(a['id'])); // id 기준으로 내림차순 정렬
          }
        });
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
                    height: 130, // 원하는 높이로 고정
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Color(0xFFFFF5E1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(left: 10.0, top: 10.0), // 왼쪽과 위쪽 여백 추가
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Q. ',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange, // 'Q.'의 색상을 오렌지색으로 지정
                                  ),
                                ),
                                TextSpan(
                                  text: latestQuestion!['question'],
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black, // 질문 텍스트 색상을 검정으로 지정
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Spacer(),
                        Center(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AnswerQuestionScreen(
                                    question: latestQuestion!['question'],
                                    questionId: latestQuestion!['id'] ?? 0,
                                    questionNumber: "#${index + 1}",
                                    ),
                                  ),
                                );
                              },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color.fromARGB(255, 255, 186, 81),
                              foregroundColor: Colors.white,
                              minimumSize: Size(300, 50), // 버튼의 최소 너비와 높이 설정
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              "가족의 답변 확인하러 가기",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                    leading: Text(
                      '#${(questionsAndAnswers.length - index).toString().padLeft(3, '0')}', // 번호 형식
                      style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                    ),
                    title: Text(
                      qa['question'],
                      style: TextStyle(color: Colors.black),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AnswerQuestionScreen(
                            question: qa['question'],
                            questionId: qa['id'] ?? 0,
                            questionNumber: "#${index + 1}",
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
