import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/backend_config.dart';
import 'auth_session_guard.dart';
import 'supabase_client_provider.dart';

final backendApiClientProvider = Provider<BackendApiClient>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return BackendApiClient(
    baseUrl: BackendConfig.baseUrl,
    accessTokenProvider: () => supabase.auth.currentSession?.accessToken,
    userIdProvider: () => supabase.auth.currentUser?.id,
  );
});

class BackendApiClient {
  BackendApiClient({
    required String baseUrl,
    required this.accessTokenProvider,
    required this.userIdProvider,
    HttpClient? httpClient,
  }) : _baseUri = Uri.parse(baseUrl),
       _httpClient = httpClient ?? HttpClient();

  final Uri _baseUri;
  final HttpClient _httpClient;
  final String? Function() accessTokenProvider;
  final String? Function() userIdProvider;

  String? get currentUserId => userIdProvider();

  Future<dynamic> get(String path, {Map<String, String>? query}) {
    return _send('GET', path, query: query);
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) {
    return _send('POST', path, body: body);
  }

  Future<dynamic> patch(String path, Map<String, dynamic> body) {
    return _send('PATCH', path, body: body);
  }

  Future<dynamic> put(String path, Map<String, dynamic> body) {
    return _send('PUT', path, body: body);
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
  }) async {
    final token = accessTokenProvider();
    final userId = userIdProvider();
    if (token == null || token.isEmpty || userId == null || userId.isEmpty) {
      throw const BackendApiException('ログインが必要です。');
    }
    if (!AuthSessionGuard.isTokenForCurrentProject(token)) {
      throw const BackendApiException('ログイン情報を更新してください。もう一度ログインしてください。');
    }

    final uri = _baseUri.replace(
      path: _joinPath(_baseUri.path, path),
      queryParameters: query,
    );
    final request = await _httpClient
        .openUrl(method, uri)
        .timeout(const Duration(seconds: 12));
    request.headers.contentType = ContentType.json;
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
    request.headers.set('X-Nomo-User-ID', userId);

    if (body != null) {
      request.write(jsonEncode(body));
    }

    final response = await request.close().timeout(const Duration(seconds: 20));
    final text = await utf8.decoder.bind(response).join();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw BackendApiException(
        _friendlyError(text),
        statusCode: response.statusCode,
      );
    }
    if (text.trim().isEmpty) return null;
    return jsonDecode(text);
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
        return decoded['error'] as String;
      }
    } catch (_) {
      // Use raw text below.
    }
    return text.isEmpty ? 'Backend request failed.' : text;
  }
}

class BackendApiException implements Exception {
  const BackendApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
