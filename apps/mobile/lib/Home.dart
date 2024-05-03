import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_config/flutter_config.dart';
import 'package:telephony/telephony.dart';
// import 'package:sms_maintained/sms.dart';
// import 'package:flutter_sms/flutter_sms.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/cupertino.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import 'package:material_segmented_control/material_segmented_control.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:http/http.dart' as http;

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:shake/shake.dart';
import 'package:geolocator/geolocator.dart';
//import 'package:sms_advanced/sms_advanced.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class SOSButton extends StatelessWidget {
  final bool isHelping;

  SOSButton({required this.isHelping});

  @override
  Widget build(BuildContext context) {
    return (!isHelping)
        ? Positioned(
            bottom: 160.0,
            right: 20.0,
            child: FloatingActionButton(
              onPressed: () => _onSOSPressed(context),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'SOS',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              backgroundColor: const Color.fromARGB(255, 250, 121, 121),
            ),
          )
        : SizedBox(); // If isHelping is false, return an empty SizedBox
  }

  void _onSOSPressed(BuildContext context) async {
    // Request contacts permission
    PermissionStatus permissionStatus = await Permission.contacts.request();

    if (permissionStatus.isGranted) {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(15.0), // Decrease the border radius
            ),
            title: Text(
              'Sending SOS',
              style: TextStyle(
                  fontFamily: GoogleFonts.kanit().fontFamily, fontSize: 18),
            ),
            content: SizedBox(
              height: 8.5, // Decrease the height of the SizedBox
              child: LinearProgressIndicator(
                minHeight:
                    2.0, // Decrease the minHeight of the LinearProgressIndicator
              ),
            ),
          );
        },
      );

      // Wait for 5 seconds
      await Future.delayed(Duration(seconds: 5));

      // Close the loading dialog
      Navigator.of(context).pop();

      // Show alert
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    'Emergency Alert',
                    style: TextStyle(
                        fontFamily: GoogleFonts.getFont('Kanit').fontFamily,
                        fontSize: 18),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the alert
                  },
                ),
              ],
            ),
            content: SizedBox(
              height: 40.0, // Fixed height
              child: Padding(
                padding: const EdgeInsets.only(top: 0.0),
                child: Text(
                  'Your emergency contacts have been alerted.',
                  style: TextStyle(
                      fontFamily: GoogleFonts.getFont('Kanit').fontFamily),
                ),
              ),
            ),
          );
        },
      );

      // Implement your SOS functionality here
      print('SOS sent!');
    } else {
      // Permission not granted, show a snackbar or dialog to inform the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Contacts permission required for SOS feature.',
            style:
                TextStyle(fontFamily: GoogleFonts.getFont('Kanit').fontFamily),
          ),
        ),
      );
    }
  }

  void _sendSOS(BuildContext context) async {
    final String message = 'SOS! I need help with the climate crisis!';
    final String uri = 'sms:?body=${Uri.encodeQueryComponent(message)}';

    if (await canLaunch(uri)) {
      await launch(uri);
    } else {
      print('Could not launch $uri');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: Could not launch messaging app')),
      );
    }
  }
}

class _HomeState extends State<Home> {
  Completer<GoogleMapController> _controllerCompleter = Completer();

  List<Map<String, dynamic>> userSelections = [];
  List<Marker> markers = [];

  late LatLng currentLocation = LatLng(0, 0); // Initialize with default value
  bool locationLoaded = false;
  CameraPosition currentCameraPosition =
      CameraPosition(target: LatLng(0, 0), zoom: 0);

  String selectedFilter = ''; // Track selected filter option

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    Timer.periodic(Duration(seconds: 5), (timer) {
      _checkConnectivity();
    });

