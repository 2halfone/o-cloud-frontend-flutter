import 'package:flutter/material.dart';

class MonitoringUtils {
  /// Safely converts dynamic value to double
  static double safeToDouble(dynamic value) {
    if (value == null) return 0.0;
    try {
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.parse(value);
      return 0.0;
    } catch (e) {
      debugPrint('⚠️ MonitoringUtils: Error converting to double: $value');
      return 0.0;
    }
  }

  /// Safely formats double values to string with fixed decimal places
  static String safeToFixedString(double? value, int fractionDigits) {
    if (value == null) return '0';
    try {
      return value.toStringAsFixed(fractionDigits);
    } catch (e) {
      debugPrint('⚠️ MonitoringUtils: Error formatting number: $value');
      return '0';
    }
  }

  /// Safe date parsing helper
  static DateTime safeParseDatetime(String? dateTimeString) {
    if (dateTimeString == null || dateTimeString.isEmpty) {
      return DateTime.now();
    }
    
    try {
      return DateTime.parse(dateTimeString);
    } catch (e) {
      debugPrint('⚠️ MonitoringUtils: Invalid date format: $dateTimeString, error: $e');
      return DateTime.now();
    }
  }

  /// Format timestamp for display
  static String formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  /// Get color for system health status
  static Color getSystemHealthColor(String? status) {
    switch (status?.toUpperCase()) {
      case 'HEALTHY': return Colors.green;
      case 'WARNING': return Colors.orange;
      case 'CRITICAL': return Colors.red;
      case 'DEGRADED': return Colors.yellow;
      default: return Colors.grey;
    }
  }

  /// Get color for security level
  static Color getSecurityLevelColor(String level) {
    switch (level.toUpperCase()) {
      case 'LOW_RISK': return Colors.green;
      case 'MEDIUM_RISK': return Colors.orange;
      case 'HIGH_RISK': return Colors.red;
      default: return Colors.grey;
    }
  }

  /// Get display text for security level
  static String getSecurityDisplayText(String? level) {
    switch (level?.toUpperCase()) {
      case 'LOW_RISK': return 'Low Risk';
      case 'MEDIUM_RISK': return 'Medium Risk';
      case 'HIGH_RISK': return 'High Risk';
      default: return 'Unknown';
    }
  }

  /// Get color for alert severity
  static Color getAlertColor(String severity) {
    switch (severity.toUpperCase()) {
      case 'CRITICAL': return Colors.red;
      case 'HIGH': return Colors.orange;
      case 'MEDIUM': return Colors.yellow[700]!;
      case 'LOW': return Colors.blue;
      default: return Colors.grey;
    }
  }

  /// Get icon for alert type
  static IconData getAlertIcon(String type) {
    switch (type.toUpperCase()) {
      case 'SYSTEM_HEALTH': return Icons.warning;
      case 'SECURITY': return Icons.security;
      case 'RESOURCE': return Icons.memory;
      case 'NETWORK': return Icons.network_check;
      default: return Icons.info;
    }
  }
}
