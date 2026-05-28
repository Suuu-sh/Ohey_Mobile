import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

final oheyPlaceSearchServiceProvider = Provider<OheyPlaceSearchService>((ref) {
  return const OheyPlaceSearchService();
});

class OheyPlaceSearchResult {
  const OheyPlaceSearchResult({
    required this.name,
    required this.subtitle,
    required this.distanceMeters,
    required this.latitude,
    required this.longitude,
  });

  factory OheyPlaceSearchResult.fromMap(Map<dynamic, dynamic> map) {
    return OheyPlaceSearchResult(
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

class OheyPlaceSearchService {
  const OheyPlaceSearchService();

  static const _channel = MethodChannel('ohey/place_search');

  Future<List<OheyPlaceSearchResult>> searchNearby({
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
        .map(OheyPlaceSearchResult.fromMap)
        .where((place) => place.name.isNotEmpty)
        .toList(growable: false);
  }
}
