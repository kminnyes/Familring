import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:familring2/token_util.dart'; // 토큰 유틸리티 함수 임포트
import 'package:shared_preferences/shared_preferences.dart';


class BucketListScreen extends StatefulWidget {
  @override
  _BucketListScreenState createState() => _BucketListScreenState();
}

class _BucketListScreenState extends State<BucketListScreen> {
  List<dynamic> _familyBucketList = [];
  List<dynamic> _personalBucketList = [];
  String nickname = "";

  @override
  void initState() {
    super.initState();
    _fetchBucketLists();
    _loadNickname(); // 닉네임을 로드합니다.
  }

  Future<void> _loadNickname() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      nickname = prefs.getString('nickname') ?? '사용자';
    });
  }

  // access_token을 가져와 헤더에 추가하는 함수
  Future<Map<String, String>> _getHeaders() async {
    String? token = await getAccessToken();
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };
  }

  // 가족 및 개인 버킷리스트 가져오기
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

  // 버킷리스트 완료 상태 변경 API 호출
  void _toggleCompleteBucketItem(int bucketId, bool isCompleted) async {
    try {
      Map<String, String> headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('http://127.0.0.1:8000/api/bucket/complete/$bucketId/'),
        headers: headers,
        body: jsonEncode({'is_completed': isCompleted}),
      );
      if (response.statusCode == 200) {
        _fetchBucketLists();
      } else {
        throw Exception('Failed to toggle bucket item');
      }
    } catch (error) {
      print('Error toggling bucket item: $error');
    }
  }

  // 버킷리스트 추가 팝업
  void _showAddBucketDialog() {
    String newBucketItem = '';
    bool isFamilyBucket = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('버킷리스트 추가'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                onChanged: (value) {
                  newBucketItem = value;
                },
                decoration: InputDecoration(hintText: "새로운 버킷리스트 항목"),
              ),
              SizedBox(height: 10),
              CheckboxListTile(
                title: Text('가족 버킷리스트로 만들기'),
                value: isFamilyBucket,
                onChanged: (value) {
                  setState(() {
                    isFamilyBucket = value ?? false;
                  });
                },
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('취소'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('확인'),
              onPressed: () {
                _addBucketItem(newBucketItem, isFamilyBucket);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // 버킷리스트 항목 추가
  void _addBucketItem(String item, bool isFamilyBucket) async {
    try {
      Map<String, String> headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/api/bucket/add/'),
        headers: headers,
        body: jsonEncode({
          'bucket_title': item,
          'is_family_bucket': isFamilyBucket,
          'is_completed': false,
        }),
      );
      if (response.statusCode == 201) {
        _fetchBucketLists();
      } else {
        throw Exception('Failed to add bucket list');
      }
    } catch (error) {
      print('Error adding bucket item: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    int remainingGoals = _familyBucketList.where((item) => !item['is_completed']).length +
        _personalBucketList.where((item) => !item['is_completed']).length;
    int completedGoals = _familyBucketList.where((item) => item['is_completed']).length +
        _personalBucketList.where((item) => item['is_completed']).length;

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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 20.0), // 전체 화면 양옆의 padding 추가
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: " 하고 싶은 것들이 ",
                              style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold, color: Colors.black),
                            ),
                            TextSpan(
                              text: "$remainingGoals개\n ",
                              style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold, color: Color(0xFFFFBA51)),
                            ),
                            TextSpan(
                              text: "남았어요!",
                              style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold, color: Colors.black),
                            ),
                          ],
                        ),
                      ),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: "  지금까지 ",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                            ),
                            TextSpan(
                              text: "$completedGoals개",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2FC4FF)),
                            ),
                            TextSpan(
                              text: "를 이뤘어요.",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Image.asset('images/familring_icon_in_bkl.png', width: 180, height: 150),
                ],
              ),
              SizedBox(height: 20),
              ListView.builder(
                physics: NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: _familyBucketList.length + _personalBucketList.length,
                itemBuilder: (context, index) {
                  final isFamily = index < _familyBucketList.length;
                  final item = isFamily
                      ? _familyBucketList[index]
                      : _personalBucketList[index - _familyBucketList.length];
                  final color = isFamily ? Color(0xFF38963B) : Color(0xFFFF9CBA);
                  final titlePrefix = isFamily ? "가족 목표" : "$nickname 님의 개인 목표";

                  return Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Color.fromARGB(255, 255, 186, 81)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    margin: EdgeInsets.symmetric(vertical: 5),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      titlePrefix,
                                      style: TextStyle(fontSize: 14, color: Colors.black54),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 5),
                                Padding(
                                  padding: const EdgeInsets.only(left: 18.0), // content를 오른쪽으로 약간 이동
                                  child: Text(
                                    item['bucket_title'],
                                    style: TextStyle(fontSize: 18),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _toggleCompleteBucketItem(item['bucket_id'], !item['is_completed']);
                              });
                            },
                            child: Icon(
                              Icons.check_circle,
                              size: 40,
                              color: item['is_completed'] ? Colors.orange : Color(0xFFFFECC3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 50), // 리스트와 버튼 사이 간격 추가
              Center(
                child: ElevatedButton(
                  onPressed: _showAddBucketDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 255, 186, 81),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20), // 버튼의 세로 크기 조정
                  ),
                  child: Text(
                    "버킷리스트 생성 하기",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
