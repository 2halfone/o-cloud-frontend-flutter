class AuthLog {
  final int id;
  final String userEmail;
  final String? username; // ✅ Già nullable nella definizione
  final String action;
  final String timestamp;
  final String ipAddress;
  final String userAgent;
  final bool success;

  AuthLog({
    required this.id,
    required this.userEmail,
    this.username, // ✅ Già opzionale
    required this.action,
    required this.timestamp,
    required this.ipAddress,
    required this.userAgent,
    required this.success,
  });

  factory AuthLog.fromJson(Map<String, dynamic> json) {
    return AuthLog(
      id: json['id'] as int,
      userEmail: json['user_email'] as String,
      username: json['username'] as String?, // ✅ QUESTO È IL FIX CRITICO
      action: json['action'] as String,
      timestamp: json['timestamp'] as String,
      ipAddress: json['ip_address'] as String,
      userAgent: json['user_agent'] as String,
      success: json['success'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_email': userEmail,
      'username': username, // ✅ Può essere null
      'action': action,
      'timestamp': timestamp,
      'ip_address': ipAddress,
      'user_agent': userAgent,
      'success': success,
    };
  }

  String get formattedTimestamp {
    try {
      final dateTime = DateTime.parse(timestamp);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return timestamp;
    }
  }
  String get actionDescription {
    switch (action) {
      case 'login_success':
        return 'Login Successful';
      case 'login_failed_wrong_password':
        return 'Login Failed - Wrong Password';
      case 'login_failed_user_not_found':
        return 'Login Failed - User Not Found';
      default:
        return action.replaceAll('_', ' ').toUpperCase();
    }
  }

  // Getter per display name - usa username se disponibile, altrimenti estrae dall'email
  String get displayName {
    if (username != null && username!.isNotEmpty) {
      return username!;
    }
    // Estrae la parte prima della @ dall'email
    return userEmail.split('@')[0];
  }
  // Getter per informazioni complete di display
  String get fullDisplayInfo {
    return '$displayName ($userEmail)';
  }
}

class AuthLogStats {
  final int currentPage;
  final int pagesTotal;
  final int totalLogs;

  AuthLogStats({
    required this.currentPage,
    required this.pagesTotal,
    required this.totalLogs,
  });

  factory AuthLogStats.fromJson(Map<String, dynamic> json) {
    return AuthLogStats(
      currentPage: json['current_page'] as int,
      pagesTotal: json['pages_total'] as int,
      totalLogs: json['total_logs'] as int,
    );
  }
}

class AuthLogsResponse {
  final List<AuthLog> logs;
  final int page;
  final int limit;
  final int total;
  final AuthLogStats stats;

  AuthLogsResponse({
    required this.logs,
    required this.page,
    required this.limit,
    required this.total,
    required this.stats,
  });

  factory AuthLogsResponse.fromJson(Map<String, dynamic> json) {
    return AuthLogsResponse(
      logs: (json['logs'] as List)
          .map((logJson) => AuthLog.fromJson(logJson))
          .toList(),
      page: json['page'] as int,
      limit: json['limit'] as int,
      total: json['total'] as int,
      stats: AuthLogStats.fromJson(json['stats']),
    );
  }
}
