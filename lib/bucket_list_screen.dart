import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http; // 토큰 유틸리티 함수 임포트

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

  // 토큰을 가져와서 헤더에 추가하는 함수
  Future<Map<String, String>> _getHeaders() async {
    return {
      'Content-Type': 'application/json; charset=UTF-8',
    };
  }

  // 버킷리스트 가져오기
  void _fetchBucketList() async {
    try {
      Map<String, String> headers = await _getHeaders();  // 헤더에 토큰 추가
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
      Map<String, String> headers = await _getHeaders();  // 헤더에 토큰 추가
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
      Map<String, String> headers = await _getHeaders();  // 헤더에 토큰 추가
      final response = await http.put(
        Uri.parse('http://127.0.0.1:8000/api/bucket/complete/$bucketId/'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        _fetchBucketList(); // 성공적으로 완료된 후, 목록을 다시 로드
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
          padding: const EdgeInsets.only(left: 18.0, top: 10.0), // 위쪽 여백 추가
          child: SizedBox(
            width: 42, // 이미지 크기 조정
            height: 42,
            child: Image.asset(
              'images/appbaricon.png', // 이미지 파일 경로
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
      body: _bucketList.isEmpty
          ? Center(child: CircularProgressIndicator()) // 데이터가 로드될 때 로딩 인디케이터 표시
          : SingleChildScrollView(  // 넘치는 경우 스크롤 가능하게 처리
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              ListView.builder(
                physics: NeverScrollableScrollPhysics(), // 내부에서 스크롤 방지
                shrinkWrap: true, // 부모의 크기에 맞춤
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
