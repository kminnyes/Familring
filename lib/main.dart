import 'package:familring2/bucket_list_screen.dart';
import 'package:familring2/calender_main_screen.dart';
import 'package:familring2/login_screen.dart';
import 'package:familring2/signup_screen.dart';
import 'package:familring2/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'question_list_screen.dart';
import 'home_screen.dart';
import 'calender_component_screen.dart';
import 'mypage_screen.dart' as mypage; // 별칭 사용하여 중복 방지
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:familring2/font_size_settings_screen.dart'; // 글씨 크기 변경 페이지 import
import 'package:familring2/token_util.dart'; // 토큰 유틸리티 함수 임포트
import 'package:intl/date_symbol_data_local.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await initializeDateFormatting('ko_KR', null);

  // 저장된 토큰이 있는지 확인
  String? token = await getToken();

  // 저장된 글씨 크기 가져오기
  double savedFontSize = await getSavedFontSize();

  // 초기 경로 설정: 토큰이 없으면 로그인 화면, 있으면 홈 화면
  runApp(MyApp(
    initialRoute: token == null ? '/welcome' : '/home',
    fontSize: savedFontSize,
  ));
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  final double fontSize;

  MyApp({required this.initialRoute, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Navigation Bar',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white, //앱 기본 배경색을 흰색으로 설정
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
        ),
        textTheme: TextTheme(
          bodyMedium: TextStyle(fontSize: fontSize), // `bodyMedium` 사용
          bodyLarge: TextStyle(fontSize: fontSize),
          headlineSmall: TextStyle(fontSize: fontSize), // 헤드라인에도 적용
        ),
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: initialRoute, // 초기 경로 설정
      routes: {
        '/login': (context) => LoginScreen(),
        '/signup': (context) => SignupScreen(),
        '/home': (context) => MyHomePage(),
        '/calender': (context) => CalendarMainScreen(),
        '/bucketlist': (context) => BucketListScreen(),
        '/today_question': (context) => QuestionListScreen(),
        '/edit_profile': (context) => mypage.EditProfileScreen(nickname: '닉네임'),
        '/font_size_settings': (context) => FontSizeSettingsScreen(),
        '/welcome' : (context) => WelcomeScreen()
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 2; //완료되면 0으로 바꿔서 home_screen으로 전환할 것!

  @override
  void initState() {
    super.initState();
  }


  static List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    QuestionListScreen(),
    CalendarComponentScreen(),
    mypage.MyPageScreen(),
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
        backgroundColor: Colors.white,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: ImageIcon(
              AssetImage('images/home_icon.png'),
              size: 35,
            ),
            label: '홈',
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
