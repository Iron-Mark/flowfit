import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Service for OpenRouteService API integration
class OpenRouteService {
  static const String apiKey = '5b3ce35978511000001cf62248';
  static const String baseUrl = 'https://api.openrouteservice.org';
  
  final _cacheManager = DefaultCacheManager();

  /// Encodes a list of GPS coordinates into a polyline string
  Future<String> encodePolyline(List<LatLng> points) async {
    if (points.isEmpty) return '';

    try {
      final coordinates = points
          .map((p) => [p.longitude, p.latitude])
          .toList();

      final response = await http.post(
        Uri.parse('$baseUrl/v2/directions/foot-walking/geojson'),
        headers: {
          'Authorization': apiKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'coordinates': coordinates,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['routes'][0]['geometry'] as String;
      } else if (response.statusCode == 429) {
        throw OpenRouteServiceException('Rate limit exceeded');
      } else {
        throw OpenRouteServiceException(
          'Failed to encode polyline: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw OpenRouteServiceException('Error encoding polyline: $e');
    }
  }

  /// Decodes a polyline string into a list of GPS coordinates
  List<LatLng> decodePolyline(String encoded) {
    if (encoded.isEmpty) return [];

    // Simple polyline decoding algorithm
    final List<LatLng> points = [];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int b;
      int shift = 0;
      int result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }

  /// Gets a map tile URL for the given coordinates and zoom level
  String getMapTileUrl(int x, int y, int zoom) {
    return 'https://tile.openstreetmap.org/$zoom/$x/$y.png';
  }

  /// Fetches and caches a map tile
  Future<String?> getMapTile(int x, int y, int zoom) async {
    try {
      final url = getMapTileUrl(x, y, zoom);
      final file = await _cacheManager.getSingleFile(url);
      return file.path;
    } catch (e) {
      return null;
    }
  }

  /// Calculates bounding box for a list of route points
  Map<String, double> calculateBounds(List<LatLng> routePoints) {
    if (routePoints.isEmpty) {
      return {
        'minLat': 0.0,
        'maxLat': 0.0,
        'minLng': 0.0,
        'maxLng': 0.0,
      };
    }

    double minLat = routePoints.first.latitude;
    double maxLat = routePoints.first.latitude;
    double minLng = routePoints.first.longitude;
    double maxLng = routePoints.first.longitude;

    for (final point in routePoints) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    return {
      'minLat': minLat,
      'maxLat': maxLat,
      'minLng': minLng,
      'maxLng': maxLng,
    };
  }

  /// Searches for nearby POIs
  Future<List<POI>> searchNearbyPOIs(
    LatLng location, {
    required double radius,
    required List<String> categories,
  }) async {
    try {
      // Mock implementation - in production, use OpenRouteService POI API
      // For now, generate mock POIs based on location
      final pois = <POI>[];
      
      // Generate some mock POIs around the location
      final random = DateTime.now().millisecondsSinceEpoch % 100;
      for (int i = 0; i < 5; i++) {
        final angle = (i / 5) * 2 * 3.14159;
        final distance = (radius / 2) * (0.5 + (random + i) % 50 / 100);
        final lat = location.latitude + (distance / 111000) * (angle > 3.14159 ? -1 : 1);
        final lng = location.longitude + (distance / 111000) * (angle % 3.14159 > 1.57 ? -1 : 1);
        
        pois.add(POI(
          name: '${categories[i % categories.length]} ${i + 1}',
          location: LatLng(lat, lng),
          category: categories[i % categories.length],
        ));
      }
      
      return pois;
    } catch (e) {
      return [];
    }
  }

  /// Clears the map tile cache
  Future<void> clearCache() async {
    await _cacheManager.emptyCache();
  }
}

/// Point of Interest model
class POI {
  final String name;
  final LatLng location;
  final String category;

  POI({
    required this.name,
    required this.location,
    required this.category,
  });
}

/// Exception thrown when OpenRouteService API fails
class OpenRouteServiceException implements Exception {
  final String message;
  OpenRouteServiceException(this.message);

  @override
  String toString() => 'OpenRouteServiceException: $message';
}
