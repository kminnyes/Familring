import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:familring2/token_util.dart'; // 토큰 유틸리티 함수 임포트

class BucketListScreen extends StatefulWidget {
  @override
  _BucketListScreenState createState() => _BucketListScreenState();
}

class _BucketListScreenState extends State<BucketListScreen> {
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

  // 버킷리스트 추가 API 호출
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
        _fetchBucketLists(); // 목록 다시 로드하여 UI 업데이트
      } else {
        throw Exception('Failed to add bucket list');
      }
    } catch (error) {
      print('Error adding bucket item: $error');
    }
  }

  // 버킷리스트 완료 API 호출
  void _completeBucketItem(int bucketId, bool isCompleted) async {
    try {
      print('Completing bucket item with ID: $bucketId');

      Map<String, String> headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('http://127.0.0.1:8000/api/bucket/complete/$bucketId/'),
        headers: headers,
        body: jsonEncode({'is_completed': isCompleted}),
      );
      if (response.statusCode == 200) {
        _fetchBucketLists(); // 성공적으로 완료된 후, 목록을 다시 로드
      } else {
        throw Exception('Failed to complete bucket item');
      }
    } catch (error) {
      print('Error completing bucket item: $error');
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
              StatefulBuilder( // Use StatefulBuilder for checkbox state management in dialog
                builder: (BuildContext context, StateSetter setState) {
                  return CheckboxListTile(
                    title: Text('가족 버킷리스트로 만들기'),
                    value: isFamilyBucket,
                    onChanged: (value) {
                      setState(() {
                        isFamilyBucket = value ?? false;
                      });
                    },
                  );
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
              Text(
                "가족 버킷리스트",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              _familyBucketList.isEmpty
                  ? Text("가족 버킷리스트가 없습니다.")
                  : ListView.builder(
                physics: NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: _familyBucketList.length,
                itemBuilder: (context, index) {
                  return Card(
                    child: ListTile(
                      leading: Icon(Icons.emoji_objects),
                      title: Text(_familyBucketList[index]['bucket_title']),
                      trailing: Checkbox(
                        value: _familyBucketList[index]['is_completed'],
                        onChanged: (bool? value) {
                          if (value != null) {
                            setState(() {
                              _familyBucketList[index]['is_completed'] = value;
                            });
                            _completeBucketItem(_familyBucketList[index]['bucket_id'], value);
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 20),
              Text(
                "개인 버킷리스트",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              _personalBucketList.isEmpty
                  ? Text("개인 버킷리스트가 없습니다.")
                  : ListView.builder(
                physics: NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: _personalBucketList.length,
                itemBuilder: (context, index) {
                  return Card(
                    child: ListTile(
                      leading: Icon(Icons.emoji_objects),
                      title: Text(_personalBucketList[index]['bucket_title']),
                      trailing: Checkbox(
                        value: _personalBucketList[index]['is_completed'],
                        onChanged: (bool? value) {
                          if (value != null) {
                            setState(() {
                              _personalBucketList[index]['is_completed'] = value;
                            });
                            _completeBucketItem(_personalBucketList[index]['bucket_id'], value);
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
