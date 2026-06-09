import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
  });

  final String apiBaseUrl;
  final String supabaseUrl;
  final String supabaseAnonKey;

  static const _apiBaseFromEnv = String.fromEnvironment('FLOWLY_API_BASE_URL');
  static const _supabaseUrlFromEnv = String.fromEnvironment('SUPABASE_URL');
  static const _supabaseKeyFromEnv = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );
  static const _assetEnvPath = 'assets/config/app.env';

  static Future<AppConfig> load() async {
    final assetEnv = await _loadAssetEnv();
    final apiBaseUrl = _normalizeBaseUrl(
      _firstNonEmpty([
        _apiBaseFromEnv,
        assetEnv['FLOWLY_API_BASE_URL'],
        _defaultApiBaseUrl,
      ]),
    );
    var supabaseUrl = _firstNonEmpty([
      _supabaseUrlFromEnv,
      assetEnv['SUPABASE_URL'],
    ]);
    var supabaseKey = _firstNonEmpty([
      _supabaseKeyFromEnv,
      assetEnv['SUPABASE_PUBLISHABLE_KEY'],
    ]);

    try {
      final response = await http
          .get(Uri.parse('$apiBaseUrl/api/config'))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        supabaseUrl = (json['supabaseUrl'] as String? ?? supabaseUrl).trim();
        supabaseKey = (json['supabasePublishableKey'] as String? ?? supabaseKey)
            .trim();
      }
    } on Object {
      // The app can still boot from --dart-define values when the API is remote
      // or not available during startup.
    }

    if (supabaseUrl.isEmpty || supabaseKey.isEmpty) {
      throw const AppConfigException(
        'Thiếu cấu hình Supabase. Hãy chạy backend hoặc tạo assets/config/app.env với SUPABASE_URL và SUPABASE_PUBLISHABLE_KEY.',
      );
    }

    return AppConfig(
      apiBaseUrl: apiBaseUrl,
      supabaseUrl: supabaseUrl,
      supabaseAnonKey: supabaseKey,
    );
  }

  Uri apiUri(String path) {
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$apiBaseUrl$cleanPath');
  }

  static String _normalizeBaseUrl(String value) {
    final trimmed = value.trim();
    final base = trimmed.isEmpty ? 'http://localhost:3000' : trimmed;
    return base.replaceAll(RegExp(r'/+$'), '');
  }

  static String get _defaultApiBaseUrl {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000';
    }

    return 'http://localhost:3000';
  }

  static String _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      final trimmed = value?.trim() ?? '';
      if (trimmed.isNotEmpty) return trimmed;
    }
    return '';
  }

  static Future<Map<String, String>> _loadAssetEnv() async {
    try {
      final text = await rootBundle.loadString(_assetEnvPath);
      return _parseEnv(text);
    } on Object {
      return {};
    }
  }

  static Map<String, String> _parseEnv(String text) {
    final values = <String, String>{};

    for (final line in const LineSplitter().convert(text)) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;

      final separatorIndex = trimmed.indexOf('=');
      if (separatorIndex <= 0) continue;

      final key = trimmed.substring(0, separatorIndex).trim();
      var value = trimmed.substring(separatorIndex + 1).trim();

      if (value.length >= 2 &&
          ((value.startsWith('"') && value.endsWith('"')) ||
              (value.startsWith("'") && value.endsWith("'")))) {
        value = value.substring(1, value.length - 1);
      }

      values[key] = value;
    }

    return values;
  }
}

class AppConfigException implements Exception {
  const AppConfigException(this.message);

  final String message;

  @override
  String toString() => message;
}
