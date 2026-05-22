import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:pharmacy_wms/Models/UserRoleModel.dart';
import 'package:pharmacy_wms/Models/orderModel.dart';
import 'package:pharmacy_wms/Services/api_config.dart';
import 'package:http/http.dart' as http;

class OrderService {
  static String get _baseUrl => '${ApiConfig.baseUrl}/Orders';
  static final List<OrderModel> _orders = [];
  static final ValueNotifier<int> changes = ValueNotifier<int>(0);
  static bool _loaded = false;

  static Future<List<OrderModel>> getAllOrders() async {
    if (!_loaded) await _fetchOrders();
    return List.unmodifiable(_orders);
  
static Future<List<OrderModel>> getPendingOrders() async {
    if (!_loaded) await _fetchOrders();
    return _orders
        .where((order) => order.status == OrderStatus.pending)
        .toList(growable: false);
  
static Future<void> addOrder(OrderModel order) async {
    try {
      final response = await http
          .post(
            Uri.parse(_baseUrl),
            headers: AuthService.authHeaders,
            body: jsonEncode(order.toJson()),
          )
          .timeout(const Duration(seconds: 15)));

      if (response.statusCode == 200 || response.statusCode == 201) {
        _orders.insert(0, order);
        changes.value++;
      }
    } catch (e) {
      debugPrint('[OrderService] Failed to add order: $e');
      _orders.insert(0, order);
      changes.value++;
    }
  
static Future<void> updateOrderStatus(String id, OrderStatus status) async {
    try {
      final response = await http
          .patch(
            Uri.parse('$_baseUrl/$id/status'),
            headers: AuthService.authHeaders,
            body: jsonEncode({'status': status.name}),
          )
          .timeout(const Duration(seconds: 15)));

      if (response.statusCode == 200) {
        final index = _orders.indexWhere((order) => order.id == id);
        if (index != -1) {
          _orders[index] = _orders[index].copyWith(status: status);
          changes.value++;
        }
      }
    } catch (e) {
      debugPrint('[OrderService] Failed to update order status: $e');
    }
  
static Future<void> clearOrders() async {
    _orders.clear();
    _loaded = false;
    changes.value++;
  
static Future<void> _fetchOrders() async {
    try {
      final response = await http
          .get(Uri.parse(_baseUrl), headers: AuthService.authHeaders)
          .timeout(const Duration(seconds: 15)));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> items = decoded is List ? decoded : [];
        _orders.clear();
        for (final item in items) {
          _orders.add(OrderModel.fromJson(item as Map<String, dynamic>)));

        }
        _loaded = true;
      }
    } catch (e) {
      debugPrint('[OrderService] Failed to fetch orders: $e');
    }
  }
}
