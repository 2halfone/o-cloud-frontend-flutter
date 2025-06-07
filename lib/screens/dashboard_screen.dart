import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class DashboardScreen extends StatefulWidget {
  final String? userId;
  
  const DashboardScreen({super.key, this.userId});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _authService = AuthService();
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  String _selectedTab = 'overview';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      // Ottieni dati utente dal secure storage o dall'API
      final userEmail = await _authService.getUserEmail();
      final userId = await _authService.getUserId();
      
      setState(() {
        _userData = {
          'email': userEmail ?? 'No email',
          'id': userId ?? 'No ID',
          'username': 'Flutter User', // Placeholder
        };
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    await _authService.logout();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cloud Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // TODO: Implement notifications
            },
          ),          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle),
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'profile',
                child: const ListTile(
                  leading: Icon(Icons.person),
                  title: Text('Profile'),
                ),
              ),
              PopupMenuItem<String>(
                value: 'settings',
                child: const ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Settings'),
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'logout',
                child: const ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Logout'),
                ),
              ),
            ],
            onSelected: (String value) {
              switch (value) {
                case 'profile':
                  _selectTab('profile');
                  break;
                case 'settings':
                  _selectTab('settings');
                  break;
                case 'logout':
                  _logout();
                  break;
              }
            },
          ),
        ],
      ),
      body: Row(
        children: [
          // Sidebar per desktop
          if (MediaQuery.of(context).size.width > 768)
            _buildSidebar(),
          // Main content
          Expanded(
            child: _buildMainContent(),
          ),
        ],
      ),
      bottomNavigationBar: MediaQuery.of(context).size.width <= 768
          ? _buildBottomNavigation()
          : null,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Add quick action
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Quick action pressed!')),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 250,
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          // User info section
          Container(
            padding: const EdgeInsets.all(20),            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    _userData?['email']?.substring(0, 1).toUpperCase() ?? 'U',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _userData?['username'] ?? 'User',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _userData?['email'] ?? '',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          // Navigation items
          Expanded(
            child: ListView(
              children: [
                _buildNavItem(Icons.dashboard, 'Overview', 'overview'),
                _buildNavItem(Icons.cloud, 'Cloud Services', 'services'),
                _buildNavItem(Icons.storage, 'Storage', 'storage'),
                _buildNavItem(Icons.analytics, 'Analytics', 'analytics'),
                _buildNavItem(Icons.person, 'Profile', 'profile'),
                _buildNavItem(Icons.settings, 'Settings', 'settings'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String title, String tab) {
    final isSelected = _selectedTab == tab;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected 
            ? Theme.of(context).colorScheme.primary 
            : Colors.grey[600],
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected 
              ? Theme.of(context).colorScheme.primary 
              : Colors.grey[800],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onTap: () => _selectTab(tab),
    );
  }

  Widget _buildBottomNavigation() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _getBottomNavIndex(),
      onTap: (index) {
        final tabs = ['overview', 'services', 'analytics', 'profile'];
        if (index < tabs.length) {
          _selectTab(tabs[index]);
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Overview',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.cloud),
          label: 'Services',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.analytics),
          label: 'Analytics',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }

  int _getBottomNavIndex() {
    switch (_selectedTab) {
      case 'overview': return 0;
      case 'services': return 1;
      case 'analytics': return 2;
      case 'profile': return 3;
      default: return 0;
    }
  }

  void _selectTab(String tab) {
    setState(() {
      _selectedTab = tab;
    });
  }

  Widget _buildMainContent() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            _getTabTitle(),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          // Content based on selected tab
          Expanded(
            child: _buildTabContent(),
          ),
        ],
      ),
    );
  }

  String _getTabTitle() {
    switch (_selectedTab) {
      case 'overview': return 'Dashboard Overview';
      case 'services': return 'Cloud Services';
      case 'storage': return 'Storage Management';
      case 'analytics': return 'Analytics';
      case 'profile': return 'User Profile';
      case 'settings': return 'Settings';
      default: return 'Dashboard';
    }
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 'overview':
        return _buildOverviewTab();
      case 'services':
        return _buildServicesTab();
      case 'storage':
        return _buildStorageTab();
      case 'analytics':
        return _buildAnalyticsTab();
      case 'profile':
        return _buildProfileTab();
      case 'settings':
        return _buildSettingsTab();
      default:
        return _buildOverviewTab();
    }
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Stats cards
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: MediaQuery.of(context).size.width > 768 ? 4 : 2,
            childAspectRatio: 1.5,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: [
              _buildStatsCard('Active Services', '12', Icons.cloud, Colors.blue),
              _buildStatsCard('Storage Used', '2.3 GB', Icons.storage, Colors.green),
              _buildStatsCard('API Calls', '1,234', Icons.api, Colors.orange),
              _buildStatsCard('Uptime', '99.9%', Icons.trending_up, Colors.purple),
            ],
          ),
          const SizedBox(height: 30),
          // Recent activity
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent Activity',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildActivityItem('User logged in', '2 minutes ago', Icons.login),
                  _buildActivityItem('Service deployed', '1 hour ago', Icons.rocket_launch),
                  _buildActivityItem('Backup completed', '3 hours ago', Icons.backup),
                  _buildActivityItem('New user registered', '5 hours ago', Icons.person_add),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(String title, String time, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            child: Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(time, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesTab() {
    return GridView.count(
      crossAxisCount: MediaQuery.of(context).size.width > 768 ? 3 : 2,
      childAspectRatio: 1.2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _buildServiceCard('Compute Engine', 'Running', Icons.computer, Colors.green),
        _buildServiceCard('Cloud Storage', 'Active', Icons.cloud_upload, Colors.blue),
        _buildServiceCard('Database', 'Connected', Icons.storage, Colors.orange),
        _buildServiceCard('API Gateway', 'Online', Icons.api, Colors.purple),
        _buildServiceCard('Load Balancer', 'Healthy', Icons.balance, Colors.teal),
        _buildServiceCard('Monitoring', 'Active', Icons.monitor_heart, Colors.red),
      ],
    );
  }

  Widget _buildServiceCard(String name, String status, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 12),
            Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status,
                style: TextStyle(color: color, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageTab() {
    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Storage Usage', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: 0.65,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(height: 8),
                const Text('6.5 GB of 10 GB used'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Recent Files', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: 5,
                      itemBuilder: (context, index) {
                        final files = [
                          {'name': 'backup_2025.zip', 'size': '1.2 GB', 'type': 'archive'},
                          {'name': 'database.sql', 'size': '450 MB', 'type': 'database'},
                          {'name': 'images.tar', 'size': '2.1 GB', 'type': 'media'},
                          {'name': 'logs.txt', 'size': '15 MB', 'type': 'text'},
                          {'name': 'config.json', 'size': '2 KB', 'type': 'config'},
                        ];
                        final file = files[index];
                        return ListTile(
                          leading: Icon(_getFileIcon(file['type']!)),
                          title: Text(file['name']!),
                          subtitle: Text(file['size']!),
                          trailing: IconButton(
                            icon: const Icon(Icons.more_vert),
                            onPressed: () {},
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  IconData _getFileIcon(String type) {
    switch (type) {
      case 'archive': return Icons.archive;
      case 'database': return Icons.storage;
      case 'media': return Icons.image;
      case 'text': return Icons.description;
      case 'config': return Icons.settings;
      default: return Icons.file_present;
    }
  }

  Widget _buildAnalyticsTab() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text('API Requests', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(
                        '1,234',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text('Last 24h'),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text('Error Rate', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(
                        '0.1%',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text('Last 24h'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Performance Metrics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.show_chart, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'Analytics Chart Placeholder',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          const Text('Chart implementation would go here'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      _userData?['email']?.substring(0, 1).toUpperCase() ?? 'U',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _userData?['username'] ?? 'User',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _userData?['email'] ?? '',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ID: ${_userData?['id'] ?? 'Unknown'}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Edit Profile'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Edit profile feature coming soon!')),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.security),
                  title: const Text('Change Password'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Change password feature coming soon!')),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.privacy_tip),
                  title: const Text('Privacy Settings'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Privacy settings coming soon!')),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'General Settings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                SwitchListTile(
                  title: const Text('Dark Mode'),
                  subtitle: const Text('Toggle dark/light theme'),
                  value: Theme.of(context).brightness == Brightness.dark,
                  onChanged: (value) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Theme toggle coming soon!')),
                    );
                  },
                ),
                SwitchListTile(
                  title: const Text('Push Notifications'),
                  subtitle: const Text('Receive notifications'),
                  value: true,
                  onChanged: (value) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Notification settings updated!')),
                    );
                  },
                ),
                SwitchListTile(
                  title: const Text('Auto Backup'),
                  subtitle: const Text('Automatically backup data'),
                  value: false,
                  onChanged: (value) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Auto backup toggled!')),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'About',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const ListTile(
                  leading: Icon(Icons.info),
                  title: Text('App Version'),
                  subtitle: Text('1.0.0'),
                ),
                ListTile(
                  leading: const Icon(Icons.help),
                  title: const Text('Help & Support'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Help section coming soon!')),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.description),
                  title: const Text('Terms & Privacy'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Legal documents coming soon!')),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
