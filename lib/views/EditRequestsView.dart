import 'package:flutter/material.dart';
import 'package:pharmacy_wms/Models/UserRoleModel.dart';
import 'package:pharmacy_wms/Models/app_localizations.dart';
import 'package:pharmacy_wms/Models/orderModel.dart';
import 'package:pharmacy_wms/Services/ApprovalService.dart';
import 'package:pharmacy_wms/Services/notificationService.dart';
import 'package:pharmacy_wms/Services/orderService.dart';

class EditRequestsPage extends StatefulWidget {
  const EditRequestsPage({super.key});
  @override
  State<EditRequestsPage> createState() => _EditRequestsPageState();
}

class _EditRequestsPageState extends State<EditRequestsPage> {
  List<Map<String, dynamic>>? _approvalRequests;
  List<OrderModel> _oldEditRequests = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        ApprovalService.fetchAllRequests(),
        Future.value(OrderService.getAllOrders()),
      ]);
      final approvals = results[0] as List<Map<String, dynamic>>;
      final orders = results[1] as List<OrderModel>;
      if (!mounted) return;
      setState(() {
        _approvalRequests = approvals;
        _oldEditRequests = orders.where((o) => o.type == OrderType.edit).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return Colors.orange;
      case 'approved': return Colors.green;
      case 'rejected': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _formatDate(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw.isEmpty ? '-' : raw;
    return '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Edit Requests',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
              const Spacer(),
              if (_loading)
                const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loading ? null : _load,
                tooltip: 'Refresh',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(child: _buildContent(isDark, textColor)),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDark, Color textColor) {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final allOld = _oldEditRequests;
    final allNew = _approvalRequests ?? [];
    final totalItems = allOld.length + allNew.length;

    if (totalItems == 0) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit_note, size: 64, color: isDark ? Colors.white24 : Colors.black12),
            const SizedBox(height: 16),
            Text('No edit requests',
                style: TextStyle(color: isDark ? Colors.white60 : Colors.black45, fontSize: 16)),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowHeight: 54,
          dataRowMinHeight: 56,
          dataRowMaxHeight: 56,
          columns: const [
            DataColumn(label: Text('Product Name')),
            DataColumn(label: Text('Old Expiry')),
            DataColumn(label: Text('New Expiry')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Requested By')),
            DataColumn(label: Text('Date')),
            DataColumn(label: Text('Source')),
          ],
          rows: [
            ...allNew.map((a) {
              final status = (a['status'] ?? 'Pending').toString();
              final batch = a['batch'] as Map<String, dynamic>?;
              final product = batch?['product'] as Map<String, dynamic>?;
              final productName = (product?['materialName'] ?? a['productName'] ?? a['materialName'] ?? '').toString();
              return DataRow(
                color: WidgetStatePropertyAll(_statusColor(status).withOpacity(0.05)),
                cells: [
                  DataCell(Text(productName)),
                  DataCell(Text(_formatDate((a['oldExpiry'] ?? a['currentExpiry'] ?? '').toString()))),
                  DataCell(Text(_formatDate((a['newExpiry'] ?? '').toString()))),
                  DataCell(Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor(status).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(status, style: TextStyle(fontSize: 12, color: _statusColor(status), fontWeight: FontWeight.w600)),
                  )),
                  DataCell(Text((a['requestedBy'] ?? a['createdBy'] ?? a['requestedByName'] ?? '').toString())),
                  DataCell(Text(_formatDate((a['requestedAt'] ?? a['createdAt'] ?? '').toString()))),
                  DataCell(Text('Approval', style: TextStyle(fontSize: 11, color: Colors.blue))),
                ],
              );
            }),
            ...allOld.map((o) {
              final status = o.status == OrderStatus.completed ? 'Approved' : (o.status == OrderStatus.canceled ? 'Rejected' : 'Pending');
              return DataRow(
                color: WidgetStatePropertyAll(_statusColor(status).withOpacity(0.05)),
                cells: [
                  DataCell(Text(o.productName)),
                  DataCell(Text('-')),
                  DataCell(Text(_formatDate(o.expiryDate ?? o.notes ?? ''))),
                  DataCell(Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor(status).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(status, style: TextStyle(fontSize: 12, color: _statusColor(status), fontWeight: FontWeight.w600)),
                  )),
                  DataCell(Text(o.createdBy)),
                  DataCell(Text(_formatDate(o.createdAt.toIso8601String()))),
                  DataCell(Text('Order', style: TextStyle(fontSize: 11, color: Colors.orange))),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}