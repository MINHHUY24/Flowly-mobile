import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_config.dart';

class ApiClient {
  ApiClient({required this.config});

  final AppConfig config;

  Future<Map<String, dynamic>> get(String path) {
    return _request(path, method: 'GET');
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) {
    return _request(path, method: 'POST', body: body);
  }

  Future<Map<String, dynamic>> put(String path, Map<String, dynamic> body) {
    return _request(path, method: 'PUT', body: body);
  }

  Future<Map<String, dynamic>> patch(String path, Map<String, dynamic> body) {
    return _request(path, method: 'PATCH', body: body);
  }

  Future<Map<String, dynamic>> delete(String path) {
    return _request(path, method: 'DELETE');
  }

  Future<Map<String, dynamic>> _request(
    String path, {
    required String method,
    Map<String, dynamic>? body,
  }) async {
    final session = Supabase.instance.client.auth.currentSession;
    final token = session?.accessToken;

    if (token == null || token.isEmpty) {
      throw const ApiException('Bạn cần đăng nhập lại.');
    }

    final request = http.Request(method, config.apiUri(path));
    request.headers.addAll({
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    });

    if (body != null) {
      request.body = jsonEncode(body);
    }

    final http.StreamedResponse streamed;
    try {
      streamed = await request.send().timeout(const Duration(seconds: 12));
    } on http.ClientException {
      throw const ApiException(
        'Không kết nối được API. Hãy chạy backend hoặc kiểm tra FLOWLY_API_BASE_URL.',
      );
    } on TimeoutException {
      throw const ApiException(
        'Không kết nối được API. Hãy chạy backend hoặc kiểm tra FLOWLY_API_BASE_URL.',
      );
    }
    final response = await http.Response.fromStream(streamed);
    final text = response.body;
    Map<String, dynamic> json = {};

    if (text.isNotEmpty) {
      final decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) {
        json = decoded;
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        json['message'] as String? ??
            json['error'] as String? ??
            text.ifEmpty('API error ${response.statusCode}'),
      );
    }

    return json;
  }
}

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
