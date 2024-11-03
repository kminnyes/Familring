import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:familring2/token_util.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _familyBucketList = [];
  List<dynamic> _personalBucketList = [];

  @override
  void initState() {
    super.initState();
    _fetchBucketLists();
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
