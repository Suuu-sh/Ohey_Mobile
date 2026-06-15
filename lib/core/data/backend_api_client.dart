import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/backend_config.dart';
import 'auth_identity_provider.dart';

final backendApiClientProvider = Provider<BackendApiClient>((ref) {
  final authIdentity = ref.watch(authIdentityProvider);
  return BackendApiClient(
    baseUrl: BackendConfig.baseUrl,
    accessTokenProvider: () => authIdentity.currentAccessToken,
    accessTokenRefreshProvider: authIdentity.currentAccessTokenOrRefresh,
    userIdProvider: () => authIdentity.currentUserId,
    tokenValidator: authIdentity.isTokenValidForEnvironment,
  );
});

class BackendApiClient {
  BackendApiClient({
    required String baseUrl,
    required this.accessTokenProvider,
    this.accessTokenRefreshProvider,
    required this.userIdProvider,
    required this.tokenValidator,
    HttpClient? httpClient,
  }) : _baseUri = _normalizeBackendBaseUri(baseUrl),
       _httpClient = httpClient ?? HttpClient();

  final Uri _baseUri;
  final HttpClient _httpClient;
  final String? Function() accessTokenProvider;
  final Future<String?> Function()? accessTokenRefreshProvider;
  final String? Function() userIdProvider;
  final bool Function(String token) tokenValidator;

  String? get currentUserId => userIdProvider();

  Future<dynamic> get(String path, {Map<String, String>? query}) {
    return _send('GET', path, query: query);
  }

  Future<dynamic> post(
    String path,
    Map<String, dynamic> body, {
    Map<String, String>? query,
  }) {
    return _send('POST', path, query: query, body: body);
  }

  Future<dynamic> postNoBody(String path, {Map<String, String>? query}) {
    return _send('POST', path, query: query);
  }

  Future<dynamic> patch(String path, Map<String, dynamic> body) {
    return _send('PATCH', path, body: body);
  }

  Future<dynamic> put(String path, Map<String, dynamic> body) {
    return _send('PUT', path, body: body);
  }

  Future<dynamic> delete(
    String path, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
  }) {
    return _send('DELETE', path, query: query, body: body);
  }

  Future<List<Map<String, dynamic>>> getRows(
    String path, {
    Map<String, String>? query,
  }) async {
    return rowsFrom(await get(path, query: query));
  }

  Future<Map<String, dynamic>> getRow(
    String path, {
    Map<String, String>? query,
  }) async {
    return mapFrom(await get(path, query: query));
  }

  Future<Map<String, dynamic>> postRow(
    String path,
    Map<String, dynamic> body,
  ) async {
    return mapFrom(await post(path, body));
  }

  static List<Map<String, dynamic>> rowsFrom(dynamic value) {
    if (value is! List) {
      throw const BackendApiException('Backend response format is invalid.');
    }
    return [
      for (final row in value)
        if (row is Map)
          Map<String, dynamic>.from(row)
        else
          throw const BackendApiException(
            'Backend response format is invalid.',
          ),
    ];
  }

  static Map<String, dynamic> mapFrom(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    throw const BackendApiException('Backend response format is invalid.');
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
  }) async {
    var token = accessTokenProvider();
    final userId = userIdProvider();
    if (token == null || token.isEmpty) {
      token = await accessTokenRefreshProvider?.call();
    }
    if (token == null || token.isEmpty || userId == null || userId.isEmpty) {
      throw const BackendApiException('ログインが必要です。');
    }
    if (!tokenValidator(token)) {
      throw const BackendApiException('もう一度ログインしてね。');
    }

    final uri = _baseUri.replace(
      path: _joinPath(_baseUri.path, path),
      queryParameters: query,
    );
    final first = await _sendOnce(
      method,
      uri,
      token: token,
      userId: userId,
      body: body,
    );
    if (first.statusCode == HttpStatus.unauthorized &&
        accessTokenRefreshProvider != null) {
      final refreshed = await accessTokenRefreshProvider?.call();
      if (refreshed != null &&
          refreshed.isNotEmpty &&
          refreshed != token &&
          tokenValidator(refreshed)) {
        final retry = await _sendOnce(
          method,
          uri,
          token: refreshed,
          userId: userId,
          body: body,
        );
        return _decodeResponse(retry);
      }
    }
    return _decodeResponse(first);
  }

  Future<_BackendResponse> _sendOnce(
    String method,
    Uri uri, {
    required String token,
    required String userId,
    Map<String, dynamic>? body,
  }) async {
    final request = await _httpClient
        .openUrl(method, uri)
        .timeout(const Duration(seconds: 12));
    request.headers.contentType = ContentType.json;
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
    request.headers.set('X-Ohey-User-ID', userId);

    if (body != null) {
      request.write(jsonEncode(body));
    }

    final response = await request.close().timeout(const Duration(seconds: 20));
    final text = await utf8.decoder.bind(response).join();
    return _BackendResponse(statusCode: response.statusCode, text: text);
  }

  dynamic _decodeResponse(_BackendResponse response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw BackendApiException(
        _friendlyError(response.text),
        statusCode: response.statusCode,
      );
    }
    if (response.text.trim().isEmpty) return null;
    try {
      return jsonDecode(response.text);
    } on FormatException {
      throw const BackendApiException('Backend response format is invalid.');
    }
  }

  String _joinPath(String basePath, String path) {
    final left = basePath.endsWith('/')
        ? basePath.substring(0, basePath.length - 1)
        : basePath;
    final right = path.startsWith('/') ? path : '/$path';
    return '$left$right';
  }

  String _friendlyError(String text) {
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map && decoded['error'] is String) {
        return _safeBackendErrorMessage(decoded['error'] as String);
      }
    } catch (_) {
      return 'Backend request failed.';
    }
    return 'Backend request failed.';
  }

  String _safeBackendErrorMessage(String message) {
    final sanitized = message
        .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '')
        .trim();
    if (sanitized.isEmpty) return 'Backend request failed.';
    const maxErrorLength = 160;
    if (sanitized.length <= maxErrorLength) return sanitized;
    return '${sanitized.substring(0, maxErrorLength)}…';
  }
}

class _BackendResponse {
  const _BackendResponse({required this.statusCode, required this.text});

  final int statusCode;
  final String text;
}

class BackendApiException implements Exception {
  const BackendApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

Uri _normalizeBackendBaseUri(String value) {
  final uri = Uri.parse(value.trim());
  if (uri.scheme != 'https' || uri.host.trim().isEmpty) {
    throw ArgumentError.value(
      value,
      'baseUrl',
      'Ohey backend URL must be an HTTPS URL with a host.',
    );
  }
  return uri;
}
