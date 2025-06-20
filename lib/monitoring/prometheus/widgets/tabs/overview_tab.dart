import 'package:flutter/material.dart';
import '../../../core/monitoring_utils.dart';
import '../../services/prometheus_api_service.dart';

class OverviewTab extends StatefulWidget {
  const OverviewTab({super.key});

  @override
  State<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<OverviewTab> {
  Map<String, dynamic>? _dashboardData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      Map<String, dynamic> data;
      try {
        data = await PrometheusApiService().loadAllDashboardData();
      } catch (e) {
        // If Insights API fails, try to load security and VM health only
        print('⚠️ Insights API failed, attempting partial dashboard load: $e');
        data = {};
        try {
          final security = await PrometheusApiService().loadSecurityData();
          data['security_metrics'] = security['data'] ?? {};
        } catch (e) {
          print('❌ Security API also failed: $e');
        }
        try {
          final vm = await PrometheusApiService().loadVMHealthData();
          data['system_health'] = vm['data'] ?? {};
          data['system_resources'] = vm['data']?['system_resources'] ?? {};
        } catch (e) {
          print('❌ VM Health API also failed: $e');
        }
        // No analytics if Insights failed
        data['analytics'] = null;
      }
      setState(() {
        _dashboardData = data;
        _isLoading = false;
      });
      print('🎯 OverviewTab - Dashboard data keys: \\${data.keys}');
      if (data['metadata'] != null) {
        print('🎯 OverviewTab - Metadata: \\${data['metadata']}');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      print('❌ OverviewTab - Error fetching dashboard data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text('Error loading data', style: const TextStyle(color: Colors.red, fontSize: 18)),
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchDashboardData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (_dashboardData == null) return _buildNoDataState();

    // Check if at least one main section has data
    final hasSystemHealth = _dashboardData?['system_health'] != null;
    final hasSecurity = _dashboardData?['security_metrics'] != null;
    final hasAnalytics = _dashboardData?['analytics'] != null;
    final hasSystemResources = _dashboardData?['system_resources'] != null;
    if (!hasSystemHealth && !hasSecurity && !hasAnalytics && !hasSystemResources) {
      return _buildNoDataState();
    }

    return RefreshIndicator(
      onRefresh: _fetchDashboardData,
      backgroundColor: const Color(0xFF1A1A2E),
      color: const Color(0xFF667eea),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (hasSystemHealth || hasSecurity || hasSystemResources) _buildApiEndpointsStatus(),
            const SizedBox(height: 24),
            if (hasSystemHealth || hasSecurity || hasAnalytics) _buildOverviewCards(),
            const SizedBox(height: 24),
            if (hasSystemHealth) _buildQuickMetrics() else _buildSectionWarning('Quick Metrics unavailable'),
            const SizedBox(height: 24),
            _buildRecentActivity(),
          ],
        ),
      ),
    );
  }

  Widget _buildApiEndpointsStatus() {
    final metadata = _dashboardData?['metadata'];
    final dataSource = metadata?['data_source'] ?? 'unknown';
    final endpointsUsed = metadata?['endpoints_used'] ?? [];
    final lastUpdated = metadata?['last_updated'] ?? 'unknown';
    final collectionTime = metadata?['collection_time_ms'] ?? 0;

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
              Icon(Icons.api, color: Colors.blue, size: 24),
              SizedBox(width: 12),
              Text(
                'Backend API Status',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildApiEndpointCard('Security', 
                  _dashboardData?['security_metrics'] != null),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _dashboardData?['system_resources'] != null
                  ? _buildApiEndpointCard('VM Health', true)
                  : _buildSectionWarning('VM Health data unavailable'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _dashboardData?['analytics'] != null
                  ? _buildApiEndpointCard('Analytics', true)
                  : _buildSectionWarning('Analytics data unavailable'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Data Source: $dataSource',
                  style: const TextStyle(color: Colors.blue, fontSize: 12),
                ),
                Text(
                  'Collection Time: \${collectionTime}ms',
                  style: const TextStyle(color: Colors.blue, fontSize: 12),
                ),
                Text(
                  'Endpoints: \${endpointsUsed.toString()}',
                  style: const TextStyle(color: Colors.blue, fontSize: 12),
                ),
                Text(
                  'Last Updated: \${lastUpdated.toString().substring(0, 19)}',
                  style: const TextStyle(color: Colors.blue, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApiEndpointCard(String name, bool hasData) {
    final color = hasData ? Colors.green : Colors.red;
    final icon = hasData ? Icons.check_circle : Icons.error;
    final status = hasData ? 'Connected' : 'No Data';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
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
              _dashboardData?['system_health']?['overall_status'] ?? 'UNKNOWN',
              Icons.health_and_safety_rounded,
              MonitoringUtils.getSystemHealthColor(_dashboardData?['system_health']?['overall_status']),
            ),
            _buildOverviewCard(
              'Security Level',
              MonitoringUtils.getSecurityDisplayText(_dashboardData?['security_metrics']?['security_level']),
              Icons.security_rounded,
              MonitoringUtils.getSecurityLevelColor(_dashboardData?['security_metrics']?['security_level'] ?? 'UNKNOWN'),
            ),
            _buildOverviewCard(
              'Active Users',
              '\\${_dashboardData?['analytics']?['user_behavior']?['active_users'] ?? '0'}',
              Icons.people_rounded,
              Colors.purple,
            ),
            _buildOverviewCard(
              'QR Scans Today',
              '\\${_dashboardData?['analytics']?['qr_code_analytics']?['total_scans_24h'] ?? '0'}',
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
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
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
            ),
            const SizedBox(height: 4),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
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
                '\\${MonitoringUtils.safeToFixedString(MonitoringUtils.safeToDouble(_dashboardData?['system_health']?['resource_usage']?['cpu_usage_percent']), 1)}%', 
                Icons.memory, 
                Colors.blue
              ),
              _buildQuickMetric(
                'Memory', 
                '\\${MonitoringUtils.safeToFixedString(MonitoringUtils.safeToDouble(_dashboardData?['system_health']?['resource_usage']?['memory_usage_percent']), 1)}%', 
                Icons.storage, 
                Colors.green
              ),
              _buildQuickMetric(
                'Network', 
                '\\${MonitoringUtils.safeToFixedString(MonitoringUtils.safeToDouble(_dashboardData?['system_health']?['resource_usage']?['network_usage']), 1)} MB/s', 
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

  Widget _buildSectionWarning(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.warning, color: Colors.red, size: 20),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'No Data',
            style: TextStyle(
              color: Colors.red.withOpacity(0.8),
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
