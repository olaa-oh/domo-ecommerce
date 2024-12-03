import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DirectionsController extends GetxController {
  final RxSet<Polyline> polylines = <Polyline>{}.obs;
  final RxList<LatLng> polylineCoordinates = <LatLng>[].obs;

  Future<void> getDirections({
    required LatLng destination,
    LatLng? origin,
  }) async {
    // Clear previous polylines
    polylines.clear();
    polylineCoordinates.clear();

    try {
      // If no origin is provided, get current location
      if (origin == null) {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high
        );
        origin = LatLng(position.latitude, position.longitude);
      }

      // Replace with your actual Google Maps Directions API key
      const apiKey = 'YOUR_GOOGLE_MAPS_DIRECTIONS_API_KEY';
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=$apiKey'
      );

      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = json.decode(response.body);
        
        if (responseBody['status'] == 'OK') {
          // Decode polyline
          final points = responseBody['routes'][0]['overview_polyline']['points'];
          polylineCoordinates.value = _decodePolyline(points);

          // Create polyline
          final polyline = Polyline(
            polylineId: const PolylineId('route'),
            color: Colors.blue,
            points: polylineCoordinates,
            width: 5,
          );

          polylines.add(polyline);
        } else {
          Get.snackbar('Error', 'Unable to fetch directions');
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to get directions: $e');
    }
  }

  // Decode Google Maps encoded polyline
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int result = 1;
      int shift = 0;
      int byte;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result += byte << shift;
        shift += 5;
      } while (byte >= 0x20);
      
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      result = 1;
      shift = 0;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result += byte << shift;
        shift += 5;
      } while (byte >= 0x20);
      
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }
}


  
