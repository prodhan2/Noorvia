// import 'dart:async';

// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:intl/intl.dart';

// import 'package:geocoding/geocoding.dart';
// import 'package:table_calendar/table_calendar.dart';

// void main() {
//   runApp(const PrayerTimesApp());
// }

// class PrayerTimesApp extends StatelessWidget {
//   const PrayerTimesApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Monthly Prayer Times',
//       theme: ThemeData(
//         primarySwatch: Colors.green,
//         visualDensity: VisualDensity.adaptivePlatformDensity,
//       ),
//       home: const MonthlyPrayerTimesScreen(),
//     );
//   }
// }

// class MonthlyPrayerTimesScreen extends StatefulWidget {
//   const MonthlyPrayerTimesScreen({super.key});

//   @override
//   _MonthlyPrayerTimesScreenState createState() => _MonthlyPrayerTimesScreenState();
// }

// class _MonthlyPrayerTimesScreenState extends State<MonthlyPrayerTimesScreen> {
//   List<Map<String, dynamic>> prayerDataList = [];
//   bool isLoading = true;
//   String errorMessage = '';
//   String city = 'Rajshahi';
//   String country = 'Bangladesh';
//   int method = 8;
//   late DateTime currentDate;
//   late DateTime focusedDate;
//   late ScrollController _scrollController;
//   int currentDayIndex = 0;
//   bool isCalendarVisible = false;
//   Duration? timeRemaining;
//   Duration? nextPrayerRemaining;
//   String nextPrayerName = '';
//   Timer? _timer;
//   Timer? _nextPrayerTimer;

//   @override
//   void initState() {
//     super.initState();
//     currentDate = DateTime.now();
//     focusedDate = currentDate;
//     _scrollController = ScrollController();
//     _getCurrentLocation();
//   }

//   @override
//   void dispose() {
//     _scrollController.dispose();
//     _timer?.cancel();
//     _nextPrayerTimer?.cancel();
//     super.dispose();
//   }

//   void _startTimers() {
//     _timer?.cancel();
//     _nextPrayerTimer?.cancel();

//     // Update current time every second
//     _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       setState(() {});
//     });

//     // Update next prayer countdown every second
//     _nextPrayerTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       _calculateNextPrayerTime();
//     });
//   }

//   void _calculateNextPrayerTime() {
//     if (prayerDataList.isEmpty || currentDayIndex >= prayerDataList.length) return;

//     final now = DateTime.now();
//     final todayData = prayerDataList[currentDayIndex];
//     final timings = todayData['data']['timings'];
    
//     // Parse all prayer times
//     final prayerTimes = {
//       'Fajr': _parsePrayerTime(timings['Fajr']),
//       'Sunrise': _parsePrayerTime(timings['Sunrise']),
//       'Dhuhr': _parsePrayerTime(timings['Dhuhr']),
//       'Asr': _parsePrayerTime(timings['Asr']),
//       'Maghrib': _parsePrayerTime(timings['Maghrib']),
//       'Isha': _parsePrayerTime(timings['Isha']),
//     };

//     // Find the next prayer
//     DateTime? nextPrayerTime;
//     String? nextPrayer;
    
//     for (var entry in prayerTimes.entries) {
//       if (entry.value.isAfter(now)) {
//         nextPrayerTime = entry.value;
//         nextPrayer = entry.key;
//         break;
//       }
//     }

//     // If all prayers have passed today, use first prayer of next day
//     if (nextPrayerTime == null && currentDayIndex + 1 < prayerDataList.length) {
//       final tomorrowData = prayerDataList[currentDayIndex + 1];
//       final tomorrowTimings = tomorrowData['data']['timings'];
//       nextPrayerTime = _parsePrayerTime(tomorrowTimings['Fajr']);
//       nextPrayer = 'Fajr (Tomorrow)';
//     }

//     if (nextPrayerTime != null) {
//       setState(() {
//         nextPrayerRemaining = nextPrayerTime?.difference(now);
//         nextPrayerName = nextPrayer ?? '';
//       });
//     }
//   }

