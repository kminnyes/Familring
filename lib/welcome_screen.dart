import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // familring_welcome.png 이미지 표시
              Image.asset(
                'images/familring_welcome.png',  // 이미지 경로 설정
                width: 300,
                height: 290,
              ),
              SizedBox(height: 40),

              // "로그인하러 가기" 버튼
              SizedBox(
                width: 220, // 가로 크기 조정
                height: 60, // 세로 크기 조정
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/login');  // 로그인 페이지로 이동
                  },
                  child: Text(
                    '로그인하러 가기',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 253, 200, 82),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    minimumSize: Size(250, 50), // 최소 크기 설정
                  ),
                ),
              ),
              SizedBox(height: 30),

              // "회원 가입하기" 버튼
              SizedBox(
                width: 220, // 가로 크기 조정
                height: 60, // 세로 크기 조정
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/signup');  // 회원가입 페이지로 이동
                  },
                  child: Text(
                    '회원 가입하기',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 253, 200, 82),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    minimumSize: Size(250, 50), // 최소 크기 설정
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
