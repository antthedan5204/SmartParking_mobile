import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'package:flutter/foundation.dart';

class RoutingService {
  static const String _baseUrl = 'https://router.project-osrm.org/route/v1/driving';

  /// Fetch route between two points
  /// Returns a list of LatLng points for the polyline
  static Future<List<LatLng>> getRoute(LatLng start, LatLng end) async {
    final String url = '$_baseUrl/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final List coordinates = data['routes'][0]['geometry']['coordinates'];
          return coordinates.map((point) => LatLng(point[1].toDouble(), point[0].toDouble())).toList();
        }
      }
    } catch (e) {
      debugPrint('Routing error: $e');
    }
    return [];
  }

  /// Get simplified distance and duration from OSRM
  static Future<Map<String, dynamic>?> getRouteInfo(LatLng start, LatLng end) async {
    final String url = '$_baseUrl/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=false';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          return {
            'distance': route['distance'] / 1000, // km
            'duration': route['duration'] / 60, // minutes
          };
        }
      }
    } catch (e) {
      debugPrint('Route info error: $e');
    }
    return null;
  }
}
