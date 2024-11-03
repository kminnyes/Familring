import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:familring2/token_util.dart'; // 토큰 유틸리티 함수 임포트

class BucketListScreen extends StatefulWidget {
  @override
  _BucketListScreenState createState() => _BucketListScreenState();
}

class _BucketListScreenState extends State<BucketListScreen> {
  List<dynamic> _bucketList = [];

  @override
  void initState() {
    super.initState();
    _fetchBucketList();
  }

  // access_token을 가져와 헤더에 추가하는 함수
  Future<Map<String, String>> _getHeaders() async {
    String? token = await getAccessToken(); // access_token 가져오기
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token', // 헤더에 access_token 추가
    };
  }

  // 버킷리스트 가져오기
  void _fetchBucketList() async {
    try {
      Map<String, String> headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/bucket/'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        setState(() {
          _bucketList = json.decode(response.body);
        });
      } else {
        throw Exception('Failed to load bucket list');
      }
    } catch (error) {
      print('Error fetching bucket list: $error');
    }
  }

  // 버킷리스트 추가 API 호출
  void _addBucketItem(String item) async {
    try {
      Map<String, String> headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/api/bucket/add/'),
        headers: headers,
        body: jsonEncode({
          'bucket_title': item,
          'bucket_content': '이건 언젠간 추가하는거겠죠?',
          'is_completed': false,
        }),
      );
      if (response.statusCode == 201) {
        _fetchBucketList();
      } else {
        throw Exception('Failed to add bucket list');
      }
    } catch (error) {
      print('Error adding bucket item: $error');
    }
  }

  // 버킷리스트 완료 API 호출
  void _completeBucketItem(int bucketId) async {
    try {
      Map<String, String> headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('http://127.0.0.1:8000/api/bucket/complete/$bucketId/'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        _fetchBucketList();
      } else {
        throw Exception('Failed to complete bucket list');
      }
    } catch (error) {
      print('Error completing bucket item: $error');
    }
  }

  void _showAddBucketDialog() {
    String newBucketItem = '';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('버킷리스트 추가'),
          content: TextField(
            onChanged: (value) {
              newBucketItem = value;
            },
            decoration: InputDecoration(hintText: "새로운 버킷리스트 항목"),
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
                _addBucketItem(newBucketItem);
                Navigator.of(context).pop();
              },
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
      body: _bucketList.isEmpty
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              ListView.builder(
                physics: NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: _bucketList.length,
                itemBuilder: (context, index) {
                  return Card(
                    child: ListTile(
                      leading: Icon(Icons.emoji_objects),
                      title: Text(_bucketList[index]['bucket_title']),
                      trailing: Checkbox(
                        value: _bucketList[index]['is_completed'],
                        onChanged: (bool? value) {
                          if (value == true) {
                            _completeBucketItem(_bucketList[index]['id']);
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddBucketDialog,
        backgroundColor: Color.fromARGB(255, 255, 207, 102),
        child: Icon(Icons.add),
      ),
    );
  }
}
