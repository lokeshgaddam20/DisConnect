import 'package:flutter/material.dart';

import 'package:flutter_config/flutter_config.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:Sahaya/firebase_options.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'getPhoneNumber.dart';
import 'getPermissions.dart';
import 'Home.dart';
import 'Weather.dart';

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
        // NavigationDestination(
        //   icon: Icon(Icons.family_restroom_outlined),
        //   selectedIcon: Icon(Icons.family_restroom),
        //   label: 'Family',
        // ),
        //<------------------ADD MORE OPTIONS AS NEEDED----------------->
      ],
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FlutterConfig.loadEnvVariables();
  final prefs = await SharedPreferences.getInstance();
  var phoneNumber = prefs.getString('phoneNumber');
  bool permissionsGranted = prefs.getBool('permissionsGranted') ?? false;
  runApp(
      MyApp(phoneNumber: phoneNumber, permissionsGranted: permissionsGranted));
}

class MyApp extends StatefulWidget {
  final String? phoneNumber;
  final bool permissionsGranted;

  MyApp({Key? key, required this.phoneNumber, required this.permissionsGranted})
      : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DisConnect',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            widget.phoneNumber == null ? GetPhoneNumber() : Home(),
            widget.permissionsGranted ? WeatherScreen() : GetPermissions(),
            // widget.permissionsGranted ? FamilySpaceScreen() : GetPermissions(),
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
