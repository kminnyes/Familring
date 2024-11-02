import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:familring2/token_util.dart';
import 'dart:convert';

class FamilyManagementScreen extends StatefulWidget {
  @override
  _FamilyManagementScreenState createState() => _FamilyManagementScreenState();
}

class _FamilyManagementScreenState extends State<FamilyManagementScreen> {
  List<dynamic> _allUsers = [];
  List<dynamic> _filteredUsers = [];
  String searchQuery = '';
  dynamic _pendingFamilyRequest;
  TextEditingController _familyNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _checkPendingFamilyRequest();
  }

  Future<void> _loadUsers() async {
    String? token = await getAccessToken();
    if (token == null) {
      print('No token found!');
      return;
    }

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final response = await http.get(
      Uri.parse('http://127.0.0.1:8000/api/users/'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      setState(() {
        _allUsers = data;
        _filteredUsers = data;
      });
    } else {
      print('Failed to load users');
    }
  }

  Future<void> _checkPendingFamilyRequest() async {
    String? token = await getAccessToken();
    if (token == null) {
      print('No token found!');
      return;
    }

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final response = await http.get(
      Uri.parse('http://127.0.0.1:8000/api/family/pending/'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));

      if (data != null && data['message'] != '진행중인 가족 초대 요청이 없습니다.') {
        setState(() {
          _pendingFamilyRequest = data;
        });
        _showPendingRequestDialog();
      } else {
        print('No pending family request');
      }
    } else {
      print('Failed to check pending family request');
    }
  }

  void _searchUser(String query) {
    setState(() {
      searchQuery = query;
      if (searchQuery.isEmpty) {
        _filteredUsers = _allUsers;
      } else {
        _filteredUsers = _allUsers.where((user) {
          final userName = user['username'].toLowerCase();
          return userName.contains(searchQuery.toLowerCase());
        }).toList();
      }
    });
  }

  Future<void> _sendFamilyInvitation(String toUserId) async {
    String? token = await getAccessToken();
    if (token == null) {
      print('No token found!');
      return;
    }

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final response = await http.post(
      Uri.parse('http://127.0.0.1:8000/api/family/invite/'),
      headers: headers,
      body: jsonEncode({'to_user_id': toUserId}),
    );

    if (response.statusCode == 201) {
      print('초대 요청이 전송되었습니다.');
    } else {
      print('초대 요청 실패');
    }
  }

  Future<void> _createFamily() async {
    String? token = await getAccessToken();
    if (token == null) {
      print('No token found!');
      return;
    }

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final response = await http.post(
      Uri.parse('http://127.0.0.1:8000/api/family/create/'),
      headers: headers,
      body: jsonEncode({'family_name': _familyNameController.text}),
    );

    if (response.statusCode == 201) {
      print('가족이 생성되었습니다.');
      Navigator.of(context).pop();
    } else {
      print('가족 생성 실패');
    }
  }

  void _showCreateFamilyDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('가족 만들기'),
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          content: TextField(
            controller: _familyNameController,
            decoration: InputDecoration(labelText: '가족 이름 입력'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _createFamily();
              },
              child: Text('생성'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _respondToFamilyRequest(String action) async {
    String? token = await getAccessToken();
    if (token == null) {
      print('No token found!');
      return;
    }

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final response = await http.post(
      Uri.parse('http://127.0.0.1:8000/api/family/invitation/respond/'),
      headers: headers,
      body: jsonEncode({'request_id': _pendingFamilyRequest['id'], 'action': action}),
    );

    if (response.statusCode == 200) {
      print('가족 초대 요청 처리 완료');
      setState(() {
        _pendingFamilyRequest = null; // 요청 처리 후 초기화
      });
    } else {
      print('가족 초대 요청 처리 실패');
    }
  }

  void _showPendingRequestDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('가족 초대 요청'),
          content: Text(
              '${_pendingFamilyRequest['family']['family_name']} 가족에 가입하시겠습니까?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                _respondToFamilyRequest('승인');
                Navigator.of(context).pop();
              },
              child: Text('승인'),
            ),
            TextButton(
              onPressed: () {
                _respondToFamilyRequest('거절');
                Navigator.of(context).pop();
              },
              child: Text('거절'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('가족 관리')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _showCreateFamilyDialog,
              child: Text('가족 만들기'),
            ),
            TextField(
              decoration: InputDecoration(labelText: '사용자 검색'),
              onChanged: _searchUser,
            ),
            SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredUsers.length,
                itemBuilder: (context, index) {
                  final user = _filteredUsers[index];
                  return ListTile(
                    title: Text(user['username']),
                    subtitle: Text(user['nickname'] ?? ''),
                    trailing: IconButton(
                      icon: Icon(Icons.person_add),
                      onPressed: () {
                        _sendFamilyInvitation(user['id'].toString());
                      },
                    ),
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
