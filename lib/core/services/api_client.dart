import 'dart:convert';
import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'session_service.dart';

class ApiException implements Exception {
  const ApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Thin HTTP wrapper around the NutriVision backend.
///
/// All requests inject the stored access token. On 401 it attempts one silent
/// refresh before propagating an [ApiException].
class ApiClient {
  ApiClient({SessionService? sessionService, http.Client? httpClient})
      : _session = sessionService ?? SessionService(),
        _http = httpClient ?? http.Client();

  static const _baseUrl = 'https://ai-diet-backend-y5ks.onrender.com/api';
  static const _tag = 'NutriVision·API';

  final SessionService _session;
  final http.Client _http;

  // ---------------------------------------------------------------------------
  // Public verbs
  // ---------------------------------------------------------------------------

  Future<dynamic> get(String path, {Map<String, String>? query}) =>
      _request('GET', path, query: query);

  Future<dynamic> post(String path, {Object? body}) =>
      _request('POST', path, body: body);

  Future<dynamic> put(String path, {Object? body}) =>
      _request('PUT', path, body: body);

  Future<dynamic> delete(String path) => _request('DELETE', path);

  Future<dynamic> postMultipart(
    String path, {
    required String fileField,
    required List<int> fileBytes,
    required String filename,
  }) async {
    final token = await _session.getAccessToken();
    final uri = Uri.parse('$_baseUrl$path');

    _log('→ POST (multipart) $path  [file: $filename, ${fileBytes.length} bytes]');

    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll({if (token != null) 'Authorization': 'Bearer $token'})
      ..files.add(http.MultipartFile.fromBytes(fileField, fileBytes, filename: filename));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    _log('← ${response.statusCode} POST $path');

    if (response.statusCode == 401) {
      if (token != null) {
        _log('⟳ Token rejected — attempting refresh for POST $path');
        final refreshed = await _tryRefresh();
        if (refreshed) {
          _log('✓ Refresh succeeded — retrying POST $path');
          return postMultipart(path, fileField: fileField, fileBytes: fileBytes, filename: filename);
        }
        _log('✗ Refresh failed for POST $path — session expired');
        throw const ApiException('Session expired. Please log in again.');
      }
      return _parse(response, path);
    }

    return _parse(response, path);
  }

  // ---------------------------------------------------------------------------
  // Core
  // ---------------------------------------------------------------------------

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
    bool isRetry = false,
  }) async {
    final token = await _session.getAccessToken();

    final queryStr = (query != null && query.isNotEmpty) ? '?${query.entries.map((e) => '${e.key}=${e.value}').join('&')}' : '';
    _log('→ $method $path$queryStr${isRetry ? ' [retry]' : ''}${body != null ? '  body: ${_truncate(jsonEncode(body))}' : ''}');

    final response = await _send(method, path, token: token, query: query, body: body);

    _log('← ${response.statusCode} $method $path${isRetry ? ' [retry]' : ''}');

    if (response.statusCode == 401 && !isRetry) {
      if (token != null) {
        _log('⟳ Token rejected — attempting refresh for $method $path');
        final refreshed = await _tryRefresh();
        if (refreshed) {
          _log('✓ Refresh succeeded — retrying $method $path');
          return _request(method, path, query: query, body: body, isRetry: true);
        }
        _log('✗ Refresh failed for $method $path — session expired');
        throw const ApiException('Session expired. Please log in again.');
      }
      // No token sent — let backend's error through (e.g., wrong password on login).
      _log('⚠ 401 on $method $path (no token sent) — passing backend error through');
      return _parse(response, path);
    }

    return _parse(response, path);
  }

  Future<http.Response> _send(
    String method,
    String path, {
    String? token,
    Map<String, String>? query,
    Object? body,
  }) {
    var uri = Uri.parse('$_baseUrl$path');
    if (query != null && query.isNotEmpty) {
      uri = uri.replace(queryParameters: query);
    }

    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final encoded = body != null ? jsonEncode(body) : null;

    return switch (method) {
      'GET' => _http.get(uri, headers: headers),
      'POST' => _http.post(uri, headers: headers, body: encoded),
      'PUT' => _http.put(uri, headers: headers, body: encoded),
      'DELETE' => _http.delete(uri, headers: headers),
      _ => throw ArgumentError('Unsupported HTTP method: $method'),
    };
  }

  Future<bool> _tryRefresh() async {
    final refreshToken = await _session.getRefreshToken();
    if (refreshToken == null) {
      _log('⟳ Refresh skipped — no refresh token stored');
      return false;
    }

    _log('⟳ POST /auth/refresh');
    try {
      final response = await _http.post(
        Uri.parse('$_baseUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      _log('⟳ /auth/refresh → ${response.statusCode}');

      if (response.statusCode != 200) return false;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = json['data'] as Map<String, dynamic>?;
      if (data == null) return false;

      await _session.updateTokens(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
      );
      _log('✓ Tokens refreshed and saved');
      return true;
    } catch (e) {
      _log('✗ Refresh request threw: $e');
      return false;
    }
  }

  dynamic _parse(http.Response response, [String? path]) {
    if (response.body.isEmpty) {
      if (response.statusCode >= 200 && response.statusCode < 300) return null;
      _log('✗ Empty body with status ${response.statusCode}${path != null ? ' for $path' : ''}');
      throw ApiException('HTTP ${response.statusCode}');
    }

    late final Map<String, dynamic> json;
    try {
      json = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      _log('✗ Non-JSON response${path != null ? ' for $path' : ''}: ${_truncate(response.body)}');
      throw ApiException('Invalid response from server.');
    }

    final success = json['success'] as bool? ?? false;
    if (!success || response.statusCode >= 400) {
      final msg = json['message'] as String? ?? 'An error occurred.';
      _log('✗ API error${path != null ? ' [$path]' : ''}: $msg');
      throw ApiException(msg);
    }

    return json['data'];
  }

  // ---------------------------------------------------------------------------
  // Logging helpers — debug builds only
  // ---------------------------------------------------------------------------

  static void _log(String message) {
    if (kDebugMode) {
      dev.log(message, name: _tag);
    }
  }

  static String _truncate(String s, {int max = 200}) =>
      s.length <= max ? s : '${s.substring(0, max)}…';
}
