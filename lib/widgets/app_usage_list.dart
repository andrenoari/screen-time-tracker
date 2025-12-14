import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/screen_time_provider.dart';
import '../theme/app_theme.dart';

class AppUsageList extends StatelessWidget {
  const AppUsageList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ScreenTimeProvider>(
      builder: (context, provider, child) {
        final usage = provider.aggregatedUsage;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'App Usage',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${usage.length} apps',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingM),
            if (usage.isEmpty)
              _buildEmptyState()
            else
              ...usage.asMap().entries.map((entry) {
                final index = entry.key;
                final app = entry.value;
                return _AppUsageItem(
                  app: app,
                  index: index,
                  color: AppTheme.chartColors[index % AppTheme.chartColors.length],
                );
              }),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingXL),
      decoration: BoxDecoration(
        color: AppTheme.backgroundCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: const Center(
        child: Column(
          children: [
            Icon(
              Icons.hourglass_empty_rounded,
              size: 48,
              color: AppTheme.textMuted,
            ),
            SizedBox(height: AppTheme.spacingM),
            Text(
              'No activity recorded yet',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Start using apps to see your screen time',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppUsageItem extends StatefulWidget {
  final dynamic app;
  final int index;
  final Color color;

  const _AppUsageItem({
    required this.app,
    required this.index,
    required this.color,
  });

  @override
  State<_AppUsageItem> createState() => _AppUsageItemState();
}

class _AppUsageItemState extends State<_AppUsageItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
        padding: const EdgeInsets.all(AppTheme.spacingM),
        decoration: BoxDecoration(
          color: _isHovered
              ? AppTheme.backgroundCardHover
              : AppTheme.backgroundCard,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: _isHovered ? widget.color.withOpacity(0.3) : AppTheme.borderColor,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // App Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    widget.color,
                    widget.color.withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _getAppInitial(widget.app.displayName),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spacingM),

            // App Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.app.displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        widget.app.formattedTime,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: widget.color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: widget.app.percentage / 100,
                            backgroundColor: AppTheme.surfaceDark,
                            valueColor: AlwaysStoppedAnimation<Color>(widget.color),
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${widget.app.percentage.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getAppInitial(String name) {
    if (name.isEmpty) return '?';
    if (name.contains(' ')) {
      final parts = name.split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }
}
