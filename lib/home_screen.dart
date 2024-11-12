import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:familring2/token_util.dart';
import 'question_notification.dart';
import 'dart:math';
import 'family_management_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _allBucketList = [];
  Map<String, dynamic>? _randomBucketListItem;
  List<Map<String, dynamic>> _scheduleList = [];
  List<dynamic> _familyMembers = [];
  int? familyId;
  String nickname = '';
  double imageSize = 60.0;
  double fontSize = 15.0;
  String familyName = '';

  @override
  void initState() {
    super.initState();
    _loadSharedPreferences();
    Future.delayed(Duration(seconds: 1), () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => QuestionNotification()),
      );
    });
    _fetchBucketLists();
    _fetchFamilyMembers();
    _fetchFamilyName();
  }


  Future<void> _loadSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      familyId = prefs.getInt('family_id');
      nickname = prefs.getString('nickname') ?? '';
    });
    _fetchTodayEvents();
  }

  Future<void> _fetchFamilyName() async {
    String? token = await getAccessToken();
    if (token == null) return;

    final response = await http.get(
      Uri.parse('http://127.0.0.1:8000/api/family_name/$familyId/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        familyName = data['family_name'] ?? '';
      });
    } else {
      print('Failed to load family name');
    }
  }

  void _fetchBucketLists() async {
    try {
      String? token = await getAccessToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/bucket/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _allBucketList = [
            ...data['family_bucket_list'],
            ...data['personal_bucket_list']
          ];

          if (_allBucketList.isNotEmpty) {
            final randomIndex = Random().nextInt(_allBucketList.length);
            _randomBucketListItem = _allBucketList[randomIndex];
          }
        });
      } else {
        print('Failed to load bucket lists');
      }
    } catch (error) {
      print('Error fetching bucket lists: $error');
    }
  }

  void _fetchFamilyMembers() async {
    try {
      String? token = await getAccessToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/family/members/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _familyMembers = data;
        });
      } else {
        print('Failed to load family members');
      }
    } catch (error) {
      print('Error fetching family members: $error');
    }
  }

  void _fetchTodayEvents() async {
    if (familyId == null) {
      print("Family ID is null. Cannot fetch today's events.");
      return;
    }

    try {
      String? token = await getAccessToken();
      if (token == null) return;

      final today = DateTime.now();
      final url = 'http://127.0.0.1:8000/api/get-today-events/?family_id=$familyId&date=${today.toIso8601String().split("T")[0]}';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> eventsData = jsonDecode(response.body);
        setState(() {
          _scheduleList = eventsData.map((eventData) {
            final isFamilyEvent = eventData['event_type'] == '가족일정';
            return {
              "name": isFamilyEvent ? '우리 가족' : nickname,
              "task": eventData['event_content'],
              "img": isFamilyEvent ? "images/familring_icon_in_bkl.png" : "images/familring_user_icon4.png"
            };
          }).toList();
        });
      } else {
        print('Failed to load today\'s events');
      }
    } catch (error) {
      print('Error fetching today\'s events: $error');
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 25.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: "$familyName",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: " 가족",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.normal),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Color(0xFFFFCF66),
                  borderRadius: BorderRadius.circular(12),
                ),
                height: 135,
                alignment: Alignment.center,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _familyMembers.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _familyMembers.length) {
                      return _buildFamilyAddButton();
                    } else {
                      return Padding(
                        padding: const EdgeInsets.only(right: 16.0),
                        child: _buildFamilyMember(_familyMembers[index]),
                      );
                    }
                  },
                ),
              ),
              SizedBox(height: 30),
              Row(
                children: [
                  Text(
                    "우리 가족 ",
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  Text(
                    "버킷리스트",
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 255, 186, 81),
                  ),
                  ),
                ],
              ),
              SizedBox(height: 1),
              _randomBucketListItem == null
                  ? Text("버킷리스트가 없습니다.")
                  : _buildBucketListItem(_randomBucketListItem!),
              SizedBox(height: 20),
              Text(
                "오늘의 일정",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 0),
              Text(
                "오늘 우리 가족은 무엇을 하며 하루를 보내게 될까요?",
                style: TextStyle(fontSize: 15, color: Colors.black),
              ),
              SizedBox(height: 7),
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
                      border: Border.all(color: Color(0xFFFFA651), width: 1.2),
                    ),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 16.0),
                          child: Column(
                            children: [
                              SizedBox(
                                width: 40,
                                height: 40,
                                child: Image.asset(
                                  _scheduleList[index]["img"]!,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              Transform.translate(
                                offset: Offset(0, -1),
                                child: Text(
                                  _scheduleList[index]["name"]!,
                                  style: TextStyle(fontSize: 11.5, color: Color(0xFF656565)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 12.0),
                            child: Text(
                              _scheduleList[index]["task"]!,
                              style: TextStyle(fontSize: 18),
                            ),
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
      ),
    );
  }

  Widget _buildFamilyMember(Map<String, dynamic> member) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: imageSize,
          height: imageSize,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Image.asset(
            "images/familring_user_icon4.png",
            fit: BoxFit.contain,
          ),
        ),
        SizedBox(height: 4),
        Text(
          member['nickname'],
          style: TextStyle(fontSize: fontSize),
        ),
      ],
    );
  }

  Widget _buildFamilyAddButton() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => FamilyManagementScreen()),
            );
          },
          child: Container(
            width: imageSize - 6,
            height: imageSize - 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFFFECC3),
              border: Border.all(color: Color(0xFF656565), width: 1.4),
            ),
            child: Center(
              child: Icon(Icons.add, color: Color(0xFF656565), size: 24),
            ),
          ),
        ),
        SizedBox(height: 10),
        Text(
          '가족 추가',
          style: TextStyle(fontSize: 15, color: Color(0xFF656565)),
        ),
      ],
    );
  }

  Widget _buildBucketListItem(Map<String, dynamic> item) {
    final isFamilyBucket = item['bucket_type'] == 'family';
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20), // 전체 위치 조정
      margin: EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey, width: 1.1), // 회색 테두리 추가
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 목표 유형과 색상 원을 오른쪽으로 옮기기 위해 Row에 Padding 적용
          Padding(
            padding: const EdgeInsets.only(left: 18.0),
            child: Row(
              children: [
                Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: isFamilyBucket ? Color(0xFF38963B) : Color(0xFFFF9CBA),
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 6),
                Text(
                  isFamilyBucket ? '가족 목표' : '개인 목표',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal),
                ),
              ],
            ),
          ),
          SizedBox(height: 3),
          // 버킷리스트 내용
          Padding(
            padding: const EdgeInsets.only(left: 40.0), // content를 더 오른쪽에서 시작
            child: Text(
              item['bucket_title'],
              style: TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }


  void _toggleCompleteStatus(int bucketId, bool isCompleted) async {
    try {
      String? token = await getAccessToken();
      if (token == null) return;

      final response = await http.put(
        Uri.parse('http://127.0.0.1:8000/api/bucket/complete/$bucketId/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'is_completed': isCompleted}),
      );

      if (response.statusCode != 200) {
        print('Failed to complete bucket item');
      }
    } catch (error) {
      print('Error completing bucket item: $error');
    }
  }
}
