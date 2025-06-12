import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:math';

class PrometheusMonitorScreen extends StatefulWidget {
  const PrometheusMonitorScreen({super.key});

  @override
  State<PrometheusMonitorScreen> createState() => _PrometheusMonitorScreenState();
}

class _PrometheusMonitorScreenState extends State<PrometheusMonitorScreen> {
  Timer? _refreshTimer;
  Timer? _notificationTimer;
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _dashboardData;
  DateTime? _lastUpdate;
  int _retryCount = 0;
  int _connectionAttempts = 0;
  bool _isRetrying = false;
  List<Map<String, dynamic>> _criticalAlerts = [];
  String _connectionStatus = 'CONNECTING';
  // Enhanced API configuration
  static const String _apiUrl = 'http://34.140.122.146:3003/api/dashboard/personal';
  static const int _maxRetries = 3;
  static const Duration _retryBaseDelay = Duration(seconds: 2);  static const Duration _refreshInterval = Duration(seconds: 30);
  static const Duration _requestTimeout = Duration(seconds: 15);

  // Safe date parsing helper
  DateTime _safeParseDatetime(String? dateTimeString) {
    if (dateTimeString == null || dateTimeString.isEmpty) {
      return DateTime.now();
    }
    
    try {
      return DateTime.parse(dateTimeString);
    } catch (e) {
      // Log the error for debugging but don't crash the app
      debugPrint('⚠️ PrometheusMonitor: Invalid date format: $dateTimeString, error: $e');
      return DateTime.now(); // Return current time as fallback
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeMonitoring();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _notificationTimer?.cancel();
    super.dispose();
  }

  void _initializeMonitoring() {
    _loadDashboardData();
    _startAutoRefresh();
    _startNotificationSystem();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(_refreshInterval, (_) {
      if (mounted && !_isRetrying) _loadDashboardData();
    });
  }

  void _startNotificationSystem() {
    _notificationTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) _checkCriticalAlerts();
    });
  }

  Future<void> _loadDashboardData() async {
    if (_isRetrying) return;

    try {
      _connectionAttempts++;
      setState(() {
        _connectionStatus = 'CONNECTING';
        if (_retryCount == 0) _isLoading = true;
      });

      final response = await http.get(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'Flutter-Dashboard/1.0',
        },
      ).timeout(_requestTimeout);

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _dashboardData = data;
          _isLoading = false;
          _error = null;
          _lastUpdate = DateTime.now();
          _retryCount = 0;
          _connectionStatus = 'LIVE';
        });
        
        _extractCriticalAlerts(data);
        _showConnectionSuccess();
      } else {
        await _handleApiError(response.statusCode, response.body);
      }
    } catch (e) {
      if (!mounted) return;
      await _handleNetworkError(e);
    }
  }

  Future<void> _handleApiError(int statusCode, String responseBody) async {
    String errorMessage;
    switch (statusCode) {
      case 400:
        errorMessage = 'Bad Request: Invalid parameters';
        break;
      case 500:
        errorMessage = 'Internal Server Error: Backend issue';
        break;
      case 502:
        errorMessage = 'Bad Gateway: Prometheus unreachable';
        break;
      case 503:
        errorMessage = 'Service Unavailable: System temporarily down';
        break;
      default:
        errorMessage = 'API Error: Server returned status $statusCode';
    }

    setState(() {
      _connectionStatus = 'ERROR';
      _error = '$errorMessage\n\nStatus Code: $statusCode\nAPI: $_apiUrl';
      _isLoading = false;
    });

    await _retryWithBackoff();
  }

  Future<void> _handleNetworkError(dynamic error) async {
    String errorDetails = _analyzeNetworkError(error);
    
    setState(() {
      _connectionStatus = 'OFFLINE';
      _error = 'Connection Error: $errorDetails\n\nAPI: $_apiUrl\nAttempts: $_connectionAttempts';
      _isLoading = false;
    });

    await _retryWithBackoff();
  }

  String _analyzeNetworkError(dynamic error) {
    String errorStr = error.toString().toLowerCase();
    
    if (errorStr.contains('timeout')) {
      return 'Request timeout - Server too slow to respond';
    } else if (errorStr.contains('connection refused')) {
      return 'Connection refused - Server may be down';
    } else if (errorStr.contains('network is unreachable')) {
      return 'Network unreachable - Check internet connection';
    } else if (errorStr.contains('no route to host')) {
      return 'No route to host - Network connectivity issue';
    } else if (errorStr.contains('socket')) {
      return 'Socket error - Network connection problem';
    } else {
      return error.toString();
    }
  }

  Future<void> _retryWithBackoff() async {
    if (_retryCount >= _maxRetries || _isRetrying) return;

    setState(() => _isRetrying = true);
    
    final delaySeconds = pow(2, _retryCount) * _retryBaseDelay.inSeconds;
    final maxDelay = 30;
    final actualDelay = min(delaySeconds.toInt(), maxDelay);
    
    setState(() {
      _connectionStatus = 'RETRYING';
    });

    await Future.delayed(Duration(seconds: actualDelay));
    
    if (mounted) {
      _retryCount++;
      setState(() => _isRetrying = false);
      await _loadDashboardData();
    }
  }

  void _extractCriticalAlerts(Map<String, dynamic> data) {
    _criticalAlerts.clear();
    
    // System health alerts
    final systemHealth = data['system_health'] ?? {};
    final overallStatus = systemHealth['overall_status'] ?? '';
    if (overallStatus != 'HEALTHY') {
      _criticalAlerts.add({
        'type': 'SYSTEM_HEALTH',
        'severity': 'CRITICAL',
        'message': 'System health status: $overallStatus',
        'timestamp': DateTime.now(),
      });
    }    // Security alerts
    final securityMetrics = data['security_metrics'] ?? {};
    final securityAlerts = securityMetrics['security_alerts'] as List? ?? [];
    for (final alert in securityAlerts) {
      if (alert['severity'] == 'HIGH' || alert['severity'] == 'CRITICAL') {
        _criticalAlerts.add({
          'type': 'SECURITY',
          'severity': alert['severity'],
          'message': alert['message'],
          'timestamp': _safeParseDatetime(alert['timestamp']),
        });
      }
    }

    // Resource usage alerts
    final resourceUsage = systemHealth['resource_usage'] ?? {};
    final cpuUsage = resourceUsage['cpu_usage_percent'] ?? 0;
    final memoryUsage = resourceUsage['memory_usage_percent'] ?? 0;
    
    if (cpuUsage > 90) {
      _criticalAlerts.add({
        'type': 'RESOURCE',
        'severity': 'CRITICAL',
        'message': 'CPU usage critical: ${cpuUsage.toStringAsFixed(1)}%',
        'timestamp': DateTime.now(),
      });
    }
    
    if (memoryUsage > 90) {
      _criticalAlerts.add({
        'type': 'RESOURCE',
        'severity': 'CRITICAL',
        'message': 'Memory usage critical: ${memoryUsage.toStringAsFixed(1)}%',
        'timestamp': DateTime.now(),
      });
    }
  }

  void _checkCriticalAlerts() {
    if (_criticalAlerts.isNotEmpty) {
      _showCriticalAlert(_criticalAlerts.first);
    }
  }

  void _showCriticalAlert(Map<String, dynamic> alert) {
    if (!mounted) return;
    
    HapticFeedback.vibrate();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _getAlertColor(alert['severity']),
        content: Row(
          children: [
            Icon(
              _getAlertIcon(alert['type']),
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${alert['severity']}: ${alert['message']}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 8),
        action: SnackBarAction(
          label: 'DISMISS',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  void _showConnectionSuccess() {
    if (_retryCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Connection restored successfully', 
                style: TextStyle(color: Colors.white)),
            ],
          ),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Color _getAlertColor(String severity) {
    switch (severity) {
      case 'CRITICAL': return Colors.red;
      case 'HIGH': return Colors.orange;
      case 'MEDIUM': return Colors.yellow[700]!;
      default: return Colors.blue;
    }
  }

  IconData _getAlertIcon(String type) {
    switch (type) {
      case 'SYSTEM_HEALTH': return Icons.warning;
      case 'SECURITY': return Icons.security;
      case 'RESOURCE': return Icons.memory;
      default: return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F23),
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              'Prometheus Monitor',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(width: 8),
            _buildConnectionStatusChip(),
          ],
        ),
        backgroundColor: const Color(0xFF1A1A2E),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          // Quick Stats Bar
          if (_dashboardData != null && _error == null)
            Expanded(
              child: _buildQuickStatsBar(),
            ),
          // Alerts indicator
          if (_criticalAlerts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildAlertsIndicator(),
            ),
          // Retry button when error
          if (_error != null && !_isRetrying)
            IconButton(
              icon: const Icon(Icons.replay),
              onPressed: () {
                _retryCount = 0;
                _loadDashboardData();
              },
              tooltip: 'Retry Connection',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isRetrying ? null : _loadDashboardData,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        backgroundColor: const Color(0xFF1A1A2E),
        color: const Color(0xFF667eea),
        child: _buildBody(),
      ),
      floatingActionButton: _buildFloatingActions(),
    );
  }

  Widget _buildConnectionStatusChip() {
    Color chipColor;
    IconData chipIcon;
    String chipText;
    
    switch (_connectionStatus) {
      case 'LIVE':
        chipColor = Colors.green;
        chipIcon = Icons.circle;
        chipText = 'LIVE';
        break;
      case 'CONNECTING':
        chipColor = Colors.orange;
        chipIcon = Icons.access_time;
        chipText = 'CONNECTING';
        break;
      case 'RETRYING':
        chipColor = Colors.yellow;
        chipIcon = Icons.refresh;
        chipText = 'RETRYING';
        break;
      case 'ERROR':
        chipColor = Colors.red;
        chipIcon = Icons.error;
        chipText = 'ERROR';
        break;
      case 'OFFLINE':
        chipColor = Colors.grey;
        chipIcon = Icons.offline_bolt;
        chipText = 'OFFLINE';
        break;
      default:
        chipColor = Colors.grey;
        chipIcon = Icons.help;
        chipText = 'UNKNOWN';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(chipIcon, color: chipColor, size: 12),
          const SizedBox(width: 4),
          Text(
            chipText,
            style: TextStyle(
              color: chipColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsIndicator() {
    if (_criticalAlerts.isEmpty) return const SizedBox();
    
    return GestureDetector(
      onTap: _showAlertsDialog,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning, color: Colors.red, size: 14),
            const SizedBox(width: 4),
            Text(
              '${_criticalAlerts.length}',
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildFloatingActions() {
    if (_error != null) return null;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_criticalAlerts.isNotEmpty)
          FloatingActionButton.small(
            heroTag: "alerts",
            backgroundColor: Colors.red,
            onPressed: _showAlertsDialog,
            child: const Icon(Icons.warning, color: Colors.white),
          ),
        const SizedBox(height: 8),
        FloatingActionButton.small(
          heroTag: "settings",
          backgroundColor: const Color(0xFF667eea),
          onPressed: _showSettingsDialog,
          child: const Icon(Icons.settings, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildQuickStatsBar() {
    if (_dashboardData == null) return const SizedBox();
    
    final systemHealth = _dashboardData!['system_health'] ?? {};
    final overallStatus = systemHealth['overall_status'] ?? 'UNKNOWN';
    final resourceUsage = systemHealth['resource_usage'] ?? {};
    final performance = systemHealth['performance'] ?? {};
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // System Status
          _buildQuickStat(
            overallStatus,
            _getSystemHealthColor(overallStatus),
            Icons.health_and_safety,
          ),
          const SizedBox(width: 8),
          // CPU Usage
          _buildQuickStat(
            '${(resourceUsage['cpu_usage_percent'] ?? 0).toStringAsFixed(0)}%',
            _getUsageColor(resourceUsage['cpu_usage_percent'] ?? 0),
            Icons.developer_board,
          ),
          const SizedBox(width: 8),
          // Memory Usage
          _buildQuickStat(
            '${(resourceUsage['memory_usage_percent'] ?? 0).toStringAsFixed(0)}%',
            _getUsageColor(resourceUsage['memory_usage_percent'] ?? 0),
            Icons.memory,
          ),
          const SizedBox(width: 8),
          // Response Time
          _buildQuickStat(
            '${(performance['avg_response_time_ms'] ?? 0).toStringAsFixed(0)}ms',
            _getResponseTimeColor(performance['avg_response_time_ms'] ?? 0),
            Icons.speed,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getSystemHealthColor(String status) {
    switch (status.toUpperCase()) {
      case 'HEALTHY': return Colors.green;
      case 'WARNING': return Colors.orange;
      case 'CRITICAL': return Colors.red;
      default: return Colors.grey;
    }
  }

  Color _getUsageColor(double usage) {
    if (usage >= 90) return Colors.red;
    if (usage >= 70) return Colors.orange;
    if (usage >= 50) return Colors.yellow;
    return Colors.green;
  }

  Color _getResponseTimeColor(double responseTime) {
    if (responseTime >= 1000) return Colors.red;
    if (responseTime >= 500) return Colors.orange;
    if (responseTime >= 200) return Colors.yellow;
    return Colors.green;
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: Color(0xFF667eea),
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            Text(
              _isRetrying ? 'Retrying connection...' : 'Loading dashboard data...',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            if (_retryCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Attempt ${_retryCount + 1} of $_maxRetries',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontSize: 14,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_dashboardData == null) {
      return _buildNoDataState();
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dashboard Header with last update
          _buildDashboardHeader(),
          const SizedBox(height: 16),
          
          // Critical Alerts Banner
          if (_criticalAlerts.isNotEmpty)
            _buildCriticalAlertsBanner(),
          
          // System Health Section - Enhanced
          _buildSystemHealthSection(),
          const SizedBox(height: 24),
          
          // Security Metrics Section - Comprehensive
          _buildSecurityMetricsSection(),
          const SizedBox(height: 24),
          
          // Analytics Section - QR & User Behavior
          _buildAnalyticsSection(),
          const SizedBox(height: 24),
          
          // Performance & Resource Usage
          _buildPerformanceSection(),
          const SizedBox(height: 24),
          
          // Database & API Metrics
          _buildDatabaseApiSection(),
          const SizedBox(height: 24),
          
          // Real-time Activity Feed
          _buildActivityFeedSection(),
          
          // Footer with API info
          _buildFooterInfo(),
        ],
      ),
    );
  }

  // Continue with the remaining build methods...
  Widget _buildDashboardHeader() {
    final metadata = _dashboardData!['metadata'] ?? {};
    final userInfo = _dashboardData!['user_info'] ?? {};
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Prometheus Dashboard',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  metadata['api_version'] ?? 'v1.0.0',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (userInfo['username'] != null)
            Text(
              'User: ${userInfo['username']} (${userInfo['role'] ?? 'User'})',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          if (_lastUpdate != null)
            Text(
              'Last updated: ${_formatTimestamp(_lastUpdate!)}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCriticalAlertsBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${_criticalAlerts.length} Critical Alert${_criticalAlerts.length > 1 ? 's' : ''} - Tap to view details',
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: _showAlertsDialog,
            child: const Text('VIEW', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemHealthSection() {
    final systemHealth = _dashboardData!['system_health'] ?? {};
    final overallStatus = systemHealth['overall_status'] ?? 'UNKNOWN';
    final services = systemHealth['services'] as List? ?? [];
    final performance = systemHealth['performance'] ?? {};
    final resourceUsage = systemHealth['resource_usage'] ?? {};

    return _buildSection(
      title: 'System Health',
      icon: Icons.health_and_safety,
      children: [
        // Overall Status Card
        _buildMetricCard(
          'Overall Status',
          overallStatus,
          _getSystemHealthColor(overallStatus),
          Icons.circle,
        ),
        
        // Performance Metrics
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Avg Response Time',
                '${(performance['avg_response_time_ms'] ?? 0).toStringAsFixed(1)}ms',
                _getResponseTimeColor(performance['avg_response_time_ms'] ?? 0),
                Icons.speed,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Error Rate',
                '${(performance['error_rate_percent'] ?? 0).toStringAsFixed(1)}%',
                _getErrorRateColor(performance['error_rate_percent'] ?? 0),
                Icons.error_outline,
              ),
            ),
          ],
        ),
        
        // Resource Usage with Progress Bars
        _buildResourceUsageCard(resourceUsage),
        
        // Services Status
        if (services.isNotEmpty)
          _buildServicesStatusCard(services),
      ],
    );
  }

  Widget _buildResourceUsageCard(Map<String, dynamic> resourceUsage) {
    final cpuUsage = (resourceUsage['cpu_usage_percent'] ?? 0).toDouble();
    final memoryUsage = (resourceUsage['memory_usage_percent'] ?? 0).toDouble();
    final diskUsage = (resourceUsage['disk_usage_percent'] ?? 0).toDouble();
    final networkUsage = (resourceUsage['network_usage_percent'] ?? 0).toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resource Usage',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildProgressBar('CPU', cpuUsage, _getUsageColor(cpuUsage)),
          const SizedBox(height: 12),
          _buildProgressBar('Memory', memoryUsage, _getUsageColor(memoryUsage)),
          const SizedBox(height: 12),
          _buildProgressBar('Disk', diskUsage, _getUsageColor(diskUsage)),
          const SizedBox(height: 12),
          _buildProgressBar('Network', networkUsage, _getUsageColor(networkUsage)),
        ],
      ),
    );
  }

  Widget _buildProgressBar(String label, double value, Color color) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70)),
            Text('${value.toStringAsFixed(1)}%', 
              style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: value / 100,
          backgroundColor: Colors.grey[800],
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ],
    );
  }

  Widget _buildServicesStatusCard(List services) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Services Status',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...services.map((service) => _buildServiceItem(service)).toList(),
        ],
      ),
    );
  }

  Widget _buildServiceItem(Map<String, dynamic> service) {
    final status = service['status'] ?? 'UNKNOWN';
    final name = service['name'] ?? 'Unknown Service';
    final responseTime = service['response_time_ms'] ?? 0;
    final uptime = service['uptime_percent'] ?? 0;
    
    final statusColor = status == 'UP' ? Colors.green : Colors.red;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(name, style: const TextStyle(color: Colors.white)),
          ),
          Text(
            '${responseTime.toStringAsFixed(1)}ms',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(width: 8),
          Text(
            '${uptime.toStringAsFixed(1)}%',
            style: TextStyle(
              color: uptime > 99 ? Colors.green : Colors.orange,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Continue with more comprehensive sections...
  
  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.blue, size: 24),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, Color color, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
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

  Color _getErrorRateColor(double errorRate) {
    if (errorRate >= 5) return Colors.red;
    if (errorRate >= 2) return Colors.orange;
    if (errorRate >= 1) return Colors.yellow;
    return Colors.green;
  }

  // Add all the missing methods for the comprehensive dashboard sections
  Widget _buildSecurityMetricsSection() {
    final securityMetrics = _dashboardData!['security_metrics'] ?? {};
    final authStats = securityMetrics['authentication_stats'] ?? {};
    final activeSessions = securityMetrics['active_sessions'] ?? {};
    final securityAlerts = securityMetrics['security_alerts'] as List? ?? [];

    return _buildSection(
      title: 'Security Metrics',
      icon: Icons.security,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Success Rate',
                '${(authStats['success_rate_percent'] ?? 0).toStringAsFixed(1)}%',
                _getSuccessRateColor(authStats['success_rate_percent'] ?? 0),
                Icons.check_circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Active Sessions',
                '${activeSessions['total_active'] ?? 0}',
                Colors.blue,
                Icons.people,
              ),
            ),
          ],
        ),
        if (securityAlerts.isNotEmpty)
          _buildSecurityAlertsCard(securityAlerts),
      ],
    );
  }

  Widget _buildAnalyticsSection() {
    final analytics = _dashboardData!['analytics'] ?? {};
    final qrAnalytics = analytics['qr_code_analytics'] ?? {};
    final userBehavior = analytics['user_behavior'] ?? {};
    final attendanceStats = analytics['attendance_stats'] ?? {};

    return _buildSection(
      title: 'Analytics & User Behavior',
      icon: Icons.analytics,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'QR Scans (24h)',
                '${qrAnalytics['total_scans_24h'] ?? 0}',
                Colors.green,
                Icons.qr_code_scanner,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Attendance Rate',
                '${(attendanceStats['attendance_rate_percent'] ?? 0).toStringAsFixed(1)}%',
                _getSuccessRateColor(attendanceStats['attendance_rate_percent'] ?? 0),
                Icons.how_to_reg,
              ),
            ),
          ],
        ),
        _buildUserActivityCard(userBehavior),
      ],
    );
  }

  Widget _buildPerformanceSection() {
    final analytics = _dashboardData!['analytics'] ?? {};
    final apiStats = analytics['api_usage_stats'] ?? {};
    final systemHealth = _dashboardData!['system_health'] ?? {};
    final performance = systemHealth['performance'] ?? {};

    return _buildSection(
      title: 'Performance Metrics',
      icon: Icons.speed,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Requests/sec',
                '${(performance['requests_per_second'] ?? 0).toStringAsFixed(1)}',
                Colors.blue,
                Icons.trending_up,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Throughput',
                '${(performance['throughput_mbps'] ?? 0).toStringAsFixed(1)} Mbps',
                Colors.purple,
                Icons.network_check,
              ),
            ),
          ],
        ),
        if (apiStats['top_endpoints'] != null)
          _buildTopEndpointsCard(apiStats['top_endpoints']),
      ],
    );
  }

  Widget _buildDatabaseApiSection() {
    final analytics = _dashboardData!['analytics'] ?? {};
    final dbMetrics = analytics['database_metrics'] ?? {};

    return _buildSection(
      title: 'Database & Cache',
      icon: Icons.storage,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Cache Hit Rate',
                '${(dbMetrics['cache_hit_rate_percent'] ?? 0).toStringAsFixed(1)}%',
                _getSuccessRateColor(dbMetrics['cache_hit_rate_percent'] ?? 0),
                Icons.cached,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Queries/sec',
                '${(dbMetrics['queries_per_second'] ?? 0).toStringAsFixed(1)}',
                Colors.teal,
                Icons.query_stats,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Active Connections',
                '${dbMetrics['connections_active'] ?? 0}',
                Colors.orange,
                Icons.link,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Database Size',
                dbMetrics['database_size'] ?? 'N/A',
                Colors.indigo,
                Icons.data_usage,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActivityFeedSection() {
    final analytics = _dashboardData!['analytics'] ?? {};
    final userBehavior = analytics['user_behavior'] ?? {};
    final mostActiveUsers = userBehavior['most_active_users'] as List? ?? [];

    return _buildSection(
      title: 'Real-time Activity',
      icon: Icons.timeline,
      children: [
        if (mostActiveUsers.isNotEmpty)
          _buildActivityFeedCard(mostActiveUsers),
      ],
    );
  }

  Widget _buildFooterInfo() {
    final metadata = _dashboardData!['metadata'] ?? {};
    
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E).withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Data Source: ${metadata['data_source'] ?? 'prometheus'}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              Text(
                'API Version: ${metadata['api_version'] ?? 'v1.0.0'}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Connection Attempts: $_connectionAttempts | Last Refresh: ${_lastUpdate != null ? _formatTimestamp(_lastUpdate!) : 'Never'}',
            style: const TextStyle(color: Colors.grey, fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Helper methods for building specific cards
  Widget _buildSecurityAlertsCard(List securityAlerts) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Security Alerts',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...securityAlerts.take(3).map((alert) => _buildAlertItem(alert)).toList(),
          if (securityAlerts.length > 3)
            TextButton(
              onPressed: _showAlertsDialog,
              child: Text('View all ${securityAlerts.length} alerts'),
            ),
        ],
      ),
    );
  }

  Widget _buildAlertItem(Map<String, dynamic> alert) {
    final severity = alert['severity'] ?? 'INFO';
    final color = _getAlertColor(severity);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(_getAlertIcon(alert['type']), color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              alert['message'] ?? 'Unknown alert',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          Chip(
            label: Text(severity, style: const TextStyle(fontSize: 10)),
            backgroundColor: color,
          ),
        ],
      ),
    );
  }

  Widget _buildUserActivityCard(Map<String, dynamic> userBehavior) {
    final mostActiveUsers = userBehavior['most_active_users'] as List? ?? [];
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Most Active Users',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...mostActiveUsers.take(5).map((user) => _buildUserActivityItem(user)).toList(),
        ],
      ),
    );
  }

  Widget _buildUserActivityItem(Map<String, dynamic> user) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.person, color: Colors.blue, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              user['username'] ?? 'Unknown',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          Text(
            '${user['activity_count'] ?? 0} actions',
            style: const TextStyle(color: Colors.grey, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildTopEndpointsCard(List topEndpoints) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top API Endpoints',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...topEndpoints.take(5).map((endpoint) => _buildEndpointItem(endpoint)).toList(),
        ],
      ),
    );
  }

  Widget _buildEndpointItem(Map<String, dynamic> endpoint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.api, color: Colors.purple, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              endpoint['endpoint'] ?? 'Unknown',
              style: const TextStyle(color: Colors.white, fontSize: 11),
            ),
          ),
          Text(
            '${endpoint['request_count'] ?? 0} req',
            style: const TextStyle(color: Colors.grey, fontSize: 10),
          ),
          const SizedBox(width: 8),
          Text(
            '${(endpoint['avg_response_ms'] ?? 0).toStringAsFixed(0)}ms',
            style: TextStyle(
              color: _getResponseTimeColor(endpoint['avg_response_ms'] ?? 0),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityFeedCard(List mostActiveUsers) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Live Activity Feed',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...mostActiveUsers.take(3).map((user) => _buildActivityFeedItem(user)).toList(),
        ],
      ),
    );
  }

  Widget _buildActivityFeedItem(Map<String, dynamic> user) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.flash_on, color: Colors.green, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${user['username']} - ${user['activity_count']} actions',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),          ),
          Text(
            _formatTimestamp(_safeParseDatetime(user['last_active'])),
            style: const TextStyle(color: Colors.grey, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Color _getSuccessRateColor(double rate) {
    if (rate >= 95) return Colors.green;
    if (rate >= 90) return Colors.yellow;
    if (rate >= 80) return Colors.orange;
    return Colors.red;
  }

  // Error and No Data states
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _connectionStatus == 'OFFLINE' ? Icons.wifi_off : Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              _connectionStatus == 'OFFLINE' ? 'Connection Lost' : 'Connection Error',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error occurred',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            if (!_isRetrying) ...[
              ElevatedButton.icon(
                onPressed: () {
                  _retryCount = 0;
                  _loadDashboardData();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry Connection'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF667eea),
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _showSettingsDialog,
                child: const Text(
                  'Connection Settings',
                  style: TextStyle(color: Colors.blue),
                ),
              ),
            ] else ...[
              const CircularProgressIndicator(color: Color(0xFF667eea)),
              const SizedBox(height: 12),
              Text(
                'Retrying... (${_retryCount + 1}/$_maxRetries)',
                style: const TextStyle(color: Colors.orange),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.dashboard,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'No Data Available',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Dashboard data is empty or invalid',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _showAlertsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          'Critical Alerts',
          style: TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _criticalAlerts.length,
            itemBuilder: (context, index) {
              final alert = _criticalAlerts[index];
              return Card(
                color: const Color(0xFF16213E),
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(
                    _getAlertIcon(alert['type']),
                    color: _getAlertColor(alert['severity']),
                  ),
                  title: Text(
                    alert['message'],
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  subtitle: Text(
                    _formatTimestamp(alert['timestamp']),
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  trailing: Chip(
                    label: Text(
                      alert['severity'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: _getAlertColor(alert['severity']),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          'Monitor Settings',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.timer, color: Colors.blue),
              title: const Text(
                'Auto Refresh',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Every 30 seconds',
                style: TextStyle(color: Colors.grey),
              ),
              trailing: Switch(
                value: _refreshTimer?.isActive ?? false,
                onChanged: (value) {
                  if (value) {
                    _startAutoRefresh();
                  } else {
                    _refreshTimer?.cancel();
                  }
                  Navigator.of(context).pop();
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.notifications, color: Colors.orange),
              title: const Text(
                'Critical Alerts',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Real-time notifications',
                style: TextStyle(color: Colors.grey),
              ),
              trailing: Switch(
                value: _notificationTimer?.isActive ?? false,
                onChanged: (value) {
                  if (value) {
                    _startNotificationSystem();
                  } else {
                    _notificationTimer?.cancel();
                  }
                  Navigator.of(context).pop();
                },
              ),
            ),
            const Divider(color: Colors.grey),
            ListTile(
              leading: const Icon(Icons.info, color: Colors.blue),
              title: const Text(
                'Connection Info',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'API: $_apiUrl',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  Text(
                    'Attempts: $_connectionAttempts',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  if (_lastUpdate != null)
                    Text(
                      'Last Update: ${_formatTimestamp(_lastUpdate!)}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    
    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}
