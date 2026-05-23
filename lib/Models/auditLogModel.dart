class AuditLogModel {
  final int id;
  final String action;
  final String entityType;
  final int? entityId;
  final String? details;
  final int userId;
  final String userName;
  final String userRole;
  final String? ipAddress;
  final DateTime timestamp;

  AuditLogModel({
    required this.id,
    required this.action,
    required this.entityType,
    this.entityId,
    this.details,
    required this.userId,
    required this.userName,
    required this.userRole,
    this.ipAddress,
    required this.timestamp,
  });

  factory AuditLogModel.fromJson(Map<String, dynamic> json) {
    return AuditLogModel(
      id: json['id'] as int,
      action: json['action'] as String,
      entityType: json['entityType'] as String,
      entityId: json['entityId'] as int?,
      details: json['details'] as String?,
      userId: json['userId'] as int,
      userName: json['userName'] as String,
      userRole: json['userRole'] as String,
      ipAddress: json['ipAddress'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  String get formattedTimestamp {
    final d = timestamp.toLocal();
    final date =
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final time =
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    return '$date $time';
  }

  String get roleLabel =>
      userRole.toLowerCase().contains('admin') ? 'Manager' : 'Supervisor';
}
