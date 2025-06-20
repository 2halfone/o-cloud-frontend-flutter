import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'services/prometheus_api_service.dart';
import '../core/monitoring_models.dart';
import 'widgets/tabs/overview_tab.dart';
import 'widgets/tabs/system_health_tab.dart';
import 'widgets/tabs/security_tab.dart';
import 'widgets/tabs/analytics_tab.dart';
import 'widgets/tabs/performance_tab.dart';

class PrometheusMonitorScreenRefactored extends StatefulWidget {
  const PrometheusMonitorScreenRefactored({super.key});

  @override
  State<PrometheusMonitorScreenRefactored> createState() => _PrometheusMonitorScreenRefactoredState();
}

class _PrometheusMonitorScreenRefactoredState extends State<PrometheusMonitorScreenRefactored>
    with TickerProviderStateMixin {
  // Services
  final PrometheusApiService _apiService = PrometheusApiService();  
  // State management
  Timer? _refreshTimer;
  Timer? _notificationTimer;
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _dashboardData;
  int _retryCount = 0;  int _connectionAttempts = 0;
  bool _isRetrying = false;
  String _connectionStatus = 'CONNECTING';
    // Settings
  final bool _autoRefreshEnabled = true;
  final bool _alertNotificationsEnabled = true;
  
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
  
  // Constants
  static const int _maxRetries = 3;
  static const Duration _retryBaseDelay = Duration(seconds: 2);
  static const Duration _refreshInterval = Duration(seconds: 30);

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
    _refreshTimer?.cancel();    _notificationTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _initializeMonitoring() {
    _loadDashboardData();
    _startAutoRefresh();
    _startNotificationSystem();
  }

  void _startAutoRefresh() {
    if (_autoRefreshEnabled) {
      _refreshTimer = Timer.periodic(_refreshInterval, (_) {
        if (mounted && !_isRetrying) _loadDashboardData();
      });
    }
  }

  void _startNotificationSystem() {
    if (_alertNotificationsEnabled) {    }
  }

  Future<void> _loadDashboardData() async {
    if (_isRetrying) return;

    try {
      _connectionAttempts++;
      setState(() {
        _connectionStatus = 'CONNECTING';
        if (_retryCount == 0) _isLoading = true;
      });

      Map<String, dynamic> combinedData = {};
      bool allFailed = true;
      bool anySuccess = false;
      try {
        combinedData = await _apiService.loadAllDashboardData();
        allFailed = false;
        anySuccess = true;
      } catch (e) {
        // Try endpoints individually
        try {
          final security = await _apiService.loadSecurityData();
          combinedData['security_metrics'] = security['data'] ?? {};
          anySuccess = true;
        } catch (_) {}
        try {
          final vm = await _apiService.loadVMHealthData();
          combinedData['system_health'] = vm['data'] ?? {};
          combinedData['system_resources'] = vm['data']?['system_resources'] ?? {};
          anySuccess = true;
        } catch (_) {}
        try {
          final insights = await _apiService.loadInsightsData();
          combinedData['analytics'] = insights;
          anySuccess = true;
        } catch (_) {}
        allFailed = !anySuccess;
      }

      if (!mounted) return;
      setState(() {
        _dashboardData = combinedData;
        _isLoading = false;
        _error = null;
        _retryCount = 0;
        _connectionStatus = allFailed ? 'OFFLINE' : 'LIVE';
      });
      if (!allFailed) _showConnectionSuccess();

    } catch (e) {
      if (!mounted) return;
      await _handleNetworkError(e);
    }
  }

  Future<void> _handleNetworkError(dynamic error) async {
    String errorDetails = _apiService.analyzeNetworkError(error);
    setState(() {
      _connectionStatus = 'OFFLINE';
      _error = 'Connection Error: $errorDetails\n\nEndpoints: Security, VM-Health, Insights\nAttempts: $_connectionAttempts';
      _isLoading = false;
    });
    await _retryWithBackoff();
  }

  Future<void> _retryWithBackoff() async {
    if (_retryCount >= _maxRetries || _isRetrying) return;

    setState(() => _isRetrying = true);
    
    final delaySeconds = pow(2, _retryCount) * _retryBaseDelay.inSeconds;
    const maxDelay = 30;
    final actualDelay = min(delaySeconds.toInt(), maxDelay);
    
    setState(() => _connectionStatus = 'RETRYING');

    await Future.delayed(Duration(seconds: actualDelay));
    
    if (mounted) {
      _retryCount++;
      setState(() => _isRetrying = false);
      await _loadDashboardData();    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F23),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildModernAppBar(innerBoxIsScrolled),
          _buildTabBar(),
        ],        body: TabBarView(          controller: _tabController,
          children: [
            OverviewTab(),
            SystemHealthTab(
              dashboardData: _dashboardData,
              onRefresh: _loadDashboardData,
            ),
            SecurityTab(
              dashboardData: _dashboardData,
              onRefresh: _loadDashboardData,
            ),
            AnalyticsTab(
              dashboardData: _dashboardData,
              onRefresh: _loadDashboardData,
            ),
            PerformanceTab(
              dashboardData: _dashboardData,
              onRefresh: _loadDashboardData,
            ),
          ],
        ),
      ),
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
          ),
          child: SafeArea(            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Stack(
                children: [
                  // Titolo centrato spostato 10px a sinistra
                  Padding(
                    padding: const EdgeInsets.only(right: 20), // Compensa spostamento verso sinistra
                    child: Center(
                      child: Transform.translate(
                        offset: const Offset(-10, 0), // Sposta 10px a sinistra
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),                                  child: const FaIcon(
                                    FontAwesomeIcons.fire,
                                    color: Colors.orange,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
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
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Indicatore LIVE sul margine basso
                  Positioned(
                    bottom: 8,
                    right: 16,
                    child: _buildConnectionStatusChip(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
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

  void _handleMenuAction(String action) {
    switch (action) {
      case 'export':
        // TODO: Export functionality
        break;
      case 'settings':
        // TODO: Settings dialog
        break;
    }
  }

  Widget _buildConnectionStatusChip() {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (_connectionStatus) {
      case 'LIVE':
        statusColor = Colors.green;
        statusText = 'LIVE';
        statusIcon = Icons.circle;
        break;
      case 'CONNECTING':
        statusColor = Colors.orange;
        statusText = 'CONNECTING';
        statusIcon = Icons.sync;
        break;
      case 'RETRYING':
        statusColor = Colors.amber;
        statusText = 'RETRYING';
        statusIcon = Icons.refresh;
        break;
      case 'OFFLINE':
        statusColor = Colors.red;
        statusText = 'OFFLINE';
        statusIcon = Icons.circle;
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'UNKNOWN';
        statusIcon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, color: statusColor, size: 12),
          const SizedBox(width: 4),
          Text(
            statusText,
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

  Widget _buildTabBar() {
    return SliverPersistentHeader(
      delegate: _SliverTabBarDelegate(
        TabBar(
          controller: _tabController,
          indicatorColor: _tabs[_selectedTabIndex].gradient.first,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.6),
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          isScrollable: true,
          tabs: _tabs.map((tab) => Tab(
            icon: Icon(tab.icon, size: 18),
            text: tab.title,
          )).toList(),
        ),
      ),
      pinned: true,    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverTabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFF1A1A2E),
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
