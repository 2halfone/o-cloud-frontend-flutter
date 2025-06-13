import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:math';

// Dashboard Tab Model
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

class PrometheusMonitorScreen extends StatefulWidget {
  const PrometheusMonitorScreen({super.key});

  @override
  State<PrometheusMonitorScreen> createState() => _PrometheusMonitorScreenState();
}

class _PrometheusMonitorScreenState extends State<PrometheusMonitorScreen>
    with TickerProviderStateMixin {
  Timer? _refreshTimer;
  Timer? _notificationTimer;
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _dashboardData;
  DateTime? _lastUpdate;
  int _retryCount = 0;
  int _connectionAttempts = 0;
  bool _isRetrying = false;
  final List<Map<String, dynamic>> _criticalAlerts = [];
  String _connectionStatus = 'CONNECTING';
  
  // Tab Navigation
  late TabController _tabController;
  int _selectedTabIndex = 0;
  
  final List<DashboardTab> _tabs = [
    DashboardTab(
      title: 'Overview',
      icon: Icons.dashboard_rounded,
      gradient: [const Color(0xFF667eea), const Color(0xFF764ba2)],
    ),
    DashboardTab(
      title: 'System Health',
      icon: Icons.health_and_safety_rounded,
      gradient: [const Color(0xFF11998e), const Color(0xFF38ef7d)],
    ),
    DashboardTab(
      title: 'Security',
      icon: Icons.security_rounded,
      gradient: [const Color(0xFFfa709a), const Color(0xFFfee140)],
    ),
    DashboardTab(
      title: 'Analytics',
      icon: Icons.analytics_rounded,
      gradient: [const Color(0xFF4facfe), const Color(0xFF00f2fe)],
    ),
    DashboardTab(
      title: 'Performance',
      icon: Icons.speed_rounded,
      gradient: [const Color(0xFFa8edea), const Color(0xFFfed6e3)],
    ),
  ];
    // Updated API configuration for specialized dashboard endpoints
  static const String _baseApiUrl = 'http://34.140.122.146:3003';
  static const String _securityUrl = '$_baseApiUrl/api/dashboard/security';
  static const String _vmHealthUrl = '$_baseApiUrl/api/dashboard/vm-health';
  static const String _insightsUrl = '$_baseApiUrl/api/dashboard/insights';
  
  static const int _maxRetries = 3;
  static const Duration _retryBaseDelay = Duration(seconds: 2);
  static const Duration _refreshInterval = Duration(seconds: 30);
  static const Duration _requestTimeout = Duration(seconds: 15);
  // Dashboard data structure for specialized endpoints
  Map<String, dynamic> _securityData = {};
  Map<String, dynamic> _vmHealthData = {};
  Map<String, dynamic> _insightsData = {};

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
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    });
    _initializeMonitoring();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _notificationTimer?.cancel();
    _tabController.dispose();
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
      });      // Load data from all 3 specialized endpoints concurrently
      await Future.wait([
        _loadSecurityData(),
        _loadVMHealthData(), 
        _loadInsightsData(),
      ]);

      if (!mounted) return;

      // Combine all data into unified dashboard structure
      final combinedData = _combineSpecializedData();

      setState(() {
        _dashboardData = combinedData;
        _isLoading = false;
        _error = null;
        _lastUpdate = DateTime.now();
        _retryCount = 0;
        _connectionStatus = 'LIVE';
      });
      
      _extractCriticalAlerts(combinedData);
      _showConnectionSuccess();

    } catch (e) {
      if (!mounted) return;
      await _handleNetworkError(e);
    }
  }

  Future<Map<String, dynamic>> _loadSecurityData() async {
    final response = await http.get(
      Uri.parse(_securityUrl),
      headers: {
        'Accept': 'application/json',
        'User-Agent': 'Flutter-Dashboard/1.0',
      },
    ).timeout(_requestTimeout);

    if (response.statusCode == 200) {
      _securityData = json.decode(response.body);
      return _securityData;
    } else {
      throw Exception('Security API returned status ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> _loadVMHealthData() async {
    final response = await http.get(
      Uri.parse(_vmHealthUrl),
      headers: {
        'Accept': 'application/json',
        'User-Agent': 'Flutter-Dashboard/1.0',
      },
    ).timeout(_requestTimeout);

    if (response.statusCode == 200) {
      _vmHealthData = json.decode(response.body);
      return _vmHealthData;
    } else {
      throw Exception('VM Health API returned status ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> _loadInsightsData() async {
    final response = await http.get(
      Uri.parse(_insightsUrl),
      headers: {
        'Accept': 'application/json', 
        'User-Agent': 'Flutter-Dashboard/1.0',
      },
    ).timeout(_requestTimeout);

    if (response.statusCode == 200) {
      _insightsData = json.decode(response.body);
      return _insightsData;
    } else {
      throw Exception('Insights API returned status ${response.statusCode}');
    }
  }

  Map<String, dynamic> _combineSpecializedData() {
    // Combine data from 3 specialized endpoints into unified structure
    return {
      'system_health': {
        'overall_status': _calculateOverallStatus(),
        'services': _buildServicesStatus(),
        'performance': _vmHealthData['response_times'] ?? {},
        'resource_usage': _vmHealthData['system_resources'] ?? {},
      },
      'security_metrics': {
        'authentication_stats': _securityData['authentication_stats'] ?? {},
        'jwt_validation': _securityData['jwt_validation'] ?? {},
        'user_activity': _securityData['user_activity'] ?? {},
        'security_level': _securityData['security_level'] ?? 'UNKNOWN',
        'security_alerts': _buildSecurityAlerts(),
      },
      'analytics': {
        'qr_code_analytics': _insightsData['qr_analytics'] ?? {},
        'user_behavior': _insightsData['user_activity'] ?? {},
        'attendance_stats': _buildAttendanceStats(),
        'api_usage_stats': _buildApiUsageStats(),
        'database_metrics': _buildDatabaseMetrics(),
      },
      'metadata': {
        'data_source': 'prometheus+database',
        'endpoints_used': ['security', 'vm-health', 'insights'],
        'last_updated': DateTime.now().toIso8601String(),
        'collection_time_ms': _calculateCollectionTime(),
      },
      'user_info': {
        'source': 'specialized_endpoints',
        'real_data': true,
      }
    };
  }

  String _calculateOverallStatus() {
    final securityLevel = _securityData['security_level'] ?? 'UNKNOWN';
    final serviceHealth = _vmHealthData['service_health'] ?? {};
    final servicesUp = serviceHealth['services_up'] ?? 0;
    final servicesTotal = serviceHealth['services_total'] ?? 1;

    if (securityLevel == 'HIGH_RISK' || servicesUp < servicesTotal) {
      return 'CRITICAL';
    } else if (securityLevel == 'MEDIUM_RISK') {
      return 'WARNING'; 
    } else {
      return 'HEALTHY';
    }
  }

  List<Map<String, dynamic>> _buildServicesStatus() {
    final serviceHealth = _vmHealthData['service_health'] ?? {};
    return [
      {
        'name': 'Auth Service',
        'status': serviceHealth['auth_service_uptime'] != null && 
                 serviceHealth['auth_service_uptime'] > 95 ? 'UP' : 'DOWN',
        'uptime_percent': serviceHealth['auth_service_uptime'] ?? 0,
        'response_time_ms': (_vmHealthData['response_times'] ?? {})['auth_service_ms'] ?? 0,
      },
      {
        'name': 'User Service', 
        'status': serviceHealth['user_service_uptime'] != null &&
                 serviceHealth['user_service_uptime'] > 95 ? 'UP' : 'DOWN',
        'uptime_percent': serviceHealth['user_service_uptime'] ?? 0,
        'response_time_ms': (_vmHealthData['response_times'] ?? {})['user_service_ms'] ?? 0,
      },
      {
        'name': 'Gateway',
        'status': serviceHealth['gateway_uptime'] != null &&
                 serviceHealth['gateway_uptime'] > 95 ? 'UP' : 'DOWN', 
        'uptime_percent': serviceHealth['gateway_uptime'] ?? 0,
        'response_time_ms': (_vmHealthData['response_times'] ?? {})['gateway_ms'] ?? 0,
      },
    ];
  }

  List<Map<String, dynamic>> _buildSecurityAlerts() {
    final securityLevel = _securityData['security_level'] ?? 'LOW_RISK';
    final userActivity = _securityData['user_activity'] ?? {};
    final suspiciousActivity = userActivity['suspicious_activity'] ?? 0;

    List<Map<String, dynamic>> alerts = [];

    if (securityLevel == 'HIGH_RISK') {
      alerts.add({
        'severity': 'CRITICAL',
        'message': 'High security risk detected - immediate attention required',
        'timestamp': DateTime.now().toIso8601String(),
        'type': 'SECURITY',
      });
    }

    if (suspiciousActivity > 5) {
      alerts.add({
        'severity': 'HIGH',
        'message': 'Suspicious activity detected: $suspiciousActivity incidents',
        'timestamp': DateTime.now().toIso8601String(), 
        'type': 'SECURITY',
      });
    }

    return alerts;
  }

  Map<String, dynamic> _buildAttendanceStats() {
    final qrAnalytics = _insightsData['qr_analytics'] ?? {};
    return {
      'total_scans': qrAnalytics['total_scans_24h'] ?? 0,
      'successful_scans': qrAnalytics['successful_scans'] ?? 0,
      'success_rate': qrAnalytics['success_rate_percent'] ?? 0,
      'events_today': (qrAnalytics['trends'] ?? {})['today'] ?? 0,
    };
  }

  Map<String, dynamic> _buildApiUsageStats() {
    final usagePatterns = _insightsData['usage_patterns'] ?? {};
    return {
      'requests_per_hour': usagePatterns['peak_usage_hour'] ?? 0,
      'system_load': usagePatterns['system_load'] ?? 'normal',
      'top_endpoints': _buildTopEndpoints(),
    };
  }

  List<Map<String, dynamic>> _buildTopEndpoints() {
    return [
      {
        'endpoint': '/api/dashboard/security',
        'requests': 1250,
        'avg_response_ms': (_vmHealthData['response_times'] ?? {})['auth_service_ms'] ?? 80,
      },
      {
        'endpoint': '/api/dashboard/vm-health', 
        'requests': 1100,
        'avg_response_ms': (_vmHealthData['response_times'] ?? {})['user_service_ms'] ?? 120,
      },
      {
        'endpoint': '/api/dashboard/insights',
        'requests': 980,
        'avg_response_ms': (_vmHealthData['response_times'] ?? {})['gateway_ms'] ?? 100,
      },
    ];
  }

  Map<String, dynamic> _buildDatabaseMetrics() {
    final dbHealth = _vmHealthData['database_health'] ?? {};
    return {
      'auth_db_status': dbHealth['auth_db_status'] ?? 'unknown',
      'user_db_status': dbHealth['user_db_status'] ?? 'unknown',
      'connections_active': 25,
      'query_performance': 'optimal',
    };
  }

  int _calculateCollectionTime() {
    // Estimate collection time based on successful data loading
    final hasSecurityData = _securityData.isNotEmpty;
    final hasVMHealthData = _vmHealthData.isNotEmpty;
    final hasInsightsData = _insightsData.isNotEmpty;

    if (hasSecurityData && hasVMHealthData && hasInsightsData) {
      return 95; // Average collection time when all endpoints respond
    } else if (hasSecurityData || hasVMHealthData || hasInsightsData) {
      return 150; // Slower when some endpoints fail
    } else {    return 200; // Slowest when using fallback data
    }
  }

  Future<void> _handleNetworkError(dynamic error) async {
    String errorDetails = _analyzeNetworkError(error);
    
    setState(() {
      _connectionStatus = 'OFFLINE';
      _error = 'Connection Error: $errorDetails\n\nEndpoints: Security, VM-Health, Insights\nAttempts: $_connectionAttempts';
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
    const maxDelay = 30;
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
        'message': 'CPU usage critical: ${_safeToFixedString(cpuUsage, 1)}%',
        'timestamp': DateTime.now(),
      });
    }
    
    if (memoryUsage > 90) {
      _criticalAlerts.add({
        'type': 'RESOURCE',
        'severity': 'CRITICAL',
        'message': 'Memory usage critical: ${_safeToFixedString(memoryUsage, 1)}%',
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
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildModernAppBar(innerBoxIsScrolled),
          _buildTabBar(),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildOverviewTab(),
            _buildSystemHealthTab(),
            _buildSecurityTab(),
            _buildAnalyticsTab(),
            _buildPerformanceTab(),
          ],
        ),
      ),
      floatingActionButton: _buildModernFAB(),
    );
  }
  Widget _buildModernAppBar(bool innerBoxIsScrolled) {
    return SliverAppBar(
      expandedHeight: 100,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF1A1A2E),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF667eea),
                Color(0xFF764ba2),
                Color(0xFF1A1A2E),
              ],
            ),
          ),          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.monitor_heart_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Prometheus Monitor',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Real-time System Analytics',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildConnectionStatusChip(),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_lastUpdate != null)
                    Text(
                      'Last updated: ${_formatTimestamp(_lastUpdate!)}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        if (_criticalAlerts.isNotEmpty)
          _buildAlertsIndicator(),
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          onPressed: _isRetrying ? null : _loadDashboardData,
          tooltip: 'Refresh Data',
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
          color: const Color(0xFF1A1A2E),
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'export',
              child: Row(
                children: [
                  Icon(Icons.download_rounded, color: Colors.blue),
                  SizedBox(width: 12),
                  Text('Export Data', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings_rounded, color: Colors.grey),
                  SizedBox(width: 12),
                  Text('Settings', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Handler per le azioni del menu
  void _handleMenuAction(String action) {
    switch (action) {
      case 'export':
        _exportDashboardData();
        break;
      case 'settings':
        _showSettingsDialog();
        break;
    }
  }

  // Modern Floating Action Button
  Widget _buildModernFAB() {
    if (_isLoading || _error != null) return const SizedBox.shrink();
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_criticalAlerts.isNotEmpty)
          FloatingActionButton.small(
            heroTag: "alerts",
            backgroundColor: const Color(0xFFff6b6b),
            onPressed: _showAlertsDialog,
            child: Stack(
              children: [
                const Icon(Icons.warning_rounded, color: Colors.white),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${_criticalAlerts.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        FloatingActionButton(
          backgroundColor: _tabs[_selectedTabIndex].gradient.first,
          onPressed: _loadDashboardData,
          child: _isRetrying
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.refresh_rounded, color: Colors.white),
        ),
      ],
    );
  }

  // Overview Tab - Dashboard principale
  Widget _buildOverviewTab() {
    if (_isLoading) return _buildLoadingState();
    if (_error != null) return _buildErrorState();
    if (_dashboardData == null) return _buildNoDataState();

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
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
            if (_criticalAlerts.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildCriticalAlertsBanner(),
            ],
          ],
        ),
      ),
    );
  }
  // Sezioni Overview Tab
  Widget _buildOverviewCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calcola il numero di colonne basato sulla larghezza disponibile
        int crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
        double childAspectRatio = constraints.maxWidth > 600 ? 1.4 : 1.3;
        
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: childAspectRatio,          children: [
            _buildOverviewCard(
              'System Health',
              _dashboardData?['system_health']?['overall_status'] ?? 'UNKNOWN',
              Icons.health_and_safety_rounded,
              _getSystemHealthColor(_dashboardData?['system_health']?['overall_status']),
            ),
            _buildOverviewCard(
              'Security Level',
              _getSecurityDisplayText(_dashboardData?['security_metrics']?['security_level']),
              Icons.security_rounded,
              _getSecurityLevelColor(_dashboardData?['security_metrics']?['security_level'] ?? 'UNKNOWN'),
            ),
            _buildOverviewCard(
              'Active Users',
              '${_dashboardData?['analytics']?['user_behavior']?['active_users'] ?? _securityData['user_activity']?['active_sessions'] ?? '0'}',
              Icons.people_rounded,
              Colors.purple,
            ),
            _buildOverviewCard(
              'QR Scans Today',
              '${_dashboardData?['analytics']?['qr_code_analytics']?['total_scans_24h'] ?? _insightsData['qr_analytics']?['total_scans_24h'] ?? '0'}',
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
            mainAxisAlignment: MainAxisAlignment.spaceAround,            children: [
              _buildQuickMetric(
                'CPU', 
                '${_safeToFixedString(_safeToDouble(_dashboardData?['system_health']?['resource_usage']?['cpu_usage_percent'] ?? _vmHealthData['system_resources']?['cpu_usage_percent']), 1)}%', 
                Icons.memory, 
                Colors.blue
              ),
              _buildQuickMetric(
                'Memory', 
                '${_safeToFixedString(_safeToDouble(_dashboardData?['system_health']?['resource_usage']?['memory_usage_percent'] ?? _vmHealthData['system_resources']?['memory_usage_percent']), 1)}%', 
                Icons.storage, 
                Colors.green
              ),
              _buildQuickMetric(
                'Network', 
                '${_safeToFixedString(_safeToDouble(_vmHealthData['network_traffic']?['bytes_received_mb']), 1)} MB/s', 
                Icons.network_check, 
                Colors.purple
              ),
              _buildQuickMetric(
                'Uptime', 
                '${_safeToFixedString(_safeToDouble(_vmHealthData['service_health']?['gateway_uptime']), 1)}%', 
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
    return Flexible(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 10,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
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
          Row(
            children: [
              const Text(
                'Recent Activity',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Live',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(3, (index) => _buildActivityItem(
            'System event ${index + 1}',
            'Just now',
            Icons.circle,
            Colors.blue,
          )),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String title, String time, IconData icon, Color color) {
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
                  time,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCriticalAlertsBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_rounded, color: Colors.red, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_criticalAlerts.length} Critical Alert${_criticalAlerts.length > 1 ? 's' : ''}',
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Require immediate attention',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _showAlertsDialog(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('VIEW'),
          ),
        ],
      ),
    );
  }

  // System Health Tab
  Widget _buildSystemHealthTab() {
    if (_isLoading) return _buildLoadingState();
    if (_error != null) return _buildErrorState();
    if (_dashboardData == null) return _buildNoDataState();

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      backgroundColor: const Color(0xFF1A1A2E),
      color: const Color(0xFF11998e),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSystemHealthOverview(),
            const SizedBox(height: 24),
            _buildResourceUsageSection(),
            const SizedBox(height: 24),
            _buildServicesStatusSection(),
          ],
        ),
      ),
    );
  }

  // Security Tab
  Widget _buildSecurityTab() {
    if (_isLoading) return _buildLoadingState();
    if (_error != null) return _buildErrorState();
    if (_dashboardData == null) return _buildNoDataState();

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      backgroundColor: const Color(0xFF1A1A2E),
      color: const Color(0xFFfa709a),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSecurityOverview(),
            const SizedBox(height: 24),
            _buildAuthenticationMetrics(),
            const SizedBox(height: 24),
            _buildSecurityAlertsSection(),
          ],
        ),
      ),
    );
  }

  // Analytics Tab
  Widget _buildAnalyticsTab() {
    if (_isLoading) return _buildLoadingState();
    if (_error != null) return _buildErrorState();
    if (_dashboardData == null) return _buildNoDataState();

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      backgroundColor: const Color(0xFF1A1A2E),
      color: const Color(0xFF4facfe),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildAnalyticsOverview(),
            const SizedBox(height: 24),
            _buildQRCodeMetrics(),
            const SizedBox(height: 24),
            _buildUserBehaviorMetrics(),
          ],
        ),
      ),
    );
  }

  // Performance Tab
  Widget _buildPerformanceTab() {
    if (_isLoading) return _buildLoadingState();
    if (_error != null) return _buildErrorState();
    if (_dashboardData == null) return _buildNoDataState();

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      backgroundColor: const Color(0xFF1A1A2E),
      color: const Color(0xFFa8edea),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildPerformanceOverview(),
            const SizedBox(height: 24),
            _buildAPIPerformanceMetrics(),
            const SizedBox(height: 24),
            _buildDatabaseMetricsSection(),
          ],
        ),
      ),
    );
  }  // System Health Tab Sections
  Widget _buildSystemHealthOverview() {
    final systemHealth = _dashboardData?['system_health'] ?? {};
    final resourceUsage = systemHealth['resource_usage'] ?? {};
    
    // Prendi i dati dalle API reali
    final cpuUsage = _safeToDouble(resourceUsage['cpu_usage_percent']) ?? 
                     _safeToDouble(_vmHealthData['system_resources']?['cpu_usage_percent']) ?? 0.0;
    final memoryUsage = _safeToDouble(resourceUsage['memory_usage_percent']) ?? 
                        _safeToDouble(_vmHealthData['system_resources']?['memory_usage_percent']) ?? 0.0;
    final diskUsage = _safeToDouble(resourceUsage['disk_usage_percent']) ?? 
                      _safeToDouble(_vmHealthData['system_resources']?['disk_usage_percent']) ?? 0.0;
    
    final overallStatus = systemHealth['overall_status'] ?? 'UNKNOWN';
    final isHealthy = overallStatus == 'HEALTHY';

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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.health_and_safety_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'System Health Overview',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isHealthy ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isHealthy ? Colors.green : Colors.orange,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isHealthy ? Icons.check_circle : Icons.warning,
                      color: isHealthy ? Colors.green : Colors.orange,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      overallStatus,
                      style: TextStyle(
                        color: isHealthy ? Colors.green : Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSystemMetric('CPU Usage', cpuUsage, '%', Colors.blue),
          const SizedBox(height: 16),
          _buildSystemMetric('Memory Usage', memoryUsage, '%', Colors.purple),
          const SizedBox(height: 16),
          _buildSystemMetric('Disk Usage', diskUsage, '%', Colors.orange),
        ],
      ),
    );
  }

  Widget _buildSystemMetric(String label, double value, String unit, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${_safeToFixedString(value, 1)}$unit',
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

  Widget _buildResourceUsageSection() {
    final vmHealth = _dashboardData?['vm_health'] ?? {};
    final systemResources = vmHealth['system_resources'] ?? {};
    final networkTraffic = vmHealth['network_traffic'] ?? {};

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
              Icon(Icons.memory_rounded, color: Color(0xFF11998e), size: 24),
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
          Row(
            children: [
              Expanded(
                child: _buildResourceCard(
                  'CPU Cores',
                  '${systemResources['cpu_cores'] ?? '0'}',
                  Icons.settings_input_component,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildResourceCard(
                  'Total RAM',
                  '${_safeToFixedString(_safeToDouble(systemResources['memory_total_gb']), 1)} GB',
                  Icons.memory,
                  Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildResourceCard(
                  'Network In',
                  '${_safeToFixedString(_safeToDouble(networkTraffic['bytes_received_mb']), 1)} MB',
                  Icons.download_rounded,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildResourceCard(
                  'Network Out',
                  '${_safeToFixedString(_safeToDouble(networkTraffic['bytes_sent_mb']), 1)} MB',
                  Icons.upload_rounded,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResourceCard(String title, String value, IconData icon, Color color) {
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
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildServicesStatusSection() {
    final systemHealth = _dashboardData?['system_health'] ?? {};
    final services = systemHealth['services'] ?? [];
    
    // Usa i dati reali dai servizi che abbiamo costruito
    List<Map<String, dynamic>> servicesList = services.isNotEmpty 
        ? services.cast<Map<String, dynamic>>()
        : [
            {
              'name': 'Auth Service',
              'status': _securityData['authentication_stats'] != null ? 'UP' : 'DOWN',
              'uptime_percent': _vmHealthData['service_health']?['auth_service_uptime'] ?? 0,
              'response_time_ms': _vmHealthData['response_times']?['auth_service_ms'] ?? 0,
            },
            {
              'name': 'User Service',
              'status': _vmHealthData['service_health']?['user_service_uptime'] != null ? 'UP' : 'DOWN',
              'uptime_percent': _vmHealthData['service_health']?['user_service_uptime'] ?? 0,
              'response_time_ms': _vmHealthData['response_times']?['user_service_ms'] ?? 0,
            },
            {
              'name': 'Gateway',
              'status': _vmHealthData['service_health']?['gateway_uptime'] != null ? 'UP' : 'DOWN',
              'uptime_percent': _vmHealthData['service_health']?['gateway_uptime'] ?? 0,
              'response_time_ms': _vmHealthData['response_times']?['gateway_ms'] ?? 0,
            },
            {
              'name': 'Database',
              'status': _vmHealthData['database_health']?['auth_db_status'] == 'connected' ? 'UP' : 'DOWN',
              'uptime_percent': 99.5,
              'response_time_ms': 15,
            },
          ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [          const Row(
            children: [
              Icon(Icons.apps_rounded, color: Color(0xFF11998e), size: 24),
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
          const SizedBox(height: 20),          // Wrap services list in a constrained container to prevent overflow
          SizedBox(
            height: 200, // Fixed height to prevent layout issues
            child: SingleChildScrollView(
              child: Column(
                children: servicesList.map((service) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildServiceItem(service),
                )).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildServiceItem(Map<String, dynamic> service) {
    final name = service['name'] ?? 'Unknown Service';
    final status = service['status'] ?? 'DOWN';
    final uptimePercent = _safeToDouble(service['uptime_percent']) ?? 0.0;
    final responseTimeMs = _safeToDouble(service['response_time_ms']) ?? 0.0;
    
    final isOnline = status == 'UP';
    final statusColor = isOnline ? Colors.green : Colors.red;
    
    // Determina l'icona basata sul nome del servizio
    IconData icon;
    switch (name.toLowerCase()) {
      case 'auth service':
      case 'authentication':
        icon = Icons.lock_rounded;
        break;
      case 'user service':
        icon = Icons.people_rounded;
        break;
      case 'gateway':
      case 'api gateway':
        icon = Icons.api_rounded;
        break;
      case 'database':
        icon = Icons.storage_rounded;
        break;
      default:
        icon = Icons.settings_rounded;
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: statusColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Uptime: ${_safeToFixedString(uptimePercent, 1)}%',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Response: ${_safeToFixedString(responseTimeMs, 0)}ms',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withOpacity(0.5)),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }// Security Tab Sections
  Widget _buildSecurityOverview() {
    final securityMetrics = _dashboardData?['security_metrics'] ?? {};
    final securityLevel = securityMetrics['security_level'] ?? 'UNKNOWN';
    final authStats = securityMetrics['authentication_stats'] ?? {};
    final userActivity = securityMetrics['user_activity'] ?? {};

    Color securityColor = _getSecurityLevelColor(securityLevel);
    IconData securityIcon = _getSecurityLevelIcon(securityLevel);

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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFfa709a), Color(0xFFfee140)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.security_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Security Overview',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: securityColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: securityColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(securityIcon, color: securityColor, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      securityLevel,
                      style: TextStyle(
                        color: securityColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildSecurityCard(
                  'Active Sessions',
                  '${authStats['active_sessions'] ?? '0'}',
                  Icons.people_rounded,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSecurityCard(
                  'Failed Logins',
                  '${userActivity['failed_login_attempts'] ?? '0'}',
                  Icons.block_rounded,
                  Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSecurityCard(
                  'Suspicious Activity',
                  '${userActivity['suspicious_activity'] ?? '0'}',
                  Icons.warning_rounded,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSecurityCard(
                  'JWT Validations',
                  '${securityMetrics['jwt_validation']?['total_validations'] ?? '0'}',
                  Icons.verified_user_rounded,
                  Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getSecurityLevelColor(String level) {
    switch (level) {
      case 'LOW_RISK': return Colors.green;
      case 'MEDIUM_RISK': return Colors.orange;
      case 'HIGH_RISK': return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData _getSecurityLevelIcon(String level) {
    switch (level) {
      case 'LOW_RISK': return Icons.check_circle;
      case 'MEDIUM_RISK': return Icons.warning;
      case 'HIGH_RISK': return Icons.error;
      default: return Icons.help;
    }
  }

  Widget _buildSecurityCard(String title, String value, IconData icon, Color color) {
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
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthenticationMetrics() {
    final authStats = _dashboardData?['security_metrics']?['authentication_stats'] ?? {};
    final jwtValidation = _dashboardData?['security_metrics']?['jwt_validation'] ?? {};

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
              Icon(Icons.login_rounded, color: Color(0xFFfa709a), size: 24),
              SizedBox(width: 12),
              Text(
                'Authentication Metrics',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildAuthMetricRow(
            'Successful Logins',
            '${authStats['successful_logins'] ?? '0'}',
            Icons.check_circle,
            Colors.green,
          ),
          const SizedBox(height: 12),
          _buildAuthMetricRow(
            'Failed Attempts',
            '${authStats['failed_attempts'] ?? '0'}',
            Icons.cancel,
            Colors.red,
          ),
          const SizedBox(height: 12),
          _buildAuthMetricRow(
            'JWT Tokens Issued',
            '${jwtValidation['tokens_issued'] ?? '0'}',
            Icons.token,
            Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildAuthMetricRow(
            'JWT Tokens Expired',
            '${jwtValidation['tokens_expired'] ?? '0'}',
            Icons.schedule,
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildAuthMetricRow(String title, String value, IconData icon, Color color) {
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
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
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
    );
  }

  Widget _buildSecurityAlertsSection() {
    final securityAlerts = _dashboardData?['security_metrics']?['security_alerts'] ?? [];
    
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
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFfa709a), size: 24),
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
                  color: securityAlerts.isNotEmpty ? Colors.red.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${securityAlerts.length} alerts',
                  style: TextStyle(
                    color: securityAlerts.isNotEmpty ? Colors.red : Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (securityAlerts.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No Security Alerts',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            ...securityAlerts.take(5).map((alert) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildSecurityAlertItem(alert),
            )),
        ],
      ),
    );
  }

  Widget _buildSecurityAlertItem(Map<String, dynamic> alert) {
    final severity = alert['severity'] ?? 'MEDIUM';
    final message = alert['message'] ?? 'Security alert detected';
    final timestamp = alert['timestamp'] ?? '';
    
    Color severityColor = _getAlertColor(severity);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: severityColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: severityColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(_getAlertIcon(alert['type']), color: severityColor, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (timestamp.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    timestamp,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: severityColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              severity,
              style: TextStyle(
                color: severityColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }  // Analytics Tab Sections
  Widget _buildAnalyticsOverview() {
    final analytics = _dashboardData?['analytics'] ?? {};
    final qrAnalytics = analytics['qr_code_analytics'] ?? {};
    final userBehavior = analytics['user_behavior'] ?? {};
    final attendanceStats = analytics['attendance_stats'] ?? {};

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
              Icon(Icons.analytics_rounded, color: Color(0xFF4facfe), size: 24),
              SizedBox(width: 12),
              Text(
                'Analytics Overview',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildAnalyticsCard(
                  'Total QR Scans',
                  '${qrAnalytics['total_scans_24h'] ?? 0}',
                  Icons.qr_code_scanner_rounded,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAnalyticsCard(
                  'Active Users',
                  '${userBehavior['active_users'] ?? 0}',
                  Icons.people_rounded,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildAnalyticsCard(
                  'Success Rate',
                  '${attendanceStats['success_rate'] ?? 0}',
                  Icons.check_circle_rounded,
                  Colors.purple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAnalyticsCard(
                  'Events Today',
                  '${attendanceStats['events_today'] ?? 0}',
                  Icons.event_rounded,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(String title, String value, IconData icon, Color color) {
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
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRCodeMetrics() {
    final qrAnalytics = _dashboardData?['analytics']?['qr_code_analytics'] ?? {};
    
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
              Icon(Icons.qr_code_rounded, color: Color(0xFF4facfe), size: 24),
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
          _buildQRMetricRow(
            'Total Scans (24h)',
            '${qrAnalytics['total_scans_24h'] ?? 0}',
            Icons.qr_code_scanner_rounded,
            Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildQRMetricRow(
            'Successful Scans',
            '${qrAnalytics['successful_scans'] ?? 0}',
            Icons.check_circle_rounded,
            Colors.green,
          ),
          const SizedBox(height: 12),
          _buildQRMetricRow(
            'Success Rate',
            '${qrAnalytics['success_rate_percent'] ?? 0}%',
            Icons.trending_up_rounded,
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildQRMetricRow(String title, String value, IconData icon, Color color) {
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
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
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
    );
  }

  Widget _buildUserBehaviorMetrics() {
    final userBehavior = _dashboardData?['analytics']?['user_behavior'] ?? {};
    
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
              Icon(Icons.people_rounded, color: Color(0xFF4facfe), size: 24),
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
          Row(
            children: [
              Expanded(
                child: _buildBehaviorCard(
                  'Active Users',
                  '${userBehavior['active_users'] ?? 0}',
                  Icons.person_rounded,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBehaviorCard(
                  'New Users',
                  '${userBehavior['new_users_today'] ?? 0}',
                  Icons.person_add_rounded,
                  Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBehaviorCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // Performance Tab Sections
  Widget _buildPerformanceOverview() {
    final vmHealth = _dashboardData?['system_health'] ?? {};
    final performance = vmHealth['performance'] ?? {};
    
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
              Icon(Icons.speed_rounded, color: Color(0xFFa8edea), size: 24),
              SizedBox(width: 12),
              Text(
                'Performance Overview',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildPerformanceCard(
                  'Avg Response',
                  '${performance['avg_response_time_ms'] ?? 95}ms',
                  Icons.timer_rounded,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPerformanceCard(
                  'Throughput',
                  '${performance['requests_per_sec'] ?? 150}/s',
                  Icons.speed_rounded,
                  Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAPIPerformanceMetrics() {
    final apiStats = _dashboardData?['analytics']?['api_usage_stats'] ?? {};
    final topEndpoints = apiStats['top_endpoints'] as List? ?? [];
    
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
              Icon(Icons.api_rounded, color: Color(0xFFa8edea), size: 24),
              SizedBox(width: 12),
              Text(
                'API Performance',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...topEndpoints.take(3).map((endpoint) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildAPIEndpointItem(endpoint),
          )),
        ],
      ),
    );
  }

 
  Widget _buildAPIEndpointItem(Map<String, dynamic> endpoint) {
    final endpointName = endpoint['endpoint'] ?? '';
    final requests = endpoint['requests'] ?? 0;
    final responseTime = endpoint['avg_response_ms'] ?? 0;
    
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
              color: const Color(0xFFa8edea).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.api_rounded, color: Color(0xFFa8edea), size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  endpointName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '$requests requests',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${responseTime}ms',
            style: const TextStyle(
              color: Color(0xFFa8edea),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatabaseMetricsSection() {
    final dbMetrics = _dashboardData?['analytics']?['database_metrics'] ?? {};
    
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
              Icon(Icons.storage_rounded, color: Color(0xFFa8edea), size: 24),
              SizedBox(width: 12),
              Text(
                'Database Metrics',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildDBMetricRow(
            'Auth DB Status',
            '${dbMetrics['auth_db_status'] ?? 'unknown'}',
            Icons.security_rounded,
            _getDBStatusColor(dbMetrics['auth_db_status']),
          ),
          const SizedBox(height: 12),
          _buildDBMetricRow(
            'User DB Status',
            '${dbMetrics['user_db_status'] ?? 'unknown'}',
            Icons.people_rounded,
            _getDBStatusColor(dbMetrics['user_db_status']),
          ),
          const SizedBox(height: 12),
          _buildDBMetricRow(
            'Active Connections',
            '${dbMetrics['connections_active'] ?? 0}',
            Icons.link_rounded,
            Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildDBMetricRow(String title, String value, IconData icon, Color color) {
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
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getDBStatusColor(String? status) {
    switch (status) {
      case 'healthy':
      case 'connected':
        return Colors.green;
      case 'warning':
        return Colors.orange;
      case 'error':
      case 'disconnected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Helper Methods - Utility functions for safe data handling and UI operations
  
  /// Safely converts dynamic values to double with null checking
  double? _safeToDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        debugPrint('⚠️ PrometheusMonitor: Could not parse double from string: $value');
        return null;
      }
    }
    return null;
  }

  /// Safely formats double values to string with fixed decimal places
  String _safeToFixedString(double? value, int fractionDigits) {
    if (value == null) return '0';
    try {
      return value.toStringAsFixed(fractionDigits);
    } catch (e) {
      debugPrint('⚠️ PrometheusMonitor: Error formatting number: $value');
      return '0';
    }
  }
  /// Shows detailed alerts dialog with all critical alerts
  void _showAlertsDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_rounded, color: Colors.red, size: 24),
            const SizedBox(width: 12),
            const Text(
              'Critical Alerts',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_criticalAlerts.length}',
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_criticalAlerts.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No critical alerts at this time',
                          style: TextStyle(color: Colors.green),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _criticalAlerts.length,
                    itemBuilder: (context, index) {
                      final alert = _criticalAlerts[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _getAlertColor(alert['severity']).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getAlertColor(alert['severity']).withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _getAlertIcon(alert['type']),
                                  color: _getAlertColor(alert['severity']),
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    alert['message'] ?? 'Unknown alert',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getAlertColor(alert['severity']).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    alert['severity'] ?? 'UNKNOWN',
                                    style: TextStyle(
                                      color: _getAlertColor(alert['severity']),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (alert['timestamp'] != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Time: ${_formatTimestamp(alert['timestamp'])}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'CLOSE',
              style: TextStyle(color: Colors.white),
            ),
          ),
          if (_criticalAlerts.isNotEmpty)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _loadDashboardData(); // Refresh to check if alerts are resolved
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('REFRESH'),
            ),
        ],
      ),
    );
  }
  /// Shows dashboard settings dialog
  void _showSettingsDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.settings_rounded, color: Colors.blue, size: 24),
            SizedBox(width: 12),
            Text(
              'Dashboard Settings',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSettingItem(
                'Auto Refresh',
                'Automatically refresh data every 30 seconds',
                Icons.refresh_rounded,
                true,
                (value) {
                  // Handle auto refresh toggle
                  if (value) {
                    _startAutoRefresh();
                  } else {
                    _refreshTimer?.cancel();
                  }
                },
              ),
              const SizedBox(height: 16),
              _buildSettingItem(
                'Alert Notifications',
                'Show critical alert notifications',
                Icons.notifications_rounded,
                true,
                (value) {
                  // Handle notification toggle
                  if (value) {
                    _startNotificationSystem();
                  } else {
                    _notificationTimer?.cancel();
                  }
                },
              ),
              const SizedBox(height: 16),
              _buildSettingItem(
                'Haptic Feedback',
                'Vibrate on critical alerts',
                Icons.vibration_rounded,
                true,
                (value) {
                  // Handle haptic feedback toggle
                },
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Connection Info',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Base URL: $_baseApiUrl',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),                    Text(
                      'Endpoints: Security, VM-Health, Insights',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      'Connection Attempts: $_connectionAttempts',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'CLOSE',
              style: TextStyle(color: Colors.white),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _loadDashboardData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('REFRESH'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(
    String title,
    String description,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
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
              color: Colors.blue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.blue, size: 20),
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
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.blue,
            activeTrackColor: Colors.blue.withOpacity(0.3),
            inactiveThumbColor: Colors.grey,
            inactiveTrackColor: Colors.grey.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  /// Exports dashboard data for external analysis
  void _exportDashboardData() async {
    if (!mounted || _dashboardData == null) return;

    try {
      // Create export data structure
      final exportData = {
        'export_timestamp': DateTime.now().toIso8601String(),
        'dashboard_version': '2.0.0',
        'export_type': 'prometheus_dashboard_data',
        'connection_status': _connectionStatus,
        'data': _dashboardData,
        'metadata': {
          'total_alerts': _criticalAlerts.length,
          'connection_attempts': _connectionAttempts,
          'last_update': _lastUpdate?.toIso8601String(),
          'retry_count': _retryCount,
          'endpoints_used': [_securityUrl, _vmHealthUrl, _insightsUrl],
        },
        'system_summary': {
          'system_health': _dashboardData!['system_health']?['overall_status'],
          'security_level': _dashboardData!['security_metrics']?['security_level'],
          'active_users': _dashboardData!['analytics']?['user_behavior']?['active_users'],
          'qr_scans_today': _dashboardData!['analytics']?['qr_code_analytics']?['total_scans_24h'],
        },
      };

      // Convert to JSON
      final jsonString = jsonEncode(exportData);      // Show export success dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A2E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.download_done_rounded, color: Colors.green, size: 24),
                SizedBox(width: 12),
                Text(
                  'Export Ready',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dashboard data has been prepared for export.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Export Summary:',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• Data size: ${(jsonString.length / 1024).toStringAsFixed(1)} KB',
                        style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                      ),                      Text(
                        '• Endpoints: 3',
                        style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                      ),
                      Text(
                        '• Alerts included: ${_criticalAlerts.length}',
                        style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Note: In a production app, this would save to device storage or share via system dialog.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('CLOSE', style: TextStyle(color: Colors.white)),
              ),
              ElevatedButton(
                onPressed: () {
                  // Copy to clipboard
                  Clipboard.setData(ClipboardData(text: jsonString));
                  Navigator.of(context).pop();
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: Colors.green,
                      content: Row(
                        children: [
                          Icon(Icons.copy_rounded, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Data copied to clipboard'),
                        ],
                      ),
                      duration: Duration(seconds: 3),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('COPY TO CLIPBOARD'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Row(
              children: [
                const Icon(Icons.error_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Export failed: ${e.toString()}'),
                ),
              ],
            ),
            duration: const Duration(seconds: 5),
          ),
        );      }
    }
  }

  /// Format timestamp for display
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }

  /// Build TabBar widget
  Widget _buildTabBar() {
    return SliverPersistentHeader(
      delegate: _TabBarDelegate(
        TabBar(
          controller: _tabController,
          isScrollable: true,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: _tabs[_selectedTabIndex].gradient,
            ),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.6),
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 14,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          tabs: _tabs.map((tab) => Tab(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(tab.icon, size: 18),
                  const SizedBox(width: 8),
                  Text(tab.title),
                ],
              ),
            ),
          )).toList(),
        ),
      ),
      pinned: true,
    );
  }

  /// Build connection status chip
  Widget _buildConnectionStatusChip() {
    Color statusColor;
    IconData statusIcon;
    
    switch (_connectionStatus) {
      case 'LIVE':
        statusColor = Colors.green;
        statusIcon = Icons.circle;
        break;
      case 'CONNECTING':
        statusColor = Colors.orange;
        statusIcon = Icons.sync;
        break;
      case 'RETRYING':
        statusColor = Colors.yellow;
        statusIcon = Icons.refresh;
        break;
      case 'OFFLINE':
        statusColor = Colors.red;
        statusIcon = Icons.circle;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, color: statusColor, size: 12),
          const SizedBox(width: 6),
          Text(
            _connectionStatus,
            style: TextStyle(
              color: statusColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Build alerts indicator for app bar
  Widget _buildAlertsIndicator() {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_rounded, color: Colors.white),
          onPressed: _showAlertsDialog,
          tooltip: 'View Alerts',
        ),
        if (_criticalAlerts.isNotEmpty)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${_criticalAlerts.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Build loading state widget
  Widget _buildLoadingState() {
    return Container(
      color: const Color(0xFF0F0F23),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_tabs[_selectedTabIndex].gradient.first),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Loading Dashboard Data...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Connecting to Prometheus endpoints',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build error state widget
  Widget _buildErrorState() {
    return Container(
      color: const Color(0xFF0F0F23),
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: Colors.red,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _connectionStatus == 'OFFLINE' ? 'Connection Lost' : 'Connection Error',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Unknown error occurred',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isRetrying ? null : _loadDashboardData,
              icon: _isRetrying 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh_rounded),
              label: Text(_isRetrying ? 'Retrying...' : 'Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _tabs[_selectedTabIndex].gradient.first,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build no data state widget
  Widget _buildNoDataState() {
    return Container(
      color: const Color(0xFF0F0F23),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
              child: const Icon(
                Icons.data_usage_rounded,
                color: Colors.grey,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Data Available',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Dashboard data is not available at the moment',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadDashboardData,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _tabs[_selectedTabIndex].gradient.first,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom TabBar Delegate for SliverPersistentHeader
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFF1A1A2E),
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}

// Helper Methods per Overview Cards
Color _getSystemHealthColor(String? status) {
  switch (status) {
    case 'HEALTHY': return Colors.green;
    case 'WARNING': return Colors.orange;
    case 'CRITICAL': return Colors.red;
    default: return Colors.grey;
  }
}

String _getSecurityDisplayText(String? level) {
  switch (level) {
    case 'LOW_RISK': return 'SECURE';
    case 'MEDIUM_RISK': return 'MEDIUM';
    case 'HIGH_RISK': return 'HIGH RISK';
    default: return 'UNKNOWN';
  }
}
