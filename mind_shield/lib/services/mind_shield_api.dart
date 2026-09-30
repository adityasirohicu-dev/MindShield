import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// Small API client for the authenticated prototype flows.
class MindShieldApi {
  MindShieldApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  String? _accessToken;
  String? _refreshToken;
  String? _sessionCredential;
  final List<Map<String, dynamic>> _pendingCheckins = [];
  bool _syncingCheckins = false;

  static Uri get _baseUri {
    const configured = String.fromEnvironment('API_BASE_URL');
    if (configured.isNotEmpty) {
      final normalized = configured.endsWith('/') ? configured : '$configured/';
      return Uri.parse(normalized);
    }
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return Uri.parse('http://10.0.2.2:8000/v1/');
    }
    return Uri.parse('http://127.0.0.1:8000/v1/');
  }

  bool get isAuthenticated => _accessToken != null;
  int get pendingCheckinsCount => _pendingCheckins.length;

  Future<Map<String, dynamic>> requestOtp({
    required String credential,
    String? email,
    String purpose = 'login',
  }) async => await _request(
    'POST',
    '/auth/otp',
    body: {
      'credential': credential,
      if (email != null) 'email': email,
      'purpose': purpose,
    },
    authenticated: false,
  ) as Map<String, dynamic>;

  Future<String> login({
    required String credential,
    required String otp,
  }) async {
    final data = await _request(
      'POST',
      '/auth/login',
      body: {'credential': credential, 'otp': otp},
      authenticated: false,
    );
    _accessToken = data['access_token'] as String?;
    _refreshToken = data['refresh_token'] as String?;
    _sessionCredential = credential;
    final role = data['role'] as String?;
    if (_accessToken == null || role == null) {
      throw const ApiException(
        'The server returned an incomplete login response.',
      );
    }
    return role;
  }

  Future<String> register({
    required String credential,
    required String displayName,
    required String email,
    required String otp,
    String role = 'personnel',
    String unitName = 'Alpha Unit',
    String rankLabel = 'Operator',
  }) async {
    final data = await _request(
      'POST',
      '/auth/register',
      body: {
        'credential': credential,
        'display_name': displayName,
        'email': email,
        'otp': otp,
        'role': role,
        'unit_name': unitName,
        'rank_label': rankLabel,
      },
      authenticated: false,
    );
    _accessToken = data['access_token'] as String?;
    _refreshToken = data['refresh_token'] as String?;
    _sessionCredential = credential;
    final returnedRole = data['role'] as String?;
    if (_accessToken == null || returnedRole == null) {
      throw const ApiException(
        'The server returned an incomplete registration response.',
      );
    }
    return returnedRole;
  }

  Future<bool> submitCheckIn({
    required String readinessState,
    required int stressLevel,
    required int sleepHours,
    required String restQuality,
    required List<String> frictionFactors,
  }) async {
    final payload = <String, dynamic>{
        'readiness_state': readinessState,
        'duty_stress_10': stressLevel,
        'sleep_hours': sleepHours,
        'rest_quality': restQuality,
        'friction_factors': frictionFactors,
        'early_warning_consent': true,
        'client_submitted_at': DateTime.now().toUtc().toIso8601String(),
      };
    try {
      await _request('POST', '/checkins', body: payload);
      return false;
    } on ApiException catch (error) {
      if (error.statusCode != null) rethrow;
      _pendingCheckins.add({'credential': _sessionCredential, 'payload': payload});
      return true;
    }
  }

  Future<Map<String, dynamic>> getMyRisk() async =>
      await _request('GET', '/risk/me') as Map<String, dynamic>;

  Future<Map<String, dynamic>> getMyProfile() async =>
      await _request('GET', '/users/me') as Map<String, dynamic>;

  Future<List<Map<String, dynamic>>> getRiskQueue({String levels = 'elevated,high', String sort = 'risk'}) async {
    final result = await _request('GET', '/risk/queue?risk_level=$levels&sort=$sort');
    return (result as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getCounsellingQueue() async {
    final result = await _request('GET', '/counselling/queue');
    return (result as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<void> updateCounsellingRequest(String id, String status) async {
    await _request('PATCH', '/counselling/requests/$id', body: {'status': status});
  }

  Future<Map<String, dynamic>> getOrgTrends() async =>
      await _request('GET', '/org/trends') as Map<String, dynamic>;

  Future<List<Map<String, dynamic>>> getAuditLogs() async {
    final result = await _request('GET', '/audit/logs');
    return (result as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getConsentSources() async {
    final result = await _request('GET', '/privacy/sources');
    return (result as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<void> updateConsent(String dataType, bool granted) async {
    await _request('POST', '/consent', body: {
      'data_type': dataType,
      'status': granted ? 'granted' : 'revoked',
    });
  }

  Future<Map<String, dynamic>> purgeSensorData() async => await _request(
    'POST', '/privacy/purge', body: const <String, dynamic>{},
  ) as Map<String, dynamic>;

  Future<void> reviewRisk(String id, {required String action, String? notes}) async {
    await _request('POST', '/risk/$id/review', body: {'action_taken': action, 'notes': notes});
  }

  Future<Map<String, dynamic>> getRiskDetail(String id) async =>
      await _request('GET', '/risk/$id') as Map<String, dynamic>;

  Future<List<Map<String, dynamic>>> getMyCheckIns(String range) async {
    final result = await _request('GET', '/checkins/me?range=$range');
    return (result as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createCounsellingRequest({
    required String channel,
    required String timeWindow,
    required String urgency,
  }) async => await _request(
    'POST',
    '/counselling/requests',
    body: {
      'channel': channel,
      'time_window': timeWindow,
      'urgency': urgency,
      'source': 'self_requested',
    },
  ) as Map<String, dynamic>;

  Future<List<Map<String, dynamic>>> getMyCounsellingRequests() async {
    final result = await _request('GET', '/counselling/requests/me');
    return (result as List<dynamic>).cast<Map<String, dynamic>>();
  }

  void logout() {
    if (_accessToken != null) {
      _request('POST', '/auth/logout').then<void>((_) {}, onError: (_) {});
    }
    _accessToken = null;
    _refreshToken = null;
    _sessionCredential = null;
    _pendingCheckins.clear();
  }

  void clearPendingCheckins() => _pendingCheckins.clear();

  Future<bool> _refreshAccessToken() async {
    final token = _refreshToken;
    if (token == null) return false;
    try {
      final response = await _client.post(
        _baseUri.resolve('auth/refresh'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': token}),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) return false;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      _accessToken = data['access_token'] as String?;
      return _accessToken != null;
    } catch (_) {
      return false;
    }
  }

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
    bool allowRefresh = true,
  }) async {
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    if (authenticated && !_syncingCheckins && _pendingCheckins.isNotEmpty && normalizedPath != 'checkins') {
      await _flushPendingCheckins();
    }
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (authenticated && _accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }
    final uri = _baseUri.resolve(
      normalizedPath,
    );
    try {
      final response = switch (method) {
        'POST' => await _client.post(
          uri,
          headers: headers,
          body: jsonEncode(body ?? {}),
        ),
        'GET' => await _client.get(uri, headers: headers),
        'PATCH' => await _client.patch(uri, headers: headers, body: jsonEncode(body ?? {})),
        _ => throw UnsupportedError('Unsupported method: $method'),
      };
      final decoded = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (response.statusCode == 401 && authenticated && allowRefresh) {
          final refreshed = await _refreshAccessToken();
          if (refreshed) {
            return _request(method, path, body: body, authenticated: authenticated, allowRefresh: false);
          }
          _accessToken = null;
          _refreshToken = null;
          throw const ApiException('Your session expired. Please sign in again.', statusCode: 401);
        }
        final error = decoded is Map<String, dynamic> ? decoded['error'] : null;
        final message = error is Map<String, dynamic>
            ? error['message'] as String? ?? 'Request failed.'
            : 'Request failed (${response.statusCode}).';
        throw ApiException(message, statusCode: response.statusCode);
      }
      return decoded;
    } on ApiException {
      rethrow;
    } on http.ClientException {
      throw const ApiException(
        'Cannot reach Mind Shield. Check the server connection and try again.',
      );
    } on FormatException {
      throw const ApiException('The server returned an unreadable response.');
    }
  }

  Future<void> _flushPendingCheckins() async {
    if (_syncingCheckins || _pendingCheckins.isEmpty || _accessToken == null) return;
    _syncingCheckins = true;
    try {
      while (_pendingCheckins.isNotEmpty) {
        final queued = _pendingCheckins.first;
        if (queued['credential'] != _sessionCredential) break;
        final payload = queued['payload'] as Map<String, dynamic>;
        try {
          await _request('POST', '/checkins', body: payload, allowRefresh: true);
          _pendingCheckins.removeAt(0);
        } on ApiException {
          break;
        }
      }
    } finally {
      _syncingCheckins = false;
    }
  }
}
