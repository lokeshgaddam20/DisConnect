import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'ChatScreen.dart';
import 'FamilyMember.dart';

class FamilySpaceScreen extends StatefulWidget {
  @override
  _FamilySpaceScreenState createState() => _FamilySpaceScreenState();
}

class _FamilySpaceScreenState extends State<FamilySpaceScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  List<FamilyMember> _familyMembers =
      []; // Family members retrieved from Firestore

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    _getFamilyMembers(); // Retrieve family members from Firestore
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
              },
              initialCameraPosition: CameraPosition(
                target: LatLng(37.7749, -122.4194),
                zoom: 12,
              ),
              markers: _markers,
              zoomControlsEnabled: false,
            ),
          ),
          Expanded(
            child: FamilyList(),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () async {
              final position = await Geolocator.getCurrentPosition(
                desiredAccuracy: LocationAccuracy.high,
              );
              final currentLocation =
                  LatLng(position.latitude, position.longitude);
              setState(() {
                _markers.add(Marker(
                  markerId: MarkerId('currentLocation'),
                  position: currentLocation,
                  infoWindow: InfoWindow(title: 'You'),
                ));
              });
              _mapController?.animateCamera(
                CameraUpdate.newCameraPosition(
                  CameraPosition(
                    target: currentLocation,
                    zoom: 14,
                  ),
                ),
              );
              // Save current location to Firestore
              _saveUserLocation(currentLocation);
            },
            child: Icon(Icons.location_on),
          ),
          SizedBox(
              height: 10), // Add some space between the FloatingActionButtons
          FloatingActionButton(
            onPressed: () {
              _showAddMemberDialog();
            },
            child: Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  void _showAddMemberDialog() {
    TextEditingController _phoneNumberController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Family Member'),
          content: TextField(
            controller: _phoneNumberController,
            decoration: InputDecoration(
              hintText: 'Enter phone number',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                String phoneNumber = _phoneNumberController.text.trim();
                if (phoneNumber.isNotEmpty) {
                  _addFamilyMember(phoneNumber);
                }
                Navigator.pop(context);
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _addFamilyMember(String phoneNumber) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added family member: $phoneNumber'),
        backgroundColor: Color.fromARGB(255, 250, 121, 121),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(30),
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        action: SnackBarAction(
          label: 'Dismiss',
          disabledTextColor: Colors.white,
          textColor: Colors.white,
          onPressed: () {
            //Do whatever you want
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  Future<void> _getUserLocation() async {
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    final currentLocation = LatLng(position.latitude, position.longitude);
    setState(() {
      _markers.add(Marker(
        markerId: MarkerId('currentLocation'),
        position: currentLocation,
        infoWindow: InfoWindow(title: 'You'),
      ));
    });
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: currentLocation,
          zoom: 14,
        ),
      ),
    );
  }

  // Save user's phone number and current location to Firestore
  void _saveUserLocation(LatLng currentLocation) async {
    final prefs = await SharedPreferences.getInstance();
    String phoneNumber = prefs.getString('phoneNumber') ?? 'UniqueNUmber';
    FirebaseFirestore.instance
        .collection('familyspace')
        .doc(phoneNumber) // Use user's phone number as document ID
        .set({
      'phoneNumber': phoneNumber, // Change to actual user's phone number
      'location': GeoPoint(currentLocation.latitude, currentLocation.longitude),
    });
  }

  // Retrieve family members' data from Firestore
  void _getFamilyMembers() async {
    final prefs = await SharedPreferences.getInstance();
    String phoneNumber = prefs.getString('phoneNumber') ?? 'UniqueNUmber';

    FirebaseFirestore.instance
        .collection('familyspace')
        .get()
        .then((QuerySnapshot querySnapshot) {
      querySnapshot.docs.forEach((doc) {
        if (doc.id != phoneNumber) {
          _addOrUpdateMarker(
              doc); // Add or update marker for each family member
        }
      });
    });

    FirebaseFirestore.instance
        .collection('familyspace')
        .snapshots()
        .listen((QuerySnapshot querySnapshot) {
      querySnapshot.docChanges.forEach((change) {
        if (change.type == DocumentChangeType.added ||
            change.type == DocumentChangeType.modified) {
          // Check if the added/modified document is a family member
          if (change.doc.id != phoneNumber) {
            // Exclude current user
            _addOrUpdateMarker(change.doc);
          }
        }
        if (change.type == DocumentChangeType.removed) {
          // Remove marker if a family member is removed
          _removeMarker(change.doc.id);
        }
      });
    });
  }

  void _addOrUpdateMarker(DocumentSnapshot document) {
    final location = document['location'] as GeoPoint;
    final markerId = MarkerId(document.id);

    setState(() {
      _markers.removeWhere((marker) => marker.markerId == markerId);
      _markers.add(
        Marker(
          markerId: markerId,
          position: LatLng(location.latitude, location.longitude),
          infoWindow: InfoWindow(title: document['phoneNumber']),
        ),
      );
    });
  }

  void _removeMarker(String documentId) {
    setState(() {
      _markers.removeWhere((marker) => marker.markerId.value == documentId);
    });
  }
}

class FamilyList extends StatefulWidget {
  const FamilyList({Key? key}) : super(key: key);

  @override
  State<FamilyList> createState() => _FamilyListState();
}

class _FamilyListState extends State<FamilyList> {
  Set<Marker> _markers = {};
  @override
  Widget build(BuildContext context) {
    final phoneNumber = _getPhoneNumber();
    final familySpaceStream =
        FirebaseFirestore.instance.collection('familyspace').snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: familySpaceStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final familyMembers = _extractFamilyMembers(snapshot, phoneNumber);

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: ListView.builder(
            itemCount: familyMembers.length,
            itemBuilder: (context, index) {
              final member = familyMembers[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0), // Add padding to ListTile
                  child: ListTile(
                    title: Text(
                      member.name,
                      style: TextStyle(
                          fontWeight: FontWeight.bold), // Make title bold
                    ),
                    subtitle: Text('${member.distance} miles away'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            member: member,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<String?> _getPhoneNumber() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('phoneNumber');
  }

  List<FamilyMember> _extractFamilyMembers(
      AsyncSnapshot<QuerySnapshot> snapshot, Future<String?> phoneNumber) {
    final List<FamilyMember> familyMembers = [];

    snapshot.data!.docs.forEach((doc) {
      if (doc.id != phoneNumber) {
        final data = doc.data() as Map<String, dynamic>;
        final location = data['location'] as GeoPoint;
        final double distance = double.parse(
          (Random().nextDouble() * 3).toStringAsFixed(2),
        );
        // final double distance = await calculateDistance(location);
        final member = FamilyMember(
          name: data['phoneNumber'] ?? '',
          distance: distance,
          //       distance: Geolocator.distanceBetween(
          //   startLatitude,
          //   startLongitude,
          //   endLatitude,
          //   endLongitude,
          // );, // You can calculate distance if needed
        );
        familyMembers.add(member);
        // _addOrUpdateMarker(doc);
      }
    });

    return familyMembers;
  }

  Future<double> calculateDistance(GeoPoint locationDetails) async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    LatLng currentLocation = LatLng(position.latitude, position.longitude);
    // locationLoaded = true;
    // currentCameraPosition =
    //     CameraPosition(target: currentLocation, zoom: 15.0);
    final double startLatitude = currentLocation.latitude;
    final double startLongitude = currentLocation.longitude;

    final double endLatitude = locationDetails.latitude;
    final double endLongitude = locationDetails.longitude;
    double distanceInMeters = Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
    // Convert distance from meters to kilometers
    double distanceInKm = distanceInMeters / 1000;
    return distanceInKm;
  }

  // Future<void> getDistances(List<Map<String, double>> origins,
  //     List<Map<String, double>> destinations) async {
  //   final apiKey = 'YOUR_API_KEY'; // Replace with your Google Maps API key
  //   final url = Uri.parse(
  //       'https://routes.googleapis.com/distanceMatrix/v2:computeRouteMatrix');

  //   final requestBody = {
  //     'origins': origins
  //         .map((origin) => {
  //               'waypoint': {
  //                 'location': {'latLng': origin}
  //               },
  //               'routeModifiers': {'avoid_ferries': true},
  //             })
  //         .toList(),
  //     'destinations': destinations
  //         .map((destination) => {
  //               'waypoint': {
  //                 'location': {'latLng': destination}
  //               },
  //             })
  //         .toList(),
  //     'travelMode': 'DRIVE',
  //     'routingPreference': 'TRAFFIC_AWARE',
  //   };

  //   final headers = {
  //     'Content-Type': 'application/json',
  //     'X-Goog-Api-Key': apiKey,
  //     'X-Goog-FieldMask':
  //         'originIndex,destinationIndex,duration,distanceMeters,status,condition',
  //   };

  //   final response = await http.post(
  //     url,
  //     headers: headers,
  //     body: json.encode(requestBody),
  //   );

  //   if (response.statusCode == 200) {
  //     final List<dynamic> data = json.decode(response.body);
  //     // Process the response data to get distance information
  //     // Example: data[0]['distanceMeters'] contains the distance in meters for the first origin-destination pair
  //   } else {
  //     throw Exception('Failed to fetch distance: ${response.statusCode}');
  //   }
  // }
}
