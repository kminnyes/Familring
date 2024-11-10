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
  List<Map<String, dynamic>> _scheduleList = []; // 오늘의 일정 리스트
  List<dynamic> _familyMembers = []; // 가족 멤버 데이터
  int? familyId;
  String nickname = '';

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

  void _fetchFamilyMembers() async {
    try {
      Map<String, String> headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/family/members/'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _familyMembers = data;
        });
      } else {
        throw Exception('Failed to load family members');
      }
    } catch (error) {
      print('Error fetching family members: $error');
    }
  }

  Future<void> _loadSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      familyId = prefs.getInt('family_id');
      nickname = prefs.getString('nickname') ?? '';
    });
    _fetchTodayEvents(); // familyId를 로드한 후에 오늘의 일정 불러오기
  }

  Future<Map<String, String>> _getHeaders() async {
    String? token = await getAccessToken();
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };
  }

  void _fetchTodayEvents() async {
    if (familyId == null) {
      print("Family ID is null. Cannot fetch today's events.");
      return;
    }

    try {
      Map<String, String> headers = await _getHeaders();
      final today = DateTime.now();
      final url = 'http://127.0.0.1:8000/api/get-today-events/?family_id=$familyId&date=${today.toIso8601String().split("T")[0]}';

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        List<dynamic> eventsData = jsonDecode(response.body);
        setState(() {
          _scheduleList = eventsData.map((eventData) {
            final isFamilyEvent = eventData['event_type'] == '가족일정';
            return {
              "name": isFamilyEvent ? '우리 가족' : nickname,
              "task": eventData['event_content'],
              "img": isFamilyEvent ? "images/familring_icon_in_bkl.png" : "images/familring_user_icon1.png"
            };
          }).toList();
        });
      } else {
        print('Failed to load today\'s events: ${response.statusCode}');
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
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 가족 추가 및 가족 멤버 UI
              Row(
                children: [
                  ..._familyMembers.map((member) => _buildFamilyMember(member)).toList(),
                  _buildFamilyAddButton(),
                ],
              ),
              SizedBox(height: 20),

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
              SizedBox(height: 0),
              Text(
                "오늘 우리 가족은 무엇을 하며 하루를 보내게 될까요?",
                style: TextStyle(fontSize: 15, color: Colors.grey[700]),
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
                          padding: const EdgeInsets.only(left: 16.0),
                          child: Column(
                            children: [
                              SizedBox(
                                width: 50,
                                height: 50,
                                child: Image.asset(
                                  _scheduleList[index]["img"]!,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              Transform.translate(
                                offset: Offset(0, -8),
                                child: Text(
                                  _scheduleList[index]["name"]!,
                                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 16),
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
      ),
    );
  }

  Widget _buildFamilyMember(Map<String, dynamic> member) {
    return Column(
      children: [
        SizedBox(
          width: 60,
          height: 60,
          child: CircleAvatar(
            backgroundImage: AssetImage("images/familring_user_icon1.png"),
            child: Text(
              member['nickname'][0],
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
        SizedBox(height: 4),
        Text(
          member['nickname'],
          style: TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildFamilyAddButton() {
    return GestureDetector(
      onTap: _showAddFamilyDialog,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.orange, width: 2),
        ),
        child: Icon(Icons.add, color: Colors.orange, size: 30),
      ),
    );
  }

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

  void _showAddFamilyDialog() {
    // 가족 추가 다이얼로그 코드
  }

  void _showMessageDialog(String message) {
    // 메시지 다이얼로그 코드
  }
}
