import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'calender_main_screen.dart';
import 'bucket_list_screen.dart';

class CalendarComponentScreen extends StatefulWidget {
  @override
  _CalendarComponentScreenState createState() => _CalendarComponentScreenState();
}

class _CalendarComponentScreenState extends State<CalendarComponentScreen> {
  late Map<DateTime, List<Event>> _events;
  late List<Event> _selectedEvents;
  late DateTime _focusedDay;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    _events = {
      DateTime.utc(2024, 7, 16): [Event('아빠 생신')],
      DateTime.utc(2024, 7, 22): [Event('가족 여행 시작')],
      DateTime.utc(2024, 7, 25): [Event('가족 여행 종료')],
    };
    _selectedEvents = [];
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
  }

  List<Event> _getEventsForDay(DateTime day) {
    return _events[day] ?? [];
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('홈'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => BucketListScreen()),
                  );
                },
                child: Card(
                  color: Colors.orange.shade100,
                  child: ListTile(
                    leading: Icon(Icons.book, color: Colors.orange),
                    title: Text(
                      '우리 가족 버킷리스트',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('우리 가족 만의 버킷리스트를 만들고 함께 실천해보세요!'),
                  ),
                ),
              ),
              SizedBox(height: 50),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CalendarMainScreen()),
                  );
                },
                child: Card(
                  color: Colors.white,
                  elevation: 4,
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '7월',
                              style: TextStyle(fontSize: 32, color: Colors.orange),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20.0), // 네비게이션 바와의 간격을 주기 위해 패딩 추가
                        child: TableCalendar(
                          firstDay: DateTime.utc(2020, 1, 1),
                          lastDay: DateTime.utc(2030, 12, 31),
                          focusedDay: _focusedDay,
                          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                          onDaySelected: _onDaySelected,
                          eventLoader: _getEventsForDay,
                          calendarStyle: CalendarStyle(
                            todayTextStyle: TextStyle(color: Colors.black),
                            todayDecoration: BoxDecoration(
                              color: Colors.orangeAccent,
                              shape: BoxShape.circle,
                            ),
                            selectedDecoration: BoxDecoration(
                              color: Colors.orange,
                              shape: BoxShape.circle,
                            ),
                            markerDecoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                            outsideDaysVisible: false,
                            weekendTextStyle: TextStyle(color: Colors.red),
                            holidayTextStyle: TextStyle(color: Colors.red),
                            cellMargin: EdgeInsets.all(6.0), // 행 하단의 줄을 제거하기 위해 셀 마진 설정
                          ),
                          headerStyle: HeaderStyle(
                            formatButtonVisible: false,
                            titleCentered: true,
                            titleTextStyle: TextStyle(fontSize: 20, color: Colors.orange),
                            leftChevronIcon: Icon(Icons.chevron_left, color: Colors.orange),
                            rightChevronIcon: Icon(Icons.chevron_right, color: Colors.orange),
                            decoration: BoxDecoration(
                              color: Colors.white,
                            ),
                          ),
                          daysOfWeekStyle: DaysOfWeekStyle(
                            weekendStyle: TextStyle(color: Colors.red),
                          ),
                          calendarBuilders: CalendarBuilders(
                            dowBuilder: (context, day) {
                              if (day.weekday == DateTime.sunday) {
                                return Center(
                                  child: Text(
                                    '일',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                );
                              } else if (day.weekday == DateTime.saturday) {
                                return Center(
                                  child: Text(
                                    '토',
                                    style: TextStyle(color: Colors.blue),
                                  ),
                                );
                              } else {
                                return Center(
                                  child: Text(
                                    ['월', '화', '수', '목', '금'][day.weekday - 1],
                                    style: TextStyle(color: Colors.black),
                                  ),
                                );
                              }
                            },
                            defaultBuilder: (context, day, focusedDay) {
                              return Container(
                                margin: const EdgeInsets.all(6.0),
                                child: Center(
                                  child: Text(
                                    '${day.day}',
                                    style: TextStyle(color: Colors.black),
                                  ),
                                ),
                              );
                            },
                            selectedBuilder: (context, date, events) {
                              return Container(
                                margin: const EdgeInsets.all(6.0),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${date.day}',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              );
                            },
                            todayBuilder: (context, date, events) {
                              return Container(
                                margin: const EdgeInsets.all(6.0),
                                decoration: BoxDecoration(
                                  color: Colors.orangeAccent,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${date.day}',
                                    style: TextStyle(color: Colors.black),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
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

class Event {
  final String title;

  Event(this.title);

  @override
  String toString() => title;
}
