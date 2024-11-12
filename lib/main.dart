import 'package:familring2/bucket_list_screen.dart';
import 'package:familring2/calender_main_screen.dart';
import 'package:familring2/login_screen.dart';
import 'package:familring2/signup_screen.dart';
import 'package:familring2/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Provider 패키지 추가
import 'question_list_screen.dart';
import 'home_screen.dart';
import 'calender_component_screen.dart';
import 'mypage_screen.dart' as mypage; // 별칭 사용하여 중복 방지
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:familring2/font_size_settings_screen.dart'; // 글씨 크기 변경 페이지 import
import 'package:familring2/token_util.dart'; // 토큰 유틸리티 함수 임포트
import 'package:intl/date_symbol_data_local.dart';
import 'font_size_provider.dart'; // 글씨 크기 상태 관리 Provider 추가

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await initializeDateFormatting('ko_KR', null);

  // 저장된 토큰이 있는지 확인
  String? token = await getAccessToken();

  runApp(
    ChangeNotifierProvider(
      create: (context) => FontSizeProvider()..loadFontSize(),
      child: MyApp(initialRoute: '/welcome'),
    ),
  );
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  MyApp({required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return Consumer<FontSizeProvider>(
      builder: (context, fontSizeProvider, child) {
        return MaterialApp(
          title: 'Flutter Navigation Bar',
          theme: ThemeData(
            primarySwatch: Colors.amber, // 앱의 기본 색상을 주황색으로 설정
            scaffoldBackgroundColor: Colors.white, // 앱 기본 배경색을 흰색으로 설정
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.white,
              iconTheme: IconThemeData(color: Colors.black), // 앱바 아이콘 색상을 검은색으로 설정
            ),
            textTheme: TextTheme(
              bodyMedium: TextStyle(fontSize: fontSizeProvider.fontSize),
              bodyLarge: TextStyle(fontSize: fontSizeProvider.fontSize),
              headlineSmall: TextStyle(fontSize: fontSizeProvider.fontSize),
            ),
            colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.amber).copyWith(
              secondary: Colors.amber, // 강조 색상 설정
            ),
            inputDecorationTheme: InputDecorationTheme(
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.amber), // 입력 필드 포커스 색상 설정
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
          ),
          debugShowCheckedModeBanner: false,
          initialRoute: initialRoute,
          routes: {
            '/login': (context) => LoginScreen(),
            '/signup': (context) => SignupScreen(),
            '/home': (context) => MyHomePage(),
            '/calender': (context) => CalendarMainScreen(),
            '/bucketlist': (context) => BucketListScreen(),
            '/today_question': (context) => QuestionListScreen(),
            '/edit_profile': (context) => mypage.EditProfileScreen(nickname: '닉네임'),
            '/font_size_settings': (context) => FontSizeSettingsScreen(),
            '/welcome': (context) => WelcomeScreen(),
          },
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0; // 완료되면 0으로 바꿔서 home_screen으로 전환할 것!

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
