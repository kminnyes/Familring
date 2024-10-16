import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CalendarMainScreen extends StatefulWidget {
  @override
  _CalendarMainScreenState createState() => _CalendarMainScreenState();
}

class _CalendarMainScreenState extends State<CalendarMainScreen> {
  // 이벤트를 저장하는 Map을 초기화합니다.
  Map<DateTime, List<Event>> _events = {};
  List<Event> _selectedEvents = [];
  late DateTime _focusedDay;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    // 앱 초기화 시 백엔드에서 이벤트를 가져옵니다.
    _fetchEvents();
  }

  // 특정 날짜의 이벤트를 가져옵니다.
  List<Event> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  // 날짜를 선택했을 때 호출됩니다.
  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        _selectedEvents = _getEventsForDay(selectedDay);
      });
    }
  }

  // 이벤트를 추가하고 백엔드에 저장합니다.
  void _addEvent(DateTime date, String title, String content) {
    DateTime eventDate = DateTime(date.year, date.month, date.day);

    // 로컬 이벤트 리스트에 추가합니다.
    if (_events[eventDate] != null) {
      _events[eventDate]!.add(Event(title));
    } else {
      _events[eventDate] = [Event(title)];
    }

    // 백엔드에 이벤트를 저장합니다.
    _addEventToDatabase(title, content, date);

    setState(() {
      _selectedEvents = _getEventsForDay(_selectedDay);
    });
  }

  // 백엔드에 이벤트를 저장하는 함수입니다.
  Future<void> _addEventToDatabase(String title, String content, DateTime date) async {
    final url = 'http://your-django-server-url/add-event/';

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token your_token',  // 필요 시 인증 토큰 추가
      },
      body: jsonEncode({
        'event_title': title,  // Django의 필드명에 맞게 전송
        'event_content': content,
        'start_date': date.toIso8601String().split('T')[0],  // 날짜는 ISO 포맷으로 전송
        'end_date': date.toIso8601String().split('T')[0],    // 단일 날짜 이벤트로 설정
      }),
    );

    if (response.statusCode == 201) {
      print('Event added to database');
    } else {
      print('Failed to add event to database');
    }
  }

  // 백엔드에서 이벤트를 가져오는 함수입니다.
  Future<void> _fetchEvents() async {
    final url = 'http://your-django-server-url/get-family-events/';

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token your_token',  // 필요 시 인증 토큰 추가
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);

      // 가져온 이벤트를 로컬 _events에 추가합니다.
      data.forEach((eventData) {
        DateTime eventDate = DateTime.parse(eventData['start_date']);
        DateTime keyDate = DateTime(eventDate.year, eventDate.month, eventDate.day);
        String title = eventData['event_title'];

        if (_events[keyDate] != null) {
          _events[keyDate]!.add(Event(title));
        } else {
          _events[keyDate] = [Event(title)];
        }
      });

      setState(() {
        _selectedEvents = _getEventsForDay(_selectedDay);
      });
    } else {
      print('Failed to fetch events from database');
    }
  }

  // 일정 추가 다이얼로그를 표시합니다.
  void _showAddEventDialog() {
    DateTime selectedDate = _selectedDay;
    String eventTitle = '';
    String eventContent = '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('일정 추가'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.calendar_today),
                title: Text("${selectedDate.toLocal()}".split(' ')[0]),
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null && picked != selectedDate) {
                    setState(() {
                      selectedDate = picked;
                    });
                  }
                },
              ),
              TextField(
                onChanged: (value) {
                  eventTitle = value;
                },
                decoration: InputDecoration(hintText: "일정 제목을 입력하세요"),
              ),
              TextField(
                onChanged: (value) {
                  eventContent = value;
                },
                decoration: InputDecoration(hintText: "일정 내용을 입력하세요"),
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
              child: Text('추가'),
              onPressed: () {
                if (eventTitle.isNotEmpty && eventContent.isNotEmpty) {
                  Navigator.of(context).pop(); // 다이얼로그를 닫습니다.
                  _addEvent(selectedDate, eventTitle, eventContent);
                }
              },
            ),
          ],
        );
      },
    );
  }

  // UI를 빌드합니다.
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
      body: Container(
        color: Colors.white,
        child: Column(
          children: [
            SizedBox(height: 40), // AppBar와 캘린더 사이의 간격입니다.
            TableCalendar(
              focusedDay: _focusedDay,
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: _onDaySelected,
              eventLoader: _getEventsForDay,
              calendarStyle: CalendarStyle(
                todayTextStyle: TextStyle(color: Colors.white),
                todayDecoration: BoxDecoration(
                  color: Colors.orangeAccent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orangeAccent.withOpacity(0.5),
                      spreadRadius: 0,
                      blurRadius: 0,
                      offset: Offset(0, 0),
                    ),
                  ],
                ),
                selectedDecoration: BoxDecoration(
                  color: Colors.orangeAccent,
                  shape: BoxShape.circle,
                ),
                markerDecoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                outsideDaysVisible: true,
                outsideTextStyle: TextStyle(color: Colors.grey.withOpacity(0.5)), // 지난 달과 다음 달 날짜를 옅은 회색으로 표시
                disabledTextStyle: TextStyle(color: Colors.grey),
                weekendTextStyle: TextStyle(
                  color: Colors.red,
                ),
                cellMargin: EdgeInsets.symmetric(vertical: 14.0),
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextFormatter: (date, locale) {
                  return '${date.year}년 ${date.month}월'; // '2024년 10월' 형식으로 표시
                },
                titleTextStyle: TextStyle(
                  fontSize: 23, // 글씨 크기 설정
                  fontWeight: FontWeight.bold, // 굵은 글씨 설정
                  color: Color.fromARGB(255, 255, 207, 102),
                ),
                leftChevronIcon: Icon(Icons.chevron_left, size: 30, color: Color.fromARGB(255, 255, 207, 102)),
                rightChevronIcon: Icon(Icons.chevron_right, size: 30, color: Color.fromARGB(255, 255, 207, 102)),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
                weekendStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue, // 토요일은 파란색으로 설정
                ),
              ),
              daysOfWeekHeight: 40.0, // 요일 부분의 높이를 키움
              calendarBuilders: CalendarBuilders(
                dowBuilder: (context, day) {
                  final days = ['월', '화', '수', '목', '금', '토', '일'];
                  final text = days[day.weekday - 1];

                  return Center(
                    child: Text(
                      text,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: day.weekday == DateTime.saturday
                            ? Colors.blue // 토요일 색상
                            : day.weekday == DateTime.sunday
                            ? Colors.red // 일요일 색상
                            : Colors.black,
                      ),
                    ),
                  );
                },
                defaultBuilder: (context, date, _) {
                  if (date.weekday == DateTime.saturday) {
                    return Center(
                      child: Text(
                        '${date.day}',
                        style: TextStyle(color: Colors.blue),
                      ),
                    );
                  } else if (date.weekday == DateTime.sunday) {
                    return Center(
                      child: Text(
                        '${date.day}',
                        style: TextStyle(color: Colors.red),
                      ),
                    );
                  }
                  return null;
                },
                markerBuilder: (context, date, events) {
                  if (events.isNotEmpty) {
                    return Positioned(
                      right: 1,
                      bottom: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        width: 16,
                        height: 16,
                        child: Center(
                          child: Text(
                            '${events.length}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.0,
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                  return SizedBox();
                },
              ),
            ),




            Expanded(
              child: ListView.builder(
                itemCount: _selectedEvents.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_selectedEvents[index].title),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.all(20.0),
        child: FloatingActionButton(
          onPressed: _showAddEventDialog,
          backgroundColor: Color.fromARGB(255, 255, 207, 102),
          child: Icon(Icons.add),
        ),
      ),
    );
  }
}

// 이벤트 모델 클래스입니다.
class Event {
  final String title;

  Event(this.title);

  @override
  String toString() => title;
}
