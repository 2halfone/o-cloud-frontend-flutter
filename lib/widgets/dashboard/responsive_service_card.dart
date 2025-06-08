import 'package:flutter/material.dart';

class ResponsiveServiceCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final List<Color> gradientColors;
  final VoidCallback onTap;
  final bool isEnabled;

  const ResponsiveServiceCard({
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
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate responsive dimensions based on available space
        final cardWidth = constraints.maxWidth;
        final cardHeight = constraints.maxHeight;
        
        // Responsive sizing
        final iconSize = (cardHeight * 0.25).clamp(20.0, 40.0);
        final titleFontSize = (cardWidth * 0.08).clamp(12.0, 16.0);
        final descriptionFontSize = (cardWidth * 0.06).clamp(10.0, 13.0);
        final padding = (cardWidth * 0.06).clamp(8.0, 16.0);
        
        return Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: isEnabled ? onTap : null,
            borderRadius: BorderRadius.circular(20),
            splashColor: isEnabled 
              ? gradientColors[0].withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.1),
            highlightColor: isEnabled 
              ? gradientColors[0].withValues(alpha: 0.05)
              : Colors.grey.withValues(alpha: 0.05),
            child: Container(
              width: cardWidth,
              height: cardHeight,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.08),
                    Colors.white.withValues(alpha: 0.03),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                    spreadRadius: 1,
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                    spreadRadius: 0,
                  ),
                  if (isEnabled)
                    BoxShadow(
                      color: gradientColors[0].withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                      spreadRadius: 1,
                    ),
                ],
              ),              child: Padding(
                padding: EdgeInsets.all(padding),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Icon section - centered
                    Container(
                      width: iconSize + 16,
                      height: iconSize + 16,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isEnabled 
                            ? gradientColors 
                            : [Colors.grey.shade600, Colors.grey.shade700],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: (isEnabled ? gradientColors[0] : Colors.grey)
                                .withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                            spreadRadius: 1,
                          ),
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.1),
                            blurRadius: 3,
                            offset: const Offset(0, -1),
                          ),
                        ],
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: iconSize,
                      ),
                    ),
                    
                    SizedBox(height: padding * 0.8),
                    
                    // Title section - centered
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.1,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    SizedBox(height: padding * 0.4),
                    
                    // Description section - centered
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: descriptionFontSize,
                        color: Colors.grey[400],
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    // Admin badge - only if not enabled
                    if (!isEnabled) ...[
                      SizedBox(height: padding * 0.6),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: padding * 0.5,
                          vertical: padding * 0.25,
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
                        ),
                        child: Text(
                          'Admin Only',
                          style: TextStyle(
                            fontSize: (descriptionFontSize * 0.8).clamp(8.0, 10.0),
                            color: Colors.orange[300],
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
