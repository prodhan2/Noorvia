import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:async';

class RamadanCalendarPage extends StatefulWidget {
  @override
  _RamadanCalendarPageState createState() => _RamadanCalendarPageState();
}

class _RamadanCalendarPageState extends State<RamadanCalendarPage> {
  List<dynamic> calendarData = [];
  bool isLoading = true;
  String? error;
  String selectedCity = 'Dhaka';
  final List<String> cities = ['Dhaka', 'Chittagong', 'Sylhet', 'Rajshahi', 'Khulna', 'Barishal', 'Rangpur', 'Mymensingh'];
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();
  Timer? _timer;
  DateTime currentDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    fetchRamadanData();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> fetchRamadanData() async {
    final url =
        'https://api.aladhan.com/v1/calendarByCity?city=$selectedCity&country=Bangladesh&method=2&month=3&year=2025';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() {
          calendarData = jsonData['data'];
          isLoading = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToCurrentDate();
        });
      } else {
        setState(() {
          error = 'ডেটা লোড করতে ব্যর্থ হয়েছে';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'ত্রুটি: $e';
        isLoading = false;
      });
    }
  }

  void _scrollToCurrentDate() {
    if (calendarData.isEmpty) return;
    
    final today = DateFormat('dd-MM-yyyy').format(currentDate);
    int index = calendarData.indexWhere((day) {
      final gregorian = day['date']['gregorian'];
      final dateStr = '${gregorian['day']}-${gregorian['month']['number']}-${gregorian['year']}';
      return dateStr == today;
    });

    if (index != -1) {
      final scrollPosition = (index * 70.0).clamp(0.0, _verticalController.position.maxScrollExtent);
      _verticalController.animateTo(
        scrollPosition,
        duration: Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      );
    }
  }

  String _getCountdown(String prayerTime) {
    try {
      final cleanTime = prayerTime.split(' ')[0];
      final dateFormat = DateFormat('HH:mm');
      final prayerDateTime = dateFormat.parse(cleanTime);
      
      final now = DateTime.now();
      final todayPrayerTime = DateTime(now.year, now.month, now.day, prayerDateTime.hour, prayerDateTime.minute);
      
      if (now.isAfter(todayPrayerTime)) {
        return 'সময় শেষ';
      }
      
      final remaining = todayPrayerTime.difference(now);
      return '${remaining.inHours.toString().padLeft(2, '0')}:${(remaining.inMinutes % 60).toString().padLeft(2, '0')}:${(remaining.inSeconds % 60).toString().padLeft(2, '0')}';
    } catch (e) {
      return prayerTime.split(' ')[0];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('রমজান ক্যালেন্ডার ২০২৫ - $selectedCity'),
        backgroundColor: Colors.green.shade700,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButtonFormField<String>(
              value: selectedCity,
              decoration: InputDecoration(
                labelText: 'শহর নির্বাচন করুন',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
              ),
              isExpanded: true,
              items: cities.map((String city) {
                return DropdownMenuItem<String>(
                  value: city,
                  child: Text(city),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    selectedCity = newValue;
                    isLoading = true;
                  });
                  fetchRamadanData();
                }
              },
            ),
          ),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : error != null
                    ? Center(child: Text(error!, style: TextStyle(fontSize: 16)))
                    : Scrollbar(
                        controller: _verticalController,
                        thumbVisibility: true,
                        child: Scrollbar(
                          controller: _horizontalController,
                          thumbVisibility: true,
                          notificationPredicate: (notification) => notification.depth == 1,
                          child: SingleChildScrollView(
                            controller: _verticalController,
                            child: SingleChildScrollView(
                              controller: _horizontalController,
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                columnSpacing: 12,
                                horizontalMargin: 8,
                                dataRowHeight: 70,
                                headingRowHeight: 50,
                                columns: [
                                  DataColumn(label: _HeaderCell('তারিখ')),
                                  DataColumn(label: _HeaderCell('হিজরি')),
                                  DataColumn(label: _HeaderCell('দিন')),
                                  DataColumn(label: _HeaderCell('সেহরি')),
                                  DataColumn(label: _HeaderCell('সেহরি সময় বাকি')),
                                  DataColumn(label: _HeaderCell('ইফতার')),
                                  DataColumn(label: _HeaderCell('ইফতার সময় বাকি')),
                                ],
                                rows: calendarData.map((day) {
                                  final timings = day['timings'];
                                  final hijri = day['date']['hijri'];
                                  final gregorian = day['date']['gregorian'];
                                  
                                  final fajrTime = _formatTimeTo12Hour(timings['Fajr']);
                                  final maghribTime = _formatTimeTo12Hour(timings['Maghrib']);
                                  final weekday = _getBanglaWeekday(gregorian['weekday']['en']);
                                  final gregorianDate = gregorian['day'] + ' ' + gregorian['month']['en'];
                                  final hijriDate = hijri['day'] + ' ' + hijri['month']['en'];

                                  final isToday = _isToday(gregorian);
                                  
                                  return DataRow(
                                    color: MaterialStateProperty.resolveWith<Color>((states) {
                                      if (isToday) return Colors.green.shade100;
                                      if (calendarData.indexOf(day) == 0 || 
                                          calendarData.indexOf(day) == calendarData.length - 1) {
                                        return Colors.green.shade50;
                                      }
                                      return Colors.transparent;
                                    }),
                                    cells: [
                                      DataCell(_DataCellContent(gregorianDate, isToday)),
                                      DataCell(_DataCellContent(hijriDate, isToday)),
                                      DataCell(_DataCellContent(weekday, isToday)),
                                      DataCell(_DataCellContent(fajrTime, isToday)),
                                      DataCell(_CountdownCell(_getCountdown(timings['Fajr']))),
                                      DataCell(_DataCellContent(maghribTime, isToday)),
                                      DataCell(_CountdownCell(_getCountdown(timings['Maghrib']))),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _scrollToCurrentDate,
        child: Icon(Icons.calendar_today),
        backgroundColor: Colors.green.shade700,
        tooltip: 'আজকের তারিখে যান',
      ),
    );
  }

  bool _isToday(Map<String, dynamic> gregorian) {
    final today = DateFormat('dd-MM-yyyy').format(currentDate);
    final dateStr = '${gregorian['day']}-${gregorian['month']['number']}-${gregorian['year']}';
    return dateStr == today;
  }

  String _formatTimeTo12Hour(String time) {
    try {
      final cleanTime = time.split(' ')[0];
      final dateFormat = DateFormat('HH:mm');
      final dateTime = dateFormat.parse(cleanTime);
      return DateFormat('h:mm a').format(dateTime);
    } catch (e) {
      return time.split(' ')[0];
    }
  }

  String _getBanglaWeekday(String englishWeekday) {
    switch (englishWeekday.toLowerCase()) {
      case 'sunday': return 'রবি';
      case 'monday': return 'সোম';
      case 'tuesday': return 'মঙ্গল';
      case 'wednesday': return 'বুধ';
      case 'thursday': return 'বৃহঃ';
      case 'friday': return 'শুক্র';
      case 'saturday': return 'শনি';
      default: return englishWeekday;
    }
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;

  const _HeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: Colors.white,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _DataCellContent extends StatelessWidget {
  final String text;
  final bool isHighlighted;

  const _DataCellContent(this.text, this.isHighlighted);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
          color: isHighlighted ? Colors.green.shade900 : Colors.black,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _CountdownCell extends StatelessWidget {
  final String text;

  const _CountdownCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.red.shade700,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
