import 'dart:convert';


import 'package:flutter/foundation.dart';

import 'package:pharmacy_wms/Models/UserRoleModel.dart';

import 'package:pharmacy_wms/Services/api_config.dart';

import 'package:http/http.dart' as http;

import 'package:shared_preferences/shared_preferences.dart';


class ThresholdService {
  static String get _baseUrl => '${ApiConfig.baseUrl}/Settings/thresholds';
  static const _kLowStock = 'threshold_low_stock';
  static const _kExpiringSoonDays = 'threshold_expiring_soon_days';

  static Future<int> getLowStockThreshold() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getInt(_kLowStock);
    if (cached != null) return cached;
    try {
      await _fetchThresholds();
      return prefs.getInt(_kLowStock) ?? 100;
    } catch (_) {
      return 100;
    }
  }




  static Future<int> getExpiringSoonDays() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getInt(_kExpiringSoonDays);
    if (cached != null) return cached;
    try {
      await _fetchThresholds();
      return prefs.getInt(_kExpiringSoonDays) ?? 30;
    } catch (_) {
      return 30;
    }
  }




  static Future<void> setLowStockThreshold(int value) async {
    try {
      final response = await http
          .put(
            Uri.parse(_baseUrl),
            headers: AuthService.authHeaders,
            body: jsonEncode({'lowStockThreshold': value}),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_kLowStock, value);
      }
    } catch (e) {
      debugPrint('[ThresholdService] Failed to save low stock threshold: $e');
    }
  }




  static Future<void> setExpiringSoonDays(int value) async {
    try {
      final response = await http
          .put(
            Uri.parse(_baseUrl),
            headers: AuthService.authHeaders,
            body: jsonEncode({'expiringSoonDays': value}),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_kExpiringSoonDays, value);
      }
    } catch (e) {
      debugPrint('[ThresholdService] Failed to save expiring soon days: $e');
    }
  }




  static Future<void> _fetchThresholds() async {
    try {
      final response = await http
          .get(Uri.parse(_baseUrl), headers: AuthService.authHeaders)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final prefs = await SharedPreferences.getInstance();
        if (data['lowStockThreshold'] != null) {
          await prefs.setInt(_kLowStock, data['lowStockThreshold'] as int);
        }
        if (data['expiringSoonDays'] != null) {
          await prefs.setInt(_kExpiringSoonDays, data['expiringSoonDays'] as int);
        }
      }
    } catch (e) {
      debugPrint('[ThresholdService] Failed to fetch thresholds: $e');
    }
  }
}
