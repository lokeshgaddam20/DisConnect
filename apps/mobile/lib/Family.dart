import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import 'ChatScreen.dart';
import 'FamilyMember.dart';

class FamilySpaceScreen extends StatefulWidget {
  @override
  _FamilySpaceScreenState createState() => _FamilySpaceScreenState();
}

class _FamilySpaceScreenState extends State<FamilySpaceScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Marker> _familyMemberMarkers = {};
  List<FamilyMember> _familyMembers = [
    FamilyMember(
      name: 'Alice',
      distance: 1.2,
      avatarUrl: 'assets/icon/icon.png',
      // markerIcon: 'maps/markers/family.png'
    ),
    FamilyMember(
      name: 'Bob',
      distance: 2.3,
      avatarUrl: 'assets/icon/icon.png',
      // markerIcon: 'maps/markers/family.png'
    ),
    FamilyMember(
      name: 'Charlie',
      distance: 3.4,
      avatarUrl: 'assets/icon/icon.png',
      // markerIcon: 'maps/markers/family.png'
    ),
  ];

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    // _getMarkerIcon();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Family Space')),
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
            child: ListView.builder(
              itemCount: _familyMembers.length,
              physics: BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final member = _familyMembers[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(member.name[0]),
                    ),
                    title: Text(member.name),
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
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
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
        },
        child: Icon(Icons.location_on),
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

    _getRandomMarkers();
  }

  void _getRandomMarkers() {
    _familyMemberMarkers.clear(); // Clear previous markers

    for (int index = 0; index < _familyMembers.length; index++) {
      final familyMember = _familyMembers[index];
      final double latOffset = (familyMember.distance / 100) *
          Random().nextDouble() *
          (Random().nextBool() ? 1 : -1);
      final double lngOffset = (familyMember.distance / 100) *
          Random().nextDouble() *
          (Random().nextBool() ? 1 : -1);
      final position = LatLng(
        _markers.first.position.latitude + latOffset,
        _markers.first.position.longitude + lngOffset,
      );

      // final markerIcon = _getMarkerIcon();

      _familyMemberMarkers.add(
        Marker(
          markerId: MarkerId('familyMember$index'),
          position: position,
          // icon: markerIcon,
          infoWindow: InfoWindow(title: familyMember.name),
        ),
      );
    }

    setState(() {
      _markers.addAll(_familyMemberMarkers);
    });

    // _adjustMapBounds();
  }

  // _getMarkerIcon() {
  //   final bitmap = BitmapDescriptor.fromAssetImage(
  //     ImageConfiguration.empty,
  //     "assets/maps/markers/family.png",
  //   );
  //   return bitmap;
  // }

  // void _adjustMapBounds() {
  //   if (_mapController == null || _markers.isEmpty) return;

  //   final bounds = _markers.fold<LatLngBounds?>(null, (bounds, marker) {
  //     return bounds?.extend(marker.position) ??
  //         LatLngBounds(southwest: marker.position, northeast: marker.position);
  //   });

  //   if (bounds != null) {
  //     _mapController?.animateCamera(
  //       CameraUpdate.newLatLngBounds(bounds, 100),
  //     );
  //   }
  // }
}
