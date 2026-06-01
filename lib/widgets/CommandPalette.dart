import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:pharmacy_wms/Models/ProductProvider.dart';
import 'package:pharmacy_wms/Models/materialModel.dart';
import 'package:pharmacy_wms/Models/app_localizations.dart';

class CommandPaletteDialog extends StatefulWidget {
  final ProductProvider provider;
  final Function(int) onNavigate;

  const CommandPaletteDialog({
    super.key,
    required this.provider,
    required this.onNavigate,
  });

  @override
  State<CommandPaletteDialog> createState() => _CommandPaletteDialogState();
}

class _CommandPaletteDialogState extends State<CommandPaletteDialog> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _inputFocus = FocusNode();
  List<dynamic> _searchResults = [];
  int _selectedIndex = 0;

  final List<Map<String, dynamic>> _navigationCommands = [
    {'title': 'Go to Dashboard', 'icon': Icons.dashboard, 'action': 0},
    {'title': 'Open Inventory', 'icon': Icons.inventory, 'action': 1},
    {'title': 'Open Orders Panel', 'icon': Icons.shopping_cart, 'action': 2},
    {'title': 'Generate Reports', 'icon': Icons.bar_chart, 'action': 3},
    {'title': 'Threshold Settings', 'icon': Icons.settings, 'action': 4},
  ];

  @override
  void initState() {
    super.initState();
    _inputFocus.requestFocus();
    _performSearch('');
  }

  @override
  void dispose() {
    _searchController.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    final cleanQuery = query.trim().toLowerCase();
    final List<dynamic> results = [];

    results.addAll(_navigationCommands.where((cmd) =>
        cmd['title'].toString().toLowerCase().contains(cleanQuery)));

    if (cleanQuery.isNotEmpty) {
      final matchedProducts = widget.provider.products
          .where((p) =>
              p.name.toLowerCase().contains(cleanQuery) ||
              p.sku.toLowerCase().contains(cleanQuery))
          .take(5)
          .toList();
      results.addAll(matchedProducts);
    }

    setState(() {
      _searchResults = results;
      _selectedIndex = 0;
    });
  }

  void _handleSelection() {
    if (_searchResults.isEmpty) return;
    final selected = _searchResults[_selectedIndex];

    if (selected is Map<String, dynamic>) {
      widget.onNavigate(selected['action'] as int);
      Navigator.pop(context);
    } else if (selected is MaterialModel) {
      Navigator.pop(context);
      _showProductDetails(selected);
    }
  }

  void _showProductDetails(MaterialModel product) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(product.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('SKU', product.sku, isDark),
            _detailRow('Quantity', product.quantity.toString(), isDark),
            _detailRow('Unit', product.unit, isDark),
            _detailRow('Location', product.location, isDark),
            _detailRow('Expiry', product.expiryDate, isDark),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text('$label:', style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black54)),
          ),
          Expanded(child: Text(value, style: TextStyle(color: isDark ? Colors.white : Colors.black87))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Dialog(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        child: Container(
          width: 580,
          height: 400,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xDD1E293B) : const Color(0xDDFFFFFF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.black12,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: RawKeyboardListener(
                  focusNode: FocusNode(),
                  onKey: (event) {
                    if (event.runtimeType.toString() == 'RawKeyDownEvent') {
                      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                        setState(() {
                          _selectedIndex = (_selectedIndex + 1) % _searchResults.length;
                        });
                      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                        setState(() {
                          _selectedIndex = (_selectedIndex - 1 + _searchResults.length) % _searchResults.length;
                        });
                      } else if (event.logicalKey == LogicalKeyboardKey.enter) {
                        _handleSelection();
                      }
                    }
                  },
                  child: TextField(
                    controller: _searchController,
                    focusNode: _inputFocus,
                    onChanged: _performSearch,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      hintText: 'Type a command or search product SKU...',
                      prefixIcon: const Icon(Icons.bolt, color: Colors.blueAccent),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : Colors.grey[100],
                    ),
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: _searchResults.isEmpty
                    ? Center(
                        child: Text(
                          'No commands or products found',
                          style: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final item = _searchResults[index];
                          final isSelected = index == _selectedIndex;

                          if (item is Map<String, dynamic>) {
                            return ListTile(
                              selected: isSelected,
                              selectedTileColor: Colors.blueAccent.withOpacity(0.12),
                              leading: Icon(item['icon'] as IconData,
                                  color: isSelected ? Colors.blueAccent : Colors.grey),
                              title: Text(
                                item['title'] as String,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              trailing: const Text('Cmd', style: TextStyle(fontSize: 11, color: Colors.grey)),
                              onTap: () {
                                setState(() => _selectedIndex = index);
                                _handleSelection();
                              },
                            );
                          } else if (item is MaterialModel) {
                            return ListTile(
                              selected: isSelected,
                              selectedTileColor: Colors.blueAccent.withOpacity(0.12),
                              leading: const Icon(Icons.medication, color: Colors.green),
                              title: Text(
                                item.name,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              subtitle: Text('SKU: ${item.sku} \u2022 Stock: ${item.quantity}'),
                              trailing: const Text('Product', style: TextStyle(fontSize: 11, color: Colors.grey)),
                              onTap: () {
                                setState(() => _selectedIndex = index);
                                _handleSelection();
                              },
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
