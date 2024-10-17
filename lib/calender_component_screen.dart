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
    _events = {};
    _selectedEvents = [];
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _fetchEvents(); // 초기화 시 이벤트를 가져옵니다.
  }

  List<Event> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  Future<void> _fetchEvents() async {
    DateTime exampleDate = DateTime.now();
    _events[exampleDate] = [Event('예시 일정 1'), Event('예시 일정 2')];

    setState(() {
      _selectedEvents = _getEventsForDay(_selectedDay);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
      body: SingleChildScrollView( // 스크롤 가능하도록 추가
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '우리 가족 ',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.normal,
                        color: Colors.black87,
                      ),
                    ),
                    TextSpan(
                      text: '버킷리스트',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => BucketListScreen()),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      '버킷리스트 확인하러 가기',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 40),
              Container(
                width: MediaQuery.of(context).size.width, // 앱의 가로 길이에 맞춤
                height: 7, // 선의 두께를 더 두껍게 설정
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade100,
                      blurRadius: 1,
                      spreadRadius: 0.5,
                      offset: Offset(0, 1), // Inner shadow를 구현하기 위한 설정
                    ),
                  ],
                ),
              ),
              SizedBox(height: 40),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '우리 가족 ',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.normal,
                        color: Colors.black87,
                      ),
                    ),
                    TextSpan(
                      text: '캘린더',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 25),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CalendarMainScreen()),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.4),
                        blurRadius: 2,
                        spreadRadius: 1,
                        offset: Offset(0, 0), // 모든 방향으로 균일한 그림자
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      width: double.infinity,
                      child: TableCalendar(
                        focusedDay: _focusedDay,
                        firstDay: DateTime.utc(2020, 1, 1),
                        lastDay: DateTime.utc(2030, 12, 31),
                        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                        onDaySelected: (selectedDay, focusedDay) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => CalendarMainScreen()),
                          );
                        },
                        eventLoader: _getEventsForDay,
                        daysOfWeekHeight: 40.0,
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
                          outsideDaysVisible: true,
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
                            fontSize: 21,
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
                                      ? Colors.blue
                                      : day.weekday == DateTime.sunday
                                      ? Colors.red
                                      : Colors.black,
                                ),
                              ),
                            );
                          },
                          defaultBuilder: (context, day, focusedDay) {
                            return Container(
                              margin: const EdgeInsets.all(6.0),
                              child: Center(
                                child: Text(
                                  '${day.day}',
                                  style: TextStyle(
                                    color: day.weekday == DateTime.saturday
                                        ? Colors.blue
                                        : day.weekday == DateTime.sunday
                                        ? Colors.red
                                        : Colors.black,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              ListView.builder(
                shrinkWrap: true, // ListView의 크기를 내용에 맞게 조정
                physics: NeverScrollableScrollPhysics(), // 내부 스크롤 비활성화
                itemCount: _selectedEvents.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_selectedEvents[index].title),
                  );
                },
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
