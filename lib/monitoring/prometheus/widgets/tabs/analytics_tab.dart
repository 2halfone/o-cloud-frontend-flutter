import 'package:flutter/material.dart';
import '../../services/analytics_api_service.dart';

class AnalyticsTab extends StatefulWidget {
  final Map<String, dynamic>? dashboardData;
  final VoidCallback? onRefresh;

  const AnalyticsTab({
    super.key,
    this.dashboardData,
    this.onRefresh,
  });

  @override
  State<AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends State<AnalyticsTab> {
  Map<String, dynamic>? _analyticsData;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('📊 AnalyticsTab - Loading real analytics data...');
      final data = await AnalyticsApiService.getAllAnalyticsData();
      setState(() {
        _analyticsData = data;
        _isLoading = false;
      });
      print('📊 AnalyticsTab - Analytics data loaded successfully');
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      print('❌ AnalyticsTab - Error loading analytics data: $e');
    }
  }  @override
  Widget build(BuildContext context) {
    // Debug logging dettagliato
    print('� AnalyticsTab BUILD - Status:');
    print('   - _isLoading: $_isLoading');
    print('   - _error: $_error');
    print('   - _analyticsData: $_analyticsData');
    print('   - _analyticsData keys: ${_analyticsData?.keys}');
    
    if (_analyticsData != null) {
      print('   - qr_events: ${_analyticsData!['qr_events']}');
      print('   - summary: ${_analyticsData!['summary']}');
      print('   - auth_logs: ${_analyticsData!['auth_logs']}');
      print('   - users: ${_analyticsData!['users']}');
    }    if (_isLoading) {
      print('📊 Showing loading state');
      return _buildLoadingState();
    }
    if (_error != null) {
      print('❌ Showing error state: $_error');
      return _buildErrorState();
    }
    
    print('📊 Showing analytics cards with data: ${_analyticsData != null ? "YES" : "NO"}');
    
    // Show the analytics cards with calculated data (even if some APIs return empty data)
    return RefreshIndicator(
      onRefresh: () async {
        await _loadAnalyticsData();
        widget.onRefresh?.call();
      },
      backgroundColor: const Color(0xFF1A1A2E),
      color: const Color(0xFF4facfe),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),        child: Column(
          children: [
            _buildQRCodeAnalytics(),
            const SizedBox(height: 24),
            _buildUserBehavior(),
            const SizedBox(height: 24),
            _buildAPIUsageStats(),
            const SizedBox(height: 24),
            _buildAnalyticsDebugInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF4facfe)),
          SizedBox(height: 16),
          Text(
            'Loading Analytics Data...',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          const Text(
            'Error loading analytics data',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Unknown error',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadAnalyticsData,
            child: const Text('Retry'),
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
          const Icon(Icons.analytics, color: Colors.grey, size: 48),
          const SizedBox(height: 16),          const Text(
            'No Analytics Data Available',
            style: TextStyle(color: Colors.white70, fontSize: 18),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadAnalyticsData,
            child: const Text('Reload Data'),
          ),
        ],
      ),
    );
  }
  Widget _buildQRCodeAnalytics() {
    print('🔍 Building QR Code Analytics');    final qrEvents = _analyticsData?['qr_events'];
    
    print('   - qrEvents: $qrEvents');    // Calculate metrics directly from API data
    final Map<String, dynamic> qrMetrics = {
      'total_events': qrEvents?['total'] ?? (qrEvents?['data'] as List?)?.length ?? 0,
      'total_scans': qrEvents?['total_scans'] ?? qrEvents?['total'] ?? (qrEvents?['data'] as List?)?.length ?? 0,
      'active_events': qrEvents?['active_events'] ?? qrEvents?['total'] ?? (qrEvents?['data'] as List?)?.length ?? 0,
      'scan_rate': '85.0%', // Placeholder for now
    };
    
    print('   - qrMetrics: $qrMetrics');List<Widget> metrics = [];

    qrMetrics.forEach((key, value) {
      if (value != null) {
        metrics.add(_buildQRMetric(
          _formatStatName(key),
          value.toString(),
          _getQRStatIcon(key),
          _getQRStatColor(key),
        ));
      }
    });

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
  }  Widget _buildUserBehavior() {
    final users = _analyticsData?['users'];
    final authLogs = _analyticsData?['auth_logs'];    // Calculate metrics directly from API data (no complex logic)
    int totalUsers = users?['total'] ?? (users?['data'] as List?)?.length ?? 0;
    int totalAuthAttempts = authLogs?['total'] ?? (authLogs?['data'] as List?)?.length ?? 0;
    
    // Try to get auth success rate from API or use a reasonable default
    String authSuccessRate = authLogs?['success_rate'] ?? '85.0'; // Default 85% if not provided
    if (!authSuccessRate.contains('%')) {
      authSuccessRate += '%';
    }

    final Map<String, dynamic> userMetrics = {
      'total_users': totalUsers,
      'active_users_today': totalUsers, // For now, assume all users are active
      'auth_success_rate': authSuccessRate,
      'total_auth_attempts': totalAuthAttempts,
    };

    List<Widget> metrics = [];

    userMetrics.forEach((key, value) {
      if (value != null) {
        metrics.add(_buildBehaviorMetric(
          _formatStatName(key),
          value.toString(),
          _getUserBehaviorIcon(key),
          _getUserBehaviorColor(key),
        ));
      }
    });

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
          )),
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
  }  Widget _buildAttendanceStats() {
    final qrEvents = _analyticsData?['qr_events'];

    // Calculate metrics directly from API data (no summary dependency)
    final Map<String, dynamic> attendanceMetrics = {
      'total_events': qrEvents?['total'] ?? (qrEvents?['data'] as List?)?.length ?? 0,
      'total_scans': qrEvents?['total_scans'] ?? qrEvents?['total'] ?? (qrEvents?['data'] as List?)?.length ?? 0,
      'active_events': qrEvents?['active_events'] ?? qrEvents?['total'] ?? (qrEvents?['data'] as List?)?.length ?? 0,
      'average_attendance': _calculateAverageAttendance(qrEvents),
    };

    List<Widget> metrics = [];

    attendanceMetrics.forEach((key, value) {
      if (value != null) {
        metrics.add(_buildAttendanceMetric(
          _formatStatName(key),
          value.toString(),
          _getAttendanceIcon(key),
          _getAttendanceColor(key),
        ));
      }
    });

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
  }  Widget _buildAPIUsageStats() {
    final authLogs = _analyticsData?['auth_logs'];
    final users = _analyticsData?['users'];
    final qrEvents = _analyticsData?['qr_events'];

    // Calculate API metrics directly from API data or use defaults
    int authApiCalls = authLogs?['total'] ?? (authLogs?['data'] as List?)?.length ?? 0;
    int userApiCalls = users?['total'] ?? (users?['data'] as List?)?.length ?? 0;
    int qrApiCalls = qrEvents?['total'] ?? (qrEvents?['data'] as List?)?.length ?? 0;
    int totalApiRequests = authApiCalls + userApiCalls + qrApiCalls;

    final apiMetrics = {
      'auth_api_calls': authApiCalls,
      'user_api_calls': userApiCalls,
      'qr_api_calls': qrApiCalls,
      'total_api_requests': totalApiRequests,
    };

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
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: apiMetrics.entries.map((entry) {
              return _buildAPIMetric(
                _formatStatName(entry.key),
                entry.value.toString(),
                _getAPIIcon(entry.key),
                _getAPIColor(entry.key),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAPIMetric(String title, String value, IconData icon, Color color) {
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
  }  Widget _buildAnalyticsDebugInfo() {
    // Show real data counts from API responses
    final users = _analyticsData?['users'];
    final qrEvents = _analyticsData?['qr_events'];
    final authLogs = _analyticsData?['auth_logs'];
    
    int totalUsers = users?['total'] ?? (users?['data'] as List?)?.length ?? 0;
    int totalEvents = qrEvents?['total'] ?? (qrEvents?['data'] as List?)?.length ?? 0;
    int totalAuth = authLogs?['total'] ?? (authLogs?['data'] as List?)?.length ?? 0;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Analytics Debug Info',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Data Status: ${_analyticsData != null ? "✅ Real Data Loaded" : "❌ No Data"}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          if (_analyticsData != null) ...[
            Text(
              'Auth Logs: ${_analyticsData!['auth_logs'] != null ? "✅" : "❌"}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            Text(
              'Users Data: ${_analyticsData!['users'] != null ? "✅" : "❌"}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            Text(
              'QR Events: ${_analyticsData!['qr_events'] != null ? "✅" : "❌"}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),            const SizedBox(height: 8),
            const Text(
              'Real Data Counts:',
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            Text(
              'Total Users: $totalUsers',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            Text(
              'Total Events: $totalEvents',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            Text(
              'Total Auth Attempts: $totalAuth',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
          if (_analyticsData?['metadata'] != null) ...[
            const SizedBox(height: 8),
            Text(
              'Data Source: ${_analyticsData!['metadata']['data_source'] ?? "unknown"}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            Text(
              'Collection Time: ${_analyticsData!['metadata']['collection_time'] ?? "unknown"}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
  // Calculate summary statistics from raw data or use existing summary
  Map<String, dynamic> _calculateSummaryStats() {
    if (_analyticsData == null) {
      return {
        'total_users': 0,
        'total_events': 0,
        'total_auth_attempts': 0,
        'active_users_today': 0,
        'successful_auth_rate': 0.0,
        'qr_scan_rate': 0.0,
      };
    }    // Get data from API response
    final existingSummary = _analyticsData!['summary'];
    final qrEvents = _analyticsData!['qr_events'];
    final users = _analyticsData!['users'];
    final authLogs = _analyticsData!['auth_logs'];
    
    // First try to use existing summary data from API, but supplement with other fields
    if (existingSummary != null && existingSummary is Map) {
      print('📊 Using existing summary data from API: $existingSummary');
        // Try to get total_events from multiple sources
      int totalEvents = existingSummary['total_events'] ?? 
                       qrEvents?['total'] ?? 
                       (qrEvents?['data'] as List?)?.length ?? 0;
      
      // Try to get total_scans from multiple sources
      int totalScans = existingSummary['total_scans'] ?? 
                      qrEvents?['total_scans'] ?? 
                      _calculateTotalScans(qrEvents);
      
      return {
        'total_users': existingSummary['total_users'] ?? 
                      users?['total'] ?? 
                      (users?['data'] as List?)?.length ?? 0,
        'total_events': totalEvents,
        'total_scans': totalScans,
        'total_auth_attempts': existingSummary['total_auth_attempts'] ?? 
                              authLogs?['total'] ?? 
                              (authLogs?['data'] as List?)?.length ?? 0,
        'active_users_today': existingSummary['active_users_today'] ?? 0,
        'successful_auth_rate': existingSummary['successful_auth_rate'] ?? 0.0,
        'qr_scan_rate': existingSummary['qr_scan_rate'] ?? 0.0,
      };
    }

    print('📊 No summary data from API, calculating manually...');
    
    // Fallback: calculate manually from raw data
    
    // Calculate total users
    int totalUsers = 0;
    if (users != null && users['data'] is List) {
      totalUsers = (users['data'] as List).length;
    }
    
    // Calculate total events
    int totalEvents = 0;
    if (qrEvents != null && qrEvents['data'] is List) {
      totalEvents = (qrEvents['data'] as List).length;
    }
    
    // Calculate auth statistics
    int totalAuthAttempts = 0;
    int successfulAuth = 0;
    if (authLogs != null && authLogs['data'] is List) {
      final logs = authLogs['data'] as List;
      totalAuthAttempts = logs.length;
      for (var log in logs) {
        if (log is Map && log['success'] == true) {
          successfulAuth++;
        }
      }
    }
    
    double successfulAuthRate = totalAuthAttempts > 0 
        ? (successfulAuth / totalAuthAttempts) * 100 
        : 0.0;
      // Calculate active users today (simplified - users with recent activity)
    int activeUsersToday = totalUsers; // For now, consider all users as potentially active
    
    // Calculate total scans
    int totalScans = _calculateTotalScans(qrEvents);
    
    // Calculate QR scan rate (simplified)
    double qrScanRate = totalEvents > 0 ? 85.0 : 0.0; // Placeholder calculation
    
    final calculated = {
      'total_users': totalUsers,
      'total_events': totalEvents,
      'total_scans': totalScans,
      'total_auth_attempts': totalAuthAttempts,
      'active_users_today': activeUsersToday,
      'successful_auth_rate': successfulAuthRate,
      'qr_scan_rate': qrScanRate,
    };
    
    print('📊 Manually calculated stats: $calculated');
    return calculated;
  }

  // Helper methods for calculations
  int _calculateTotalScans(Map<String, dynamic>? qrEvents) {
    final events = qrEvents?['data'] as List? ?? [];
    int totalScans = 0;
    for (var event in events) {
      if (event is Map) {
        totalScans += (event['scans_count'] as int? ?? 0);
      }
    }
    return totalScans;
  }

  int _calculateActiveEvents(Map<String, dynamic>? qrEvents) {
    final events = qrEvents?['data'] as List? ?? [];
    int activeEvents = 0;
    final now = DateTime.now();
    for (var event in events) {
      if (event is Map) {
        final endDate = event['end_date'];
        if (endDate != null) {
          try {
            final eventEndDate = DateTime.parse(endDate.toString());
            if (eventEndDate.isAfter(now)) {
              activeEvents++;
            }
          } catch (e) {
            // If date parsing fails, consider it active
            activeEvents++;
          }
        }
      }
    }
    return activeEvents;
  }

  int _calculateAverageAttendance(Map<String, dynamic>? qrEvents) {
    final events = qrEvents?['data'] as List? ?? [];
    if (events.isEmpty) return 0;
    
    int totalAttendance = 0;
    int eventCount = 0;
    
    for (var event in events) {
      if (event is Map) {
        final scansCount = event['scans_count'] as int? ?? 0;
        totalAttendance += scansCount;
        eventCount++;
      }
    }
    
    return eventCount > 0 ? (totalAttendance / eventCount).round() : 0;
  }

  int _calculateTotalApiRequests() {
    final authLogs = _analyticsData?['auth_logs'];
    final users = _analyticsData?['users'];
    final qrEvents = _analyticsData?['qr_events'];
    
    int total = 0;
    total += (authLogs?['data'] as List?)?.length ?? 0;
    total += (users?['data'] as List?)?.length ?? 0;
    total += (qrEvents?['data'] as List?)?.length ?? 0;
    
    return total;
  }

  // Helper methods for formatting and styling
  String _formatStatName(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  IconData _getQRStatIcon(String key) {
    switch (key.toLowerCase()) {
      case 'total_events':
        return Icons.event;
      case 'total_scans':
        return Icons.qr_code_scanner;
      case 'active_events':
        return Icons.event_available;
      case 'scan_rate':
        return Icons.trending_up;
      default:
        return Icons.analytics;
    }
  }

  Color _getQRStatColor(String key) {
    switch (key.toLowerCase()) {
      case 'total_events':
        return Colors.blue;
      case 'total_scans':
        return Colors.green;
      case 'active_events':
        return Colors.orange;
      case 'scan_rate':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getUserBehaviorIcon(String key) {
    switch (key.toLowerCase()) {
      case 'total_users':
        return Icons.people;
      case 'active_users_today':
        return Icons.person_pin;
      case 'auth_success_rate':
        return Icons.verified_user;
      case 'total_auth_attempts':
        return Icons.login;
      default:
        return Icons.person;
    }
  }

  Color _getUserBehaviorColor(String key) {
    switch (key.toLowerCase()) {
      case 'total_users':
        return Colors.blue;
      case 'active_users_today':
        return Colors.green;
      case 'auth_success_rate':
        return Colors.purple;
      case 'total_auth_attempts':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getAttendanceIcon(String key) {
    switch (key.toLowerCase()) {
      case 'total_events':
        return Icons.event;
      case 'total_scans':
        return Icons.qr_code_scanner;
      case 'active_events':
        return Icons.event_available;
      case 'average_attendance':
        return Icons.groups;
      default:
        return Icons.analytics;
    }
  }

  Color _getAttendanceColor(String key) {
    switch (key.toLowerCase()) {
      case 'total_events':
        return Colors.blue;
      case 'total_scans':
        return Colors.green;
      case 'active_events':
        return Colors.orange;
      case 'average_attendance':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getAPIIcon(String key) {
    switch (key.toLowerCase()) {
      case 'auth_api_calls':
        return Icons.security;
      case 'user_api_calls':
        return Icons.person;
      case 'qr_api_calls':
        return Icons.qr_code;
      case 'total_api_requests':
        return Icons.api;
      default:
        return Icons.http;
    }
  }

  Color _getAPIColor(String key) {
    switch (key.toLowerCase()) {
      case 'auth_api_calls':
        return Colors.red;
      case 'user_api_calls':
        return Colors.blue;
      case 'qr_api_calls':
        return Colors.green;
      case 'total_api_requests':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
