import 'dart:convert';


import 'package:pharmacy_wms/Models/UserRoleModel.dart';

import 'package:pharmacy_wms/Models/materialModel.dart';

import 'package:pharmacy_wms/Services/api_config.dart';
import 'package:pharmacy_wms/Services/http_client.dart';
import 'package:http/http.dart' as http;


class ProductService {
  static String get _baseUrl => '${ApiConfig.baseUrl}/Products';

  static Future<List<MaterialModel>> getAllProducts() async {
    final response = await _get(Uri.parse(_baseUrl));
    final decoded = _decodeBody(response.body);
    if (response.statusCode == 200) {
      final items = _extractItems(decoded);
      return items.map(MaterialModel.fromJson).toList();
    }


    throw Exception(await _extractError(response.statusCode, decoded));
  }




  static Future<List<MaterialModel>> getAdminProducts() async {
    final response = await _get(Uri.parse('$_baseUrl/AdminProducts'));
    final decoded = _decodeBody(response.body);

    if (response.statusCode == 200) {
      final items = _extractItems(decoded);
      return items.map(MaterialModel.fromJson).toList();
    }


    throw Exception(await _extractError(response.statusCode, decoded));
  }




  static Future<void> addProduct(Map<String, dynamic> body) async {
    final response = await _post(Uri.parse(_baseUrl), body);
    final decoded = _decodeBody(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return;
    }


    throw Exception(await _extractError(response.statusCode, decoded));
  }




  static Future<void> updateProduct(
    String id,
    Map<String, dynamic> body,
  ) async {
    // Try PATCH first; if the server returns 405 (Method Not Allowed) fall
    // back to PUT — ASP.NET backends vary in which verb they expose.
    http.Response response = await _patch(Uri.parse('$_baseUrl/$id'), body);

    if (response.statusCode == 405) {
      response = await _put(Uri.parse('$_baseUrl/$id'), body);
    }



    final decoded = _decodeBody(response.body);

    if (response.statusCode == 200 ||
        response.statusCode == 201 ||
        response.statusCode == 204) {
      return;
    }


    throw Exception(await _extractError(response.statusCode, decoded));
  }




  static Future<String?> deleteProduct(String id) async {
    try {
      final response = await _delete(Uri.parse('$_baseUrl/$id'));
      final decoded = _decodeBody(response.body);

      if (response.statusCode == 200 ||
          response.statusCode == 202 ||
          response.statusCode == 204) {
        return null;
      }

      return await _extractError(response.statusCode, decoded);
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }




  static Future<List<Map<String, dynamic>>> getBatches(String productId) async {
    final response = await _get(Uri.parse('$_baseUrl/$productId/batches'));
    final decoded = _decodeBody(response.body);
    if (response.statusCode == 200) {
      final items = _extractItems(decoded);
      return items;
    }
    throw Exception(await _extractError(response.statusCode, decoded));
  }

  static Future<Map<String, dynamic>> receiveStock(
    String productId,
    int quantity,
    String? expiryDate,
  ) async {
    final response = await _post(Uri.parse('$_baseUrl/$productId/batches/receive'), {
      'quantity': quantity,
      if (expiryDate != null && expiryDate.isNotEmpty) 'expiryDate': expiryDate,
    });
    final decoded = _decodeBody(response.body);
    if (response.statusCode == 200) {
      return decoded is Map<String, dynamic> ? decoded : {};
    }
    throw Exception(await _extractError(response.statusCode, decoded));
  }

  static Future<Map<String, dynamic>> getFefoPlan(
    String productId,
    int quantity,
  ) async {
    final response =
        await _get(Uri.parse('$_baseUrl/$productId/batches/fefo?quantity=$quantity'));
    final decoded = _decodeBody(response.body);
    if (response.statusCode == 200) {
      return decoded is Map<String, dynamic> ? decoded : {};
    }
    throw Exception(await _extractError(response.statusCode, decoded));
  }

  static Future<void> updateProductDetails(String id, Map<String, dynamic> body) async {
    final response = await _patch(Uri.parse('$_baseUrl/$id'), body);
    final decoded = _decodeBody(response.body);
    if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204) return;
    throw Exception(await _extractError(response.statusCode, decoded));
  }

