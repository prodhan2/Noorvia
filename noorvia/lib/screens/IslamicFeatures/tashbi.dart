import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Firebase imports — requires google-services.json to be configured.
// App runs without it; Firebase features are gracefully disabled.
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Firebase not configured — app continues without it
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'বাংলা তাসবিহ কাউন্টার',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        fontFamily: 'Bangla',
      ),
      debugShowCheckedModeBanner: false,
      home: const TasbihCounter(),
    );
  }
}

class TasbihCounter extends StatefulWidget {
  const TasbihCounter({super.key});

  @override
  State<TasbihCounter> createState() => _TasbihCounterState();
}

class _TasbihCounterState extends State<TasbihCounter>
    with SingleTickerProviderStateMixin {
  bool _isActive = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  // Current zikr & target
  String _selectedZikr = "সুবহানাল্লাহ";
  int _targetCount = 33;

  // Complete list of zikr
  final List<String> _zikrList = [
    "সুবহানাল্লাহ",
    "আলহামদুলিল্লাহ",
    "আল্লাহু আকবার",
    "লা ইলাহা ইল্লাল্লাহ",
    "আস্তাগফিরুল্লাহ",
    "লা হাওলা ওয়া লা কুয়াতা ইল্লা বিল্লাহ",
    "ইয়া আল্লাহু",
    "বিসমিল্লাহির রাহমানির রাহিম",
    "সাল্লাল্লাহু আলাইহি ওয়া সাল্লাম (সাল্লাল্লাহু আলাইহি ওয়া সাল্লাম)",
    "আল্লাহুম্মা অন্তাস সালাম",
    "আল্লাহুম্মা অন্তা রাহমা",
    "হুমদুলিল্লাহি রাব্বিল আলামিন",
    "সুবহানাল্লাহি ওয়া বিহামদিহি",
    "সুবহানাল্লাহি আল-আজীম",
    "আল্লাহুম্মা আনতা সাল্লাম",
    "নাস-আলাহু লা ইলাহা ইল্লা হু",
    "হুব্বুল্লাহ",
    "মাহফুজ-ইলাহি",
    "রাব্বি গফফারুন",
    "রাব্বানা আতিনা",
    "লা ইলাহা ইল্লাল্লাহু মুহাম্মাদুর রসূলুল্লাহ",
    "ইয়া রাব্বি ইনা নাস-আলুক",
    "আজীবা আল্লাহ",
    "ইয়া হাইয়্যু ইয়া কামীয্যু",
    "লা ইলাহা ইল্লা হুয়া",
    "ইয়া রাব্বি তাহফাজ",
    "ইয়া আযীমু ইয়া করীমু",
    "হুযুরাল্লাহ",
    "মাশাল্লাহ",
    "তাকবীর (আল্লাহু আকবার পুনরাবৃত্তি)",
    "হামদ (আলহামদুলিল্লাহ পুনরাবৃত্তি)",
    "সুবহানাল্লাহ রাব্বি আল-আলামিন",
    "লা ইলাহা ইল্লা অন্ল্লাহু ওয়া লা নুয়াকু’বিল্লাহ",
    "আল্লাহুম্মা বারিক",
    "আল্লাহুম্মা রহম",
    "তায়িবুন লা ইলাহা ইল্লাল্লাহ",
    "সাল্লাল্লাহু আলাইহি ওয়া সাল্লাম"
  ];

  Map<String, dynamic> _zikrData = {};

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _animation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) _animationController.reverse();
      });

    _loadZikrData();
  }

  Future<void> _loadZikrData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? dataStr = prefs.getString('tasbih_zikr_data');
    setState(() {
      if (dataStr != null) {
        _zikrData = Map<String, dynamic>.from(jsonDecode(dataStr));
      } else {
        _zikrData = {};
      }
      _selectedZikr = prefs.getString('tasbih_selected_zikr') ?? _selectedZikr;
      _targetCount = prefs.getInt('tasbih_target_count') ?? _targetCount;
    });
  }

  Future<void> _saveZikrData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tasbih_zikr_data', jsonEncode(_zikrData));
    await prefs.setString('tasbih_selected_zikr', _selectedZikr);
    await prefs.setInt('tasbih_target_count', _targetCount);
  }

  int get _currentCounter {
    return _zikrData[_selectedZikr]?["counter"] ?? 0;
  }

  int get _completedTimes {
    return _zikrData[_selectedZikr]?["completedTimes"] ?? 0;
  }

  void _incrementCounter() async {
    setState(() {
      _isActive = true;

      Map<String, dynamic> current = _zikrData[_selectedZikr] != null
          ? Map<String, dynamic>.from(_zikrData[_selectedZikr])
          : {
              "counter": 0,
              "completedTimes": 0,
              "lastUpdated": DateTime.now().toString()
            };

      current["counter"] = (current["counter"] ?? 0) + 1;

      if (current["counter"] >= _targetCount) {
        current["completedTimes"] = (current["completedTimes"] ?? 0) + 1;
        current["counter"] = 0; // Reset counter for next round
        _showSuccessDialog(current["completedTimes"]);
      }

      current["lastUpdated"] = DateTime.now().toString();
      _zikrData[_selectedZikr] = current;
    });

    await _saveZikrData();

    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        _isActive = false;
      });
    });
  }

  void _resetCounter() {
    setState(() {
      Map<String, dynamic> current = _zikrData[_selectedZikr] ?? {};
      current["counter"] = 0;
      _zikrData[_selectedZikr] = current;
      _saveZikrData();
    });
  }

  void _showHistoryDialog() {
    Map<String, dynamic> current = _zikrData[_selectedZikr] ?? {};
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("পূর্বের রেকর্ড"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("বর্তমান সংখ্যা: ${current["counter"] ?? 0}"),
              const SizedBox(height: 10),
              Text("সম্পন্ন হয়েছে: ${current["completedTimes"] ?? 0} বার"),
              const SizedBox(height: 10),
              Text("শেষ আপডেট: ${current["lastUpdated"] ?? 'অজানা'}"),
            ],
          ),
          actions: [
            TextButton(
              child: const Text("বন্ধ করুন"),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  void _showZikrSettingDialog() {
    int tempTarget = _targetCount;
    String tempZikr = _selectedZikr;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("সেটিংস"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<String>(
                value: tempZikr,
                isExpanded: true,
                items: _zikrList
                    .map((zikr) =>
                        DropdownMenuItem(value: zikr, child: Text(zikr)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => tempZikr = val);
                },
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("লক্ষ্য সংখ্যা:"),
                  SizedBox(
                    width: 60,
                    child: TextField(
                      keyboardType: TextInputType.number,
                      controller:
                          TextEditingController(text: tempTarget.toString()),
                      onChanged: (val) {
                        tempTarget = int.tryParse(val) ?? tempTarget;
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text("ক্যানসেল"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text("সেভ"),
              onPressed: () {
                setState(() {
                  _selectedZikr = tempZikr;
                  _targetCount = tempTarget;
                  Map<String, dynamic> current = _zikrData[_selectedZikr] ?? {};
                  current["counter"] = 0;
                  _zikrData[_selectedZikr] = current;
                  _saveZikrData();
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showSuccessDialog(int completedTimes) async {
    String greeting = 'অনামী ব্যবহারকারী';

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();
        if (userDoc.exists && userDoc.data()?['name'] != null) {
          greeting = 'প্রিয় ${userDoc.data()!['name']}';
        }
      }
    } catch (_) {
      // Firebase not available — use default greeting
    }

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: EdgeInsets.all(20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/dinlogo.png',
                height: 80,
                width: 80,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 16),
              Text(
                "$greeting, ধন্যবাদ!",
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                "আপনি $_selectedZikr $_targetCount বার জিকির সম্পন্ন করেছেন।",
                style: const TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "এটি $completedTimes বার সম্পন্ন হয়েছে।",
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text(
                  "ঠিক আছে",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> current = _zikrData[_selectedZikr] ?? {};
    return Scaffold(
      appBar: AppBar(
        title: const Text("বাংলা তাসবিহ কাউন্টার"),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _showHistoryDialog,
            tooltip: "পূর্বের রেকর্ড দেখুন",
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showZikrSettingDialog,
            tooltip: "সেটিংস পরিবর্তন করুন",
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            GestureDetector(
              onTap: _incrementCounter,
              child: ScaleTransition(
                scale: _animation,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _isActive ? Colors.green : Colors.red,
                      width: 8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${current["counter"] ?? 0}',
                        style: const TextStyle(
                            fontSize: 60,
                            fontWeight: FontWeight.bold,
                            color: Colors.black),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '$_selectedZikr লক্ষ্য: $_targetCount',
                        textAlign: TextAlign.center,
                        style:
                            const TextStyle(fontSize: 18, color: Colors.teal),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'সম্পন্ন হয়েছে: ${current["completedTimes"] ?? 0} বার',
                        style: const TextStyle(
                            fontSize: 16, color: Colors.blueGrey),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text("রিসেট করুন"),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: _resetCounter,
            ),
          ],
        ),
      ),
    );
  }
}
