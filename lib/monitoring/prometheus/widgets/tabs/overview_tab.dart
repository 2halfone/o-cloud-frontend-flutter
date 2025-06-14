import 'package:flutter/material.dart';
import '../../../core/monitoring_utils.dart';

class OverviewTab extends StatelessWidget {
  final Map<String, dynamic>? dashboardData;
  final VoidCallback? onRefresh;

  const OverviewTab({
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
      color: const Color(0xFF667eea),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildOverviewCards(),
            const SizedBox(height: 24),
            _buildQuickMetrics(),
            const SizedBox(height: 24),
            _buildRecentActivity(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
        double childAspectRatio = constraints.maxWidth > 600 ? 1.4 : 1.3;
        
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: childAspectRatio,
          children: [
            _buildOverviewCard(
              'System Health',
              dashboardData?['system_health']?['overall_status'] ?? 'UNKNOWN',
              Icons.health_and_safety_rounded,
              MonitoringUtils.getSystemHealthColor(dashboardData?['system_health']?['overall_status']),
            ),
            _buildOverviewCard(
              'Security Level',
              MonitoringUtils.getSecurityDisplayText(dashboardData?['security_metrics']?['security_level']),
              Icons.security_rounded,
              MonitoringUtils.getSecurityLevelColor(dashboardData?['security_metrics']?['security_level'] ?? 'UNKNOWN'),
            ),
            _buildOverviewCard(
              'Active Users',
              '${dashboardData?['analytics']?['user_behavior']?['active_users'] ?? '0'}',
              Icons.people_rounded,
              Colors.purple,
            ),
            _buildOverviewCard(
              'QR Scans Today',
              '${dashboardData?['analytics']?['qr_code_analytics']?['total_scans_24h'] ?? '0'}',
              Icons.qr_code_scanner_rounded,
              Colors.orange,
            ),
          ],
        );
      },
    );
  }

  Widget _buildOverviewCard(String title, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.8),
            color.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 8),
            Flexible(
              child: Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickMetrics() {
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
          const Text(
            'Quick Metrics',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildQuickMetric(
                'CPU', 
                '${MonitoringUtils.safeToFixedString(MonitoringUtils.safeToDouble(dashboardData?['system_health']?['resource_usage']?['cpu_usage_percent']), 1)}%', 
                Icons.memory, 
                Colors.blue
              ),
              _buildQuickMetric(
                'Memory', 
                '${MonitoringUtils.safeToFixedString(MonitoringUtils.safeToDouble(dashboardData?['system_health']?['resource_usage']?['memory_usage_percent']), 1)}%', 
                Icons.storage, 
                Colors.green
              ),
              _buildQuickMetric(
                'Network', 
                '${MonitoringUtils.safeToFixedString(MonitoringUtils.safeToDouble(dashboardData?['system_health']?['resource_usage']?['network_usage']), 1)} MB/s', 
                Icons.network_check, 
                Colors.purple
              ),
              _buildQuickMetric(
                'Uptime', 
                '99.5%', 
                Icons.timer, 
                Colors.orange
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickMetric(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
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
          const Text(
            'Recent Activity',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildActivityItem(
            'System Health Check',
            'All systems operational',
            Icons.check_circle,
            Colors.green,
            '2 min ago',
          ),
          _buildActivityItem(
            'Security Scan',
            'No threats detected',
            Icons.security,
            Colors.blue,
            '5 min ago',
          ),
          _buildActivityItem(
            'Performance Monitor',
            'CPU usage within normal range',
            Icons.speed,
            Colors.orange,
            '8 min ago',
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String title, String description, IconData icon, Color color, String time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 11,
            ),
          ),
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
            Icons.data_usage_outlined,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'No Data Available',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Pull to refresh or check your connection',
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