    ShakeDetector.autoStart(
      onPhoneShake: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Shaked!'),
          ),
        );
        // _sendEmergencyMessage(); // Call function to send SOS message
      },
      minimumShakeCount: 2,
      shakeSlopTimeMS: 500,
      shakeCountResetTime: 3000,
      shakeThresholdGravity: 2.7,
    );
  }

  String _mapStyle = '';
  bool isHelping = false;
  bool isOffline = false;

  Future<void> _checkConnectivity() async {
    final isConnected = await InternetConnectionChecker().hasConnection;
    setState(() {
      isOffline = !isConnected;
    });
  }

  // Function to update user selections in Firestore
  void updateUserSelections(List<Map<String, dynamic>> userSelections) {
    // Reference to the Firestore collection
    CollectionReference userSelectionsCollection =
        FirebaseFirestore.instance.collection('userSelections');

    // Convert userSelections to a format suitable for Firestore
    List<Map<String, dynamic>> firestoreData = [];

    for (var selection in userSelections) {
      // Convert each selection to a Firestore document
      Map<String, dynamic> firestoreDoc = {
        'location': selection['location'],
        'selectedOptions': selection['selectedOptions'],
        'phonenumber': selection['phonenumber'],
        // Add any additional fields you want to store
      };

      firestoreData.add(firestoreDoc);
    }

    // Check if the document already exists
    userSelectionsCollection
        .doc('unique_document_id')
        .get()
        .then((docSnapshot) {
      if (docSnapshot.exists) {
        // If the document exists, update it with the new data
        userSelectionsCollection
            .doc('unique_document_id')
            .update({'selections': firestoreData})
            .then((_) => print("User selections updated"))
            .catchError(
                (error) => print("Failed to update user selections: $error"));
      } else {
        // If the document doesn't exist, create it with the new data
        userSelectionsCollection
            .doc('unique_document_id')
            .set({'selections': firestoreData})
            .then((_) => print("User selections created"))
            .catchError(
                (error) => print("Failed to create user selections: $error"));
      }
    }).catchError(
            (error) => print("Failed to check document existence: $error"));
  }

// Function to handle the submission of user selections
  // Function to handle the submission of user selections
  void submitUserSelections() async {
    // Get the selected options
    List<dynamic> selectedHelpDynamic = userSelections
        .map((selection) => selection['selectedOptions'])
        .expand((options) => options)
        .toList();

    // Ensure that all items in selectedHelpDynamic are strings
    List<String> selectedHelp = selectedHelpDynamic
        .whereType<String>()
        .toList(); // This will filter out non-string items

    // Check if any existing user selection matches the current selection
    bool userSelectionExists = userSelections.any((selection) =>
        selection['location']['latitude'] == currentLocation.latitude &&
        selection['location']['longitude'] == currentLocation.longitude &&
        List<String>.from(selection['selectedOptions'])
            .toSet()
            .containsAll(selectedHelp.toSet()));

    // Add new user selection only if it doesn't already exist in the list
    if (!userSelectionExists) {
      updateUserSelections(userSelections);
    }
  }

  List<Map<String, dynamic>> filtersNeedHelp = [
    {"type": "Hospital", "icon": FontAwesomeIcons.truckMedical},
    {"type": "Relief Camp", "icon": FontAwesomeIcons.tent},
    {"type": "Safe Space", "icon": FontAwesomeIcons.house},
    {"type": "Supplies", "icon": FontAwesomeIcons.boxOpen},
    {"type": "Volunteer", "icon": FontAwesomeIcons.handshakeAngle},
  ];

  // Define a list to store relief camp markers
  List<Marker> _reliefCampMarkers = [];

  void onReliefCampOptionClicked() {
    // Call the method to add relief camp markers from static data
    _addReliefCampMarkersFromStaticData();
  }

// Method to add relief camp markers based on static data
  void _addReliefCampMarkersFromStaticData() {
    // Static data containing relief camp coordinates
    List<Map<String, double>> reliefCampCoordinates = [
      {
        "latitude": 17.4065,
        "longitude": 78.4772
      }, // Example coordinates for Hyderabad
      // Add more coordinates as needed
    ];

    // Loop through the static data and add markers
    for (var coordinates in reliefCampCoordinates) {
      double latitude = coordinates['latitude']!;
      double longitude = coordinates['longitude']!;
      LatLng location = LatLng(latitude, longitude);
      _addReliefCampMarker(location);
    }
  }

