import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

final tomoPlaceSearchServiceProvider = Provider<TomoPlaceSearchService>((ref) {
  return const TomoPlaceSearchService();
});

class TomoPlaceSearchResult {
  const TomoPlaceSearchResult({
    required this.name,
    required this.subtitle,
    required this.distanceMeters,
    required this.latitude,
    required this.longitude,
  });

  factory TomoPlaceSearchResult.fromMap(Map<dynamic, dynamic> map) {
    return TomoPlaceSearchResult(
      name: (map['name'] as String? ?? '').trim(),
      subtitle: (map['subtitle'] as String? ?? '').trim(),
      distanceMeters: (map['distanceMeters'] as num?)?.toDouble() ?? 0,
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0,
    );
  }

  final String name;
  final String subtitle;
  final double distanceMeters;
  final double latitude;
  final double longitude;
}

class TomoPlaceSearchService {
  const TomoPlaceSearchService();

  static const _channel = MethodChannel('tomo/place_search');

  Future<List<TomoPlaceSearchResult>> searchNearby({
    required String query,
    int limit = 20,
    double radiusMeters = 2500,
  }) async {
    final rawResults = await _channel.invokeListMethod<dynamic>(
      'searchNearby',
      <String, Object>{
        'query': query.trim(),
        'limit': limit,
        'radiusMeters': radiusMeters,
      },
    );
    return (rawResults ?? const <dynamic>[])
        .whereType<Map<dynamic, dynamic>>()
        .map(TomoPlaceSearchResult.fromMap)
        .where((place) => place.name.isNotEmpty)
        .toList(growable: false);
  }
}
