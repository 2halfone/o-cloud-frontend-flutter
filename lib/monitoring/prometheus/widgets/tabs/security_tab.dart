import 'package:flutter/material.dart';
import '../../../core/monitoring_utils.dart';

class SecurityTab extends StatelessWidget {
  final Map<String, dynamic>? dashboardData;
  final VoidCallback? onRefresh;

  const SecurityTab({
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
      color: const Color(0xFFfa709a),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSecurityOverview(),
            const SizedBox(height: 24),
            _buildAuthenticationStats(),
            const SizedBox(height: 24),
            _buildSecurityAlerts(),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityOverview() {
    final securityMetrics = dashboardData?['security_metrics'];
    if (securityMetrics == null) return const SizedBox.shrink();

    final securityLevel = securityMetrics['security_level'];
    if (securityLevel == null) return const SizedBox.shrink();

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
              Icon(Icons.security, color: Colors.orange, size: 24),
              SizedBox(width: 12),
              Text(
                'Security Overview',
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
              color: MonitoringUtils.getSecurityLevelColor(securityLevel).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: MonitoringUtils.getSecurityLevelColor(securityLevel).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getSecurityIcon(securityLevel),
                  color: MonitoringUtils.getSecurityLevelColor(securityLevel),
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Security Level',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        MonitoringUtils.getSecurityDisplayText(securityLevel),
                        style: TextStyle(
                          color: MonitoringUtils.getSecurityLevelColor(securityLevel),
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

  Widget _buildAuthenticationStats() {
    final securityMetrics = dashboardData?['security_metrics'];
    final authStats = securityMetrics?['authentication_stats'];
    final userActivity = securityMetrics?['user_activity'];
    
    if (authStats == null && userActivity == null) return const SizedBox.shrink();

    List<Widget> metrics = [];

    // Authentication Stats
    if (authStats != null) {
      authStats.forEach((key, value) {
        if (value != null) {
          metrics.add(_buildAuthMetric(
            _formatAuthStatName(key),
            value.toString(),
            _getAuthStatIcon(key),
            _getAuthStatColor(key),
          ));
        }
      });
    }

    // User Activity Stats
    if (userActivity != null) {
      userActivity.forEach((key, value) {
        if (value != null) {
          metrics.add(_buildAuthMetric(
            _formatAuthStatName(key),
            value.toString(),
            _getAuthStatIcon(key),
            _getAuthStatColor(key),
          ));
        }
      });
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
              Icon(Icons.person_search, color: Colors.blue, size: 24),
              SizedBox(width: 12),
              Text(
                'Authentication & Activity',
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

  Widget _buildAuthMetric(String title, String value, IconData icon, Color color) {
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

  Widget _buildSecurityAlerts() {
    final securityMetrics = dashboardData?['security_metrics'];
    final securityAlerts = securityMetrics?['security_alerts'];
    
    if (securityAlerts == null || securityAlerts is! List || securityAlerts.isEmpty) {
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
          Row(
            children: [
              Icon(Icons.warning, color: Colors.red, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Security Alerts',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${securityAlerts.length}',
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...securityAlerts.map<Widget>((alert) => _buildSecurityAlert(alert)).toList(),
        ],
      ),
    );
  }

  Widget _buildSecurityAlert(Map<String, dynamic> alert) {
    final severity = alert['severity'];
    final message = alert['message'];
    final timestamp = alert['timestamp'];
    final type = alert['type'];

    if (message == null) return const SizedBox.shrink();

    final severityColor = MonitoringUtils.getAlertColor(severity ?? 'MEDIUM');
    final alertIcon = MonitoringUtils.getAlertIcon(type ?? 'SECURITY');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: severityColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: severityColor.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(alertIcon, color: severityColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (severity != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: severityColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          severity.toString().toUpperCase(),
                          style: TextStyle(
                            color: severityColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const Spacer(),
                    if (timestamp != null)
                      Text(
                        MonitoringUtils.formatTimestamp(
                          MonitoringUtils.safeParseDatetime(timestamp.toString())
                        ),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  message.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatAuthStatName(String key) {
    return key.split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  IconData _getAuthStatIcon(String key) {
    switch (key.toLowerCase()) {
      case 'successful_logins':
      case 'login_attempts':
        return Icons.login;
      case 'failed_logins':
        return Icons.block;
      case 'active_sessions':
        return Icons.people;
      case 'suspicious_activity':
        return Icons.warning;
      default:
        return Icons.info;
    }
  }

  Color _getAuthStatColor(String key) {
    switch (key.toLowerCase()) {
      case 'successful_logins':
        return Colors.green;
      case 'failed_logins':
      case 'suspicious_activity':
        return Colors.red;
      case 'active_sessions':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getSecurityIcon(String level) {
    switch (level.toUpperCase()) {
      case 'LOW_RISK':
        return Icons.check_circle;
      case 'MEDIUM_RISK':
        return Icons.warning;
      case 'HIGH_RISK':
        return Icons.error;
      default:
        return Icons.help;
    }
  }

  Widget _buildNoDataState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.security_outlined,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'No Security Data',
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
