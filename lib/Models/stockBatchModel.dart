class StockBatch {
  final int id;
  final int productId;
  final String expiryDate;
  final int quantity;
  final String receivedDate;

  const StockBatch({
    required this.id,
    required this.productId,
    required this.expiryDate,
    required this.quantity,
    required this.receivedDate,
  });

  factory StockBatch.fromJson(Map<String, dynamic> json) {
    return StockBatch(
      id: (json['id'] as num).toInt(),
      productId: (json['productId'] as num?)?.toInt() ?? 0,
      expiryDate: (json['expiryDate'] ?? '').toString(),
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      receivedDate: (json['receivedDate'] ?? '').toString(),
    );
  }

  String get formattedExpiry {
    if (expiryDate.isEmpty) return 'Unknown';
    try {
      final dt = DateTime.parse(expiryDate);
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
    } catch (_) {
      return expiryDate;
    }
  }

  int get daysUntilExpiry {
    try {
      final dt = DateTime.parse(expiryDate);
      return dt.difference(DateTime.now()).inDays;
    } catch (_) {
      return 9999;
    }
  }

  bool get isExpired => daysUntilExpiry < 0;

  bool get isExpiringSoon => daysUntilExpiry >= 0 && daysUntilExpiry <= 30;
}
