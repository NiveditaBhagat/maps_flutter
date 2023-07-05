import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart' as OSM;
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  OSM.MapController _mapController = OSM.MapController();
  OSM.GeoPoint? currentLocation;
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          OSM.OSMFlutter(
            controller: _mapController,
            mapIsLoading: const Center(child: CircularProgressIndicator()),
            userTrackingOption: OSM.UserTrackingOption(
              enableTracking: true,
            ),
          ),
          if (isLoading) // Show a loading indicator while getting the location
            Center(child: CircularProgressIndicator()),
          Positioned(
            bottom: 16,
            right: 16,
            child: ElevatedButton(
              onPressed: () async {
                setState(() {
                  isLoading = true;
                });

                try {
                  Position position = await getCurrentLocation();
                  setState(() {
                    currentLocation = OSM.GeoPoint(
                      latitude: position.latitude,
                      longitude: position.longitude,
                    );
                  });

                  // Store the location in Firebase Firestore
                  storeLocation(position);
                } catch (e) {
                  print('Failed to get current location: $e');
                } finally {
                  setState(() {
                    isLoading = false;
                  });
                }
              },
              child: Text('Get Current Location'),
            ),
          ),
        ],
      ),
    );
  }

  Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are disabled, handle accordingly
      throw Exception('Location services are disabled.');
    }

    // Request location permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Location permission is denied, handle accordingly
        throw Exception('Location permission is denied.');
      }
    }

    // Get the current position
    return await Geolocator.getCurrentPosition();
  }

  void storeLocation(Position position) {
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Create a new document in the 'locations' collection
    firestore.collection('locations').add({
      'latitude': position.latitude,
      'longitude': position.longitude,
    }).then((value) {
      print('Location stored successfully!');
    }).catchError((error) {
      print('Failed to store location: $error');
    });
  }
}