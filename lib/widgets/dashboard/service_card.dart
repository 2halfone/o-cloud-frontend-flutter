import 'package:flutter/material.dart';

class ServiceCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final List<Color> gradientColors;
  final VoidCallback onTap;
  final bool isEnabled;

  const ServiceCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.gradientColors,
    required this.onTap,
    this.isEnabled = true,
  });
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(24),
        splashColor: isEnabled 
          ? gradientColors[0].withValues(alpha: 0.1)
          : Colors.grey.withValues(alpha: 0.1),
        highlightColor: isEnabled 
          ? gradientColors[0].withValues(alpha: 0.05)
          : Colors.grey.withValues(alpha: 0.05),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.08),
                Colors.white.withValues(alpha: 0.03),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1.5,
            ),
            boxShadow: [
              // Main shadow for depth
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: 2,
              ),
              // Inner highlight
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.1),
                blurRadius: 6,
                offset: const Offset(0, -3),
                spreadRadius: 0,
              ),
              // Colored glow for enabled cards
              if (isEnabled)
                BoxShadow(
                  color: gradientColors[0].withValues(alpha: 0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                  spreadRadius: 1,
                ),
            ],
          ),          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon with gradient background
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isEnabled 
                        ? gradientColors 
                        : [Colors.grey.shade600, Colors.grey.shade700],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: (isEnabled ? gradientColors[0] : Colors.grey)
                            .withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                        spreadRadius: 1,
                      ),
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 26,
                  ),
                ),                
                const SizedBox(height: 12),
                
                // Title - with overflow protection
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 4),                // Description - with overflow protection
                Flexible(
                  child: Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[400],
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
                const SizedBox(height: 10),
                
                // Action indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (!isEnabled)                        Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.orange.withValues(alpha: 0.3),
                                Colors.orange.withValues(alpha: 0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.orange.withValues(alpha: 0.4),
                              width: 0.5,
                            ),
                          ),                          child: Text(
                            'Admin Only',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.orange[300],
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                    else
                      const SizedBox(),                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.grey[300],
                        size: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
