import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:convert';

class WeatherScreen extends StatefulWidget {
  @override
  _WeatherScreenState createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  late Map<String, dynamic> weatherData = {
    "Color": "red",
    "weather": "Thunderstorm",
    "Alert": "Severe Thunderstorm Warning",
    "Time": "4",
    "Precautions": [
      "There will be severe water logging in your area. Avoid going out if possible and get all supplies beforehand.",
      "About 2-3 inches of rain are expected. Be prepared for possible flooding and place all valuables in a safe place.",
      "Temperatures will reach up to a minimum of 21°C. So keep yourself warm and dry."
    ]
  };

  IconData _getWeatherIcon(String weather) {
    switch (weather.toLowerCase()) {
      case 'partly cloudy':
        return FontAwesomeIcons.cloudSun;
      case 'sunny':
        return FontAwesomeIcons.sun;
      case 'rainy':
        return FontAwesomeIcons.cloudShowersHeavy;
      case 'thunderstorm':
        return FontAwesomeIcons.bolt;
      case 'snowy':
        return FontAwesomeIcons.snowflake;
      case 'windy':
        return FontAwesomeIcons.wind;
      case 'foggy':
        return FontAwesomeIcons.smog;
      case 'hail':
        return FontAwesomeIcons.cloudMeatball;
      default:
        return FontAwesomeIcons.questionCircle;
    }
  }

  Color _getColor(String color) {
    switch (color.toLowerCase()) {
      case 'white':
        return Colors.white;
      case 'red':
        return Colors.red;
      case 'orange':
        return Colors.orange;
      case 'yellow':
        return Colors.yellow;
      case 'green':
        return Colors.green;
      default:
        return Colors.transparent;
    }
  }

  List<Widget> _buildPrecautionItems(List<dynamic> precautions) {
    return precautions
        .map(
          (precaution) => Padding(
            padding: const EdgeInsets.only(left: 40.0, right: 40.5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                  dense: true,
                  leading: Icon(Icons.circle, size: 10),
                  title: Text(
                    precaution,
                    style: TextStyle(
                      fontFamily: GoogleFonts.kanit().fontFamily,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Container(
                decoration: BoxDecoration(
                  color: _getColor(weatherData['Color']),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(height: 40),
            Icon(
              _getWeatherIcon(weatherData['weather']),
              size: 150,
            ),
            const SizedBox(height: 40),
            Text(
              weatherData['weather'],
              style: TextStyle(
                fontFamily: GoogleFonts.kanit().fontFamily,
                fontSize: 35,
              ),
            ),
            const SizedBox(height: 30),
            Container(
              width: 250,
              height: 35,
              decoration: ShapeDecoration(
                color: Color(0xFFD9D9D9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              child: Center(
                child: Text(
                  'In ${weatherData["Time"]} hrs',
                  style: GoogleFonts.kanit(
                    textStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _buildPrecautionItems(
                        weatherData['Precautions'],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
