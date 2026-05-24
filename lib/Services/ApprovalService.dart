import 'dart:convert';
import 'package:pharmacy_wms/Services/api_config.dart';
import 'package:pharmacy_wms/Services/http_client.dart';
import 'package:pharmacy_wms/Models/UserRoleModel.dart';

class ApprovalService {
  static String get _baseUrl => '${ApiConfig.baseUrl}/Approvals';

  static Future<List<Map<String, dynamic>>> fetchPendingApprovals() async {
    final response = await ApiClient.get(Uri.parse('$_baseUrl/pending'));
    final decoded = _decodeBody(response.body);
    if (response.statusCode == 200) {
      if (decoded is List) return decoded.cast<Map<String, dynamic>>();
      if (decoded is Map && decoded['items'] is List) return List<Map<String, dynamic>>.from(decoded['items']);
      if (decoded is Map && decoded['data'] is List) return List<Map<String, dynamic>>.from(decoded['data']);
    }
    throw Exception(_extractError(response.statusCode, decoded));
  }

  static Future<List<Map<String, dynamic>>> fetchAllRequests() async {
    final response = await ApiClient.get(Uri.parse(_baseUrl));
    final decoded = _decodeBody(response.body);
    if (response.statusCode == 200) {
      if (decoded is List) return decoded.cast<Map<String, dynamic>>();
      if (decoded is Map && decoded['items'] is List) return List<Map<String, dynamic>>.from(decoded['items']);
      if (decoded is Map && decoded['data'] is List) return List<Map<String, dynamic>>.from(decoded['data']);
    }
    throw Exception(_extractError(response.statusCode, decoded));
  }

  static Future<List<Map<String, dynamic>>> fetchMyRequests() async {
    final response = await ApiClient.get(Uri.parse('$_baseUrl/my'));
    final decoded = _decodeBody(response.body);
    if (response.statusCode == 200) {
      if (decoded is List) return decoded.cast<Map<String, dynamic>>();
      if (decoded is Map && decoded['items'] is List) return List<Map<String, dynamic>>.from(decoded['items']);
      if (decoded is Map && decoded['data'] is List) return List<Map<String, dynamic>>.from(decoded['data']);
    }
    throw Exception(_extractError(response.statusCode, decoded));
  }

  static Future<void> createExpiryChangeRequest(int batchId, String newExpiry, String reason) async {
    final response = await ApiClient.post(Uri.parse(_baseUrl), {'batchId': batchId, 'newExpiry': newExpiry, 'reason': reason});
    final decoded = _decodeBody(response.body);
    if (response.statusCode == 200 || response.statusCode == 201) return;
    throw Exception(_extractError(response.statusCode, decoded));
  }

  static Future<void> approveRequest(int id, {String? notes}) async {
    final response = await ApiClient.post(Uri.parse('$_baseUrl/$id/approve'), {'approved': true, if (notes != null) 'notes': notes});
    final decoded = _decodeBody(response.body);
    if (response.statusCode == 200 || response.statusCode == 204) return;
    throw Exception(_extractError(response.statusCode, decoded));
  }

  static Future<void> rejectRequest(int id, {String? notes}) async {
    final response = await ApiClient.post(Uri.parse('$_baseUrl/$id/reject'), {'approved': false, if (notes != null) 'notes': notes});
    final decoded = _decodeBody(response.body);
    if (response.statusCode == 200 || response.statusCode == 204) return;
    throw Exception(_extractError(response.statusCode, decoded));
  }

  static dynamic _decodeBody(String body) {
    if (body.trim().isEmpty) return null;
    try { return jsonDecode(body); } catch (_) { return body; }
  }

  static String _extractError(int statusCode, dynamic body) {
    if (statusCode == 401) AuthService.expireSession();
    final fallback = 'Request failed ($statusCode).';
    if (body is Map<String, dynamic>) {
      return (body['message'] ?? body['error'] ?? body['title'] ?? fallback).toString();
    }
    if (body is String && body.trim().isNotEmpty) return body;
    return fallback;
  }
}
