import 'package:flutter/material.dart';
import 'package:pharmacy_wms/Models/materialModel.dart';
import 'package:pharmacy_wms/Models/stockBatchModel.dart';
import 'package:pharmacy_wms/Models/UserRoleModel.dart';
import 'package:pharmacy_wms/Services/ProductService.dart';
import 'package:pharmacy_wms/widgets/ExpiryChangeDialog.dart';

class BatchDetailDialog extends StatefulWidget {
  final MaterialModel product;
  const BatchDetailDialog({super.key, required this.product});

  @override
  State<BatchDetailDialog> createState() => _BatchDetailDialogState();
}

class _BatchDetailDialogState extends State<BatchDetailDialog> {
  List<StockBatch>? _batches;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBatches();
  }

  Future<void> _loadBatches() async {
    try {
      final data = await ProductService.getBatches(widget.product.id);
      if (!mounted) return;
      setState(() {
        _batches = data.map((b) => StockBatch.fromJson(b)).toList();
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  Future<void> _openExpiryChange(StockBatch batch) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => ExpiryChangeDialog(
        batchId: batch.id,
        currentExpiry: batch.formattedExpiry,
        productName: widget.product.name,
      ),
    );
    if (result == true) _loadBatches();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF1E1E2E) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Row(
        children: [
          Icon(Icons.inventory_2_outlined, color: Colors.blueAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${widget.product.name} - Batches',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: _buildContent(isDark, textColor),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Close'),
        ),
      ],
    );
  }

  Widget _buildContent(bool isDark, Color textColor) {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 40),
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _loadBatches, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_batches == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final hasBatches = _batches!.isNotEmpty;

    if (!hasBatches) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined, size: 48,
                color: isDark ? Colors.white24 : Colors.black12),
            const SizedBox(height: 12),
            Text(
              'No stock batches for this product.',
              style: TextStyle(color: isDark ? Colors.white60 : Colors.black45),
            ),
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Total Stock: ',
                style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
            Text(
              '${_batches!.fold(0, (sum, b) => sum + b.quantity)}',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.blueAccent),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Divider(height: 1),
        const SizedBox(height: 8),
        Text(
          'Batches (FEFO order)',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: SingleChildScrollView(
            child: DataTable(
              columnSpacing: 20,
              columns: [
                const DataColumn(label: Text('Expiry')),
                const DataColumn(label: Text('Qty'), numeric: true),
                const DataColumn(label: Text('Status')),
                if (AuthService.isWarehouseManager)
                  const DataColumn(label: Text('Actions')),
              ],
              rows: _batches!.map((batch) {
                final isExpired = batch.isExpired;
                final isExpiringSoon = batch.isExpiringSoon;
                Color statusColor;
                String statusText;
                if (isExpired) {
                  statusColor = Colors.red;
                  statusText = 'EXPIRED';
                } else if (isExpiringSoon) {
                  statusColor = Colors.orange;
                  statusText = 'Expiring soon';
                } else {
                  statusColor = Colors.green;
                  statusText = 'Good';
                }
                return DataRow(
                  color: WidgetStatePropertyAll(
                    isExpired
                        ? Colors.red.withOpacity(0.08)
                        : batch == _batches!.first
                            ? Colors.green.withOpacity(0.06)
                            : null,
                  ),
                  cells: [
                    DataCell(Text(batch.formattedExpiry)),
                    DataCell(Text('${batch.quantity}')),
                    DataCell(Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 12,
                            color: statusColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    )),
                    if (AuthService.isWarehouseManager)
                      DataCell(IconButton(
                        icon: const Icon(Icons.edit_calendar, size: 18),
                        tooltip: 'Edit Expiry',
                        onPressed: () => _openExpiryChange(batch),
                      )),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
        if (_batches!.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.green[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'FEFO: Earliest expiry will be dispatched first.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
