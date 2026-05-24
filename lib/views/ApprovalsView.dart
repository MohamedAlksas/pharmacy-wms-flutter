import 'package:flutter/material.dart';
import 'package:pharmacy_wms/Models/app_localizations.dart';
import 'package:pharmacy_wms/Services/ApprovalService.dart';
import 'package:pharmacy_wms/Models/UserRoleModel.dart';

class ApprovalsPage extends StatefulWidget {
  const ApprovalsPage({super.key});
  @override
  State<ApprovalsPage> createState() => _ApprovalsPageState();
}

class _ApprovalsPageState extends State<ApprovalsPage> {
  List<Map<String, dynamic>>? _approvals;
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ApprovalService.fetchPendingApprovals();
      if (!mounted) return;
      setState(() { _approvals = data; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  Future<void> _approve(int id) async {
    try {
      await ApprovalService.approveRequest(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr.requestApproved)));
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _reject(int id) async {
    final notesCtrl = TextEditingController();
    final notes = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr.rejectRequest),
        content: TextField(
          controller: notesCtrl,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: context.tr.rejectionNotes,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.tr.cancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, notesCtrl.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(context.tr.reject, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (notes == null || !mounted) return;
    try {
      await ApprovalService.rejectRequest(id, notes: notes.isEmpty ? null : notes);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr.requestRejected)));
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
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
              Text(context.tr.pendingApprovals,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
              const Spacer(),
              if (_loading)
                const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loading ? null : _load,
                tooltip: context.tr.refresh,
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
            ElevatedButton(onPressed: _load, child: Text(context.tr.retry)),
          ],
        ),
      );
    }

    if (_approvals == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_approvals!.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, size: 64,
                color: isDark ? Colors.white24 : Colors.black12),
            const SizedBox(height: 16),
            Text(context.tr.noPendingApprovals,
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
          columns: [
            DataColumn(label: Text(context.tr.product)),
            DataColumn(label: Text(context.tr.batchId)),
            DataColumn(label: Text(context.tr.oldExpiry)),
            DataColumn(label: Text(context.tr.newExpiryDate)),
            DataColumn(label: Text(context.tr.requestedBy)),
            DataColumn(label: Text(context.tr.reason)),
            DataColumn(label: Text(context.tr.status)),
            DataColumn(label: Text(context.tr.actions)),
          ],
          rows: _approvals!.map((a) {
            final id = a['id'] is int ? a['id'] : int.tryParse(a['id'].toString()) ?? 0;
            final status = (a['status'] ?? 'Pending').toString();
            return DataRow(
              color: WidgetStatePropertyAll(
                status.toLowerCase() == 'pending'
                    ? Colors.orange.withOpacity(0.05)
                    : null,
              ),
              cells: [
                DataCell(Text((a['productName'] ?? a['product'] ?? a['materialName'] ?? '').toString())),
                DataCell(Text(a['batchId'].toString())),
                DataCell(Text((a['oldExpiry'] ?? a['currentExpiry'] ?? '').toString())),
                DataCell(Text((a['newExpiry'] ?? '').toString())),
                DataCell(Text((a['requestedBy'] ?? a['createdBy'] ?? a['requestedByName'] ?? '').toString())),
                DataCell(Tooltip(
                  message: (a['reason'] ?? '').toString(),
                  child: SizedBox(
                    width: 120,
                    child: Text(
                      (a['reason'] ?? '').toString(),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                )),
                DataCell(Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(status, style: TextStyle(fontSize: 12, color: _statusColor(status), fontWeight: FontWeight.w600)),
                )),
                DataCell(Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (status.toLowerCase() == 'pending') ...[
                        SizedBox(
                          height: 32,
                          child: ElevatedButton.icon(
                            onPressed: () => _approve(id),
                            icon: const Icon(Icons.check, size: 16),
                            label: Text(context.tr.approve, style: const TextStyle(fontSize: 11)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        SizedBox(
                          height: 32,
                          child: ElevatedButton.icon(
                            onPressed: () => _reject(id),
                            icon: const Icon(Icons.close, size: 16),
                            label: Text(context.tr.reject, style: const TextStyle(fontSize: 11)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                          ),
                        ),
                      ] else
                        Text(
                          status,
                          style: TextStyle(
                            color: _statusColor(status),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                )),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
