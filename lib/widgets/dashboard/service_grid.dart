import 'package:flutter/material.dart';
import 'responsive_service_card.dart';
import '../../screens/admin_logs_screen.dart';
import '../../screens/qr_scanner_screen.dart';
import '../../screens/admin_qr_page.dart';

class ServiceGrid extends StatelessWidget {
  final bool isAdmin;

  const ServiceGrid({
    super.key,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            'Services',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 16),        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.0,
            children: _buildServiceCards(context),
          ),
        ),
      ],
    );
  }
  List<Widget> _buildServiceCards(BuildContext context) {
    List<Widget> cards = [      // QR Scanner - always visible for everyone
      ResponsiveServiceCard(
        title: 'QR Scanner',
        description: 'Scan QR for attendance',
        icon: Icons.qr_code_scanner,
        gradientColors: const [Color(0xFF667eea), Color(0xFF764ba2)],
        onTap: () => _navigateToQRScanner(context),
        isEnabled: true,
      ),
        // Chat Service - visible for everyone
      ResponsiveServiceCard(
        title: 'Chat Service',
        description: 'Real-time messaging',
        icon: Icons.chat_rounded,
        gradientColors: const [Color(0xFF667eea), Color(0xFF764ba2)],
        onTap: () => _navigateToChatService(context),
        isEnabled: true,
      ),
        // Shop - visible for everyone
      ResponsiveServiceCard(
        title: 'Shop',
        description: 'Online marketplace',
        icon: Icons.store_rounded,
        gradientColors: const [Color(0xFF4facfe), Color(0xFF00f2fe)],
        onTap: () => _navigateToShop(context),
        isEnabled: true,
      ),
        // Events - visible for everyone
      ResponsiveServiceCard(
        title: 'Events',
        description: 'Event management',
        icon: Icons.event_rounded,
        gradientColors: const [Color(0xFFf093fb), Color(0xFFf5576c)],
        onTap: () => _navigateToEvents(context),
        isEnabled: true,
      ),
        // Calendar - visible for everyone
      ResponsiveServiceCard(
        title: 'Calendar',
        description: 'Schedule & planning',
        icon: Icons.calendar_today_rounded,
        gradientColors: const [Color(0xFFa8edea), Color(0xFFfed6e3)],
        onTap: () => _navigateToCalendar(context),
        isEnabled: true,
      ),
    ];    // Additional services only for admin
    if (isAdmin) {      cards.addAll([
        ResponsiveServiceCard(
          title: 'QR Generator',
          description: 'Generate QR codes',
          icon: Icons.qr_code,
          gradientColors: const [Color(0xFF667eea), Color(0xFF764ba2)],
          onTap: () => _navigateToQRGenerator(context),
          isEnabled: true,
        ),
        ResponsiveServiceCard(
          title: 'Analytics',
          description: 'System logs & analytics',
          icon: Icons.analytics_rounded,
          gradientColors: const [Color(0xFFffecd2), Color(0xFFfcb69f)],
          onTap: () => _navigateToAnalytics(context),
          isEnabled: true,        ),
        ResponsiveServiceCard(
          title: 'Cloud Storage',
          description: 'File management',
          icon: Icons.cloud_upload_rounded,
          gradientColors: const [Color(0xFF89f7fe), Color(0xFF66a6ff)],
          onTap: () => _navigateToCloudStorage(context),
          isEnabled: true,        ),
        ResponsiveServiceCard(
          title: 'Security',
          description: 'Security monitoring',
          icon: Icons.security_rounded,
          gradientColors: const [Color(0xFFfbc2eb), Color(0xFFa6c1ee)],
          onTap: () => _navigateToSecurity(context),
          isEnabled: true,
        ),
      ]);
    }

    return cards;
  }  void _navigateToQRScanner(BuildContext context) {
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

  void _navigateToChatService(BuildContext context) {
    _showComingSoonDialog(context, 'Chat Service');
  }

  void _navigateToShop(BuildContext context) {
    _showComingSoonDialog(context, 'Shop');
  }

  void _navigateToEvents(BuildContext context) {
    _showComingSoonDialog(context, 'Events');
  }

  void _navigateToCalendar(BuildContext context) {
    _showComingSoonDialog(context, 'Calendar');
  }

  void _navigateToAnalytics(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AdminLogsScreen(),
      ),
    );
  }

  void _navigateToCloudStorage(BuildContext context) {
    _showComingSoonDialog(context, 'Cloud Storage');
  }

  void _navigateToSecurity(BuildContext context) {
    _showComingSoonDialog(context, 'Security');
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