// Method to add relief camp marker to the map
  void _addReliefCampMarker(LatLng location) {
    // Create marker
    Marker marker = Marker(
      markerId: MarkerId(location.toString()),
      position: location,
      // Add custom icon if needed
      // icon: BitmapDescriptor.defaultMarker,
      onTap: () {
        // Handle marker tap event if needed
      },
    );

    // Update the list of relief camp markers
    setState(() {
      _reliefCampMarkers.add(marker);
    });
  }

  List<Map<String, dynamic>> filtersGiveHelp = [
    {"type": "Victim", "icon": FontAwesomeIcons.handHoldingMedical},
    {"type": "Volunteer", "icon": FontAwesomeIcons.handshakeAngle},
    {"type": "Donate", "icon": FontAwesomeIcons.gift},
    {"type": "Shelter", "icon": FontAwesomeIcons.house},
    {"type": "Food", "icon": FontAwesomeIcons.utensils},
  ];

  void _loadMapStyle() async {
    _mapStyle = await rootBundle.loadString('assets/maps/map_style.json');
  }

  // Future<void> _loadJsonData() async {
  //   String jsonString = await rootBundle.loadString('assets/backend.schema.json');
  //   final jsonResponse = json.decode(jsonString);
  //   _processJsonData(jsonResponse);
  // }

  Future<void> _loadJsonData() async {
    final url = Uri.parse(FlutterConfig.get('BACKEND_URL') + "/api/v1");
    // final url = Uri.parse('https://flask-7i2vfdwx7q-el.a.run.app/api/v1');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        // final jsonResponse = json.decode(response.body);
        final jsonResponse = json
            .decode(response.body.replaceAll('\n', '').replaceAll('  ', ''));
        print(jsonResponse);
        _processJsonData(jsonResponse);
      } else {
        print(
            'Failed to load data from the internet. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print("Error fetching data: $e");
    }
  }

  void _processJsonData(Map<String, dynamic> data) async {
    // // Clear existing volunteer markers
    // _volunteerMarkers.clear();

    for (var selection in userSelections) {
      if (selection['selectedOptions'].contains('Volunteer')) {
        double latitude = selection['location']['latitude'];
        double longitude = selection['location']['longitude'];
        LatLng location = LatLng(latitude, longitude);

        // Add volunteer marker to _volunteerMarkers list
        _addMarker(location);
      }
    }
  }

  List<Marker> _volunteerMarkers = [];

  void onVolunteerOptionClicked() {
    print("Volunteer option clicked"); // Add this line for debugging

    // Filter ctions tuserSeleo get entries where user has volunteered
    List<Map<String, dynamic>> volunteerSelections =
        userSelections.where((selection) {
      return selection['selectedOptions'].contains('Volunteer');
    }).toList();

    // Extract coordinates and add markers to the map
    for (var selection in volunteerSelections) {
      double latitude = selection['location']['latitude'];
      double longitude = selection['location']['longitude'];
      LatLng location = LatLng(latitude, longitude);

      // Add marker to the map
      _addMarker(location);
    }
  }

  // Method to add marker to the map
  void _addMarker(LatLng location) {
    // Create marker
    Marker marker = Marker(
      markerId: MarkerId(location.toString()),
      position: location,
      // Add custom icon if needed
      // icon: BitmapDescriptor.defaultMarker,
      onTap: () {
        // Handle marker tap event if needed
      },
    );

    // Update the list of markers
    setState(() {
      _volunteerMarkers.add(marker);
    });
  }

  // Other existing methods...
  void _showLocationDetails(
      BuildContext context, Map<String, dynamic> locationDetails) async {
    final double startLatitude = currentLocation.latitude;
    final double startLongitude = currentLocation.longitude;
    final double endLatitude = locationDetails['location']['lat'];
    final double endLongitude = locationDetails['location']['lng'];

    double distanceInMeters = Geolocator.distanceBetween(
        startLatitude, startLongitude, endLatitude, endLongitude);
    String distanceDisplay = distanceInMeters < 1000
        ? '${distanceInMeters.toStringAsFixed(0)}m'
        : '${(distanceInMeters / 1000).toStringAsFixed(1)}km';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext bc) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(15),
              topRight: Radius.circular(15),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(40, 40, 40, 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  locationDetails['type'].toString().toUpperCase(),
                  style: GoogleFonts.getFont(
                    "Lexend",
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 10),
                Divider(thickness: 2),
                SizedBox(height: 20),
                Row(
                  children: [
                    Icon(Icons.place, color: Colors.black),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Distance: $distanceDisplay',
                        style: GoogleFonts.getFont(
                          "Lexend",
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        _openMapRoute(startLatitude, startLongitude,
                            endLatitude, endLongitude);
                      },
                      icon: Icon(Icons.directions, color: Colors.blue),
                      label: Text(
                        'Route',
                        style:
                            GoogleFonts.getFont("Lexend", color: Colors.blue),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.telegram, color: Colors.black),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Ph: ${locationDetails['phone']}',
                        style: GoogleFonts.getFont(
                          "Lexend",
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () =>
                          launch('tel:${locationDetails['phone']}'),
                      icon: Icon(Icons.call, color: Colors.blue),
                      label: Text(
                        ' Call ',
                        style:
                            GoogleFonts.getFont("Lexend", color: Colors.blue),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 22),
                Text(
                  locationDetails['type'] == 'victim'
                      ? 'Needs:'
                      : 'Available Assistance:',
                  //'Available Assistance:',
                  style: GoogleFonts.getFont(
                    "Lexend",
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
                ...locationDetails['help'].map<Widget>((helpItem) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '• $helpItem',
                      style: GoogleFonts.getFont(
                        "Lexend",
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                  );
                }).toList(),
                SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openMapRoute(
      double startLat, double startLng, double endLat, double endLng) async {
    String googleMapsUrl =
        "https://www.google.com/maps/dir/?api=1&origin=$startLat,$startLng&destination=$endLat,$endLng&travelmode=driving";
    if (await canLaunch(googleMapsUrl)) {
      await launch(googleMapsUrl);
    } else {
      throw 'Could not open the map.';
    }
  }

  Future<void> _handleOfflineMode() async {
    if (isOffline) {
      while (isOffline) {
        await Future.delayed(Duration(hours: 2));
        final smsNumber = FlutterConfig.get('SMS_NUMBER');
        final lat = currentLocation.latitude;
        final lng = currentLocation.longitude;
        final message = 'offline $lat $lng';
        launch('sms:$smsNumber?body=$message');
        final response = await _waitForResponse(smsNumber);
        final jsonData = _combineJsonData(response);
        _processJsonData(jsonData);
      }
    }
  }

  void _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        currentLocation = LatLng(position.latitude, position.longitude);
        locationLoaded = true;
        currentCameraPosition =
            CameraPosition(target: currentLocation, zoom: 15.0);
      });
    } catch (e) {
      print("Error getting current location: $e");
      // Handle error or provide a default location
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _controllerCompleter.complete(controller);
    _updateMarkers();
  }
  // Import geolocator package

  Future<void> _updateMarkers() async {
    final GoogleMapController controller = await _controllerCompleter.future;

    if (selectedFilter.isNotEmpty) {
      // Clear existing markers
      markers.clear();

      if (selectedFilter == "Hospital") {
        // Add static hospital locations
        List<LatLng> hospitalLocations = getHospitalLocations();
        for (int i = 0; i < hospitalLocations.length; i++) {
          LatLng location = hospitalLocations[i];
          final Marker marker = Marker(
            markerId: MarkerId('hospital_$i'),
            position: location,
            // Add other properties like icon, info window, etc.
            infoWindow: InfoWindow(
              title: getHospitalName(i),
              snippet: getHospitalDetails(i),
              onTap: () {
                _launchMapsUrl(location.latitude, location.longitude);
              },
            ),
          );
          markers.add(marker);
        }

        // Fetch and add nearby hospitals
        await _addNearbyHospitals(controller);
      } else {
        // If the selected filter is not "Hospital", add markers based on user selections
        for (var selection in userSelections) {
          if (selection['selectedOptions'].contains(selectedFilter)) {
            double latitude = selection['location']['latitude'];
            double longitude = selection['location']['longitude'];
            LatLng location = LatLng(latitude, longitude);

            final Marker marker = Marker(
              markerId: MarkerId('marker_${markers.length}'),
              position: location,
              // Add other properties like icon, info window, etc.
            );

            markers.add(marker);
          }
        }
      }

      // Update markers on the map
      setState(() {}); // Trigger rebuild to update markers
    }
  }

  Future<void> _addNearbyHospitals(GoogleMapController controller) async {
    // Get user's current location
    Position position = await Geolocator.getCurrentPosition();

    // Fetch nearby hospital locations
    List<LatLng> nearbyHospitalLocations =
        await _fetchNearbyHospitals(position);

    // Add nearby hospitals as markers
    for (int i = 0; i < nearbyHospitalLocations.length; i++) {
      LatLng location = nearbyHospitalLocations[i];
      final Marker marker = Marker(
        markerId: MarkerId('nearby_hospital_$i'),
        position: location,
        // Add other properties like icon, info window, etc.
        infoWindow: InfoWindow(
          title: 'Nearby Hospital',
          onTap: () {
            _launchMapsUrl(location.latitude, location.longitude);
          },
        ),
      );
      markers.add(marker);
    }
  }

  Future<List<LatLng>> _fetchNearbyHospitals(Position position) async {
    // Replace 'YOUR_API_KEY' with your actual Google Places API key
    final apiKey = 'AIzaSyAcRopFCtkeYwaYEQhw1lLF2bbU50RsQgc';
    final baseUrl =
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json';

    // Define parameters for the API request
    final params = {
      'key': apiKey,
      'location': '${position.latitude},${position.longitude}',
      'radius': '5000', // Search radius in meters (adjust as needed)
      'type': 'hospital', // Search type for hospitals
    };

    // Construct the request URL
    final url = Uri.parse(baseUrl + '?' + Uri(queryParameters: params).query);

    // Send the HTTP request
    final response = await http.get(url);

    // Parse the response
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final results = data['results'] as List<dynamic>;

      // Extract locations from results
      final hospitalLocations = results.map<LatLng>((result) {
        final location = result['geometry']['location'];
        final lat = location['lat'] as double;
        final lng = location['lng'] as double;
        return LatLng(lat, lng);
      }).toList();

      return hospitalLocations;
    } else {
      throw Exception('Failed to fetch nearby hospitals');
    }
  }

  void _launchMapsUrl(double latitude, double longitude) async {
    final url =
        'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  String getHospitalName(int index) {
    // Define a function to get the hospital name based on the index
    List<String> names = [
      "Apollo Hospitals, Jubilee Hills",
      "Care Hospitals, Banjara Hills",
      "Yashoda Hospitals, Secunderabad",
      "Continental Hospitals, Nanakramguda",
      "KIMS Hospitals, Kondapur"
    ];
    return names[index];
  }

  String getHospitalDetails(int index) {
    // Define a function to get the hospital details based on the index
    List<String> details = [
      "CLICK Here(maps): ",
      "CLICK Here(maps): Rd Number 1, Prem Nagar, Banjara Hills, Hyderabad, Telangana 500034",
      "CLICK Here(maps): Alexander Rd, Kummari Guda, Shivaji Nagar, Secunderabad, Telangana 500003",
      "CLICK Here(maps): Financial District, Nanakramguda, Hyderabad, Telangana 500032",
      "CLICK Here(maps): 1-112 / 86, Survey No 5 / EE, beside Union Bank, near RTA Office, Kondapur, Telangana 500084"
    ];
    return details[index];
  }

  List<LatLng> getHospitalLocations() {
    return [
      LatLng(17.415597946043818,
          78.41282706869062), // Apollo Hospitals, Jubilee Hills
      LatLng(17.412889287173705,
          78.45023296684334), // Care Hospitals, Banjara Hills
      LatLng(17.441969329824037,
          78.49712479567914), // Yashoda Hospitals, Secunderabad
      LatLng(17.41753954787001,
          78.33938422451398), // Continental Hospitals, Nanakramguda
      LatLng(17.466517669187308, 78.3678987091736), // KIMS Hospitals, Kondapur
    ];
  }

  void _loadModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isHelping = prefs.getBool('mode') ?? false;
    });
  }

  Future<List<String>> _waitForResponse(String smsNumber) async {
    final List<String> messages = [];
    final Telephony telephony = Telephony.instance;
    List<SmsMessage> smsStream = await telephony.getInboxSms(
        columns: [SmsColumn.ADDRESS, SmsColumn.BODY],
        filter: SmsFilter.where(SmsColumn.ADDRESS)
            .equals("$smsNumber")
            .and(SmsColumn.BODY)
            .like(""),
        sortOrder: [
          OrderBy(SmsColumn.ADDRESS, sort: Sort.ASC),
          OrderBy(SmsColumn.BODY)
        ]);

    await Future.delayed(Duration(minutes: 1));
    smsStream.isEmpty ? print('No messages') : print('Messages found');
    return messages;
  }

  Map<String, dynamic> _combineJsonData(List<String> messages) {
    final Map<String, dynamic> combinedJson = {};
    final RegExp numberRegex = RegExp(r'^(\d+)-end$');
    final Map<int, String> orderedMessages = {};

    for (final message in messages) {
      final match = numberRegex.firstMatch(message);
      if (match != null) {
        final int number = int.parse(match.group(1)!);
        orderedMessages[number] = message;
      }
    }

    final List<String> orderedData = orderedMessages.values.toList();
    for (final data in orderedData) {
      final jsonData = jsonDecode(data);
      combinedJson.addAll(jsonData);
    }

    return combinedJson;
  }

  // Set<Circle> _buildCircles() {
  //   return {
  //     Circle(
  //       circleId: CircleId('current_location'),
  //       center: currentLocation,
  //       radius: 200,
  //       fillColor: Colors.green.withOpacity(0.5),
  //       strokeColor: Colors.green[800]!,
  //       strokeWidth: 3,
  //     ),
  //   };
  // }

  // Set<Marker> _buildMarkers() {
  //   return {
  //     if (currentCameraPosition.zoom < 10)
  //       Marker(
  //         markerId: MarkerId('current_location_marker'),
  //         position: currentLocation,
  //       ),
  //   };
  // }

  //<--------------------- Misc --------------------->
  // void _toggleMode(bool value) async {
  //   final prefs = await SharedPreferences.getInstance();
  //   setState(() {
  //     isHelping = value;
  //     print(isHelping);
  //     prefs.setBool('mode', isHelping);
  //   });
  // }

  // <--------------------- Actions --------------------->

  // dynamic actionButtonClickFn() {
  //   // Placeholder function to print the details
  //   print("-------------------------------------------------------------------------------------------------");
  //   print('Current Location: $currentLocation');
  //   print('Selected Filter: $selectedFilter');
  //   print('Selected Mode: ${isHelping ? "Helping" : "Need Help"}');

  // }

  // -----------------------------------------------------------------------------------------------------------------------------------------------

  void makePostRequest(List<String> selectedHelp, bool isHelping, dynamic lat,
      dynamic lng) async {
    final prefs = await SharedPreferences.getInstance();
    String phoneNumber =
        prefs.getString('phoneNumber') ?? 'No phone number set';

    String mode = isHelping ? "give" : "need";
    String type = isHelping ? "volunteer" : "victim";
    double latitude = lat;
    double longitude = lng;

    Map<String, dynamic> requestBody = {
      "mode": mode,
      "type": type,
      "location": {"lat": latitude, "lng": longitude},
      "phone": phoneNumber,
      "help": selectedHelp,
    };

    final response = await http.post(
      Uri.parse(FlutterConfig.get('BACKEND_URL') + "/api/v1"),
      headers: <String, String>{
        'Content-Type': 'application/json;',
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      // Request successful
      print('POST request successful');
      print('Response: ${response.body}');
    } else {
      // Request failed
      print('POST request failed with status: ${response.statusCode}');
      print('Response: ${response.body}');
    }
  }

  void reloadMapMarkers() async {
    await _loadJsonData();
  }

  void actionButtonClickFn() async {
    final prefs = await SharedPreferences.getInstance();
    String phoneNumber =
        prefs.getString('phoneNumber') ?? 'No phone number set';

    Map<String, IconData> helpIcons = {
      'Volunteer': Icons.volunteer_activism,
      'Donate': Icons.monetization_on,
      'Safe Space': Icons.house,
      'Offer Food': Icons.food_bank,
      'Medical': Icons.medical_services,
      'Shelter': Icons.house,
      'Food': Icons.fastfood,
      'Clothing': Icons.checkroom,
      'Other': Icons.help_outline,
    };

    Map<String, bool> helpOptions = Map.fromIterable(
      isHelping ? helpIcons.keys.take(4) : helpIcons.keys.skip(4),
      key: (item) => item as String,
      value: (item) => false,
    );

    bool isAnyOptionSelected() {
      return helpOptions.containsValue(true);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.all(40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(height: 10),
                  Text(
                    isHelping ? ' I can provide' : ' I need',
                    style: GoogleFonts.getFont(
                      "Lexend",
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  Divider(),
                  ...helpOptions.keys.map((option) {
                    final isSelected = helpOptions[option]!;
                    return Container(
                      margin: EdgeInsets.only(top: 10),
                      child: InkWell(
                        onTap: () {
                          setModalState(() {
                            helpOptions[option] = !isSelected;
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 15),
                          decoration: BoxDecoration(
                            border: isSelected
                                ? Border.all(
                                    color: Theme.of(context).primaryColor,
                                    width: 2)
                                : Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              SizedBox(width: 15), // Padding on the left side
                              Icon(helpIcons[option],
                                  color: isSelected
                                      ? Theme.of(context).primaryColor
                                      : Colors.grey),
                              SizedBox(
                                  width: 15), // Space between the icon and text
                              Expanded(
                                child: Text(
                                  option,
                                  style: GoogleFonts.getFont(
                                    "Lexend",
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? Theme.of(context).primaryColor
                                        : Colors.black,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Icon(Icons.check,
                                    color: Theme.of(context).primaryColor),
                              SizedBox(width: 15), // Padding on the right side
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: StadiumBorder(),
                      // primary: isHelping ? Colors.blue : Colors.red,
                      padding:
                          EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                    child: Text(
                      'Submit',
                      style: GoogleFonts.getFont(
                        "Lexend",
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                    onPressed: isAnyOptionSelected()
                        ? () async {
                            // Get the selected options
                            List<String> selectedHelp = helpOptions.entries
                                .where((entry) => entry.value)
                                .map((entry) => entry.key)
                                .toList();

                            // Save user's location and selected options in ArrayList
                            userSelections.add({
                              'location': {
                                'latitude': currentLocation.latitude,
                                'longitude': currentLocation.longitude
                              },
                              'selectedOptions': selectedHelp,
                              'phonenumber': phoneNumber,
                            });

                            // If phoneNumber is available and not empty, include it in the data
                            if (phoneNumber != null && phoneNumber.isNotEmpty) {
                              userSelections.last['phoneNumber'] = phoneNumber;
                            }

                            // Perform any necessary actions with the collected data
                            print('User Selections: $userSelections');

                            // Close the modal bottom sheet and reload the map markers
                            Navigator.pop(context);
                            reloadMapMarkers();
                          }
                        : null,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // <--------------------- UI --------------------->

  Widget _buildTopFloatingBar() {
    return Container(
      height: 60,
      padding: EdgeInsets.symmetric(horizontal: 20),
      margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10),
      child: Positioned(
        // top: MediaQuery.of(context).padding.top + 10,
        left: MediaQuery.of(context).size.width * 0.075,
        right: MediaQuery.of(context).size.width * 0.075,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Color.fromARGB(255, 227, 227, 227),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(color: Colors.black26, blurRadius: 8, spreadRadius: 2)
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: CupertinoSlidingSegmentedControl<int>(
                  children: {
                    0: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        'Need Help',
                        style: GoogleFonts.getFont('Lexend',
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: isHelping ? Colors.grey : Colors.redAccent),
                      ),
                    ),
                    1: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        'Give Help',
                        style: GoogleFonts.getFont('Lexend',
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: isHelping ? Colors.blue : Colors.grey),
                      ),
                    ),
                  },
                  groupValue: isHelping ? 1 : 0,
                  onValueChanged: (int? value) {
                    setState(() {
                      isHelping = value == 1;
                    });
                  },
                  backgroundColor: Color.fromARGB(255, 227, 227, 227),
                  thumbColor: Colors.white,

                  // Add Styles if needed <-->
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOfflineWidget() {
    return Container(
      margin: EdgeInsets.all(20.0),
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.redAccent,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: const Row(
        children: [
          Icon(Icons.error_outline, color: Colors.white),
          SizedBox(width: 10.0),
          Expanded(
            child: Text(
              'No network connection, switching to SMS mode',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    List<Map<String, dynamic>> filters =
        filtersNeedHelp; // Assuming this list is defined

    return Container(
      height: 60,
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (BuildContext context, int index) {
          Map<String, dynamic> filter = filters[index];
          bool isSelected = filter['type'] == selectedFilter;

          return Container(
            margin: EdgeInsets.symmetric(horizontal: 3),
            child: FilterChip(
              avatar: Icon(filter['icon'],
                  color: isSelected ? Colors.white : Colors.grey),
              label: Text(filter['type'],
                  style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                      color: isSelected ? Colors.white : Colors.grey)),
              selected: isSelected,
              onSelected: (bool value) {
                setState(() {
                  selectedFilter = value ? filter['type'] : '';
                });
                _updateMarkers(); // Update markers when filter is selected
              },
              backgroundColor: Color.fromARGB(255, 227, 227, 227),
              selectedColor: Colors.blue, // Adjust as needed
              checkmarkColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
                side: BorderSide(
                  color: isSelected ? Colors.transparent : Colors.transparent,
                ),
              ),
              shadowColor: Colors.black,
              elevation: 3,
              showCheckmark: false,
            ),
          );
        },
      ),
    );
  }

  Widget recenterBtn(Completer<GoogleMapController> controllerCompleter,
      LatLng currentLocation) {
    return FutureBuilder<GoogleMapController>(
      future: controllerCompleter.future,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Positioned(
            right: 20.0,
            bottom: 90.0,
            child: FloatingActionButton(
              mini: false,
              child: Icon(FontAwesomeIcons.streetView, color: Colors.black),
              backgroundColor: Colors.white,
              onPressed: () {
                snapshot.data!.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(
                      target: currentLocation,
                      zoom: 15.0,
                    ),
                  ),
                );
              },
            ),
          );
        } else {
          return Container();
        }
      },
    );
  }

  Widget actionBtn(isHelping, currentLocation, selectedFilter) {
    return Positioned(
      right: 20.0,
      bottom: 20.0,
      child: buildFloatingActionButton(
        isHelping: isHelping,
        currentLocation: currentLocation,
        selectedFilter: selectedFilter,
      ),
    );
  }

  Widget buildFloatingActionButton({
    required bool isHelping,
    required LatLng currentLocation,
    required String selectedFilter,
  }) {
    return FloatingActionButton(
      child: Icon(
        isHelping
            ? FontAwesomeIcons.handHoldingHeart
            : FontAwesomeIcons.handsHelping,
        color: Colors.white,
      ),
      backgroundColor: isHelping
          ? Color.fromARGB(255, 137, 202, 255)
          : Color.fromARGB(255, 250, 121, 121),
      onPressed: actionButtonClickFn,
    );
  }

  // <--------------------- Build --------------------->
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Google Map widget
          locationLoaded
              ? GoogleMap(
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  compassEnabled: false,
                  mapToolbarEnabled: false,
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: currentCameraPosition,
                  zoomControlsEnabled: false,
                  markers: Set<Marker>.of(markers),
                )
              : Center(child: CircularProgressIndicator()),

          // Column containing top floating bar, filter bar, and offline widget
          Column(
            children: [
              _buildTopFloatingBar(),
              _buildFilterBar(),
              isOffline ? _buildOfflineWidget() : Container(),
            ],
          ),

          // Recenter button
          recenterBtn(_controllerCompleter, currentLocation),

          // Action button
          actionBtn(isHelping, currentLocation, selectedFilter),

          // SOS Button
          SOSButton(isHelping: isHelping == true),

          // Button to submit user selections to Firestore
          Positioned(
            bottom: 20.0,
            left: 20.0,
            child: ElevatedButton(
              onPressed: submitUserSelections,
              child: Text('Firestore'),
            ),
          ),
        ],
      ),
    );
  }
}
