import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:familring2/token_util.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'question_notification.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _familyBucketList = [];
  List<dynamic> _personalBucketList = [];
  List<Map<String, String>> _scheduleList = [
    {"name": "아빠", "task": "친구들과 골프 약속", "img": "images/familring_user_icon1.png"},
    {"name": "엄마", "task": "냉장고 정리 하기", "img": "images/familring_user_icon3.png"},
  ];

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 1), () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => QuestionNotification()),
      );
    });
    _fetchBucketLists();
  }

  Future<Map<String, String>> _getHeaders() async {
    String? token = await getAccessToken();
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };
  }

  void _fetchBucketLists() async {
    try {
      Map<String, String> headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/bucket/'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _familyBucketList = data['family_bucket_list'];
          _personalBucketList = data['personal_bucket_list'];
        });
      } else {
        throw Exception('Failed to load bucket lists');
      }
    } catch (error) {
      print('Error fetching bucket lists: $error');
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
            // Family Bucket List Section
            Text(
              "우리 가족 버킷리스트",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange),
            ),
            SizedBox(height: 10),
            _familyBucketList.isEmpty
                ? Text("가족 버킷리스트가 없습니다.")
                : ListView.builder(
              physics: NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: _familyBucketList.length,
              itemBuilder: (context, index) {
                return Card(
                  color: Colors.orange[50],
                  child: ListTile(
                    leading: Icon(Icons.emoji_objects, color: Colors.orange),
                    title: Text(_familyBucketList[index]['bucket_title']),
                    trailing: Checkbox(
                      value: _familyBucketList[index]['is_completed'],
                      onChanged: (bool? value) {
                        if (value != null) {
                          setState(() {
                            _familyBucketList[index]['is_completed'] = value;
                          });
                          _toggleCompleteStatus(_familyBucketList[index]['bucket_id'], value);
                        }
                      },
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 20),

            // Personal Bucket List Section
            Text(
              "개인 버킷리스트",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange),
            ),
            SizedBox(height: 10),
            _personalBucketList.isEmpty
                ? Text("개인 버킷리스트가 없습니다.")
                : ListView.builder(
              physics: NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: _personalBucketList.length,
              itemBuilder: (context, index) {
                return Card(
                  color: Colors.orange[50],
                  child: ListTile(
                    leading: Icon(Icons.emoji_objects, color: Colors.orange),
                    title: Text(_personalBucketList[index]['bucket_title']),
                    trailing: Checkbox(
                      value: _personalBucketList[index]['is_completed'],
                      onChanged: (bool? value) {
                        if (value != null) {
                          setState(() {
                            _personalBucketList[index]['is_completed'] = value;
                          });
                          _toggleCompleteStatus(_personalBucketList[index]['bucket_id'], value);
                        }
                      },
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 20),

            // Schedule List Section
            Text(
              "오늘의 일정",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            ListView.builder(
              physics: NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: _scheduleList.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0), // 왼쪽 간격 추가
                        child: Column(
                          children: [
                            SizedBox(
                              width: 50, // 고정 너비
                              height: 50, // 고정 높이
                              child: Image.asset(
                                _scheduleList[index]["img"]!,
                                fit: BoxFit.cover, // 이미지가 고정된 크기에 맞추도록 설정
                              ),
                            ),
                            Transform.translate(
                              offset: Offset(0, -8), // 이미지와 텍스트 간격 줄이기
                              child: Text(
                                _scheduleList[index]["name"]!,
                                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 16), // 이미지와 텍스트 사이 간격 조정
                      Expanded(
                        child: Text(
                          _scheduleList[index]["task"]!,
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // 버킷리스트 완료 상태 변경 API 호출
  void _toggleCompleteStatus(int bucketId, bool isCompleted) async {
    try {
      Map<String, String> headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('http://127.0.0.1:8000/api/bucket/complete/$bucketId/'),
        headers: headers,
        body: jsonEncode({'is_completed': isCompleted}),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to complete bucket item');
      }
    } catch (error) {
      print('Error completing bucket item: $error');
    }
  }
}
