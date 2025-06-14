import 'package:flutter/material.dart';

class PerformanceTab extends StatelessWidget {
  final Map<String, dynamic>? dashboardData;
  final VoidCallback? onRefresh;

  const PerformanceTab({
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
      color: const Color(0xFFa8edea),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildPerformanceOverview(),
            const SizedBox(height: 24),
            _buildApiMetrics(),
            const SizedBox(height: 24),
            _buildDatabaseMetrics(),
            const SizedBox(height: 24),
            _buildTopEndpoints(),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceOverview() {
    final performance = dashboardData?['performance'];
    if (performance == null) return const SizedBox.shrink();

    final apiResponseTime = performance['api_response_time_avg'];
    final throughput = performance['requests_per_second'];
    final errorRate = performance['error_rate_percentage'];
    final dbQueryTime = performance['db_query_time_avg'];

    if (apiResponseTime == null && throughput == null && errorRate == null && dbQueryTime == null) {
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFa8edea), Color(0xFFfed6e3)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.speed_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Performance Overview',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.3,
                children: [
                  if (apiResponseTime != null)
                    _buildMetricCard(
                      'API Response Time',
                      '${apiResponseTime}ms',
                      Icons.timer_outlined,
                      _getPerformanceColor(apiResponseTime, 'response_time'),
                    ),
                  if (throughput != null)
                    _buildMetricCard(
                      'Requests/sec',
                      throughput.toString(),
                      Icons.trending_up_rounded,
                      _getPerformanceColor(throughput, 'throughput'),
                    ),
                  if (errorRate != null)
                    _buildMetricCard(
                      'Error Rate',
                      '${errorRate}%',
                      Icons.error_outline_rounded,
                      _getPerformanceColor(errorRate, 'error_rate'),
                    ),
                  if (dbQueryTime != null)
                    _buildMetricCard(
                      'DB Query Time',
                      '${dbQueryTime}ms',
                      Icons.storage_rounded,
                      _getPerformanceColor(dbQueryTime, 'db_time'),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildApiMetrics() {
    final apiMetrics = dashboardData?['api_metrics'];
    if (apiMetrics == null) return const SizedBox.shrink();

    final endpoints = apiMetrics['endpoints'] as List?;
    if (endpoints == null || endpoints.isEmpty) return const SizedBox.shrink();

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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.api_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'API Endpoints Performance',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...endpoints.take(5).map((endpoint) => _buildEndpointRow(endpoint)),
        ],
      ),
    );
  }

  Widget _buildDatabaseMetrics() {
    final dbMetrics = dashboardData?['database_metrics'];
    if (dbMetrics == null) return const SizedBox.shrink();

    final connections = dbMetrics['active_connections'];
    final queryTime = dbMetrics['avg_query_time'];
    final slowQueries = dbMetrics['slow_queries_count'];
    final poolUsage = dbMetrics['connection_pool_usage'];

    if (connections == null && queryTime == null && slowQueries == null && poolUsage == null) {
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.storage_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Database Performance',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.3,
                children: [
                  if (connections != null)
                    _buildMetricCard(
                      'Active Connections',
                      connections.toString(),
                      Icons.link_rounded,
                      _getDbConnectionColor(connections),
                    ),
                  if (queryTime != null)
                    _buildMetricCard(
                      'Avg Query Time',
                      '${queryTime}ms',
                      Icons.query_stats_rounded,
                      _getPerformanceColor(queryTime, 'db_time'),
                    ),
                  if (slowQueries != null)
                    _buildMetricCard(
                      'Slow Queries',
                      slowQueries.toString(),
                      Icons.warning_rounded,
                      _getSlowQueriesColor(slowQueries),
                    ),
                  if (poolUsage != null)
                    _buildMetricCard(
                      'Pool Usage',
                      '${poolUsage}%',
                      Icons.pool_rounded,
                      _getUsageColor(poolUsage),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTopEndpoints() {
    final topEndpoints = dashboardData?['top_endpoints'];
    if (topEndpoints == null) return const SizedBox.shrink();

    final endpoints = topEndpoints as List?;
    if (endpoints == null || endpoints.isEmpty) return const SizedBox.shrink();

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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.trending_up_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Top Endpoints by Traffic',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...endpoints.take(10).map((endpoint) => _buildTopEndpointRow(endpoint)),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEndpointRow(Map<String, dynamic> endpoint) {
    final path = endpoint['path'] ?? 'Unknown';
    final method = endpoint['method'] ?? 'GET';
    final responseTime = endpoint['avg_response_time'];
    final requests = endpoint['request_count'];
    final errorRate = endpoint['error_rate'];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getMethodColor(method),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              method,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              path,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (responseTime != null) ...[
            const SizedBox(width: 8),
            Text(
              '${responseTime}ms',
              style: TextStyle(
                color: _getPerformanceColor(responseTime, 'response_time'),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (requests != null) ...[
            const SizedBox(width: 8),
            Text(
              '${requests} req',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
          if (errorRate != null && errorRate > 0) ...[
            const SizedBox(width: 8),
            Text(
              '${errorRate}%',
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTopEndpointRow(Map<String, dynamic> endpoint) {
    final path = endpoint['path'] ?? 'Unknown';
    final requests = endpoint['requests'] ?? 0;
    final percentage = endpoint['percentage'] ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              path,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 80,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percentage / 100,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            requests.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.speed_rounded,
                  size: 48,
                  color: Colors.white.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No Performance Data',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Performance metrics will appear here when data is available',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getPerformanceColor(dynamic value, String type) {
    if (value == null) return Colors.grey;
    
    switch (type) {
      case 'response_time':
      case 'db_time':
        final time = value is String ? double.tryParse(value) ?? 0 : value.toDouble();
        if (time < 100) return Colors.greenAccent;
        if (time < 500) return Colors.orangeAccent;
        return Colors.redAccent;
      case 'throughput':
        final requests = value is String ? double.tryParse(value) ?? 0 : value.toDouble();
        if (requests > 100) return Colors.greenAccent;
        if (requests > 50) return Colors.orangeAccent;
        return Colors.redAccent;
      case 'error_rate':
        final rate = value is String ? double.tryParse(value) ?? 0 : value.toDouble();
        if (rate < 1) return Colors.greenAccent;
        if (rate < 5) return Colors.orangeAccent;
        return Colors.redAccent;
      default:
        return Colors.blueAccent;
    }
  }

  Color _getDbConnectionColor(int connections) {
    if (connections < 10) return Colors.greenAccent;
    if (connections < 20) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  Color _getSlowQueriesColor(int slowQueries) {
    if (slowQueries == 0) return Colors.greenAccent;
    if (slowQueries < 5) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  Color _getUsageColor(double usage) {
    if (usage < 70) return Colors.greenAccent;
    if (usage < 90) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  Color _getMethodColor(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
        return Colors.green;
      case 'POST':
        return Colors.blue;
      case 'PUT':
        return Colors.orange;
      case 'DELETE':
        return Colors.red;
      case 'PATCH':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
