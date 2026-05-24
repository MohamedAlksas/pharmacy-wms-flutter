import 'dart:collection';

import 'package:pharmacy_wms/Models/materialModel.dart';

import 'package:pharmacy_wms/Services/thresholdService.dart';


class MaterialService {
  static List<MaterialModel> _cache = [];
  static int _lowStockThreshold = 100;
  static int _expiringSoonDays = 30;

  static void updateCache(List<MaterialModel> products) {
    _cache = products;
  }

  static Future<void> reloadThresholds() async {
    _lowStockThreshold = await ThresholdService.getLowStockThreshold();
    _expiringSoonDays = await ThresholdService.getExpiringSoonDays();
  }

  static List<MaterialModel> getAllMaterials() => UnmodifiableListView(_cache);

  static MaterialModel? getMaterialById(String id) {
    try {
      return _cache.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  static String getMaterialStatus(MaterialModel material) {
    try {
      final expiry = DateTime.parse(material.expiryDate);
      final now = DateTime.now();
      if (expiry.isBefore(now)) return 'Expired';
      if (expiry.difference(now).inDays <= _expiringSoonDays) return 'Expiring Soon';
      if (material.quantity < _lowStockThreshold) return 'Low Stock';
      return 'Good';
    } catch (_) {
      return 'Unknown';
    }
  }

  static List<MaterialModel> getLowStockMaterials() =>
      _cache.where((m) => m.quantity < _lowStockThreshold).toList();

  static List<MaterialModel> getExpiredMaterials() => _cache.where((m) {
    try {
      return DateTime.parse(m.expiryDate).isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }).toList();

  static List<MaterialModel> getExpiringSoonMaterials() => _cache.where((m) {
    try {
      final diff = DateTime.parse(
        m.expiryDate,
      ).difference(DateTime.now()).inDays;
      return diff > 0 && diff <= _expiringSoonDays;
    } catch (_) {
      return false;
    }
  }).toList();

  static int get lowStockThreshold => _lowStockThreshold;
  static int get expiringSoonDays => _expiringSoonDays;

  static bool isLowStock(MaterialModel material) => material.quantity < _lowStockThreshold;

  static List<String> getMaterialStatuses(MaterialModel material) {
    final statuses = <String>[];
    try {
      final expiry = DateTime.parse(material.expiryDate);
      final now = DateTime.now();
      if (expiry.isBefore(now)) {
        statuses.add('Expired');
      }
      final daysUntilExpiry = expiry.difference(now).inDays;
      if (daysUntilExpiry >= 0 && daysUntilExpiry <= _expiringSoonDays) {
        statuses.add('Expiring Soon');
      }
      if (material.quantity < _lowStockThreshold) {
        statuses.add('Low Stock');
      }
      if (statuses.isEmpty) statuses.add('Good');
    } catch (_) {
      statuses.add('Unknown');
    }
    return statuses;
  }

  static List<Map<String, dynamic>> getMaterialsAsMap() =>
      _cache.map((m) => m.toJson()).toList();
}
