import 'package:flutter/material.dart';
import '../monitoring/prometheus/prometheus_monitor_screen_refactored.dart';

/// Legacy wrapper for PrometheusMonitorScreen
/// Now delegates to the refactored modular version
class PrometheusMonitorScreen extends StatelessWidget {
  const PrometheusMonitorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PrometheusMonitorScreenRefactored();
  }
}
