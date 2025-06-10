import 'package:json_annotation/json_annotation.dart';

part 'admin_events.g.dart';

// Type alias for backward compatibility
typedef AdminEvent = EventWithStatistics;

class EventStatistics {
  @JsonKey(name: 'total_users')
  final int totalUsers;
  @JsonKey(name: 'present_count')
  final int presentCount;
  @JsonKey(name: 'absent_count')
  final int absentCount;
  @JsonKey(name: 'scanned_count')
  final int scannedCount;
  @JsonKey(name: 'attendance_rate')
  final double attendanceRate;
  @JsonKey(name: 'status_breakdown')
  final Map<String, int> statusBreakdown;

  EventStatistics({
    required this.totalUsers,
    required this.presentCount,
    required this.absentCount,
    required this.scannedCount,
    required this.attendanceRate,
    required this.statusBreakdown,
  });factory EventStatistics.fromJson(Map<String, dynamic> json) {
    // Safe parsing with null checks and type casting
    final totalUsers = (json['total_users'] as num?)?.toInt() ?? 0;
    final presentCount = (json['present_count'] as num?)?.toInt() ?? 0;
    final absentCount = (json['absent_count'] as num?)?.toInt() ?? 0;
    final scannedCount = (json['scanned_count'] as num?)?.toInt() ?? 0;
    final attendanceRate = (json['attendance_rate'] as num?)?.toDouble() ?? 0.0;
    
    // Safe parsing of status_breakdown map
    Map<String, int> statusBreakdown = {};
    if (json['status_breakdown'] != null) {
      final breakdownData = json['status_breakdown'];
      if (breakdownData is Map) {
        // Convert to Map<String, dynamic> first to handle type casting safely
        final breakdown = Map<String, dynamic>.from(breakdownData);
        for (final entry in breakdown.entries) {
          if (entry.value != null) {
            statusBreakdown[entry.key] = (entry.value as num?)?.toInt() ?? 0;
          }
        }
      }
    }
    
    return EventStatistics(
      totalUsers: totalUsers,
      presentCount: presentCount,
      absentCount: absentCount,
      scannedCount: scannedCount,
      attendanceRate: attendanceRate,
      statusBreakdown: statusBreakdown,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_users': totalUsers,
      'present_count': presentCount,
      'absent_count': absentCount,
      'scanned_count': scannedCount,
      'attendance_rate': attendanceRate,
      'status_breakdown': statusBreakdown,
    };
  }
}

class EventWithStatistics {
  final int id;
  final String eventId;
  final String eventName;
  final String date;
  final String qrImagePath;
  final DateTime expiresAt;
  final bool isActive;
  final DateTime createdAt;
  final EventStatistics statistics;

  EventWithStatistics({
    required this.id,
    required this.eventId,
    required this.eventName,
    required this.date,
    required this.qrImagePath,
    required this.expiresAt,
    required this.isActive,
    required this.createdAt,
    required this.statistics,
  });

  /// Custom fromJson with safe type casting to prevent null casting errors
  factory EventWithStatistics.fromJson(Map<String, dynamic> json) {
    // Safe parsing with null checks and type casting
    final id = (json['id'] as num?)?.toInt() ?? 0;
    final eventId = json['event_id'] as String? ?? '';
    final eventName = json['event_name'] as String? ?? 'Unknown Event';
    final date = json['date'] as String? ?? '';
    final qrImagePath = json['qr_image_path'] as String? ?? '';
    final isActive = json['is_active'] as bool? ?? false;
    
    // Safe date parsing with fallbacks
    DateTime expiresAt;
    try {
      final expiresAtStr = json['expires_at'] as String?;
      expiresAt = expiresAtStr != null ? DateTime.parse(expiresAtStr) : DateTime.now().add(const Duration(days: 1));
    } catch (e) {
      print('⚠️ EventWithStatistics.fromJson: Error parsing expires_at, using tomorrow: $e');
      expiresAt = DateTime.now().add(const Duration(days: 1));
    }
    
    DateTime createdAt;
    try {
      final createdAtStr = json['created_at'] as String?;
      createdAt = createdAtStr != null ? DateTime.parse(createdAtStr) : DateTime.now();
    } catch (e) {
      print('⚠️ EventWithStatistics.fromJson: Error parsing created_at, using current time: $e');
      createdAt = DateTime.now();
    }
    
    // Safe parsing of statistics object
    EventStatistics statistics;
    try {
      final statsData = json['statistics'] as Map<String, dynamic>?;
      statistics = statsData != null ? EventStatistics.fromJson(statsData) : EventStatistics(
        totalUsers: 0,
        presentCount: 0,
        absentCount: 0,
        scannedCount: 0,
        attendanceRate: 0.0,
        statusBreakdown: {},
      );
    } catch (e) {
      print('⚠️ EventWithStatistics.fromJson: Error parsing statistics, using defaults: $e');
      statistics = EventStatistics(
        totalUsers: 0,
        presentCount: 0,
        absentCount: 0,
        scannedCount: 0,
        attendanceRate: 0.0,
        statusBreakdown: {},
      );
    }
    
    return EventWithStatistics(
      id: id,
      eventId: eventId,
      eventName: eventName,
      date: date,
      qrImagePath: qrImagePath,
      expiresAt: expiresAt,
      isActive: isActive,
      createdAt: createdAt,
      statistics: statistics,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event_id': eventId,
      'event_name': eventName,
      'date': date,
      'qr_image_path': qrImagePath,
      'expires_at': expiresAt.toIso8601String(),
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'statistics': statistics.toJson(),
    };
  }
}

