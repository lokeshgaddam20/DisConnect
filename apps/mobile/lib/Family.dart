import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import 'ChatScreen.dart';
import 'package:Sahaya/FamilyMember.dart';

class FamilySpaceScreen extends StatefulWidget {
  @override
  _FamilySpaceScreenState createState() => _FamilySpaceScreenState();
}

class _FamilySpaceScreenState extends State<FamilySpaceScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  List<FamilyMember> _familyMembers = [
    FamilyMember(
        name: 'Alice', distance: 1.2, avatarUrl: 'assets/icon/icon.png'),
    FamilyMember(name: 'Bob', distance: 2.3, avatarUrl: 'assets/icon/icon.png'),
    FamilyMember(
        name: 'Charlie', distance: 3.4, avatarUrl: 'assets/icon/icon.png'),
  ];

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
                _getUserLocation();
              },
              initialCameraPosition: CameraPosition(
                target: LatLng(37.7749, -122.4194),
                zoom: 12,
              ),
              markers: _markers,
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
                zoom: 12,
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
          zoom: 12,
        ),
      ),
    );
  }
}
