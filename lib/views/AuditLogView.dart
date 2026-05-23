import 'package:flutter/material.dart';
import 'package:pharmacy_wms/Models/UserRoleModel.dart';
import 'package:pharmacy_wms/Models/app_localizations.dart';
import 'package:pharmacy_wms/Models/auditLogModel.dart';
import 'package:pharmacy_wms/Services/auditLogService.dart';

class AuditLogPage extends StatefulWidget {
  const AuditLogPage({super.key});
  @override
  State<AuditLogPage> createState() => _AuditLogPageState();
}

class _AuditLogPageState extends State<AuditLogPage> {
  List<AuditLogModel> _logs = [];
  List<AuditLogModel> _filtered = [];
  bool _loading = true;
  String? _error;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _logs = await AuditLogService.getAll();
      _filter();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }
    if (mounted) setState(() => _loading = false);
  }

  void _filter() {
    final query = _searchCtrl.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filtered = List.from(_logs);
      } else {
        _filtered = _logs.where((log) {
          return log.action.toLowerCase().contains(query) ||
              log.userName.toLowerCase().contains(query) ||
              log.entityType.toLowerCase().contains(query) ||
              (log.details?.toLowerCase().contains(query) ?? false);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Row(
              children: [
                Icon(Icons.history, color: isDark ? Colors.white70 : Colors.black87),
                const SizedBox(width: 10),
                Text(
                  tr.auditLog,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: tr.refresh,
                  onPressed: _load,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: tr.searchAuditLog,
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              onChanged: (_) => _filter(),
            ),
          ),
          Expanded(
            child: _buildContent(tr, isDark),
          ),
          if (!_loading && _error == null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              alignment: Alignment.centerRight,
              child: Text(
                tr.noOfItems(_filtered.length),
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(AppLocalizations tr, bool isDark) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _load,
              child: Text(tr.retry),
            ),
          ],
        ),
      );
    }
    if (_filtered.isEmpty) {
      return Center(child: Text(tr.noAuditLogs));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: _filtered.length,
      itemBuilder: (context, index) {
        final log = _filtered[index];
        return _LogCard(log: log, isDark: isDark);
      },
    );
  }
}

class _LogCard extends StatelessWidget {
  final AuditLogModel log;
  final bool isDark;
  const _LogCard({required this.log, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_actionIcon, size: 18, color: _actionColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    log.action,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: log.roleLabel == 'Manager'
                        ? Colors.blue.withOpacity(0.1)
                        : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    log.roleLabel,
                    style: TextStyle(
                      fontSize: 11,
                      color: log.roleLabel == 'Manager' ? Colors.blue : Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.person_outline, size: 13,
                    color: isDark ? Colors.white60 : Colors.black54),
                const SizedBox(width: 4),
                Text(log.userName,
                    style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.black54)),
                const SizedBox(width: 16),
                Icon(Icons.access_time, size: 13,
                    color: isDark ? Colors.white60 : Colors.black54),
                const SizedBox(width: 4),
                Text(log.formattedTimestamp,
                    style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.black54)),
              ],
            ),
            if (log.details != null && log.details!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                log.details!,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white54 : Colors.black45,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData get _actionIcon {
    if (log.action.contains('Create') || log.action.contains('Add')) {
      return Icons.add_circle_outline;
    }
    if (log.action.contains('Delete') || log.action.contains('Remove')) {
      return Icons.remove_circle_outline;
    }
    if (log.action.contains('Update') ||
        log.action.contains('Edit') ||
        log.action.contains('Change')) {
      return Icons.edit_outlined;
    }
    if (log.action.contains('Login')) {
      return Icons.login;
    }
    if (log.action.contains('Register')) {
      return Icons.person_add_outlined;
    }
    return Icons.info_outline;
  }

  Color get _actionColor {
    if (log.action.contains('Create') || log.action.contains('Add')) {
      return Colors.green;
    }
    if (log.action.contains('Delete') || log.action.contains('Remove')) {
      return Colors.red;
    }
    if (log.action.contains('Update') ||
        log.action.contains('Edit') ||
        log.action.contains('Change')) {
      return Colors.orange;
    }
    if (log.action.contains('Login')) {
      return Colors.blue;
    }
    if (log.action.contains('Register')) {
      return Colors.teal;
    }
    return Colors.grey;
  }
}
