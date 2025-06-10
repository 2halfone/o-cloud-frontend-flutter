/// Classe Event per rappresentare un evento con parsing JSON robusto
/// Basata sull'esperienza acquisita con EventStatistics per gestire
/// valori null e type casting sicuri
class Event {
  final String eventId;
  final String eventName;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isActive;
  final double attendanceRate;
  final int absentCount;
  final int presentCount;
  final int scannedCount;
  final int totalUsers;
  final Map<String, int> statusBreakdown;

  Event({
    required this.eventId,
    required this.eventName,
    required this.createdAt,
    required this.expiresAt,
    required this.isActive,
    required this.attendanceRate,
    required this.absentCount,
    required this.presentCount,
    required this.scannedCount,
    required this.totalUsers,
    required this.statusBreakdown,
  });

  /// Factory constructor per parsing JSON robusto
  /// Gestisce valori null e fornisce default sicuri
  factory Event.fromJson(Map<String, dynamic> json) {
    // Parsing robusto per campi stringa con fallback sicuri
    final eventId = json['event_id'] as String? ?? json['eventId'] as String? ?? '';
    final eventName = json['event_name'] as String? ?? json['eventName'] as String? ?? 'Unknown Event';
    
    // Parsing sicuro delle date ISO 8601
    DateTime createdAt;
    try {
      final createdAtStr = json['created_at'] as String? ?? json['createdAt'] as String?;
      createdAt = createdAtStr != null ? DateTime.parse(createdAtStr) : DateTime.now();
    } catch (e) {
      print('⚠️ Event.fromJson: Error parsing created_at, using current time: $e');
      createdAt = DateTime.now();
    }

    DateTime expiresAt;
    try {
      final expiresAtStr = json['expires_at'] as String? ?? json['expiresAt'] as String?;
      expiresAt = expiresAtStr != null ? DateTime.parse(expiresAtStr) : DateTime.now().add(const Duration(days: 1));
    } catch (e) {
      print('⚠️ Event.fromJson: Error parsing expires_at, using tomorrow: $e');
      expiresAt = DateTime.now().add(const Duration(days: 1));
    }

    // Parsing sicuro per boolean con fallback
    final isActive = json['is_active'] as bool? ?? json['isActive'] as bool? ?? false;

    // Parsing robusto per valori numerici con type casting sicuro
    final attendanceRate = (json['attendance_rate'] as num?)?.toDouble() ?? 
                          (json['attendanceRate'] as num?)?.toDouble() ?? 0.0;
    
    final absentCount = (json['absent_count'] as num?)?.toInt() ?? 
                       (json['absentCount'] as num?)?.toInt() ?? 0;
    
    final presentCount = (json['present_count'] as num?)?.toInt() ?? 
                        (json['presentCount'] as num?)?.toInt() ?? 0;
    
    final scannedCount = (json['scanned_count'] as num?)?.toInt() ?? 
                        (json['scannedCount'] as num?)?.toInt() ?? 0;
    
    final totalUsers = (json['total_users'] as num?)?.toInt() ?? 
                      (json['totalUsers'] as num?)?.toInt() ?? 0;

    // Parsing robusto per statusBreakdown map
    Map<String, int> statusBreakdown = {};
    final statusData = json['status_breakdown'] ?? json['statusBreakdown'];
    
    if (statusData != null && statusData is Map) {
      try {
        // Converti a Map<String, dynamic> per gestire tipi misti
        final breakdown = Map<String, dynamic>.from(statusData);
        for (final entry in breakdown.entries) {
          if (entry.value != null) {
            // Type casting sicuro per i valori
            final intValue = (entry.value as num?)?.toInt() ?? 0;
            statusBreakdown[entry.key] = intValue;
          }
        }
      } catch (e) {
        print('⚠️ Event.fromJson: Error parsing status_breakdown: $e');
        statusBreakdown = {};
      }
    }

    return Event(
      eventId: eventId,
      eventName: eventName,
      createdAt: createdAt,
      expiresAt: expiresAt,
      isActive: isActive,
      attendanceRate: attendanceRate,
      absentCount: absentCount,
      presentCount: presentCount,
      scannedCount: scannedCount,
      totalUsers: totalUsers,
      statusBreakdown: statusBreakdown,
    );
  }

  /// Metodo toJson per serializzazione
  Map<String, dynamic> toJson() {
    return {
      'event_id': eventId,
      'event_name': eventName,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'is_active': isActive,
      'attendance_rate': attendanceRate,
      'absent_count': absentCount,
      'present_count': presentCount,
      'scanned_count': scannedCount,
      'total_users': totalUsers,
      'status_breakdown': statusBreakdown,
    };
  }

  /// Metodo toString per debug
  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('Event {');
    buffer.writeln('  eventId: $eventId');
    buffer.writeln('  eventName: $eventName');
    buffer.writeln('  createdAt: ${createdAt.toIso8601String()}');
    buffer.writeln('  expiresAt: ${expiresAt.toIso8601String()}');
    buffer.writeln('  isActive: $isActive');
    buffer.writeln('  attendanceRate: ${attendanceRate.toStringAsFixed(2)}%');
    buffer.writeln('  Statistics:');
    buffer.writeln('    totalUsers: $totalUsers');
    buffer.writeln('    presentCount: $presentCount');
    buffer.writeln('    absentCount: $absentCount');
    buffer.writeln('    scannedCount: $scannedCount');
    buffer.writeln('  statusBreakdown: $statusBreakdown');
    buffer.write('}');
    return buffer.toString();
  }

  /// Helper getters per comodità
  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isValid => isActive && !isExpired;
  double get attendancePercentage => totalUsers > 0 ? (presentCount / totalUsers) * 100 : 0.0;
  
  /// Copia l'evento con modifiche opzionali (copyWith pattern)
  Event copyWith({
    String? eventId,
    String? eventName,
    DateTime? createdAt,
    DateTime? expiresAt,
    bool? isActive,
    double? attendanceRate,
    int? absentCount,
    int? presentCount,
    int? scannedCount,
    int? totalUsers,
    Map<String, int>? statusBreakdown,
  }) {
    return Event(
      eventId: eventId ?? this.eventId,
      eventName: eventName ?? this.eventName,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isActive: isActive ?? this.isActive,
      attendanceRate: attendanceRate ?? this.attendanceRate,
      absentCount: absentCount ?? this.absentCount,
      presentCount: presentCount ?? this.presentCount,
      scannedCount: scannedCount ?? this.scannedCount,
      totalUsers: totalUsers ?? this.totalUsers,
      statusBreakdown: statusBreakdown ?? this.statusBreakdown,
    );
  }
}
