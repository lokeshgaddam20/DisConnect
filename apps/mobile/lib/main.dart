import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_config/flutter_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart'; // Import fl_chart library

import 'getPhoneNumber.dart';
import 'getPermissions.dart';
import 'Home.dart';
import 'Weather.dart';
import 'Family.dart';

class AppColors {
  static const Color contentColorBlue = Color(0xFF0000FF);
  static const Color contentColorYellow = Color(0xFFFFFF00);
  static const Color contentColorPink = Color(0xFFFF69B4);
  static const Color contentColorGreen = Color(0xFF008000);
  static const Color mainTextColor1 = Colors.black;
  static const Color mainTextColor3 = Colors.grey;
  static const Color contentColorWhite = Colors.white;
  static const Color pageBackground = Colors.white; // Change as needed
}

class Indicator extends StatelessWidget {
  final Color color;
  final String text;
  final bool isSquare;
  final double size;
  final Color textColor;

  const Indicator({
    Key? key,
    required this.color,
    required this.text,
    this.isSquare = false,
    this.size = 16,
    required this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: isSquare ? BoxShape.rectangle : BoxShape.circle,
            color: color,
          ),
        ),
        SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(fontSize: size, color: textColor),
        ),
      ],
    );
  }
}

class DVScreen extends StatefulWidget {
  final int counter;

  const DVScreen({Key? key, required this.counter}) : super(key: key);

  @override
  _DVScreenState createState() => _DVScreenState();
}

class _DVScreenState extends State<DVScreen> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Data Visualization'),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 28,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Indicator(
                color: AppColors.contentColorBlue,
                text: 'Food',
                isSquare: false,
                size: touchedIndex == 0 ? 18 : 16,
                textColor: touchedIndex == 0
                    ? AppColors.mainTextColor1
                    : AppColors.mainTextColor3,
              ),
              Indicator(
                color: const Color.fromARGB(255, 195, 255, 0),
                text: 'Clothes',
                isSquare: false,
                size: touchedIndex == 0 ? 18 : 16,
                textColor: touchedIndex == 0
                    ? AppColors.mainTextColor1
                    : AppColors.mainTextColor3,
              ),
              Indicator(
                color: Color.fromARGB(255, 50, 68, 33),
                text: 'Medicines',
                isSquare: false,
                size: touchedIndex == 0 ? 18 : 16,
                textColor: touchedIndex == 0
                    ? AppColors.mainTextColor1
                    : AppColors.mainTextColor3,
              ),
              // Add more indicators as needed
            ],
          ),
          SizedBox(
            height: 18,
          ),
          Expanded(
            child: Center(
              // Center the pie chart
              child: AspectRatio(
                aspectRatio: 10, // Adjust the aspect ratio to change size
                child: PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null) {
                            touchedIndex = -1;
                            return;
                          }
                          touchedIndex = pieTouchResponse
                              .touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    startDegreeOffset: 180,
                    borderData: FlBorderData(
                      show: false,
                    ),
                    sectionsSpace: 1,
                    centerSpaceRadius: 0,
                    sections: showingSections(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> showingSections() {
    // Provide your data here
    return [
      PieChartSectionData(
        color: AppColors.contentColorBlue,
        value: 25,
        title: '25%', // Display value
        titlePositionPercentageOffset: 0.5, // Position title at center
      ),
      PieChartSectionData(
        color: AppColors.contentColorYellow,
        value: 25,
        title: '25%', // Display value
        titlePositionPercentageOffset: 0.5, // Position title at center
      ),
      PieChartSectionData(
        color: Color.fromARGB(255, 69, 69, 38),
        value: 25,
        title: '25%', // Display value
        titlePositionPercentageOffset: 0.5, // Position title at center
      ),
      // Add more sections as needed
    ];
  }
}

class CustomNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTapped;

  CustomNavigationBar({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: onItemTapped,
      backgroundColor: Colors.white,
      destinations: [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.cloud_outlined),
          selectedIcon: Icon(Icons.cloud),
          label: 'Weather',
        ),
        NavigationDestination(
          icon: Icon(Icons.family_restroom_outlined), // Added chat icon here
          selectedIcon: Icon(Icons.family_restroom),
          label: 'Family',
        ),
        NavigationDestination(
          icon:
              Icon(Icons.insert_chart_outlined), // Icon for Data Visualization
          selectedIcon:
              Icon(Icons.insert_chart), // Selected icon for Data Visualization
          label: 'DashBoard',
        ),
        //<------------------ADD MORE OPTIONS AS NEEDED----------------->
      ],
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FlutterConfig.loadEnvVariables();
  final prefs = await SharedPreferences.getInstance();

  // Increment the counter and store it in SharedPreferences
  int counter = (prefs.getInt('counter') ?? 0) + 1;
  await prefs.setInt('counter', counter);

  var phoneNumber = prefs.getString('phoneNumber');
  bool permissionsGranted = prefs.getBool('permissionsGranted') ?? false;
  runApp(MyApp(
      phoneNumber: phoneNumber,
      permissionsGranted: permissionsGranted,
      counter: counter));
}

class MyApp extends StatefulWidget {
  final String? phoneNumber;
  final bool permissionsGranted;
  final int counter; // Add counter property

  MyApp(
      {Key? key,
      required this.phoneNumber,
      required this.permissionsGranted,
      required this.counter})
      : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _selectedIndex = 0;
  MaterialColor customColor = MaterialColor(
    0xFFFA7979,
    <int, Color>{
      50: Color(0xFFFFF3F3),
      100: Color(0xFFFFE0E0),
      200: Color(0xFFFFB3B3),
      300: Color(0xFFFF8080),
      400: Color(0xFFFF6666),
      500: Color(0xFFFA7979), // Your primary color
      600: Color(0xFFFA6666),
      700: Color(0xFFFA4D4D),
      800: Color(0xFFFA3333),
      900: Color(0xFFFA1A1A),
    },
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DisConnect',
      theme: ThemeData(
        primarySwatch: customColor,
      ),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            widget.phoneNumber == null ? GetPhoneNumber() : Home(),
            widget.permissionsGranted ? WeatherScreen() : GetPermissions(),
            widget.permissionsGranted ? FamilySpaceScreen() : GetPermissions(),
            if (_selectedIndex == 3) DVScreen(counter: widget.counter),
            //<------------------ADD MORE OPTIONS AS NEEDED----------------->
          ],
        ),
        bottomNavigationBar:
            widget.phoneNumber != null && widget.permissionsGranted
                ? CustomNavigationBar(
                    selectedIndex: _selectedIndex,
                    onItemTapped: _onItemTapped,
                  )
                : null,
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}
