import 'package:flutter/material.dart';

class AnalyticsTab extends StatelessWidget {
  final Map<String, dynamic>? dashboardData;
  final VoidCallback? onRefresh;

  const AnalyticsTab({
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
      color: const Color(0xFF4facfe),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildQRCodeAnalytics(),
            const SizedBox(height: 24),
            _buildUserBehavior(),
            const SizedBox(height: 24),
            _buildAttendanceStats(),
            const SizedBox(height: 24),
            _buildAPIUsageStats(),
          ],
        ),
      ),
    );
  }

  Widget _buildQRCodeAnalytics() {
    final analytics = dashboardData?['analytics'];
    final qrAnalytics = analytics?['qr_code_analytics'];
    
    if (qrAnalytics == null) return const SizedBox.shrink();

    List<Widget> metrics = [];

    qrAnalytics.forEach((key, value) {
      if (value != null) {
        metrics.add(_buildQRMetric(
          _formatStatName(key),
          value.toString(),
          _getQRStatIcon(key),
          _getQRStatColor(key),
        ));
      }
    });

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
              Icon(Icons.qr_code_scanner, color: Colors.blue, size: 24),
              SizedBox(width: 12),
              Text(
                'QR Code Analytics',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: metrics,
          ),
        ],
      ),
    );
  }

  Widget _buildQRMetric(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildUserBehavior() {
    final analytics = dashboardData?['analytics'];
    final userBehavior = analytics?['user_behavior'];
    
    if (userBehavior == null) return const SizedBox.shrink();

    List<Widget> metrics = [];

    userBehavior.forEach((key, value) {
      if (value != null) {
        metrics.add(_buildBehaviorMetric(
          _formatStatName(key),
          value.toString(),
          _getUserBehaviorIcon(key),
          _getUserBehaviorColor(key),
        ));
      }
    });

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
              Icon(Icons.people_alt, color: Colors.purple, size: 24),
              SizedBox(width: 12),
              Text(
                'User Behavior',
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
            padding: const EdgeInsets.only(bottom: 12),
            child: metric,
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildBehaviorMetric(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
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
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceStats() {
    final analytics = dashboardData?['analytics'];
    final attendanceStats = analytics?['attendance_stats'];
    
    if (attendanceStats == null) return const SizedBox.shrink();

    List<Widget> metrics = [];

    attendanceStats.forEach((key, value) {
      if (value != null) {
        metrics.add(_buildAttendanceMetric(
          _formatStatName(key),
          value.toString(),
          _getAttendanceIcon(key),
          _getAttendanceColor(key),
        ));
      }
    });

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
              Icon(Icons.event_available, color: Colors.green, size: 24),
              SizedBox(width: 12),
              Text(
                'Attendance Statistics',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: metrics,
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceMetric(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildAPIUsageStats() {
    final analytics = dashboardData?['analytics'];
    final apiStats = analytics?['api_usage_stats'];
    
    if (apiStats == null) return const SizedBox.shrink();

    final topEndpoints = apiStats['top_endpoints'];
    
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
              Icon(Icons.api, color: Colors.orange, size: 24),
              SizedBox(width: 12),
              Text(
                'API Usage Statistics',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // API Stats Summary
          Row(
            children: [
              if (apiStats['requests_per_hour'] != null)
                _buildAPIStatCard(
                  'Requests/Hour',
                  apiStats['requests_per_hour'].toString(),
                  Icons.speed,
                  Colors.blue,
                ),
              const SizedBox(width: 12),
              if (apiStats['system_load'] != null)
                _buildAPIStatCard(
                  'System Load',
                  apiStats['system_load'].toString().toUpperCase(),
                  Icons.memory,
                  _getLoadColor(apiStats['system_load'].toString()),
                ),
            ],
          ),
          // Top Endpoints
          if (topEndpoints != null && topEndpoints is List && topEndpoints.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text(
              'Top Endpoints',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ...topEndpoints.map<Widget>((endpoint) => _buildEndpointItem(endpoint)).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildAPIStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEndpointItem(Map<String, dynamic> endpoint) {
    final endpointPath = endpoint['endpoint'];
    final requests = endpoint['requests'];
    final responseTime = endpoint['avg_response_ms'];

    if (endpointPath == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.api, color: Colors.orange, size: 16),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              endpointPath.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontFamily: 'monospace',
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (requests != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                requests.toString(),
                style: const TextStyle(
                  color: Colors.blue,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          if (responseTime != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${responseTime}ms',
                style: const TextStyle(
                  color: Colors.green,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatStatName(String key) {
    return key.split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  IconData _getQRStatIcon(String key) {
    switch (key.toLowerCase()) {
      case 'total_scans':
      case 'total_scans_24h':
        return Icons.qr_code_scanner;
      case 'successful_scans':
        return Icons.check_circle;
      case 'success_rate':
      case 'success_rate_percent':
        return Icons.trending_up;
      case 'events_today':
        return Icons.event;
      default:
        return Icons.analytics;
    }
  }

  Color _getQRStatColor(String key) {
    switch (key.toLowerCase()) {
      case 'total_scans':
      case 'total_scans_24h':
        return Colors.blue;
      case 'successful_scans':
        return Colors.green;
      case 'success_rate':
      case 'success_rate_percent':
        return Colors.purple;
      case 'events_today':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getUserBehaviorIcon(String key) {
    switch (key.toLowerCase()) {
      case 'active_users':
        return Icons.people;
      case 'new_users':
        return Icons.person_add;
      case 'returning_users':
        return Icons.refresh;
      default:
        return Icons.person;
    }
  }

  Color _getUserBehaviorColor(String key) {
    switch (key.toLowerCase()) {
      case 'active_users':
        return Colors.blue;
      case 'new_users':
        return Colors.green;
      case 'returning_users':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getAttendanceIcon(String key) {
    switch (key.toLowerCase()) {
      case 'total_scans':
        return Icons.qr_code;
      case 'successful_scans':
        return Icons.check;
      case 'success_rate':
        return Icons.percent;
      case 'events_today':
        return Icons.today;
      default:
        return Icons.event;
    }
  }

  Color _getAttendanceColor(String key) {
    switch (key.toLowerCase()) {
      case 'total_scans':
        return Colors.blue;
      case 'successful_scans':
        return Colors.green;
      case 'success_rate':
        return Colors.purple;
      case 'events_today':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _getLoadColor(String load) {
    switch (load.toLowerCase()) {
      case 'low':
      case 'normal':
        return Colors.green;
      case 'medium':
      case 'moderate':
        return Colors.orange;
      case 'high':
      case 'critical':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildNoDataState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'No Analytics Data',
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
