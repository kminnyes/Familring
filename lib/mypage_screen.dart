import 'package:flutter/material.dart';

class MyPageScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('마이페이지'),
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 20),
            CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage('images/mypage.png'), // 프로필 이미지
            ),
            SizedBox(height: 10),
            Text(
              '홍길동 님',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 30),
            ListTile(
              title: Text('내 프로필 편집'),
              trailing: Icon(Icons.arrow_forward_ios),
              onTap: () {
                // 내 프로필 편집 페이지로 이동
              },
            ),
            ListTile(
              title: Text('가족 구성 관리'),
              trailing: Icon(Icons.arrow_forward_ios),
              onTap: () {
                // 가족 구성 관리 페이지로 이동
              },
            ),
            SizedBox(height: 30),
            ListTile(
              title: Text('알림 설정'),
              trailing: Icon(Icons.arrow_forward_ios),
              onTap: () {
                // 알림 설정 페이지로 이동
              },
            ),
            ListTile(
              title: Text('글씨체 변경'),
              trailing: Icon(Icons.arrow_forward_ios),
              onTap: () {
                // 글씨체 변경 페이지로 이동
              },
            ),
            ListTile(
              title: Text('회원 탈퇴'),
              trailing: Icon(Icons.arrow_forward_ios),
              onTap: () {
                // 회원 탈퇴 페이지로 이동
              },
            ),
          ],
        ),
      ),
    );
  }
}
