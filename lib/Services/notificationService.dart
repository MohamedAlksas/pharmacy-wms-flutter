import 'dart:convert';


import 'package:flutter/foundation.dart';

import 'package:pharmacy_wms/Models/UserRoleModel.dart';

import 'package:pharmacy_wms/Services/api_config.dart';

import 'package:http/http.dart' as http;


class AppNotification {
  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final String? materialName;
  final String? productSku;
  final String? proposedExpiry;
  final String? managerName;
  bool isRead;

  AppNotification({
    String? id,
    required this.title,
    required this.body,
    DateTime? createdAt,
    this.materialName,
    this.productSku,
    this.proposedExpiry,
    this.managerName,
    this.isRead = false,
  }) : id = id ?? 'NOT-${DateTime.now().millisecondsSinceEpoch}',
       createdAt = createdAt ?? DateTime.now();
}



class NotificationService {
  static String get _baseUrl => ApiConfig.baseUrl;
  static const String fallbackSupervisorEmail = 'supervisor@pharmacy-wms.local';
  static final List<AppNotification> _notifications = [];
  static final ValueNotifier<int> changes = ValueNotifier<int>(0);
  static bool _loaded = false;

  static Future<void> init() async {
    if (!_loaded) await _fetchNotifications();
  }

  static List<AppNotification> getAll() {
    return List.unmodifiable(_notifications);
  }




  static Future<void> addNotification(AppNotification notification) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/Notifications'),
            headers: AuthService.authHeaders,
            body: jsonEncode({
              'title': notification.title,
              'body': notification.body,
              'materialName': notification.materialName,
              'productSku': notification.productSku,
              'proposedExpiry': notification.proposedExpiry,
              'managerName': notification.managerName,
            }),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200 || response.statusCode == 201) {
        _notifications.insert(0, notification);
        changes.value++;
      }
    } catch (e) {
      debugPrint('[NotificationService] Failed to add notification: $e');
      _notifications.insert(0, notification);
      changes.value++;
    }
  }




  static List<AppNotification> getUnread() {
    return _notifications.where((n) => !n.isRead).toList();
  }




  static Future<void> markAllRead() async {
    try {
      await http
          .post(
            Uri.parse('$_baseUrl/Notifications/mark-all-read'),
            headers: AuthService.authHeaders,
          )
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      debugPrint('[NotificationService] Failed to mark all read: $e');
    }
    for (final notification in _notifications) {
      notification.isRead = true;
    }
    changes.value++;
  }




  static Future<void> markRead(String id) async {
    try {
      await http
          .patch(
            Uri.parse('$_baseUrl/Notifications/$id/read'),
            headers: AuthService.authHeaders,
          )
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      debugPrint('[NotificationService] Failed to mark read: $e');
    }
    for (final notification in _notifications) {
      if (notification.id == id) {
        notification.isRead = true;
        break;
      }
    }
    changes.value++;
  }




  static Future<void> sendEditRequestEmail({
    required String productName,
    required String productSku,
    required String managerName,
    required String newExpiry,
  }) async {
    try {
      final emails = await _getSupervisorEmails();
      for (final email in emails) {
        try {
          await _sendEditRequestEmail(
            to: email,
            productName: productName,
            productSku: productSku,
            managerName: managerName,
            newExpiry: newExpiry,
          );
        } catch (e) {
          debugPrint('Edit request email to $email failed: $e');
        }
      }
    } catch (e) {
      debugPrint('Edit request email failed: $e');
    }
  }




  static Future<List<String>> _getSupervisorEmails() async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/Auth/supervisors'),
            headers: AuthService.authHeaders,
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return const [fallbackSupervisorEmail];
      }


      final decoded = _decodeBody(response.body);
      final emails = _extractEmails(decoded).toSet().toList();
      if (emails.isEmpty) return const [fallbackSupervisorEmail];
      return emails;
    } catch (e) {
      debugPrint('Supervisor lookup failed: $e; using fallback email.');
      return const [fallbackSupervisorEmail];
    }
  }




  static Future<void> _sendEditRequestEmail({
    required String to,
    required String productName,
    required String productSku,
    required String managerName,
    required String newExpiry,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/Notifications/send-email'),
          headers: AuthService.authHeaders,
          body: jsonEncode({
            'to': to,
            'subject': 'Edit Request: $productName',
            'body':
                '$managerName has requested an expiry date change for $productName (SKU: $productSku). Proposed new expiry: $newExpiry. Please review and approve or reject this request in the Orders page.',
          }),
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      debugPrint(
        'Edit request email to $to failed (${response.statusCode}): ${response.body}',
      );
    }
  }




  static Future<void> _fetchNotifications() async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/Notifications'),
            headers: AuthService.authHeaders,
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> items = decoded is List ? decoded : [];
        _notifications.clear();
        for (final item in items) {
          _notifications.add(AppNotification(
            id: (item['id'] ?? '').toString(),
            title: (item['title'] ?? '').toString(),
            body: (item['body'] ?? '').toString(),
            createdAt: DateTime.tryParse(
                (item['createdAt'] ?? '').toString()) ?? DateTime.now(),
            materialName: item['materialName']?.toString(),
            productSku: item['productSku']?.toString(),
            proposedExpiry: item['proposedExpiry']?.toString(),
            managerName: item['managerName']?.toString(),
            isRead: item['isRead'] == true || item['isRead'] == 'true',
          ));
        }
        _loaded = true;
      }
    } catch (e) {
      debugPrint('[NotificationService] Failed to fetch notifications: $e');
    }
  }



  static dynamic _decodeBody(String body) {
    if (body.trim().isEmpty) return null;
    try { return jsonDecode(body); } catch (_) { return body; }
  }




  static List<String> _extractEmails(dynamic decoded) {
    final emails = <String>[];

    void visit(dynamic value) {
      if (value is List) {
        for (final item in value) visit(item);
        return;
      }
      if (value is Map) {
        for (final key in const ['email', 'emailAddress', 'userEmail', 'mail']) {
          final email = value[key]?.toString().trim();
          if (email != null && email.contains('@') && email.contains('.')) {
            emails.add(email);
          }
        }
        for (final key in const ['data', 'items', 'result', 'users', 'supervisors']) {
          if (value.containsKey(key)) visit(value[key]);
        }
      }
    }

    visit(decoded);
    return emails;
  }
}
