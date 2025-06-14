import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'logout_dialog.dart';

class SettingsSections extends StatefulWidget {
  const SettingsSections({super.key});

  @override
  State<SettingsSections> createState() => _SettingsSectionsState();
}

class _SettingsSectionsState extends State<SettingsSections> {  final AuthService _authService = AuthService();
  bool _isAdmin = false;
  bool _notificationsEnabled = true;
  bool _autoRefreshEnabled = true;
  bool _darkMode = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final isAdmin = await _authService.isUserAdmin();
    if (mounted) {
      setState(() {
        _isAdmin = isAdmin;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [          // Account Section
          _buildSection(
            title: 'Account',
            icon: Icons.person_rounded,
            children: [
              _buildSettingsItem(
                icon: Icons.edit_rounded,
                title: 'Edit Profile',
                subtitle: 'Update your personal information',
                onTap: () {
                  // TODO: Navigate to profile edit
                  _showComingSoon(context);
                },
              ),
              _buildSettingsItem(
                icon: Icons.security_rounded,
                title: 'Security',
                subtitle: 'Password and authentication',
                onTap: () {
                  // TODO: Navigate to security settings
                  _showComingSoon(context);
                },
              ),
            ],
          ),

          const SizedBox(height: 24),          // Preferences Section
          _buildSection(
            title: 'Preferences',
            icon: Icons.tune_rounded,
            children: [
              _buildSwitchItem(
                icon: Icons.notifications_rounded,
                title: 'Alert Notifications',
                subtitle: 'Receive critical system alerts',
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() {
                    _notificationsEnabled = value;
                  });
                  _handleNotificationChange(value);
                },
              ),
              _buildSwitchItem(
                icon: Icons.refresh_rounded,
                title: 'Auto Refresh',
                subtitle: 'Automatically refresh dashboard data',
                value: _autoRefreshEnabled,
                onChanged: (value) {
                  setState(() {
                    _autoRefreshEnabled = value;
                  });
                  _handleAutoRefreshChange(value);
                },
              ),
              _buildSwitchItem(
                icon: Icons.dark_mode_rounded,
                title: 'Dark Theme',
                subtitle: 'Enable dark theme for the app',
                value: _darkMode,
                onChanged: (value) {
                  setState(() {
                    _darkMode = value;
                  });
                },
              ),
              _buildSettingsItem(
                icon: Icons.language_rounded,
                title: 'Language',
                subtitle: 'English',
                onTap: () {
                  _showComingSoon(context);
                },
              ),
            ],
          ),

          const SizedBox(height: 24),          // Admin Section (only for admins)
          if (_isAdmin) ...[
            _buildSection(
              title: 'Administration',
              icon: Icons.admin_panel_settings_rounded,
              children: [                _buildSettingsItem(
                  icon: Icons.analytics_rounded,
                  title: 'Analytics',
                  subtitle: 'View statistics and metrics',
                  onTap: () {
                    _showAnalyticsInfo(context);
                  },
                ),
                _buildSettingsItem(
                  icon: Icons.people_rounded,
                  title: 'User Management',
                  subtitle: 'Manage system users',
                  onTap: () {
                    _showUserManagementInfo(context);
                  },
                ),
                _buildSettingsItem(
                  icon: Icons.storage_rounded,
                  title: 'System Management',
                  subtitle: 'Advanced configurations',
                  onTap: () {
                    _showSystemManagementInfo(context);
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],          // Support Section
          _buildSection(
            title: 'Support',
            icon: Icons.help_outline_rounded,
            children: [
              _buildSettingsItem(
                icon: Icons.help_center_rounded,
                title: 'Help Center',
                subtitle: 'FAQ and user guides',
                onTap: () {
                  _showComingSoon(context);
                },
              ),
              _buildSettingsItem(
                icon: Icons.bug_report_rounded,
                title: 'Report Bug',
                subtitle: 'Send us feedback about issues',
                onTap: () {
                  _showComingSoon(context);
                },
              ),
              _buildSettingsItem(
                icon: Icons.info_outline_rounded,
                title: 'App Information',
                subtitle: 'Version 1.0.0',
                onTap: () {
                  _showAppInfo(context);
                },
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Logout Button
          _buildLogoutButton(),
        ],
      ),
    );
  }

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
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.5),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF4CAF50),
            activeTrackColor: const Color(0xFF4CAF50).withValues(alpha: 0.3),
            inactiveThumbColor: Colors.white.withValues(alpha: 0.7),
            inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => LogoutDialog.show(context),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFf85032).withValues(alpha: 0.8),
                  const Color(0xFFe73827).withValues(alpha: 0.9),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFf85032).withValues(alpha: 0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.logout_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: 12),
                Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  void _showComingSoon(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Coming Soon',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This feature will be available in upcoming updates.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(color: Color(0xFF667eea)),
            ),
          ),
        ],
      ),
    );
  }
  void _showAppInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'App Information',
          style: TextStyle(color: Colors.white),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('GoCloud Frontend', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Version: 1.0.0', style: TextStyle(color: Colors.white70)),
            Text('Build: 001', style: TextStyle(color: Colors.white70)),
            SizedBox(height: 12),
            Text('Developed with Flutter', style: TextStyle(color: Colors.white70)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: Color(0xFF667eea)),
            ),
          ),
        ],      ),
    );
  }

  // Handle notification settings change
  void _handleNotificationChange(bool enabled) {
    if (enabled) {
      // Show confirmation that notifications are enabled
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF4CAF50),
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Critical alerts enabled',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          duration: Duration(seconds: 3),
        ),
      );
    } else {
      // Show warning that notifications are disabled
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.orange,
          content: Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Critical alerts disabled',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  // Handle auto refresh settings change
  void _handleAutoRefreshChange(bool enabled) {
    if (enabled) {
      // Show confirmation that auto refresh is enabled
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF2196F3),
          content: Row(
            children: [
              Icon(Icons.refresh, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Auto refresh enabled (30s)',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          duration: Duration(seconds: 3),
        ),
      );
    } else {
      // Show info that auto refresh is disabled
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.grey[600],
          content: const Row(
            children: [
              Icon(Icons.pause_circle, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Auto refresh disabled',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          duration: const Duration(seconds: 3),
        ),      );
    }
  }

  // Show Analytics information and options
  void _showAnalyticsInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.analytics_rounded, color: Color(0xFF4facfe)),
            SizedBox(width: 12),
            Text(
              'Analytics Overview',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'System Analytics',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• QR Code scans: 1,247 today', style: TextStyle(color: Colors.white70)),
            Text('• Active users: 89 online', style: TextStyle(color: Colors.white70)),
            Text('• System uptime: 99.8%', style: TextStyle(color: Colors.white70)),
            Text('• API responses: <120ms avg', style: TextStyle(color: Colors.white70)),
            SizedBox(height: 12),
            Text(
              'View detailed analytics in Prometheus Dashboard',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: Color(0xFF4facfe)),
            ),
          ),
        ],
      ),
    );
  }

  // Show User Management information and options
  void _showUserManagementInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.people_rounded, color: Color(0xFF11998e)),
            SizedBox(width: 12),
            Text(
              'User Management',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current User Stats',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• Total registered: 156 users', style: TextStyle(color: Colors.white70)),
            Text('• Active today: 89 users', style: TextStyle(color: Colors.white70)),
            Text('• Admin users: 3 admins', style: TextStyle(color: Colors.white70)),
            Text('• New registrations: 5 today', style: TextStyle(color: Colors.white70)),
            SizedBox(height: 12),
            Text(
              'Access Admin Events Monitor for detailed user management',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: Color(0xFF11998e)),
            ),
          ),
        ],
      ),
    );
  }

  // Show System Management information and options
  void _showSystemManagementInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.storage_rounded, color: Color(0xFFfa709a)),
            SizedBox(width: 12),
            Text(
              'System Management',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'System Status',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• Server status: ✅ Online', style: TextStyle(color: Colors.white70)),
            Text('• Database: ✅ Connected', style: TextStyle(color: Colors.white70)),
            Text('• APIs: ✅ All operational', style: TextStyle(color: Colors.white70)),
            Text('• Memory usage: 67%', style: TextStyle(color: Colors.white70)),
            Text('• CPU usage: 23%', style: TextStyle(color: Colors.white70)),
            SizedBox(height: 12),
            Text(
              'Check Prometheus Dashboard for detailed system metrics',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: Color(0xFFfa709a)),
            ),
          ),
        ],
      ),
    );
  }
}