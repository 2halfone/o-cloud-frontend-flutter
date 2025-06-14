import 'package:flutter/material.dart';
import '../../../core/monitoring_utils.dart';

class SystemHealthTab extends StatelessWidget {
  final Map<String, dynamic>? dashboardData;
  final VoidCallback? onRefresh;

  const SystemHealthTab({
    super.key,
    this.dashboardData,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (dashboardData == null) return _buildNoDataState();

    return RefreshIndicator(
      onRefresh: () async => onRefresh?.call(),
      backgroundColor: const Color(0xFF1A1A2E),
      color: const Color(0xFF11998e),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSystemOverview(),
            const SizedBox(height: 24),
            _buildResourceUsage(),
            const SizedBox(height: 24),
            _buildServicesStatus(),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemOverview() {
    final systemHealth = dashboardData?['system_health'];
    if (systemHealth == null) return const SizedBox.shrink();

    final overallStatus = systemHealth['overall_status'];
    if (overallStatus == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.health_and_safety_rounded,
                color: MonitoringUtils.getSystemHealthColor(overallStatus),
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'System Overview',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: MonitoringUtils.getSystemHealthColor(overallStatus).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: MonitoringUtils.getSystemHealthColor(overallStatus).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  overallStatus == 'HEALTHY' ? Icons.check_circle : Icons.warning,
                  color: MonitoringUtils.getSystemHealthColor(overallStatus),
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'System Status',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        overallStatus,
                        style: TextStyle(
                          color: MonitoringUtils.getSystemHealthColor(overallStatus),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceUsage() {
    final systemHealth = dashboardData?['system_health'];
    final resourceUsage = systemHealth?['resource_usage'];
    if (resourceUsage == null) return const SizedBox.shrink();

    List<Widget> metrics = [];

    // CPU Usage
    final cpuUsage = resourceUsage['cpu_usage_percent'];
    if (cpuUsage != null) {
      metrics.add(_buildResourceMetric(
        'CPU Usage',
        MonitoringUtils.safeToDouble(cpuUsage),
        '%',
        Colors.blue,
        Icons.memory,
      ));
    }

    // Memory Usage
    final memoryUsage = resourceUsage['memory_usage_percent'];
    if (memoryUsage != null) {
      metrics.add(_buildResourceMetric(
        'Memory Usage',
        MonitoringUtils.safeToDouble(memoryUsage),
        '%',
        Colors.purple,
        Icons.storage,
      ));
    }

    // Disk Usage
    final diskUsage = resourceUsage['disk_usage_percent'];
    if (diskUsage != null) {
      metrics.add(_buildResourceMetric(
        'Disk Usage',
        MonitoringUtils.safeToDouble(diskUsage),
        '%',
        Colors.orange,
        Icons.save,
      ));
    }

    if (metrics.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bar_chart, color: Colors.blue, size: 24),
              SizedBox(width: 12),
              Text(
                'Resource Usage',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...metrics.map((metric) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: metric,
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildResourceMetric(String label, double value, String unit, Color color, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            Text(
              '${MonitoringUtils.safeToFixedString(value, 1)}$unit',
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: (value / 100).clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withOpacity(0.7),
                    color,
                  ],
                ),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildServicesStatus() {
    final systemHealth = dashboardData?['system_health'];
    final services = systemHealth?['services'];
    if (services == null || services is! List || services.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.dns, color: Colors.green, size: 24),
              SizedBox(width: 12),
              Text(
                'Services Status',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...services.map<Widget>((service) => _buildServiceItem(service)).toList(),
        ],
      ),
    );
  }

  Widget _buildServiceItem(Map<String, dynamic> service) {
    final name = service['name'];
    final status = service['status'];
    final uptimePercent = service['uptime_percent'];
    final responseTimeMs = service['response_time_ms'];

    if (name == null) return const SizedBox.shrink();

    final isOnline = status == 'UP';
    final statusColor = isOnline ? Colors.green : Colors.red;

    IconData icon;
    switch (name.toString().toLowerCase()) {
      case 'auth service':
        icon = Icons.lock_rounded;
        break;
      case 'user service':
        icon = Icons.people_rounded;
        break;
      case 'gateway':
        icon = Icons.api_rounded;
        break;
      default:
        icon = Icons.settings_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: statusColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (status != null)
                  Text(
                    status.toString(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          if (uptimePercent != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${MonitoringUtils.safeToFixedString(MonitoringUtils.safeToDouble(uptimePercent), 1)}%',
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          if (responseTimeMs != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${MonitoringUtils.safeToFixedString(MonitoringUtils.safeToDouble(responseTimeMs), 0)}ms',
                style: const TextStyle(
                  color: Colors.blue,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNoDataState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.health_and_safety_outlined,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'No System Health Data',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Check your connection and pull to refresh',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
