import 'package:flutter/material.dart';
import 'responsive_service_card.dart';
import '../../screens/admin_logs_screen.dart';
import '../../screens/qr_scanner_screen.dart';
import '../../screens/admin_qr_page.dart';
import '../../screens/admin_events_monitor_screen.dart';
import '../../screens/prometheus_monitor_screen.dart';

class ServiceGrid extends StatelessWidget {
  final bool isAdmin;

  const ServiceGrid({
    super.key,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    final cards = _buildServiceCards(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.0),
          child: Text(
            'Services',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.0,
            children: cards,
          ),
        ),
      ],
    );
  }
  List<Widget> _buildServiceCards(BuildContext context) {
    // SERVIZI ATTIVI (implementati) - IN ALTO
    List<Widget> cards = [
      // QR Scanner - sempre visibile per tutti (ATTIVO)
      ResponsiveServiceCard(
        title: 'QR Scanner',
        description: 'Scan QR for attendance',
        icon: Icons.qr_code_scanner,
        gradientColors: const [Color(0xFF667eea), Color(0xFF764ba2)],
        onTap: () => _navigateToQRScanner(context),
        isEnabled: true,
      ),
    ];
    
    // ADMIN SERVICES (se admin) - ATTIVI
    if (isAdmin) {
      cards.addAll([
        // Prometheus - monitoraggio sistema (SOLO ADMIN)
        ResponsiveServiceCard(
          title: 'Prometheus',
          description: 'System monitoring',
          icon: Icons.monitor_heart_rounded,
          gradientColors: const [Color(0xFFfbc2eb), Color(0xFFa6c1ee)],
          onTap: () => _navigateToPrometheus(context),
          isEnabled: true,
        ),
        ResponsiveServiceCard(
          title: 'QR Generator',
          description: 'Generate QR codes',
          icon: Icons.qr_code,
          gradientColors: const [Color(0xFF667eea), Color(0xFF764ba2)],
          onTap: () => _navigateToQRGenerator(context),
          isEnabled: true,
        ),
        ResponsiveServiceCard(
          title: 'Events Monitor',
          description: 'Monitor attendance events',
          icon: Icons.monitor_heart_rounded,
          gradientColors: const [Color(0xFF11998e), Color(0xFF38ef7d)],
          onTap: () => _navigateToEventsMonitor(context),
          isEnabled: true,
        ),
        ResponsiveServiceCard(
          title: 'Analytics',
          description: 'System logs & analytics',
          icon: Icons.analytics_rounded,
          gradientColors: const [Color(0xFFffecd2), Color(0xFFfcb69f)],
          onTap: () => _navigateToAnalytics(context),
          isEnabled: true,
        ),
      ]);
    }
    
    // SERVIZI FUTURI (non implementati) - IN BASSO
    cards.addAll([
      // Chat Service - FUTURO
      ResponsiveServiceCard(
        title: 'Chat Service',
        description: 'Coming soon',
        icon: Icons.chat_rounded,
        gradientColors: const [Color(0xFF9E9E9E), Color(0xFF757575)],
        onTap: () => _showComingSoonDialog(context, 'Chat Service'),
        isEnabled: false,
      ),
      
      // Shop - FUTURO
      ResponsiveServiceCard(
        title: 'Shop',
        description: 'Coming soon',
        icon: Icons.store_rounded,
        gradientColors: const [Color(0xFF9E9E9E), Color(0xFF757575)],
        onTap: () => _showComingSoonDialog(context, 'Shop'),
        isEnabled: false,
      ),
      
      // Events - FUTURO
      ResponsiveServiceCard(
        title: 'Events',
        description: 'Coming soon',
        icon: Icons.event_rounded,
        gradientColors: const [Color(0xFF9E9E9E), Color(0xFF757575)],
        onTap: () => _showComingSoonDialog(context, 'Events'),
        isEnabled: false,
      ),
      
      // Calendar - FUTURO
      ResponsiveServiceCard(
        title: 'Calendar',
        description: 'Coming soon',
        icon: Icons.calendar_today_rounded,
        gradientColors: const [Color(0xFF9E9E9E), Color(0xFF757575)],
        onTap: () => _showComingSoonDialog(context, 'Calendar'),
        isEnabled: false,
      ),
    ]);
    
    // Solo per admin: Cloud Storage - FUTURO
    if (isAdmin) {
      cards.add(
        ResponsiveServiceCard(
          title: 'Cloud Storage',
          description: 'Coming soon',
          icon: Icons.cloud_upload_rounded,
          gradientColors: const [Color(0xFF9E9E9E), Color(0xFF757575)],
          onTap: () => _showComingSoonDialog(context, 'Cloud Storage'),
          isEnabled: false,
        ),
      );
    }

    return cards;
  }

  void _navigateToQRScanner(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const QRScannerScreen(),
      ),
    );
  }

  void _navigateToQRGenerator(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AdminQrPage(),
      ),
    );
  }

  void _navigateToEventsMonitor(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AdminEventsMonitorScreen(),
      ),
    );
  }

  void _navigateToAnalytics(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AdminLogsScreen(),
      ),
    );
  }

  void _navigateToPrometheus(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PrometheusMonitorScreen(),
      ),
    );
  }

  void _showComingSoonDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            '$feature Coming Soon',
            style: const TextStyle(color: Colors.white),
          ),
          content: Text(
            'This feature is under development and will be available soon.',
            style: TextStyle(color: Colors.grey[400]),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667eea),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'OK',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}
