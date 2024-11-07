import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Transform.translate(
                offset: Offset(-10, 0),
                child: Image.asset(
                  'images/login_icon.png',
                  width: 240,
                  height: 140,
                ),
              ),
              SizedBox(height: 70),

              // "로그인하러 가기" 버튼
              SizedBox(
                width: 260, // 가로 크기 조정
                height: 50, // 세로 크기 조정
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/login'); // 로그인 페이지로 이동
                  },
                  child: Text(
                    '로그인',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 253, 200, 82),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 25),

              // "회원 가입하기" 버튼
              SizedBox(
                width: 260, // 가로 크기 조정
                height: 50, // 세로 크기 조정
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/signup'); // 회원가입 페이지로 이동
                  },
                  child: Text(
                    '회원 가입',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 253, 200, 82),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
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
