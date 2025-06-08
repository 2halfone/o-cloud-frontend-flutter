import 'package:flutter/material.dart';
import 'service_card.dart';
import '../../screens/admin_logs_screen.dart';
import '../../screens/user_detail_screen.dart';

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
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: isAdmin 
            ? GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.9,
                children: _buildServiceCards(context),
              )
            : Column(
                children: [
                  // Per utenti normali, mostra solo User Service in un layout centrato
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: _buildServiceCards(context).first,
                  ),
                  const SizedBox(height: 24),
                  // Messaggio informativo per utenti normali
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.symmetric(horizontal: 32.0),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.blue.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: Colors.blue[300],
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Additional services are available for administrators',
                            style: TextStyle(
                              color: Colors.blue[300],
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
        ),
      ],
    );
  }

  List<Widget> _buildServiceCards(BuildContext context) {
    List<Widget> cards = [
      // User Service - sempre visibile per tutti
      ServiceCard(
        title: 'User Service',
        description: 'Manage user accounts',
        icon: Icons.people_rounded,
        gradientColors: const [Color(0xFF667eea), Color(0xFF764ba2)],
        onTap: () => _navigateToUserService(context),
        isEnabled: true,
      ),
    ];

    // Servizi aggiuntivi solo per admin
    if (isAdmin) {
      cards.addAll([
        ServiceCard(
          title: 'Analytics',
          description: 'System logs & analytics',
          icon: Icons.analytics_rounded,
          gradientColors: const [Color(0xFFf093fb), Color(0xFFf5576c)],
          onTap: () => _navigateToAnalytics(context),
          isEnabled: true,
        ),
        ServiceCard(
          title: 'Cloud Storage',
          description: 'File management',
          icon: Icons.cloud_upload_rounded,
          gradientColors: const [Color(0xFF4facfe), Color(0xFF00f2fe)],
          onTap: () => _navigateToCloudStorage(context),
          isEnabled: true,
        ),
        ServiceCard(
          title: 'Security',
          description: 'Security monitoring',
          icon: Icons.security_rounded,
          gradientColors: const [Color(0xFFa8edea), Color(0xFFfed6e3)],
          onTap: () => _navigateToSecurity(context),
          isEnabled: true,
        ),
      ]);
    }

    return cards;
  }

  void _navigateToUserService(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const UserDetailScreen(userId: 'current_user'),
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
