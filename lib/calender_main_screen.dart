import 'package:flutter/material.dart';
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
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _fetchEvents();
  }

  List<Event> _getEventsForDay(DateTime day) {
    final events = _events[DateTime(day.year, day.month, day.day)] ?? [];
    print("날짜: $day, 이벤트: $events");  // 해당 날짜의 이벤트 확인
    return events;
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        _selectedEvents = _getEventsForDay(selectedDay);
      });
    }
  }

  void _addEvent(DateTime startDate, DateTime endDate, String title, String content, String eventType) {
    DateTime eventDate = startDate;

    // 시작일부터 종료일까지 반복하며 모든 날짜에 이벤트 추가
    while (!eventDate.isAfter(endDate)) { // 종료일을 포함하여 반복
      DateTime eventDay = DateTime(eventDate.year, eventDate.month, eventDate.day);

      if (_events[eventDay] != null) {
        _events[eventDay]!.add(Event(title, eventType));
      } else {
        _events[eventDay] = [Event(title, eventType)];
      }

      // 데이터베이스에 각 날짜에 해당하는 이벤트 저장
      _addEventToDatabase(title, content, eventDate);

      // 다음 날짜로 넘어가기
      eventDate = eventDate.add(Duration(days: 1));
    }

    // 선택된 날짜에 대한 이벤트 리스트 갱신
    setState(() {
      _selectedEvents = _getEventsForDay(_selectedDay);
    });
  }



  Future<void> _addEventToDatabase(String title, String content, DateTime date) async {
    final url = 'http://your-django-server-url/add-event/';

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token your_token',
      },
      body: jsonEncode({
        'event_title': title,
        'event_content': content,
        'start_date': date.toIso8601String().split('T')[0],
        'end_date': date.toIso8601String().split('T')[0],
      }),
    );

    if (response.statusCode == 201) {
      print('Event added to database');
    } else {
      print('Failed to add event to database');
    }
  }

  Future<void> _fetchEvents() async {
    final url = 'http://your-django-server-url/get-family-events/';

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token your_token',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);

      data.forEach((eventData) {
        DateTime eventDate = DateTime.parse(eventData['start_date']);
        DateTime keyDate = DateTime(eventDate.year, eventDate.month, eventDate.day);
        String title = eventData['event_title'];
        String eventType = eventData['event_type'];

        if (_events[keyDate] != null) {
          _events[keyDate]!.add(Event(title, eventType));
        } else {
          _events[keyDate] = [Event(title, eventType)];
        }
      });

      setState(() {
        _selectedEvents = _getEventsForDay(_selectedDay);
      });
    } else {
      print('Failed to fetch events from database');
    }
  }

  void _showAddEventDialog() {
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
                      Navigator.of(context).pop();
                      _addEvent(selectedStartDate, selectedEndDate, eventContent, eventContent, eventType);
                      if (selectedStartDate != selectedEndDate) {
                        setState(() {
                          _rangeStart = selectedStartDate;
                          _rangeEnd = selectedEndDate;
                        });
                      }
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
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: _onDaySelected,
              eventLoader: _getEventsForDay,
              rangeStartDay: _rangeStart,
              rangeEndDay: _rangeEnd,
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
                rangeStartDecoration: BoxDecoration(
                  color: Colors.yellow, // 범위 시작일 색상
                  shape: BoxShape.circle,
                ),
                rangeEndDecoration: BoxDecoration(
                  color: Colors.yellow, // 범위 끝일 색상
                  shape: BoxShape.circle,
                ),
                rangeHighlightColor: Colors.limeAccent.withOpacity(0.5),
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
                            width: 8,
                            height: 8,
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
                            width: 8,
                            height: 8,
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
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(80.0),
        child: ElevatedButton(
          onPressed: _showAddEventDialog,
          style: ElevatedButton.styleFrom(
            backgroundColor: Color.fromARGB(255, 255, 186, 81),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30.0),
            ),
            padding: EdgeInsets.symmetric(vertical: 16),
            minimumSize: Size(double.infinity, 60),
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
  final String title;
  final String eventType;

  Event(this.title, this.eventType);

  @override
  String toString() => title;
}