@JsonSerializable()
class EventInfo {
  @JsonKey(name: 'event_id')
  final String eventId;
  @JsonKey(name: 'event_name')
  final String eventName;
  final String date;
  @JsonKey(name: 'is_active')
  final bool isActive;

  EventInfo({
    required this.eventId,
    required this.eventName,
    required this.date,
    required this.isActive,
  });

  factory EventInfo.fromJson(Map<String, dynamic> json) =>
      _$EventInfoFromJson(json);

  Map<String, dynamic> toJson() => _$EventInfoToJson(this);
}

class UserAttendanceDetail {
  final int id;
  final int userId;
  final String name;
  final String surname;
  final String status;
  final DateTime? scannedAt;
  final DateTime? timestamp;
  final String? motivazione;
  final int? updatedBy;
  final DateTime updatedAt;

  UserAttendanceDetail({
    required this.id,
    required this.userId,
    required this.name,
    required this.surname,
    required this.status,
    this.scannedAt,
    this.timestamp,
    this.motivazione,
    this.updatedBy,
    required this.updatedAt,
  });

  /// Custom fromJson with safe type casting to handle missing fields
  factory UserAttendanceDetail.fromJson(Map<String, dynamic> json) {
    // Safe parsing with null checks and type casting
    final id = (json['id'] as num?)?.toInt() ?? 0; // Default to 0 if missing
    final userId = (json['user_id'] as num?)?.toInt() ?? 0;
    final name = json['name'] as String? ?? 'Unknown';
    final surname = json['surname'] as String? ?? 'User';
    final status = json['status'] as String? ?? 'not_registered';
    final motivazione = json['motivazione'] as String?;
    final updatedBy = (json['updated_by'] as num?)?.toInt();
    
    // Safe date parsing with fallbacks
    DateTime? scannedAt;
    try {
      final scannedAtStr = json['scanned_at'] as String?;
      scannedAt = scannedAtStr != null ? DateTime.parse(scannedAtStr) : null;
    } catch (e) {
      print('⚠️ UserAttendanceDetail.fromJson: Error parsing scanned_at: $e');
      scannedAt = null;
    }
    
    DateTime? timestamp;
    try {
      final timestampStr = json['timestamp'] as String?;
      timestamp = timestampStr != null ? DateTime.parse(timestampStr) : null;
    } catch (e) {
      print('⚠️ UserAttendanceDetail.fromJson: Error parsing timestamp: $e');
      timestamp = null;
    }
    
    DateTime updatedAt;
    try {
      final updatedAtStr = json['updated_at'] as String?;
      updatedAt = updatedAtStr != null ? DateTime.parse(updatedAtStr) : DateTime.now();
    } catch (e) {
      print('⚠️ UserAttendanceDetail.fromJson: Error parsing updated_at, using current time: $e');
      updatedAt = DateTime.now();
    }
    
    return UserAttendanceDetail(
      id: id,
      userId: userId,
      name: name,
      surname: surname,
      status: status,
      scannedAt: scannedAt,
      timestamp: timestamp,
      motivazione: motivazione,
      updatedBy: updatedBy,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'surname': surname,
      'status': status,
      'scanned_at': scannedAt?.toIso8601String(),
      'timestamp': timestamp?.toIso8601String(),
      'motivazione': motivazione,
      'updated_by': updatedBy,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helper getters
  String get fullName => '$name $surname';
  
  String get displayTimestamp {
    if (timestamp != null) {
      final time = timestamp!;
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else {
      return '-';
    }
  }

  // copyWith method for real-time updates
  UserAttendanceDetail copyWith({
    int? id,
    int? userId,
    String? name,
    String? surname,
    String? status,
    DateTime? scannedAt,
    DateTime? timestamp,
    String? motivazione,
    int? updatedBy,
    DateTime? updatedAt,
  }) {
    return UserAttendanceDetail(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      surname: surname ?? this.surname,
      status: status ?? this.status,
      scannedAt: scannedAt ?? this.scannedAt,
      timestamp: timestamp ?? this.timestamp,
      motivazione: motivazione ?? this.motivazione,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

@JsonSerializable()
class EventUsersPagination {
  @JsonKey(name: 'current_page')
  final int currentPage;
  @JsonKey(name: 'total_pages')
  final int totalPages;
  @JsonKey(name: 'total_users')
  final int totalUsers;
  @JsonKey(name: 'users_per_page')
  final int usersPerPage;

  EventUsersPagination({
    required this.currentPage,
    required this.totalPages,
    required this.totalUsers,
    required this.usersPerPage,
  });
  factory EventUsersPagination.fromJson(Map<String, dynamic> json) =>
      _$EventUsersPaginationFromJson(json);

  Map<String, dynamic> toJson() => _$EventUsersPaginationToJson(this);

  // Helper getter
  bool get hasNext => currentPage < totalPages;
}

class EventUsersResponse {
  final EventInfo? eventInfo; // Make optional since it's not in actual response
  final EventStatistics statistics;
  final List<UserAttendanceDetail> users;
  final EventUsersPagination? pagination; // Make optional since it's not in actual response

  EventUsersResponse({
    this.eventInfo,
    required this.statistics,
    required this.users,
    this.pagination,
  });

  /// Custom fromJson to handle actual backend response structure
  factory EventUsersResponse.fromJson(Map<String, dynamic> json) {
    // Parse statistics
    EventStatistics statistics;
    try {
      final statsData = json['statistics'] as Map<String, dynamic>?;
      statistics = statsData != null ? EventStatistics.fromJson(statsData) : EventStatistics(
        totalUsers: 0,
        presentCount: 0,
        absentCount: 0,
        scannedCount: 0,
        attendanceRate: 0.0,
        statusBreakdown: {},
      );
    } catch (e) {
      print('⚠️ EventUsersResponse.fromJson: Error parsing statistics: $e');
      statistics = EventStatistics(
        totalUsers: 0,
        presentCount: 0,
        absentCount: 0,
        scannedCount: 0,
        attendanceRate: 0.0,
        statusBreakdown: {},
      );
    }

    // Parse users list
    List<UserAttendanceDetail> users = [];
    try {
      final usersData = json['users'] as List?;
      if (usersData != null) {
        users = usersData
            .map((userData) => UserAttendanceDetail.fromJson(userData as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      print('⚠️ EventUsersResponse.fromJson: Error parsing users: $e');
      users = [];
    }

    // Parse optional event_info (if present)
    EventInfo? eventInfo;
    try {
      final eventInfoData = json['event_info'] as Map<String, dynamic>?;
      if (eventInfoData != null) {
        eventInfo = EventInfo.fromJson(eventInfoData);
      }
    } catch (e) {
      print('⚠️ EventUsersResponse.fromJson: Event info not available: $e');
      eventInfo = null;
    }

    // Parse optional pagination (if present)
    EventUsersPagination? pagination;
    try {
      final paginationData = json['pagination'] as Map<String, dynamic>?;
      if (paginationData != null) {
        pagination = EventUsersPagination.fromJson(paginationData);
      } else {
        // Create default pagination based on total_users if available
        final totalUsers = (json['total_users'] as num?)?.toInt() ?? users.length;
        pagination = EventUsersPagination(
          currentPage: 1,
          totalPages: 1,
          totalUsers: totalUsers,
          usersPerPage: users.length,
        );
      }
    } catch (e) {
      print('⚠️ EventUsersResponse.fromJson: Error parsing pagination: $e');
      pagination = EventUsersPagination(
        currentPage: 1,
        totalPages: 1,
        totalUsers: users.length,
        usersPerPage: users.length,
      );
    }

    return EventUsersResponse(
      eventInfo: eventInfo,
      statistics: statistics,
      users: users,
      pagination: pagination,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (eventInfo != null) 'event_info': eventInfo!.toJson(),
      'statistics': statistics.toJson(),
      'users': users.map((user) => user.toJson()).toList(),
      if (pagination != null) 'pagination': pagination!.toJson(),
    };
  }
}

@JsonSerializable()
class UserStatusUpdateResponse {
  final bool success;
  final String message;
  final UserAttendanceDetail user;
  @JsonKey(name: 'event_statistics')
  final EventStatistics eventStatistics;

  UserStatusUpdateResponse({
    required this.success,
    required this.message,
    required this.user,
    required this.eventStatistics,
  });

  factory UserStatusUpdateResponse.fromJson(Map<String, dynamic> json) =>
      _$UserStatusUpdateResponseFromJson(json);

  Map<String, dynamic> toJson() => _$UserStatusUpdateResponseToJson(this);
}
