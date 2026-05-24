import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pharmacy_wms/Models/app_localizations.dart';
import 'package:pharmacy_wms/Models/orderModel.dart';
import 'package:pharmacy_wms/Models/UserRoleModel.dart';
import 'package:pharmacy_wms/Services/orderService.dart';

class InvoicesPage extends StatefulWidget {
  const InvoicesPage({super.key});
  @override
  State<InvoicesPage> createState() => _InvoicesPageState();
}

class _InvoiceGroup {
  final String invoiceNumber;
  final List<OrderModel> orders;
  final int totalQuantity;
  final DateTime dateFrom;
  final DateTime dateTo;
  _InvoiceGroup({
    required this.invoiceNumber,
    required this.orders,
    required this.totalQuantity,
    required this.dateFrom,
    required this.dateTo,
  });
}

class _InvoicesPageState extends State<InvoicesPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedDateFilter = 'Filter by Date';
  List<OrderModel> _orders = [];
  Timer? _debounce;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    OrderService.changes.addListener(_load);
  }

  @override
  void dispose() {
    OrderService.changes.removeListener(_load);
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _load() {
    if (!mounted) return;
    setState(() {
      _orders = OrderService.getAllOrders();
      _loading = false;
    });
  }

  List<_InvoiceGroup> _buildGroups() {
    final groups = <String, List<OrderModel>>{};
    for (final order in _orders) {
      final inv = order.invoiceNumber;
      if (inv == null || inv.isEmpty) continue;
      groups.putIfAbsent(inv, () => []).add(order);
    }
    final now = DateTime.now();
    return groups.entries
        .where((e) {
          final query = _searchCtrl.text.trim().toLowerCase();
          final matchesSearch = query.isEmpty || e.key.toLowerCase().contains(query);
          if (!matchesSearch) return false;
          final dates = e.value.map((o) => o.createdAt);
          final from = dates.reduce((a, b) => a.isBefore(b) ? a : b);
          switch (_selectedDateFilter) {
            case 'Today':
              return from.year == now.year && from.month == now.month && from.day == now.day;
            case 'This Week':
              return now.difference(from).inDays <= 7;
            case 'This Month':
              return from.year == now.year && from.month == now.month;
            case 'This Year':
              return from.year == now.year;
            default:
              return true;
          }
        })
        .map((e) {
          final orders = e.value;
          final dates = orders.map((o) => o.createdAt);
          final totalQty = orders.fold(0, (sum, o) => sum + o.quantity);
          return _InvoiceGroup(
            invoiceNumber: e.key,
            orders: orders,
            totalQuantity: totalQty,
            dateFrom: dates.reduce((a, b) => a.isBefore(b) ? a : b),
            dateTo: dates.reduce((a, b) => a.isAfter(b) ? a : b),
          );
        })
        .toList()
      ..sort((a, b) => b.dateTo.compareTo(a.dateTo));
  }

  void _viewInvoiceDetails(_InvoiceGroup group, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Invoice #${group.invoiceNumber}'),
        content: SizedBox(
          width: 640,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('Materials', group.orders.length.toString()),
              _detailRow('Total Quantity', group.totalQuantity.toString()),
              _detailRow('Date Range',
                  '${_formatDate(group.dateFrom)} - ${_formatDate(group.dateTo)}'),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Text(
                'Materials:',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 8),
              ...group.orders.map((o) => _materialCard(o, isDark, onRefresh: _load)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.tr.close),
          ),
        ],
      ),
    );
  }

  Widget _materialCard(OrderModel order, bool isDark, {VoidCallback? onRefresh}) {
    final expiry = order.expiryDate;
    final typeColor = switch (order.type) {
      OrderType.add => Colors.green,
      OrderType.export => Colors.blue,
      OrderType.edit => Colors.orange,
      OrderType.refund => Colors.purple,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2332) : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? const Color(0xFF2A3F5F) : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.productName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'SKU: ${order.productSku}  |  Qty: ${order.quantity} ${order.unit}',
                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
                ),
                if (expiry != null && expiry.isNotEmpty)
                  Text(
                    'EXP: ${_formatExpiry(expiry)}',
                    style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
                  ),
              ],
            ),
          ),
          if (order.type == OrderType.export)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: SizedBox(
                height: 30,
                child: OutlinedButton.icon(
                  onPressed: () => _showRefundDialog(context, order, onRefresh: onRefresh),
                  icon: const Icon(Icons.replay, size: 14),
                  label: const Text('Refund', style: TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.purple,
                    side: const BorderSide(color: Colors.purple),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ),
            ),
          _badge(order.type.name, typeColor),
        ],
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label[0].toUpperCase() + label.substring(1),
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 11),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(child: Text(value.isEmpty ? '-' : value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final groups = _buildGroups();
    final tr = context.tr;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0E1621) : const Color(0xFFF5F5F5),
      body: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1CA0A5).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.receipt_long, color: Color(0xFF1CA0A5), size: 24),
                ),
                const SizedBox(width: 12),
                _loading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(
                        'Invoices',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Flexible(
                  flex: 2,
                  child: _searchBox(isDark),
                ),
                const SizedBox(width: 12),
                _dropdown(
                  isDark,
                  _selectedDateFilter,
                  ['Filter by Date', 'Today', 'This Week', 'This Month', 'This Year'],
                  (v) {
                    if (v != null) setState(() => _selectedDateFilter = v);
                  },
                  _dateFilterDisplay,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: groups.isEmpty
                  ? Center(
                      child: Text(
                        _loading ? '' : 'No invoices found',
                        style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.black45,
                          fontSize: 16,
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: groups.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) => _invoiceCard(groups[index], isDark),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchBox(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2332) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF2A3F5F) : Colors.grey.shade300,
        ),
      ),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (_) {
          _debounce?.cancel();
          _debounce = Timer(const Duration(milliseconds: 300), () {
            if (mounted) setState(() {});
          });
        },
        style: TextStyle(color: isDark ? Colors.white : Colors.black),
        decoration: InputDecoration(
          hintText: 'Search by invoice number...',
          hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
          prefixIcon: Icon(Icons.search, color: isDark ? Colors.white54 : Colors.black54),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _dropdown(
    bool isDark,
    String value,
    List<String> items,
    void Function(String?) onChanged,
    String Function(String) label,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2332) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF2A3F5F) : Colors.grey.shade300,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: isDark ? const Color(0xFF1A2332) : Colors.white,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          items: items
              .map((item) => DropdownMenuItem(value: item, child: Text(label(item))))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _invoiceCard(_InvoiceGroup group, bool isDark) {
    return InkWell(
      onTap: () => _viewInvoiceDetails(group, isDark),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A2332) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF2A3F5F) : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.receipt, size: 18, color: const Color(0xFF1CA0A5)),
                      const SizedBox(width: 8),
                      Text(
                        'Invoice #${group.invoiceNumber}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${group.orders.length} materials  |  Total: ${group.totalQuantity} units',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatDate(group.dateFrom)} - ${_formatDate(group.dateTo)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFF1CA0A5).withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF1CA0A5)),
            ),
          ],
        ),
      ),
    );
  }

  String _dateFilterDisplay(String value) {
    switch (value) {
      case 'Filter by Date': return 'Filter by Date';
      default: return value;
    }
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '${local.year}-$m-$d';
  }

  void _showRefundDialog(BuildContext context, OrderModel order, {VoidCallback? onRefresh}) {
    final qtyCtrl = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Refund - ${order.productName}'),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Available to refund: ${order.quantity} ${order.unit}'),
              const SizedBox(height: 12),
              TextField(
                controller: qtyCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Quantity to refund',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final qty = int.tryParse(qtyCtrl.text.trim());
              if (qty == null || qty <= 0 || qty > order.quantity) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enter a valid quantity')),
                );
                return;
              }
              final pid = order.productId;
              if (pid == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cannot refund: product ID missing')),
                );
                return;
              }
              try {
                await OrderService.refundOrder(
                  productId: int.parse(pid),
                  quantity: qty,
                  invoiceNumber: order.invoiceNumber,
                  createdBy: AuthService.currentUser?.fullName ?? 'system',
                  expiryDate: order.expiryDate,
                );
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Refunded $qty ${order.unit} of ${order.productName}')),
                  );
                }
                onRefresh?.call();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Refund failed: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
            child: const Text('Refund'),
          ),
        ],
      ),
    );
  }

  String _formatExpiry(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    final m = parsed.month.toString().padLeft(2, '0');
    final d = parsed.day.toString().padLeft(2, '0');
    return '${parsed.year}-$m-$d';
  }
}
