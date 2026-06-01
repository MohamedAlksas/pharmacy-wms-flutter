import 'package:flutter/material.dart';
import 'package:pharmacy_wms/Models/ProductProvider.dart';
import 'package:pharmacy_wms/Models/materialModel.dart';

class ExpiryCalendarView extends StatefulWidget {
  final ProductProvider provider;
  const ExpiryCalendarView({super.key, required this.provider});

  @override
  State<ExpiryCalendarView> createState() => _ExpiryCalendarViewState();
}

class _ExpiryCalendarViewState extends State<ExpiryCalendarView> {
  DateTime _focusedMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalDays = DateUtils.getDaysInMonth(_focusedMonth.year, _focusedMonth.month);
    final firstDayOffset = DateTime(_focusedMonth.year, _focusedMonth.month, 1).weekday - 1;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Expiry Calendar: ${_monthName(_focusedMonth.month)} ${_focusedMonth.year}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => setState(() {
                      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
                    }),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => setState(() {
                      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
                    }),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              Text('Mon', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Tue', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Wed', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Thu', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Fri', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Sat', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Sun', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.2,
            ),
            itemCount: totalDays + firstDayOffset,
            itemBuilder: (context, index) {
              if (index < firstDayOffset) {
                return Container();
              }

              final day = index - firstDayOffset + 1;
              final cellDate = DateTime(_focusedMonth.year, _focusedMonth.month, day);

              final expiringProducts = widget.provider.products.where((prod) {
                final expiry = DateTime.tryParse(prod.expiryDate);
                if (expiry == null) return false;
                return expiry.year == cellDate.year &&
                    expiry.month == cellDate.month &&
                    expiry.day == cellDate.day;
              }).toList();

              final hasExpiries = expiringProducts.isNotEmpty;

              return Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: hasExpiries
                      ? Colors.red.withOpacity(0.12)
                      : isDark
                          ? const Color(0xFF2A3441)
                          : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: hasExpiries ? Border.all(color: Colors.red, width: 1) : null,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        day.toString(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: hasExpiries ? Colors.red : (isDark ? Colors.white70 : Colors.black87),
                        ),
                      ),
                      const Spacer(),
                      if (hasExpiries)
                        Row(
                          children: [
                            const Icon(Icons.dangerous, color: Colors.red, size: 10),
                            const SizedBox(width: 2),
                            Text(
                              '${expiringProducts.length} Items',
                              style: const TextStyle(fontSize: 9, color: Colors.red, fontWeight: FontWeight.bold),
                            ),
                          ],
                        )
                    ],
                  ),
                ),
              );
            },
          )
        ],
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}
