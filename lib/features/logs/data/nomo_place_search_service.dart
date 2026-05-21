import 'package:flutter/services.dart';

class NomoPlaceSearchResult {
  const NomoPlaceSearchResult({
    required this.name,
    required this.subtitle,
    required this.distanceMeters,
    required this.latitude,
    required this.longitude,
  });

  factory NomoPlaceSearchResult.fromMap(Map<dynamic, dynamic> map) {
    return NomoPlaceSearchResult(
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

class NomoPlaceSearchService {
  const NomoPlaceSearchService();

  static const _channel = MethodChannel('nomo/place_search');

  Future<List<NomoPlaceSearchResult>> searchNearby({
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
        .map(NomoPlaceSearchResult.fromMap)
        .where((place) => place.name.isNotEmpty)
        .toList(growable: false);
  }
}
