import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ChatScreen.dart';
import 'FamilyMember.dart';

class FamilySpaceScreen extends StatefulWidget {
  @override
  _FamilySpaceScreenState createState() => _FamilySpaceScreenState();
}

class _FamilySpaceScreenState extends State<FamilySpaceScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  GoogleMapController? _mapController;
  List<User> _users = [];
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _addUser(String phoneNumber, String name) async {
    // Create a new document in the "familyspace" collection with the phone number
    await _firestore.collection('familyspace').doc(phoneNumber).set({
      'phoneNumber': phoneNumber,
      'name': name,
      // Add any other user details here, like title or name
    });

    // Get the user's location from the "users" collection
    DocumentSnapshot userSnapshot =
        await _firestore.collection('users').doc(phoneNumber).get();
    if (userSnapshot.exists) {
      Map<String, dynamic>? userData =
          userSnapshot.data() as Map<String, dynamic>?;
      double latitude = userData?['latitude'] ?? 0.0;
      double longitude = userData?['longitude'] ?? 0.0;

      // Add the user to the _users list
      setState(() {
        _users.add(
          User(
            title: name, // Replace with the actual title or name
            phoneNumber: phoneNumber,
            latitude: latitude,
            longitude: longitude,
          ),
        );
      });
    }

    // After adding the user, update the UI
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    // Clear the existing _users list
    _users.clear();

    // Listen to the "familyspace" collection and fetch user phone numbers
    QuerySnapshot querySnapshot =
        await _firestore.collection('familyspace').get();

    // For each phone number, fetch user location from the "users" collection
    for (QueryDocumentSnapshot doc in querySnapshot.docs) {
      // Get the user's location from the "users" collection
      String phoneNumber = doc['phoneNumber'];
      DocumentSnapshot userSnapshot =
          await _firestore.collection('users').doc(phoneNumber).get();

      if (userSnapshot.exists) {
        Map<String, dynamic>? userData =
            userSnapshot.data() as Map<String, dynamic>?;
        double latitude = userData?['latitude'] ?? 0.0;
        double longitude = userData?['longitude'] ?? 0.0;
        String name = userData?['name'] ?? 'default';

        // Add the user to the _users list
        setState(() {
          _users.add(
            User(
              title: name,
              phoneNumber: phoneNumber,
              latitude: latitude,
              longitude: longitude,
            ),
          );
        });

        // Add a marker to the map for the user's location
        _markers.add(
          Marker(
            markerId: MarkerId(phoneNumber),
            position: LatLng(latitude, longitude),
            infoWindow: InfoWindow(
              title: name,
              snippet: phoneNumber,
            ),
          ),
        );
      }
    }
  }

  Future<void> _getCurrentLocation() async {
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

  Future<void> _showAddUserDialog() async {
    String? phoneNumber;
    String? name;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add User'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Enter name',
                ),
                onChanged: (value) {
                  name = value;
                },
              ),
              SizedBox(height: 16.0),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Enter phone number',
                ),
                onChanged: (value) {
                  phoneNumber = value;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // if (phoneNumber != null &&
                //     phoneNumber.isNotEmpty &&
                //     name != null &&
                //     name.isNotEmpty) {
                _addUser(name!, phoneNumber!);
                Navigator.pop(context);
                // }
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(37.7749, -122.4194), // Initial map position
                zoom: 14.0,
              ),
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
              },
              markers: _markers,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                return Card(
                  child: ListTile(
                    title: Text(user.title),
                    subtitle: Text(user.phoneNumber),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _getCurrentLocation,
            child: Icon(Icons.my_location),
          ),
          SizedBox(height: 16.0),
          FloatingActionButton(
            onPressed: () {
              // Show a modal dialog or navigate to a new screen to add a user
              _showAddUserDialog();
            },
            child: Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

class User {
  final String title;
  final String phoneNumber;
  final double latitude;
  final double longitude;

  User({
    required this.title,
    required this.phoneNumber,
    required this.latitude,
    required this.longitude,
  });
}

  // void _listenForLocationUpdates() {
  //   CollectionReference usersRef =
  //       FirebaseFirestore.instance.collection('usersLoc');

  //   usersRef.snapshots().listen((snapshot) {
  //     snapshot.docs.forEach((doc) {
  //       var userId = doc.id;
  //       var location = doc['location'];

  //       if (location != null) {
  //         double? latitude = location.latitude;
  //         double? longitude = location.longitude;

  //         if (latitude != null && longitude != null) {
  //           // Update marker for the corresponding user
  //           _updateMarker(userId, LatLng(latitude, longitude));
  //         }
  //       }
  //     });
  //   });
  // }

  // void _updateMarker(String userId, LatLng location) {
  //   setState(() {
  //     // Remove existing marker for the user
  //     _markers.removeWhere((marker) => marker.markerId.value == userId);

  //     // Add new marker for the user
  //     _markers.add(Marker(
  //       markerId: MarkerId(userId),
  //       position: location,
  //       // You can customize the marker icon here if needed
  //     ));
  //   });
  // }

// class FamilySpaceScreen extends StatefulWidget {
//   @override
//   _FamilySpaceScreenState createState() => _FamilySpaceScreenState();
// }

// class _FamilySpaceScreenState extends State<FamilySpaceScreen> {
//   GoogleMapController? _mapController;
//   Set<Marker> _markers = {};
//   Set<Marker> _familyMemberMarkers = {};
//   List<FamilyMember> _familyMembers = [
//     FamilyMember(
//       name: 'Alice',
//       distance: 1.2,
//       avatarUrl: 'assets/icon/icon.png',
//       // markerIcon: 'maps/markers/family.png'
//     ),
//     FamilyMember(
//       name: 'Bob',
//       distance: 2.3,
//       avatarUrl: 'assets/icon/icon.png',
//       // markerIcon: 'maps/markers/family.png'
//     ),
//     FamilyMember(
//       name: 'Charlie',
//       distance: 3.4,
//       avatarUrl: 'assets/icon/icon.png',
//       // markerIcon: 'maps/markers/family.png'
//     ),
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _getUserLocation();
//     // _getMarkerIcon();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Family Space')),
//       body: Column(
//         children: [
//           Expanded(
//             child: GoogleMap(
//               onMapCreated: (GoogleMapController controller) {
//                 _mapController = controller;
//               },
//               initialCameraPosition: CameraPosition(
//                 target: LatLng(37.7749, -122.4194),
//                 zoom: 12,
//               ),
//               markers: _markers,
//               zoomControlsEnabled: false,
//             ),
//           ),
//           Expanded(
//             child: ListView.builder(
//               itemCount: _familyMembers.length,
//               physics: BouncingScrollPhysics(),
//               itemBuilder: (context, index) {
//                 final member = _familyMembers[index];
//                 return Card(
//                   child: ListTile(
//                     leading: CircleAvatar(
//                       child: Text(member.name[0]),
//                     ),
//                     title: Text(member.name),
//                     subtitle: Text('${member.distance} miles away'),
//                     onTap: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => ChatScreen(
//                             member: member,
//                           ),
//                         ),
//                       );
//                     },
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () async {
//           final position = await Geolocator.getCurrentPosition(
//             desiredAccuracy: LocationAccuracy.high,
//           );
//           final currentLocation = LatLng(position.latitude, position.longitude);
//           setState(() {
//             _markers.add(Marker(
//               markerId: MarkerId('currentLocation'),
//               position: currentLocation,
//               infoWindow: InfoWindow(title: 'You'),
//             ));
//           });
//           _mapController?.animateCamera(
//             CameraUpdate.newCameraPosition(
//               CameraPosition(
//                 target: currentLocation,
//                 zoom: 14,
//               ),
//             ),
//           );
//         },
//         child: Icon(Icons.location_on),
//       ),
//     );
//   }

//   Future<void> _getUserLocation() async {
//     final position = await Geolocator.getCurrentPosition(
//       desiredAccuracy: LocationAccuracy.high,
//     );
//     final currentLocation = LatLng(position.latitude, position.longitude);
//     setState(() {
//       _markers.add(Marker(
//         markerId: MarkerId('currentLocation'),
//         position: currentLocation,
//         infoWindow: InfoWindow(title: 'You'),
//       ));
//     });
//     _mapController?.animateCamera(
//       CameraUpdate.newCameraPosition(
//         CameraPosition(
//           target: currentLocation,
//           zoom: 14,
//         ),
//       ),
//     );

//     _getRandomMarkers();
//   }

//   void _getRandomMarkers() {
//     _familyMemberMarkers.clear(); // Clear previous markers

//     for (int index = 0; index < _familyMembers.length; index++) {
//       final familyMember = _familyMembers[index];
//       final double latOffset = (familyMember.distance / 100) *
//           Random().nextDouble() *
//           (Random().nextBool() ? 1 : -1);
//       final double lngOffset = (familyMember.distance / 100) *
//           Random().nextDouble() *
//           (Random().nextBool() ? 1 : -1);
//       final position = LatLng(
//         _markers.first.position.latitude + latOffset,
//         _markers.first.position.longitude + lngOffset,
//       );

//       // final markerIcon = _getMarkerIcon();

//       _familyMemberMarkers.add(
//         Marker(
//           markerId: MarkerId('familyMember$index'),
//           position: position,
//           // icon: markerIcon,
//           infoWindow: InfoWindow(title: familyMember.name),
//         ),
//       );
//     }

//     setState(() {
//       _markers.addAll(_familyMemberMarkers);
//     });

//     // _adjustMapBounds();
//   }

//   // _getMarkerIcon() {
//   //   final bitmap = BitmapDescriptor.fromAssetImage(
//   //     ImageConfiguration.empty,
//   //     "assets/maps/markers/family.png",
//   //   );
//   //   return bitmap;
//   // }

//   // void _adjustMapBounds() {
//   //   if (_mapController == null || _markers.isEmpty) return;

//   //   final bounds = _markers.fold<LatLngBounds?>(null, (bounds, marker) {
//   //     return bounds?.extend(marker.position) ??
//   //         LatLngBounds(southwest: marker.position, northeast: marker.position);
//   //   });

//   //   if (bounds != null) {
//   //     _mapController?.animateCamera(
//   //       CameraUpdate.newLatLngBounds(bounds, 100),
//   //     );
//   //   }
//   // }
// }
