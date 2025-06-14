import 'package:flutter/material.dart';

// Base classes for monitoring system

class MonitoringAlert {
  final String id;
  final String type;
  final String severity;
  final String message;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  MonitoringAlert({
    required this.id,
    required this.type,
    required this.severity,
    required this.message,
    required this.timestamp,
    this.metadata = const {},
  });

  factory MonitoringAlert.fromJson(Map<String, dynamic> json) {
    return MonitoringAlert(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      severity: json['severity'] ?? '',
      message: json['message'] ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      metadata: json['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'severity': severity,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }
}

class MonitoringMetric {
  final String name;
  final dynamic value;
  final String unit;
  final DateTime timestamp;
  final Map<String, String> labels;

  MonitoringMetric({
    required this.name,
    required this.value,
    required this.unit,
    required this.timestamp,
    this.labels = const {},
  });

  factory MonitoringMetric.fromJson(Map<String, dynamic> json) {
    return MonitoringMetric(
      name: json['name'] ?? '',
      value: json['value'],
      unit: json['unit'] ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      labels: Map<String, String>.from(json['labels'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'value': value,
      'unit': unit,
      'timestamp': timestamp.toIso8601String(),
      'labels': labels,
    };
  }
}

class DashboardTab {
  final String title;
  final IconData icon;
  final List<Color> gradient;
  
  DashboardTab({
    required this.title,
    required this.icon,
    required this.gradient,
  });
}

class SystemStatus {
  final String status;
  final double healthScore;
  final Map<String, dynamic> details;
  
  SystemStatus({
    required this.status,
    required this.healthScore,
    this.details = const {},
  });
  
  factory SystemStatus.fromJson(Map<String, dynamic> json) {
    return SystemStatus(
      status: json['status'] ?? 'UNKNOWN',
      healthScore: (json['health_score'] ?? 0).toDouble(),
      details: json['details'] ?? {},
    );
  }
}
