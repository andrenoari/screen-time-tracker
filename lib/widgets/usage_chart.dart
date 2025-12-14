import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/screen_time_provider.dart';
import '../theme/app_theme.dart';

class UsageChart extends StatefulWidget {
  const UsageChart({super.key});

  @override
  State<UsageChart> createState() => _UsageChartState();
}

class _UsageChartState extends State<UsageChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Consumer<ScreenTimeProvider>(
      builder: (context, provider, child) {
        final usage = provider.aggregatedUsage;

        if (usage.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          decoration: BoxDecoration(
            gradient: AppTheme.cardGradient,
            borderRadius: BorderRadius.circular(AppTheme.radiusXL),
            border: Border.all(color: AppTheme.borderColor),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Usage Breakdown',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppTheme.spacingL),
              SizedBox(
                height: 200,
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: PieChart(
                        PieChartData(
                          pieTouchData: PieTouchData(
                            touchCallback: (FlTouchEvent event, pieTouchResponse) {
                              setState(() {
                                if (!event.isInterestedForInteractions ||
                                    pieTouchResponse == null ||
                                    pieTouchResponse.touchedSection == null) {
                                  _touchedIndex = -1;
                                  return;
                                }
                                _touchedIndex = pieTouchResponse
                                    .touchedSection!.touchedSectionIndex;
                              });
                            },
                          ),
                          borderData: FlBorderData(show: false),
                          sectionsSpace: 2,
                          centerSpaceRadius: 50,
                          sections: _buildPieSections(usage),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingL),
                    Expanded(
                      flex: 3,
                      child: _buildLegend(usage),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<PieChartSectionData> _buildPieSections(List<dynamic> usage) {
    // Show top 5 apps, merge rest into "Other"
    final displayApps = usage.take(5).toList();
    final otherSeconds = usage.skip(5).fold<int>(0, (sum, app) => sum + app.totalSeconds as int);
    final totalSeconds = usage.fold<int>(0, (sum, app) => sum + app.totalSeconds as int);

    final sections = <PieChartSectionData>[];

    for (int i = 0; i < displayApps.length; i++) {
      final app = displayApps[i];
      final isTouched = i == _touchedIndex;
      final fontSize = isTouched ? 14.0 : 12.0;
      final radius = isTouched ? 55.0 : 45.0;
      final color = AppTheme.chartColors[i % AppTheme.chartColors.length];

      sections.add(
        PieChartSectionData(
          color: color,
          value: app.totalSeconds.toDouble(),
          title: '${app.percentage.toStringAsFixed(0)}%',
          radius: radius,
          titleStyle: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: const [
              Shadow(
                color: Colors.black26,
                blurRadius: 2,
              ),
            ],
          ),
          badgeWidget: isTouched
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundCard,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Text(
                    app.displayName,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                )
              : null,
          badgePositionPercentageOffset: 1.3,
        ),
      );
    }

    // Add "Other" section if there are more than 5 apps
    if (otherSeconds > 0 && totalSeconds > 0) {
      final otherPercentage = (otherSeconds / totalSeconds) * 100;
      final isTouched = displayApps.length == _touchedIndex;
      
      sections.add(
        PieChartSectionData(
          color: AppTheme.textMuted,
          value: otherSeconds.toDouble(),
          title: '${otherPercentage.toStringAsFixed(0)}%',
          radius: isTouched ? 55.0 : 45.0,
          titleStyle: TextStyle(
            fontSize: isTouched ? 14.0 : 12.0,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    return sections;
  }

  Widget _buildLegend(List<dynamic> usage) {
    final displayApps = usage.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ...displayApps.asMap().entries.map((entry) {
          final index = entry.key;
          final app = entry.value;
          final color = AppTheme.chartColors[index % AppTheme.chartColors.length];
          final isSelected = index == _touchedIndex;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: MouseRegion(
              onEnter: (_) => setState(() => _touchedIndex = index),
              onExit: (_) => setState(() => _touchedIndex = -1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withOpacity(0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: isSelected ? 14 : 10,
                      height: isSelected ? 14 : 10,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withOpacity(0.5),
                                  blurRadius: 6,
                                ),
                              ]
                            : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        app.displayName,
                        style: TextStyle(
                          fontSize: 13,
                          color: isSelected
                              ? AppTheme.textPrimary
                              : AppTheme.textSecondary,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      app.formattedTime,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? color : AppTheme.textMuted,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        if (usage.length > 5)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppTheme.textMuted,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '+${usage.length - 5} more apps',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
