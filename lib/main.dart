import 'package:familring2/bucket_list_screen.dart';
import 'package:familring2/calender_main_screen.dart';
import 'package:familring2/login_screen.dart';
import 'package:familring2/signup_screen.dart';
import 'package:familring2/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'photo_album_screen.dart';
import 'question_list_screen.dart';
import 'home_screen.dart';
import 'calender_component_screen.dart';
import 'mypage_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async{
  await dotenv.load(fileName: ".env");
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Flutter Navigation Bar',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        debugShowCheckedModeBanner: false,
        home: WelcomeScreen(),
        routes:{
          '/login' : (context) => LoginScreen(),
          '/signup' : (context) => SignupScreen(),
          '/home' : (context) => MyHomePage(),
          '/calender' : (context) => CalendarMainScreen(),
          '/bucketlist' : (context) => BucketListScreen(),
          '/today_question': (context) => QuestionListScreen(),
        }
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 2;

  static List<Widget> _widgetOptions = <Widget>[
    PhotoAlbumScreen(),
    QuestionListScreen(),
    HomeScreen(),
    CalendarComponentScreen(),
    MyPageScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: ImageIcon(
              AssetImage('images/photo_album_icon.png'),
              size: 40,
            ),
            label: '가족앨범',
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(
              AssetImage('images/question_list_icon.png'),
              size: 35,
            ),
            label: '데일리로그',
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(
              AssetImage('images/home_icon.png'),
              size: 35,
            ),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(
              AssetImage('images/calender_icon.png'),
              size: 35,
            ),
            label: '캘린더',
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(
              AssetImage('images/mypage_icon.png'),
              size: 35,
            ),
            label: '내정보',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Color.fromARGB(255, 101, 101, 101),
        unselectedItemColor: Color.fromARGB(255, 218, 218, 218),
        onTap: _onItemTapped,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),
    );
  }
}
