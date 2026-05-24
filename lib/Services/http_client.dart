import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'UserRoleModel.dart';

class ApiClient {
  static const Duration _timeout = Duration(seconds: 45);
  static const int _maxRetries = 2;

  static Future<http.Response> get(Uri uri, {int attempt = 1}) {
    return _withRetry(() => http
        .get(uri, headers: AuthService.authHeaders)
        .timeout(_timeout), attempt);
  }

  static Future<http.Response> post(Uri uri, Map<String, dynamic> body,
      {int attempt = 1}) {
    return _withRetry(
        () => http
            .post(uri,
                headers: AuthService.authHeaders, body: jsonEncode(body))
            .timeout(_timeout),
        attempt);
  }

  static Future<http.Response> patch(Uri uri, Map<String, dynamic> body,
      {int attempt = 1}) {
    return _withRetry(
        () => http
            .patch(uri,
                headers: AuthService.authHeaders, body: jsonEncode(body))
            .timeout(_timeout),
        attempt);
  }

  static Future<http.Response> put(Uri uri, Map<String, dynamic> body,
      {int attempt = 1}) {
    return _withRetry(
        () => http
            .put(uri,
                headers: AuthService.authHeaders, body: jsonEncode(body))
            .timeout(_timeout),
        attempt);
  }

  static Future<http.Response> delete(Uri uri, {int attempt = 1}) {
    return _withRetry(
        () => http
            .delete(uri, headers: AuthService.authHeaders)
            .timeout(_timeout),
        attempt);
  }

  static Future<http.Response> _withRetry(
      Future<http.Response> Function() fn, int attempt) async {
    try {
      return await fn();
    } on TimeoutException catch (_) {
      if (attempt < _maxRetries) {
        await Future.delayed(const Duration(seconds: 2));
        return _withRetry(fn, attempt + 1);
      }
      rethrow;
    }
  }
}
