import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StatsCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final LinearGradient? gradient;
  final Color? color;
  final bool isLarge;
  final double? valueSize;

  const StatsCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    this.gradient,
    this.color,
    this.isLarge = false,
    this.valueSize,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = color ?? AppTheme.primaryColor;

    return Container(
      padding: EdgeInsets.all(isLarge ? AppTheme.spacingL : AppTheme.spacingM),
      decoration: BoxDecoration(
        gradient: gradient ?? AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(
          color: gradient != null
              ? cardColor.withOpacity(0.3)
              : AppTheme.borderColor,
          width: 1,
        ),
        boxShadow: gradient != null
            ? [
                BoxShadow(
                  color: cardColor.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isLarge ? 12 : 8),
                decoration: BoxDecoration(
                  color: (gradient != null ? Colors.white : cardColor)
                      .withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: Icon(
                  icon,
                  size: isLarge ? 24 : 18,
                  color: gradient != null ? Colors.white : cardColor,
                ),
              ),
              const Spacer(),
              if (subtitle != null && !isLarge)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 10,
                      color: gradient != null
                          ? Colors.white70
                          : AppTheme.textMuted,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: isLarge ? AppTheme.spacingL : AppTheme.spacingM),
          Text(
            value,
            style: TextStyle(
              fontSize: valueSize ?? (isLarge ? 36 : 20),
              fontWeight: FontWeight.bold,
              color: gradient != null ? Colors.white : AppTheme.textPrimary,
              letterSpacing: -0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: isLarge ? 14 : 12,
              color: gradient != null
                  ? Colors.white.withOpacity(0.8)
                  : AppTheme.textMuted,
            ),
          ),
          if (subtitle != null && isLarge) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                subtitle!,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