  static Future<List<MaterialModel>> fetchAllProducts() => getAllProducts();
  static Future<List<MaterialModel>> fetchAdminProducts() => getAdminProducts();

  static Future<http.Response> _get(Uri uri) => ApiClient.get(uri);

  static Future<http.Response> _post(Uri uri, Map<String, dynamic> body) =>
      ApiClient.post(uri, body);

  static Future<http.Response> _patch(Uri uri, Map<String, dynamic> body) =>
      ApiClient.patch(uri, body);

  static Future<http.Response> _put(Uri uri, Map<String, dynamic> body) =>
      ApiClient.put(uri, body);

  static Future<http.Response> _delete(Uri uri) => ApiClient.delete(uri);




  static Future<http.Response> _post(Uri uri, Map<String, dynamic> body) {
    return http
        .post(uri, headers: AuthService.authHeaders, body: jsonEncode(body))
        .timeout(const Duration(seconds: 15));
  }




  static Future<http.Response> _patch(Uri uri, Map<String, dynamic> body) {
    return http
        .patch(uri, headers: AuthService.authHeaders, body: jsonEncode(body))
        .timeout(const Duration(seconds: 15));
  }




  static Future<http.Response> _put(Uri uri, Map<String, dynamic> body) {
    return http
        .put(uri, headers: AuthService.authHeaders, body: jsonEncode(body))
        .timeout(const Duration(seconds: 15));
  }




  static Future<http.Response> _delete(Uri uri) {
    return http
        .delete(uri, headers: AuthService.authHeaders)
        .timeout(const Duration(seconds: 15));
  }



  static dynamic _decodeBody(String body) {
    if (body.trim().isEmpty) {
      return null;
    }

    try {
      return jsonDecode(body);
    } catch (_) {
      return body;
    }
  }




  static List<Map<String, dynamic>> _extractItems(dynamic decoded) {
    final rawItems = _extractRawItems(decoded);
    final normalizedItems = <Map<String, dynamic>>[];

    for (final item in rawItems) {
      if (item is Map) {
        normalizedItems.add(
          item.map((key, value) => MapEntry(key.toString(), value)),
        );
      }
    }

    return normalizedItems;
  }




  static List<dynamic> _extractRawItems(dynamic decoded) {
    if (decoded is List) {
      return List<dynamic>.from(decoded);
    }

    if (decoded is Map<String, dynamic>) {
      final candidates = [
        decoded['items'],
        decoded['data'],
        decoded['products'],
        decoded['result'],
      ];

      for (final candidate in candidates) {
        if (candidate is List) {
          return List<dynamic>.from(candidate);
        }
      }
    }

    return const [];
  }




  static Future<String> _extractError(int statusCode, dynamic body) async {
    if (statusCode == 401) {
      await AuthService.expireSession();
    }



    final fallback = switch (statusCode) {
      400 => 'Please check the product data and try again.',
      401 => 'Your session has expired. Please sign in again.',
      404 => 'The requested product could not be found.',
      409 =>
        'This product cannot be deleted because it is linked to invoice items.',
      500 => 'The server encountered an error. Please try again later.',
      _ => 'Request failed ($statusCode).',
    };

    if (body is Map<String, dynamic>) {
      final errors = body['errors'];
      if (errors is Map<String, dynamic> && errors.isNotEmpty) {
        final messages = errors.values
            .expand((value) => value is List ? value : [value])
            .map((value) => value.toString())
            .where((value) => value.trim().isNotEmpty)
            .toList();

        if (messages.isNotEmpty) {
          return messages.join('\n');
        }
      }



      final message = (body['message'] ?? body['error'] ?? body['title'] ?? '')
          .toString()
          .trim();

      if (message.toLowerCase().contains('invoiceitem')) {
        return 'This product cannot be deleted because it is linked to invoice items.';
      }

      if (message.isNotEmpty) {
        return message;
      }
    }

    if (body is String && body.trim().isNotEmpty) {
      if (body.toLowerCase().contains('invoiceitem')) {
        return 'This product cannot be deleted because it is linked to invoice items.';
      }
      return body;
    }

    return fallback;
  }
}
