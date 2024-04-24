import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherScreen extends StatefulWidget {
  @override
  _WeatherScreenState createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  late Map<String, dynamic> weatherData = {};

  IconData _getWeatherIcon(String weather) {
    switch (weather.toLowerCase()) {
      case 'clouds':
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
        return FontAwesomeIcons.circleQuestion;
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

  Future<void> _loadWeatherData() async {
    // Replace 'YOUR_API_KEY' with your actual OpenWeatherMap API key
    String apiKey = '274d4c4a4af2c1875a5cbc27fc141b82';
    // Replace 'YOUR_CITY_NAME' with the name of the city for which you want to fetch weather data
    String city = 'Hyderabad';
    // Construct the API endpoint URL
    String apiUrl =
        'https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey';

    try {
      // Make a GET request to the OpenWeatherMap API endpoint
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        // Parse the response body to extract weather data
        final jsonData = json.decode(response.body);
        // Extract necessary weather information from the JSON response
        String weather = jsonData['weather'][0]['main'];

        print(
            'Weather condition received: $weather'); // Add this line for debugging

        // int time = jsonData['dt'];
        // Convert time to hours
        // int hours = (time ~/ 3600); // Use integer division to avoid decimals

        // Dynamically set precautions based on the weather condition
        List<String> precautions = [];
        if (weather == 'Thunderstorm') {
          // Set precautions for thunderstorm
          precautions = [
            "Stay indoors and away from windows.",
            "Unplug appliances and electrical devices.",
            "Avoid using running water."
          ];
        } else if (weather == 'Rainy') {
          // Set precautions for rainy weather
          precautions = [
            "Carry an umbrella or raincoat.",
            "Avoid driving through flooded areas.",
            "Secure outdoor belongings."
          ];
        } else if (weather == 'Partly Cloudy') {
          // Set precautions for partly cloudy weather
          precautions = [
            "No specific precautions for partly cloudy weather.",
            "Enjoy outdoor activities safely.",
            "Keep an eye on the sky for any changes."
          ];
        } else if (weather == 'Sunny') {
          // Set precautions for sunny weather
          precautions = [
            "Stay hydrated and apply sunscreen.",
            "Wear sunglasses and protective clothing.",
            "Seek shade and avoid prolonged exposure to the sun."
          ];
        } else if (weather == 'Cloudy' || weather == 'Clouds') {
          // Set precautions for cloudy weather
          precautions = [
            "Keep an eye on the sky for any signs of rain.",
            "Carry an umbrella or raincoat as a precaution.",
            "Be prepared for possible changes in weather conditions."
          ];
        } else if (weather == 'Snowy') {
          // Set precautions for snowy weather
          precautions = [
            "Dress warmly and wear layers.",
            "Clear snow from walkways and driveways.",
            "Drive cautiously on slippery roads."
          ];
        } else if (weather == 'Windy') {
          // Set precautions for windy weather
          precautions = [
            "Secure loose outdoor objects.",
            "Stay away from tall trees and power lines.",
            "Avoid outdoor activities that could be hazardous."
          ];
        } else if (weather == 'Foggy') {
          // Set precautions for foggy weather
          precautions = [
            "Use low beam headlights while driving.",
            "Reduce speed and increase following distance.",
            "Stay alert and focused on the road."
          ];
        } else if (weather == 'Hail') {
          // Set precautions for hail weather
          precautions = [
            "Stay indoors or seek shelter immediately.",
            "Protect vehicles and outdoor equipment.",
            "Avoid going outside until the hailstorm has passed."
          ];
        } else {
          // Set default precautions or handle other weather conditions
          precautions = [
            "No specific precautions for this weather condition.",
            "Stay updated with weather forecasts.",
            "Use common sense and stay safe."
          ];
        }

        // Update the weatherData variable with fetched data
        setState(() {
          weatherData = {
            "Color":
                "blue", // You can determine color based on weather condition
            "weather": weather,
            //"Time": "$hours",
            "Precautions": precautions,
          };
        });
      } else {
        // Handle error cases
        print('Failed to load weather data: ${response.statusCode}');
      }
    } catch (e) {
      // Handle network or other errors
      print('Error loading weather data: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    // Call the function to load weather data when the screen initializes
    _loadWeatherData();
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
                  color: _getColor(weatherData['Color'] ?? ''),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(height: 40),
            Icon(
              _getWeatherIcon(weatherData['weather'] ?? ''),
              size: 150,
            ),
            const SizedBox(height: 40),
            Text(
              weatherData['weather'] ?? '',
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
                  'In ${weatherData["Time"] ?? ''} hrs',
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
                        weatherData['Precautions'] ?? [],
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
