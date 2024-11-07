import 'package:familring2/token_util.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class CalendarMainScreen extends StatefulWidget {
  @override
  _CalendarMainScreenState createState() => _CalendarMainScreenState();
}

class _CalendarMainScreenState extends State<CalendarMainScreen> {
  Map<DateTime, List<Event>> _events = {};
  List<Event> _selectedEvents = [];
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  String nickname = ''; // 닉네임 저장
  int? familyId;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _loadNicknameFromSharedPreferences();
    _loadFamilyIdFromSharedPreferences().then((_) {
      if (familyId != null) {
        _fetchEvents(familyId!);
      }
    });


  }

  Future<void> _loadFamilyIdFromSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      familyId = prefs.getInt('family_id') ?? null; // 기본적으로 null 설정
      print('Family ID loaded from SharedPreferences: $familyId');
    });
  }


    Future<void> _loadNicknameFromSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      nickname = prefs.getString('nickname') ?? '';

      // 닉네임이 제대로 불러와졌는지 확인하는 출력
      print('Nickname loaded from SharedPreferences: $nickname');
    });
  }

  List<Event> _getEventsForDay(DateTime day) {
    final localDay = DateTime(day.year, day.month, day.day);
    List<Event> events = [];

    _events.forEach((eventDate, eventList) {
      eventList.forEach((event) {
        // 이벤트가 시작일, 종료일에 포함되도록 조건 수정
        if (!localDay.isBefore(event.startDate) && !localDay.isAfter(event.endDate)) {
          events.add(event);
        }
      });
    });

    print("날짜: $localDay, 이벤트: $events");
    return events;
  }


  // 중복 제거 함수
  List<Event> _getUniqueEvents(List<Event> events) {
    final seen = <String>{};
    return events.where((event) {
      final uniqueKey = '${event.eventContent}-${event.startDate.toIso8601String()}-${event.endDate.toIso8601String()}';
      if (seen.contains(uniqueKey)) {
        return false;
      } else {
        seen.add(uniqueKey);
        return true;
      }
    }).toList();
  }


  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        _selectedEvents = _getEventsForDay(selectedDay);
        print("Selected events on $_selectedDay: $_selectedEvents");  // 확인용 출력
      });
    }
  }

  void _addEvent(DateTime startDate, DateTime endDate, String content, String eventType) {
    DateTime eventDate = startDate;

    // 시작일부터 종료일까지 모든 날짜에 이벤트 추가
    while (!eventDate.isAfter(endDate)) {
      DateTime eventDay = DateTime(eventDate.year, eventDate.month, eventDate.day);

      Event newEvent = Event(
        eventType,
        content,
        startDate,
        endDate,
        nickname: eventType == '개인일정' ? nickname : null,
      );

      if (_events[eventDay] != null) {
        _events[eventDay]!.add(newEvent);
      } else {
        _events[eventDay] = [newEvent];
      }

      eventDate = eventDate.add(Duration(days: 1));
    }


    setState(() {
      _selectedEvents = _getEventsForDay(_selectedDay); // 화면에 바로 반영되도록 업데이트
    });

    // DB에 이벤트 추가 후 화면 업데이트만 진행
    Future.delayed(Duration.zero, () async {
      await _addEventToDatabase(eventType, nickname, content, startDate, endDate);
    });
  }




  Future<void> _addEventToDatabase(String eventType, String nickname, String content, DateTime startDate, DateTime endDate) async {
    final token = await getToken();
    final url = 'http://127.0.0.1:8000/api/add-event/';

    if (token == null) {
      print("Error: Token is null");
      return;
    }

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'event_type': eventType,
        'nickname': eventType == '개인일정' ? nickname : null,
        'event_content': content,
        'start_date': startDate.toIso8601String().split('T')[0],
        'end_date': endDate.toIso8601String().split('T')[0],
        'family_id': familyId,  // 이미 로드된 familyId를 사용
      }),
    );

    if (response.statusCode == 201) {
      print('Event added to database');
    } else {
      print('Failed to add event to database: ${response.statusCode} - ${response.body}');
    }
  }




  //이벤트 가져오기
  Future<void> _fetchEvents(int familyId) async {
    final url = 'http://127.0.0.1:8000/api/get-family-events/?family_id=$familyId';
    final accessToken = await getAccessToken();

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      Map<DateTime, List<Event>> fetchedEvents = {}; // 새로운 맵 생성

      for (var eventData in data) {
        DateTime startDate = DateTime.parse(eventData['start_date']).toLocal();
        DateTime endDate = DateTime.parse(eventData['end_date']).toLocal();
        DateTime keyDate = DateTime(startDate.year, startDate.month, startDate.day);
        String eventType = eventData['event_type'];
        String? nickname = eventData['nickname'];
        String eventContent = eventData['event_content'];

        Event event = Event(eventType, eventContent, startDate, endDate, nickname: nickname);

        if (fetchedEvents[keyDate] != null) {
          fetchedEvents[keyDate]!.add(event);
        } else {
          fetchedEvents[keyDate] = [event];
        }
      }

      setState(() {
        _events = fetchedEvents; // `_events`를 새로운 맵으로 업데이트
        _selectedEvents = _getEventsForDay(_selectedDay); // 새로 고침된 이벤트 설정
      });
    } else {
      print('Failed to fetch events: ${response.statusCode} - ${response.body}');
    }
  }



  // 이벤트를 삭제하는 함수
  void _deleteEvent(Event event) async {
    DateTime eventDate = event.startDate;

    // 로컬에서 이벤트 삭제
    while (!eventDate.isAfter(event.endDate)) {
      DateTime eventDay = DateTime(eventDate.year, eventDate.month, eventDate.day);
      if (_events[eventDay] != null) {
        _events[eventDay]!.removeWhere((e) => e.eventContent == event.eventContent && e.startDate == event.startDate && e.endDate == event.endDate);
        if (_events[eventDay]!.isEmpty) {
          _events.remove(eventDay);
        }
      }
      eventDate = eventDate.add(Duration(days: 1));
    }

    setState(() {
      _selectedEvents = _getUniqueEvents(_getEventsForDay(_selectedDay));
    });

    // 서버에서 이벤트 삭제
    await _deleteEventFromDatabase(event);
  }



  // 서버에 삭제 요청 보내는 함수
  Future<void> _deleteEventFromDatabase(Event event) async {
    final url = 'http://127.0.0.1:8000/api/delete-event/'; // trailing slash 유지
    final accessToken = await getAccessToken();

    final response = await http.delete(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({
        'event_type': event.eventType,
        'nickname': event.nickname,
        'event_content': event.eventContent,
        'start_date': event.startDate.toIso8601String().split('T')[0],
        'end_date': event.endDate.toIso8601String().split('T')[0],
      }),
    );

    if (response.statusCode == 200) {
      print('Event deleted from database');
    } else {
      print('Failed to delete event from database: ${response.statusCode} - ${response.body}');
    }
  }


  // 삭제 확인 팝업을 띄우는 함수
  Future<void> _showDeleteConfirmationDialog(Event event) async {
    final result = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          content: Text('이 일정을 삭제하시겠습니까?'),
          actions: <Widget>[
            TextButton(
              child: Text('취소',
                style: TextStyle(
                  color: Color(0xFFFFA651),
                  fontWeight: FontWeight.bold,
                ),),

              onPressed: () {
                Navigator.of(context).pop(false); // 삭제 취소
              },
            ),
            TextButton(
              child: Text('삭제',
                style: TextStyle(
                  color: Color(0xFFFFA651),
                  fontWeight: FontWeight.bold,
                ),),
              onPressed: () {
                Navigator.of(context).pop(true); // 삭제 진행
              },
            ),
          ],
        );
      },
    );

    if (result == true) {
      _deleteEvent(event); // 삭제 함수 호출
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('삭제되었습니다'),
        ),
      );
    }
  }

  // 롱프레스 이벤트가 발생했을 때 삭제 확인 팝업 호출
  Widget _buildEventItem(Event event) {
    final isFamilyEvent = event.eventType == '가족일정';
    final displayName = isFamilyEvent ? '우리 가족' : event.nickname ?? nickname;
    final suffix = isFamilyEvent ? '은' : '님은';

    return InkWell(
      onTap: () {
        print("Event tapped: ${event.eventContent}");
        _showEditEventDialog(event); // 다이얼로그 표시
      },
      onLongPress: () {
        print("Long press detected for event: ${event.eventContent}");
        _showDeleteConfirmationDialog(event);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Color.fromARGB(255, 255, 186, 81), width: 1.5),
            borderRadius: BorderRadius.circular(12.0),
          ),
          padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          alignment: Alignment.center,
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(
                  text: displayName,
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                TextSpan(
                  text: " $suffix 오늘 ",
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.normal,
                    color: Colors.black,
                  ),
                ),
                TextSpan(
                  text: event.eventContent,
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 255, 186, 81),
                  ),
                ),
                TextSpan(
                  text: " 일정",
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 255, 186, 81),
                  ),
                ),
                TextSpan(
                  text: "이 있어요",
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.normal,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  void _showAddEventDialog() {
    if (familyId == null) {
      _showNoFamilyDialog(); // familyId가 없을 때 팝업 표시
      return;
    }

    DateTime selectedStartDate = _selectedDay;
    DateTime selectedEndDate = _selectedDay;
    String eventContent = '';
    String eventType = '개인일정'; // 기본값 설정

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: Text('일정 추가'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    DropdownButtonFormField<String>(
                      value: eventType,
                      dropdownColor: Colors.white,
                      onChanged: (value) {
                        setState(() {
                          eventType = value!;
                        });
                      },
                      items: <String>['가족일정', '개인일정']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      decoration: InputDecoration(
                        labelText: '일정 종류 선택',
                      ),
                    ),
                    ListTile(
                      leading: Icon(Icons.calendar_today),
                      title: Text(
                        "시작 날짜: ${DateFormat('MM월 dd일 EEEE', 'ko_KR').format(selectedStartDate)}",
                      ),
                      onTap: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedStartDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                          builder: (BuildContext context, Widget? child) {
                            return Theme(
                              data: ThemeData.light().copyWith(
                                primaryColor: Color(0xFFFFA651),
                                dialogBackgroundColor: Colors.white,
                                textTheme: TextTheme(
                                  headlineMedium: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                  titleMedium: TextStyle(color: Colors.black),
                                  labelLarge: TextStyle(color: Color(0xFFFFA651), fontWeight: FontWeight.bold),
                                ),
                                colorScheme: ColorScheme.light(
                                  primary: Color(0xFFFFA651),
                                  onPrimary: Colors.white,
                                  surface: Colors.white,
                                  onSurface: Colors.black,
                                ),
                                buttonTheme: ButtonThemeData(
                                  textTheme: ButtonTextTheme.primary,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null && picked != selectedStartDate) {
                          setState(() {
                            selectedStartDate = picked;
                            if (selectedEndDate.isBefore(selectedStartDate)) {
                              selectedEndDate = selectedStartDate;
                            }
                          });
                        }
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.calendar_today),
                      title: Text(
                        "끝 날짜: ${DateFormat('MM월 dd일 EEEE', 'ko_KR').format(selectedEndDate)}",
                      ),
                      onTap: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedEndDate,
                          firstDate: selectedStartDate,
                          lastDate: DateTime(2030),
                          builder: (BuildContext context, Widget? child) {
                            return Theme(
                              data: ThemeData.light().copyWith(
                                primaryColor: Color(0xFFFFA651),
                                dialogBackgroundColor: Colors.white,
                                textTheme: TextTheme(
                                  headlineMedium: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                  titleMedium: TextStyle(color: Colors.black),
                                  labelLarge: TextStyle(color: Color(0xFFFFA651), fontWeight: FontWeight.bold),
                                ),
                                colorScheme: ColorScheme.light(
                                  primary: Color(0xFFFFA651),
                                  onPrimary: Colors.white,
                                  surface: Colors.white,
                                  onSurface: Colors.black,
                                ),
                                buttonTheme: ButtonThemeData(
                                  textTheme: ButtonTextTheme.primary,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null && picked != selectedEndDate) {
                          setState(() {
                            selectedEndDate = picked;
                          });
                        }
                      },
                    ),
                    TextField(
                      onChanged: (value) {
                        eventContent = value;
                      },
                      decoration: InputDecoration(hintText: "일정 내용을 입력하세요"),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(
                    '취소',
                    style: TextStyle(
                      color: Color(0xFFFFA651),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text(
                    '추가',
                    style: TextStyle(
                      color: Color(0xFFFFA651),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () {
                    if (eventContent.isNotEmpty) {
                      setState(() {
                        _selectedDay = selectedStartDate;  // _selectedDay를 selectedStartDate로 설정
                      });
                      Navigator.of(context).pop();
                      _addEvent(selectedStartDate, selectedEndDate, eventContent, eventType);
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );

  }


  void _showEditEventDialog(Event event) {
    if (familyId == null) {
      _showNoFamilyDialog();
      return;
    }

    DateTime selectedStartDate = event.startDate;
    DateTime selectedEndDate = event.endDate;
    String eventContent = event.eventContent;
    String eventType = event.eventType;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: Text('일정 수정'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    DropdownButtonFormField<String>(
                      value: eventType,
                      onChanged: (value) {
                        setState(() {
                          eventType = value!;
                        });
                      },
                      items: <String>['가족일정', '개인일정']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      decoration: InputDecoration(
                        labelText: '일정 종류 선택',
                      ),
                    ),
                    ListTile(
                      leading: Icon(Icons.calendar_today),
                      title: Text("시작 날짜: ${DateFormat('MM월 dd일 EEEE', 'ko_KR').format(selectedStartDate)}"),
                      onTap: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedStartDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setState(() {
                            selectedStartDate = picked;
                            if (selectedEndDate.isBefore(selectedStartDate)) {
                              selectedEndDate = selectedStartDate;
                            }
                          });
                        }
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.calendar_today),
                      title: Text("끝 날짜: ${DateFormat('MM월 dd일 EEEE', 'ko_KR').format(selectedEndDate)}"),
                      onTap: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedEndDate,
                          firstDate: selectedStartDate,
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setState(() {
                            selectedEndDate = picked;
                          });
                        }
                      },
                    ),
                    TextField(
                      controller: TextEditingController(text: eventContent),
                      onChanged: (value) {
                        eventContent = value;
                      },
                      decoration: InputDecoration(hintText: "일정 내용을 입력하세요"),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('취소'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text('수정'),
                  onPressed: () {
                    if (eventContent.isNotEmpty) {
                      Navigator.of(context).pop();
                      _updateEvent(event, selectedStartDate, selectedEndDate, eventContent, eventType);
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _updateEvent(Event oldEvent, DateTime newStartDate, DateTime newEndDate, String newContent, String newType) {
    // 로컬에서 일정 업데이트
    _deleteEvent(oldEvent);
    _addEvent(newStartDate, newEndDate, newContent, newType);

    // 서버에 업데이트 요청
    _updateEventInDatabase(oldEvent, newStartDate, newEndDate, newContent, newType);
  }

  Future<void> _updateEventInDatabase(Event oldEvent, DateTime newStartDate, DateTime newEndDate, String newContent, String newType) async {
    final url = 'http://127.0.0.1:8000/api/update-event/';
    final accessToken = await getAccessToken();

    final response = await http.put(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({
        'old_event_content': oldEvent.eventContent,
        'old_start_date': oldEvent.startDate.toIso8601String().split('T')[0],
        'old_end_date': oldEvent.endDate.toIso8601String().split('T')[0],
        'new_event_type': newType,
        'new_nickname': newType == '개인일정' ? nickname : null,
        'new_event_content': newContent,
        'new_start_date': newStartDate.toIso8601String().split('T')[0],
        'new_end_date': newEndDate.toIso8601String().split('T')[0],
        'family_id': familyId,
      }),
    );

    if (response.statusCode == 200) {
      print('Event updated successfully');
    } else {
      print('Failed to update event: ${response.statusCode} - ${response.body}');
    }
  }


  void _showNoFamilyDialog() {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.white,
            content: Text('가족이 생성되지 않았어요. \n 마이페이지에서 가족을 추가해주세요.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('확인',
                  style: TextStyle(
                    color: Color(0xFFFFA651),
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
      body: Container(
        color: Colors.white,
        child: Column(
          children: [
            SizedBox(height: 40),
            TableCalendar(
              focusedDay: _focusedDay,
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              selectedDayPredicate: (day) {
                final isSame = isSameDay(_selectedDay, day);
                print("selectedDayPredicate called for day: $day, isSame: $isSame"); // 디버그 출력
                return isSame;
              },
              onDaySelected: _onDaySelected,
              eventLoader: (day) {
                final events = _getEventsForDay(day);
                print("eventLoader called for day: $day, events: $events"); // 디버그 출력
                return events;
              },
              calendarStyle: CalendarStyle(
                todayTextStyle: TextStyle(color: Colors.white),
                todayDecoration: BoxDecoration(
                  color: Colors.orangeAccent,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Colors.orangeAccent,
                  shape: BoxShape.circle,
                ),
                markerDecoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                markerSize: 8.0,
                markersMaxCount: 2,
                // 범위 시작과 끝의 색상을 설정
                outsideDaysVisible: true,
                outsideTextStyle: TextStyle(color: Colors.grey.withOpacity(0.5)),
                disabledTextStyle: TextStyle(color: Colors.grey),
                weekendTextStyle: TextStyle(color: Colors.red),
                cellMargin: EdgeInsets.symmetric(vertical: 14.0),

              ),

              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextFormatter: (date, locale) {
                  return '${date.year}년 ${date.month}월';
                },
                titleTextStyle: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 255, 207, 102),
                ),
                leftChevronIcon: Icon(Icons.chevron_left, size: 30, color: Color.fromARGB(255, 255, 207, 102)),
                rightChevronIcon: Icon(Icons.chevron_right, size: 30, color: Color.fromARGB(255, 255, 207, 102)),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                weekendStyle: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
              ),
              daysOfWeekHeight: 40.0,
              calendarBuilders: CalendarBuilders(
                dowBuilder: (context, day) {
                  final days = ['월', '화', '수', '목', '금', '토', '일'];
                  final text = days[day.weekday - 1];

                  return Center(
                    child: Text(
                      text,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: day.weekday == DateTime.saturday ? Colors.blue : day.weekday == DateTime.sunday ? Colors.red : Colors.black,
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
                    // 'events'를 'List<Event>'로 캐스팅하여 'eventList'에 접근
                    final eventList = events.cast<Event>();

                    // 마커를 담을 리스트
                    List<Widget> markers = [];

                    // 먼저 '가족일정'을 추가
                    for (var event in eventList) {
                      if (event.eventType == '가족일정') {
                        markers.add(
                          Container(
                            margin: EdgeInsets.symmetric(horizontal: 2.0),
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                              color: Color(0xFF38963B), // 가족일정 마커는 초록색
                              shape: BoxShape.circle,
                            ),
                          ),
                        );
                        break; // 가족일정은 하나만 추가
                      }
                    }

                    // 그다음 나머지 일정 추가 ('가족일정' 제외)
                    for (var event in eventList) {
                      if (event.eventType != '가족일정') {
                        markers.add(
                          Container(
                            margin: EdgeInsets.symmetric(horizontal: 2.0),
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                              color: Color(0xFFFF9CBA), // 개인일정 마커는 분홍색
                              shape: BoxShape.circle,
                            ),
                          ),
                        );
                        break; // 개인일정도 하나만 추가
                      }
                    }

                    // 마커가 2개 이상이면 중단
                    return Positioned(
                      left: 0,
                      right: 0,
                      bottom: 1, // 날짜 아래에 배치
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center, // 가운데 정렬
                        children: markers.take(2).toList(), // 최대 2개의 마커만 표시
                      ),
                    );
                  }
                  return SizedBox();
                },



              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _getUniqueEvents(_selectedEvents).length,
                itemBuilder: (context, index) {
                  final event = _getUniqueEvents(_selectedEvents)[index];
                  return _buildEventItem(event); // _buildEventItem 함수로 이벤트 항목을 구성
                },
              ),
            ),






          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(left: 60.0, right: 60.0, bottom: 60.0), // 왼쪽, 오른쪽, 아래쪽 패딩 설정
        child: ElevatedButton(
          onPressed: _showAddEventDialog,
          style: ElevatedButton.styleFrom(
            backgroundColor: Color.fromARGB(255, 255, 186, 81),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30.0),
            ),
            padding: EdgeInsets.symmetric(vertical: 16), // 버튼 내부 패딩은 그대로 유지
            minimumSize: Size(double.infinity, 60), // 버튼 크기 유지
          ),
          child: Text(
            '일정 생성하기',
            style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

class Event {
  final String eventType;
  final String? nickname;
  final String eventContent;
  final DateTime startDate;
  final DateTime endDate;

  Event(this.eventType, this.eventContent, this.startDate, this.endDate,
      { this.nickname});

  @override
  String toString() => '$eventType: $eventContent ($startDate ~ $endDate)';
}