//   DateTime _parsePrayerTime(String timeString) {
//     final now = DateTime.now();
//     final timeParts = timeString.split(':');
//     final hour = int.parse(timeParts[0]);
//     final minute = int.parse(timeParts[1].split(' ')[0]);
    
//     return DateTime(now.year, now.month, now.day, hour, minute);
//   }

//   void _scrollToCurrentDate() {
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (_scrollController.hasClients && prayerDataList.isNotEmpty) {
//         final position = currentDayIndex * 280.0; // Approximate height of each card
//         _scrollController.animateTo(
//           position,
//           duration: const Duration(milliseconds: 800),
//           curve: Curves.easeInOut,
//         );
//       }
//     });
//   }

//   Future<void> _getCurrentLocation() async {
//     bool serviceEnabled;
//     LocationPermission permission;

//     serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       setState(() {
//         errorMessage = 'Location services are disabled. Using default location (Rajshahi, Bangladesh).';
//       });
//       _fetchMonthlyPrayerTimes();
//       return;
//     }

//     permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied) {
//         setState(() {
//           errorMessage = 'Location permissions are denied. Using default location (Rajshahi, Bangladesh).';
//         });
//         _fetchMonthlyPrayerTimes();
//         return;
//       }
//     }

//     if (permission == LocationPermission.deniedForever) {
//       setState(() {
//         errorMessage = 'Location permissions are permanently denied. Using default location (Rajshahi, Bangladesh).';
//       });
//       _fetchMonthlyPrayerTimes();
//       return;
//     }

//     try {
//       Position position = await Geolocator.getCurrentPosition(
//           desiredAccuracy: LocationAccuracy.medium);
//       List<Placemark> placemarks = await placemarkFromCoordinates(
//           position.latitude, position.longitude);

//       if (placemarks.isNotEmpty) {
//         Placemark place = placemarks[0];
//         setState(() {
//           city = place.locality ?? 'Rajshahi';
//           country = place.country ?? 'Bangladesh';
//         });
//         _fetchMonthlyPrayerTimes();
//       }
//     } catch (e) {
//       setState(() {
//         errorMessage = 'Could not get location: ${e.toString()}. Using default location (Rajshahi, Bangladesh).';
//       });
//       _fetchMonthlyPrayerTimes();
//     }
//   }

//   Future<void> _fetchMonthlyPrayerTimes() async {
//     setState(() {
//       isLoading = true;
//       prayerDataList = [];
//       errorMessage = '';
//     });

//     try {
//       DateTime firstDay = DateTime(currentDate.year, currentDate.month, 1);
//       DateTime lastDay = DateTime(currentDate.year, currentDate.month + 1, 0);

//       currentDayIndex = currentDate.day - 1;

//       List<dynamic> tempList = [];

//       for (DateTime date = firstDay;
//           date.isBefore(lastDay.add(const Duration(days: 1)));
//           date = date.add(const Duration(days: 1))) {
        
//         String formattedDate = DateFormat('dd-MM-yyyy').format(date);

//         final response = await http.get(Uri.parse(
//           'https://api.aladhan.com/v1/timingsByCity/$formattedDate?city=$city&country=$country&method=$method'));

//         if (response.statusCode == 200) {
//           final data = json.decode(response.body);
//           tempList.add(data);
//         } else {
//           errorMessage = 'Some dates failed to load';
//         }

//         // To avoid hitting the API rate limit
//         await Future.delayed(const Duration(milliseconds: 100));
//       }

//       setState(() {
//         prayerDataList = tempList.cast<Map<String, dynamic>>();
//       });
//       _startTimers();
//       _calculateNextPrayerTime();
//     } catch (e) {
//       setState(() {
//         errorMessage = 'Error: ${e.toString()}';
//       });
//     } finally {
//       setState(() {
//         isLoading = false;
//       });
//       _scrollToCurrentDate();
//     }
//   }

//   void _onDaySelected(DateTime selectedDate, DateTime focusedDate) {
//     setState(() {
//       currentDate = selectedDate;
//       this.focusedDate = focusedDate;
//       currentDayIndex = selectedDate.day - 1;
//       isCalendarVisible = false;
//     });
//     _scrollToCurrentDate();
//   }

//   Widget _buildDateHeader(String date, bool isToday) {
//     return Container(
//       padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
//       decoration: BoxDecoration(
//         color: isToday ? Colors.green[700] : Colors.green[50],
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             date,
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//               color: isToday ? Colors.white : Colors.green,
//             ),
//           ),
//           Icon(
//             isToday ? Icons.today : Icons.calendar_today,
//             size: 18,
//             color: isToday ? Colors.white : Colors.green,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildPrayerTimeRow(String prayerName, String prayerTime, bool isToday, List<String> prayerOrder) {
//     final now = DateTime.now();
//     final prayerDateTime = _parsePrayerTime(prayerTime);
//     final isCurrent = isToday && prayerDateTime.isBefore(now) && 
//         (prayerName == nextPrayerName || 
//          (prayerOrder.indexOf(prayerName) < 
//           prayerOrder.indexOf(nextPrayerName.replaceAll(' (Tomorrow)', ''))));

//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 16.0),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             prayerName,
//             style: TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.w500,
//               color: isCurrent ? Colors.green[800] : Colors.black,
//             ),
//           ),
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
//             decoration: BoxDecoration(
//               color: isCurrent ? Colors.green[100] : Colors.grey[200],
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(
//                 color: isCurrent ? Colors.green : Colors.grey,
//                 width: 1,
//               ),
//             ),
//             child: Text(
//               prayerTime,
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//                 color: isCurrent ? Colors.green[800] : Colors.black,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildHijriDate(Map<String, dynamic> hijriData, bool isToday) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
//       child: Row(
//         children: [
//           Icon(Icons.calendar_month, size: 14, color: isToday ? Colors.green[100] : Colors.grey),
//           const SizedBox(width: 4),
//           Text(
//             '${hijriData['date']} ${hijriData['month']['en']} ${hijriData['year']} (Hijri)',
//             style: TextStyle(
//               fontSize: 14,
//               color: isToday ? Colors.green[100] : Colors.grey,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildCurrentTimeAndNextPrayer() {
//     final now = DateTime.now();
//     final formattedTime = DateFormat('hh:mm:ss a').format(now);
    
//     return Container(
//       padding: const EdgeInsets.all(16.0),
//       decoration: BoxDecoration(
//         color: Colors.green[50],
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.green[200]!),
//       ),
//       child: Column(
//         children: [
//           Text(
//             'Current Time: $formattedTime',
//             style: const TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//               color: Colors.green,
//             ),
//           ),
//           const SizedBox(height: 8),
//           if (nextPrayerName.isNotEmpty && nextPrayerRemaining != null)
//             Column(
//               children: [
//                 Text(
//                   'Next: $nextPrayerName',
//                   style: const TextStyle(
//                     fontSize: 16,
//                     color: Colors.green,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   _formatDuration(nextPrayerRemaining!),
//                   style: const TextStyle(
//                     fontSize: 24,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.green,
//                   ),
//                 ),
//               ],
//             ),
//         ],
//       ),
//     );
//   }

//   String _formatDuration(Duration duration) {
//     String twoDigits(int n) => n.toString().padLeft(2, "0");
//     String hours = twoDigits(duration.inHours);
//     String minutes = twoDigits(duration.inMinutes.remainder(60));
//     String seconds = twoDigits(duration.inSeconds.remainder(60));
//     return "$hours:$minutes:$seconds";
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Monthly Prayer Times - $city, $country'),
//         backgroundColor: Colors.green[700],
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: _fetchMonthlyPrayerTimes,
//           ),
//           IconButton(
//             icon: const Icon(Icons.location_on),
//             onPressed: _getCurrentLocation,
//           ),
//           IconButton(
//             icon: const Icon(Icons.calendar_today),
//             onPressed: () {
//               setState(() {
//                 isCalendarVisible = !isCalendarVisible;
//               });
//             },
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           if (isCalendarVisible)
//             Container(
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(12),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.grey.withOpacity(0.3),
//                     spreadRadius: 2,
//                     blurRadius: 5,
//                     offset: const Offset(0, 3),
//                   ),
//                 ],
//               ),
//               margin: const EdgeInsets.all(8),
//               child: TableCalendar(
//                 firstDay: DateTime(currentDate.year, currentDate.month, 1),
//                 lastDay: DateTime(currentDate.year, currentDate.month + 1, 0),
//                 focusedDay: focusedDate,
//                 selectedDayPredicate: (day) => isSameDay(day, currentDate),
//                 onDaySelected: _onDaySelected,
//                 headerStyle: const HeaderStyle(
//                   formatButtonVisible: false,
//                   titleCentered: true,
//                 ),
//                 calendarStyle: CalendarStyle(
//                   selectedDecoration: BoxDecoration(
//                     color: Colors.green,
//                     shape: BoxShape.circle,
//                   ),
//                   todayDecoration: BoxDecoration(
//                     color: Colors.green[200],
//                     shape: BoxShape.circle,
//                   ),
//                 ),
//               ),
//             ),
//           if (!isCalendarVisible) _buildCurrentTimeAndNextPrayer(),
//           Expanded(
//             child: isLoading
//                 ? const Center(child: CircularProgressIndicator(color: Colors.green))
//                 : errorMessage.isNotEmpty
//                     ? Column(
//                         children: [
//                           Padding(
//                             padding: const EdgeInsets.all(16.0),
//                             child: Text(errorMessage, 
//                                 style: const TextStyle(color: Colors.red)),
//                           ),
//                           if (prayerDataList.isNotEmpty)
//                             Expanded(child: _buildPrayerTimesList())
//                         ],
//                       )
//                     : _buildPrayerTimesList(),
//           ),
//         ],
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           setState(() {
//             currentDate = DateTime.now();
//             currentDayIndex = currentDate.day - 1;
//             isCalendarVisible = false;
//           });
//           _scrollToCurrentDate();
//         },
//         backgroundColor: Colors.green,
//         child: const Icon(Icons.today),
//       ),
//     );
//   }

//   Widget _buildPrayerTimesList() {
//     final prayerOrder = ['Fajr', 'Sunrise', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
//     return ListView.builder(
//       controller: _scrollController,
//       itemCount: prayerDataList.length,
//       itemBuilder: (context, index) {
//         final data = prayerDataList[index];
//         final timings = data['data']['timings'];
//         final gregorianDate = data['data']['date']['readable'];
//         final hijriDate = data['data']['date']['hijri'];
//         final isToday = index == currentDayIndex;

//         return Card(
//           margin: const EdgeInsets.all(8.0),
//           elevation: 2.0,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//             side: BorderSide(
//               color: isToday ? Colors.green : Colors.grey.withOpacity(0.2),
//               width: 1,
//             ),
//           ),
//           color: isToday ? Colors.green[50] : Colors.white,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _buildDateHeader(gregorianDate, isToday),
//               _buildHijriDate(hijriDate, isToday),
//               const Divider(height: 1),
//               _buildPrayerTimeRow('Fajr', timings['Fajr'], isToday, prayerOrder),
//               _buildPrayerTimeRow('Sunrise', timings['Sunrise'], isToday, prayerOrder),
//               _buildPrayerTimeRow('Dhuhr', timings['Dhuhr'], isToday, prayerOrder),
//               _buildPrayerTimeRow('Asr', timings['Asr'], isToday, prayerOrder),
//               _buildPrayerTimeRow('Maghrib', timings['Maghrib'], isToday, prayerOrder),
//               _buildPrayerTimeRow('Isha', timings['Isha'], isToday, prayerOrder),
//               const SizedBox(height: 8),
//             ],
//           ),
//         );
//       },
//     );
//   }
// }
