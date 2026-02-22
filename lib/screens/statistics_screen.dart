import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/screen_time_provider.dart';
import '../providers/settings_provider.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  int _selectedTimeRange = 7; // 7 days default

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return ScaffoldPage(
      padding: EdgeInsets.zero,
      content: SingleChildScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header
            _buildHeader(theme, isLight),
            const SizedBox(height: 24),

            // Quick Stats Row
            _buildQuickStats(theme, isLight),
            const SizedBox(height: 24),

            // Daily Usage Chart + Top Apps Row
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Daily Usage Chart
                  Expanded(
                    flex: 3,
                    child: _buildDailyChart(theme, isLight),
                  ),
                  const SizedBox(width: 16),
                  // Top Apps this week
                  Expanded(
                    flex: 2,
                    child: _buildTopAppsCard(theme, isLight),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Usage Insights + Weekly Comparison Row
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Usage Insights
                  Expanded(
                    child: _buildUsagePatternCard(theme, isLight),
                  ),
                  const SizedBox(width: 16),
                  // Weekly Comparison
                  Expanded(
                    child: _buildTrendsCard(theme, isLight),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(FluentThemeData theme, bool isLight) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistics',
              style: theme.typography.title?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Detailed insights into your screen time',
              style: theme.typography.body?.copyWith(
                color: isLight ? Colors.grey[130] : Colors.grey[100],
              ),
            ),
          ],
        ),
        Row(
          children: [
            // Time range selector
            Container(
              decoration: BoxDecoration(
                color: isLight
                    ? const Color(0xFFF3F3F3)
                    : const Color(0xFF2D2D2D),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isLight
                      ? const Color(0xFFE5E5E5)
                      : const Color(0xFF3D3D3D),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _TimeRangeButton(
                    label: '7D',
                    isSelected: _selectedTimeRange == 7,
                    onPressed: () => setState(() => _selectedTimeRange = 7),
                    isFirst: true,
                    isLight: isLight,
                  ),
                  _TimeRangeButton(
                    label: '14D',
                    isSelected: _selectedTimeRange == 14,
                    onPressed: () => setState(() => _selectedTimeRange = 14),
                    isLight: isLight,
                  ),
                  _TimeRangeButton(
                    label: '30D',
                    isSelected: _selectedTimeRange == 30,
                    onPressed: () => setState(() => _selectedTimeRange = 30),
                    isLast: true,
                    isLight: isLight,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(FluentIcons.refresh, size: 14),
                  SizedBox(width: 8),
                  Text('Refresh'),
                ],
              ),
              onPressed: () {
                context.read<ScreenTimeProvider>().refreshData();
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickStats(FluentThemeData theme, bool isLight) {
    return Consumer<ScreenTimeProvider>(
      builder: (context, provider, child) {
        final dailyData = provider.dailyUsage;

        int totalSeconds = 0;
        int maxSeconds = 0;
        int minSeconds = dailyData.isNotEmpty ? 999999 : 0;
        String maxDay = '';

        for (final data in dailyData) {
          final seconds = data['total_seconds'] as int? ?? 0;
          totalSeconds += seconds;
          if (seconds > maxSeconds) {
            maxSeconds = seconds;
            maxDay = data['date'] as String? ?? '';
          }
          if (seconds < minSeconds && seconds > 0) {
            minSeconds = seconds;
          }
        }

        final avgSeconds = dailyData.isEmpty ? 0 : totalSeconds ~/ dailyData.length;
        
        // Calculate trend (compare first half vs second half)
        String trendText = 'No change';
        IconData trendIcon = FluentIcons.remove;
        Color trendColor = Colors.grey;
        
        if (dailyData.length >= 4) {
          final midPoint = dailyData.length ~/ 2;
          int firstHalf = 0;
          int secondHalf = 0;
          
          for (int i = 0; i < midPoint; i++) {
            firstHalf += (dailyData[i]['total_seconds'] as int? ?? 0);
          }
          for (int i = midPoint; i < dailyData.length; i++) {
            secondHalf += (dailyData[i]['total_seconds'] as int? ?? 0);
          }
          
          if (firstHalf > 0) {
            final change = ((secondHalf - firstHalf) / firstHalf * 100).round();
            if (change > 5) {
              trendText = '+$change%';
              trendIcon = FluentIcons.up;
              trendColor = Colors.orange;
            } else if (change < -5) {
              trendText = '$change%';
              trendIcon = FluentIcons.down;
              trendColor = Colors.green;
            }
          }
        }

        return Row(
          children: [
            Expanded(
              child: _QuickStatCard(
                icon: FluentIcons.timer,
                title: 'Total Time',
                value: _formatTime(totalSeconds),
                subtitle: 'Last $_selectedTimeRange days',
                accentColor: theme.accentColor,
                isLight: isLight,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickStatCard(
                icon: FluentIcons.calendar,
                title: 'Daily Average',
                value: _formatTime(avgSeconds),
                subtitle: 'Per day',
                accentColor: Colors.teal,
                isLight: isLight,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickStatCard(
                icon: FluentIcons.trophy2,
                title: 'Peak Day',
                value: maxDay.isEmpty ? '—' : DateFormat('EEE').format(DateTime.parse(maxDay)),
                subtitle: maxDay.isEmpty ? 'No data' : _formatTime(maxSeconds),
                accentColor: Colors.orange,
                isLight: isLight,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickStatCard(
                icon: trendIcon,
                title: 'Trend',
                value: trendText,
                subtitle: 'vs previous period',
                accentColor: trendColor,
                isLight: isLight,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDailyChart(FluentThemeData theme, bool isLight) {
    return Consumer<ScreenTimeProvider>(
      builder: (context, provider, child) {
        final dailyData = provider.dailyUsage;

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isLight
                ? const Color(0xFFF9F9F9)
                : const Color(0xFF2D2D2D),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isLight
                  ? const Color(0xFFE5E5E5)
                  : const Color(0xFF3D3D3D),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daily Screen Time',
                        style: theme.typography.bodyStrong,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your usage over the past week',
                        style: theme.typography.caption?.copyWith(
                          color: isLight ? Colors.grey[130] : Colors.grey[100],
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Last 7 days',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.accentColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 220,
                child: dailyData.isEmpty
                    ? _buildEmptyState(theme, isLight, FluentIcons.bar_chart4, 'No usage data available')
                    : BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: _getMaxY(dailyData),
                          barTouchData: BarTouchData(
                            enabled: true,
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipColor: (group) => isLight
                                  ? Colors.white
                                  : const Color(0xFF3D3D3D),
                              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                final date = DateTime.parse(
                                  dailyData[groupIndex]['date'] as String,
                                );
                                final hours = rod.toY ~/ 3600;
                                final minutes = (rod.toY % 3600) ~/ 60;
                                return BarTooltipItem(
                                  '${DateFormat('MMM d').format(date)}\n${hours}h ${minutes}m',
                                  TextStyle(
                                    color: isLight ? Colors.grey[160] : Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                );
                              },
                            ),
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  if (value.toInt() >= dailyData.length) {
                                    return const SizedBox();
                                  }
                                  final date = DateTime.parse(
                                    dailyData[value.toInt()]['date'] as String,
                                  );
                                  final isToday = DateFormat('yyyy-MM-dd').format(DateTime.now()) ==
                                      dailyData[value.toInt()]['date'];
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      isToday ? 'Today' : DateFormat('E').format(date),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: isToday ? FontWeight.w600 : FontWeight.normal,
                                        color: isToday 
                                            ? theme.accentColor 
                                            : (isLight ? Colors.grey[130] : Colors.grey[100]),
                                      ),
                                    ),
                                  );
                                },
                                reservedSize: 30,
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final hours = value ~/ 3600;
                                  return Text(
                                    '${hours}h',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isLight ? Colors.grey[130] : Colors.grey[100],
                                    ),
                                  );
                                },
                                reservedSize: 35,
                                interval: 3600,
                              ),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: 3600,
                            getDrawingHorizontalLine: (value) {
                              return FlLine(
                                color: isLight
                                    ? Colors.grey[50]!
                                    : Colors.grey[150]!.withOpacity(0.2),
                                strokeWidth: 1,
                              );
                            },
                          ),
                          barGroups: dailyData.asMap().entries.map((entry) {
                            final index = entry.key;
                            final data = entry.value;
                            final isToday = DateFormat('yyyy-MM-dd').format(DateTime.now()) ==
                                data['date'];
                            return BarChartGroupData(
                              x: index,
                              barRods: [
                                BarChartRodData(
                                  toY: (data['total_seconds'] as int).toDouble(),
                                  gradient: LinearGradient(
                                    colors: isToday
                                        ? [theme.accentColor.lighter, theme.accentColor]
                                        : [theme.accentColor.withOpacity(0.7), theme.accentColor.withOpacity(0.9)],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                  width: 32,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(4),
                                    topRight: Radius.circular(4),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopAppsCard(FluentThemeData theme, bool isLight) {
    return Consumer<ScreenTimeProvider>(
      builder: (context, provider, child) {
        final apps = provider.aggregatedUsage.take(5).toList();

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isLight
                ? const Color(0xFFF9F9F9)
                : const Color(0xFF2D2D2D),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isLight
                  ? const Color(0xFFE5E5E5)
                  : const Color(0xFF3D3D3D),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Top Applications',
                    style: theme.typography.bodyStrong,
                  ),
                  Icon(
                    FluentIcons.app_icon_default,
                    size: 16,
                    color: isLight ? Colors.grey[130] : Colors.grey[100],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (apps.isEmpty)
                _buildEmptyState(theme, isLight, FluentIcons.app_icon_default, 'No apps tracked yet')
              else
                ...apps.asMap().entries.map((entry) {
                  final index = entry.key;
                  final app = entry.value;
                  return _AppListItem(
                    rank: index + 1,
                    name: app.displayName,
                    time: app.formattedTime,
                    percentage: app.percentage,
                    theme: theme,
                    isLight: isLight,
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUsagePatternCard(FluentThemeData theme, bool isLight) {
    return Consumer2<ScreenTimeProvider, SettingsProvider>(
      builder: (context, provider, settings, child) {
        // Calculate Insights dynamically
        final String productiveTime;
        final String totalTime;
        final String focusSessions;
        final String breakStatus;
        Color? breakColor;

        if (provider.totalSecondsToday == 0) {
          productiveTime = 'No data yet';
          totalTime = 'No data yet';
          focusSessions = '0 sessions';
          breakStatus = 'Start tracking!';
          breakColor = Colors.grey[100];
        } else {
          // Calculate Productive Time String
          double pScore = provider.focusScore;
          if (pScore >= 80) productiveTime = 'Excellent focus';
          else if (pScore >= 50) productiveTime = 'Good focus';
          else productiveTime = 'Needs improvement';

          // Calculate Total Time Insight String
          int hours = provider.totalSecondsToday ~/ 3600;
          if (hours > 8) totalTime = 'Very High (>8h)';
          else if (hours > 4) totalTime = 'Moderate (4h-8h)';
          else totalTime = 'Light (<4h)';

          // Calculate focus sessions (matching dashboard focus score rule)
          focusSessions = '${provider.focusScore.toStringAsFixed(0)}%';

          // Break Status Insight
          if (hours > 2 && pScore < 30) {
            breakStatus = 'Take more breaks!';
            breakColor = Colors.orange;
          } else {
            breakStatus = 'Good pacing';
            breakColor = Colors.green;
          }
        }

        return Container(
          padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isLight
            ? const Color(0xFFF9F9F9)
            : const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isLight
              ? const Color(0xFFE5E5E5)
              : const Color(0xFF3D3D3D),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Usage Insights',
                style: theme.typography.bodyStrong,
              ),
              Icon(
                FluentIcons.insights,
                size: 16,
                color: isLight ? Colors.grey[130] : Colors.grey[100],
              ),
            ],
          ),
          const SizedBox(height: 16),
            _InsightRow(
              icon: FluentIcons.sunny,
              title: 'Productivity Level',
              value: productiveTime,
              isLight: isLight,
            ),
            const SizedBox(height: 12),
            _InsightRow(
              icon: FluentIcons.timer,
              title: 'Daily Load',
              value: totalTime,
              isLight: isLight,
            ),
            const SizedBox(height: 12),
            _InsightRow(
              icon: FluentIcons.red_eye,
              title: 'Focus Score',
              value: focusSessions,
              valueColor: Colors.green,
              isLight: isLight,
            ),
            const SizedBox(height: 12),
            _InsightRow(
              icon: breakColor == Colors.orange ? FluentIcons.warning : FluentIcons.check_mark,
              title: 'Screen Pacing',
              value: breakStatus,
              valueColor: breakColor,
              isLight: isLight,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildTrendsCard(FluentThemeData theme, bool isLight) {
    return Consumer<ScreenTimeProvider>(
      builder: (context, provider, child) {
        final dailyData = provider.dailyUsage;
        
        // Calculate week over week comparison
        int thisWeek = 0;
        int lastWeek = 0;
        
        for (int i = 0; i < dailyData.length && i < 7; i++) {
          thisWeek += (dailyData[i]['total_seconds'] as int? ?? 0);
        }
        
        // Simulated last week data (would come from database in real app)
        lastWeek = (thisWeek * 0.9).round(); // Placeholder

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isLight
                ? const Color(0xFFF9F9F9)
                : const Color(0xFF2D2D2D),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isLight
                  ? const Color(0xFFE5E5E5)
                  : const Color(0xFF3D3D3D),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Weekly Comparison',
                style: theme.typography.bodyStrong,
              ),
              const SizedBox(height: 16),
              _ComparisonBar(
                label: 'This Week',
                value: thisWeek,
                maxValue: thisWeek > lastWeek ? thisWeek : lastWeek,
                color: theme.accentColor,
                isLight: isLight,
              ),
              const SizedBox(height: 16),
              _ComparisonBar(
                label: 'Last Week',
                value: lastWeek,
                maxValue: thisWeek > lastWeek ? thisWeek : lastWeek,
                color: Colors.grey[100]!,
                isLight: isLight,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(FluentThemeData theme, bool isLight, IconData icon, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40,
              color: isLight ? Colors.grey[90] : Colors.grey[100],
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                color: isLight ? Colors.grey[130] : Colors.grey[100],
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _getMaxY(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return 3600;
    int maxSeconds = 0;
    for (final d in data) {
      final seconds = d['total_seconds'] as int? ?? 0;
      if (seconds > maxSeconds) maxSeconds = seconds;
    }
    return ((maxSeconds / 3600).ceil() * 3600).toDouble().clamp(3600, double.infinity);
  }

  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}

class _TimeRangeButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onPressed;
  final bool isFirst;
  final bool isLast;
  final bool isLight;

  const _TimeRangeButton({
    required this.label,
    required this.isSelected,
    required this.onPressed,
    this.isFirst = false,
    this.isLast = false,
    required this.isLight,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? theme.accentColor : Colors.transparent,
          borderRadius: BorderRadius.horizontal(
            left: isFirst ? const Radius.circular(7) : Radius.zero,
            right: isLast ? const Radius.circular(7) : Radius.zero,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected
                ? Colors.white
                : (isLight ? Colors.grey[130] : Colors.grey[100]),
          ),
        ),
      ),
    );
  }
}

class _QuickStatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color accentColor;
  final bool isLight;

  const _QuickStatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.accentColor,
    required this.isLight,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isLight
            ? const Color(0xFFF9F9F9)
            : const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isLight
              ? const Color(0xFFE5E5E5)
              : const Color(0xFF3D3D3D),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 14, color: accentColor),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.typography.subtitle?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: theme.typography.caption?.copyWith(
              color: isLight ? Colors.grey[130] : Colors.grey[100],
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _AppListItem extends StatelessWidget {
  final int rank;
  final String name;
  final String time;
  final double percentage;
  final FluentThemeData theme;
  final bool isLight;

  const _AppListItem({
    required this.rank,
    required this.name,
    required this.time,
    required this.percentage,
    required this.theme,
    required this.isLight,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: _getRankColor(rank).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _getRankColor(rank),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.typography.body,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                ProgressBar(value: percentage),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            time,
            style: theme.typography.caption?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.orange;
      case 2:
        return Colors.grey[120]!;
      case 3:
        return Colors.orange.dark;
      default:
        return Colors.grey[100]!;
    }
  }
}

class _InsightRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color? valueColor;
  final bool isLight;

  const _InsightRow({
    required this.icon,
    required this.title,
    required this.value,
    this.valueColor,
    required this.isLight,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);

    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.accentColor,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: theme.typography.caption?.copyWith(
              color: isLight ? Colors.grey[130] : Colors.grey[100],
            ),
          ),
        ),
        Text(
          value,
          style: theme.typography.caption?.copyWith(
            fontWeight: FontWeight.w500,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class _ComparisonBar extends StatelessWidget {
  final String label;
  final int value;
  final int maxValue;
  final Color color;
  final bool isLight;

  const _ComparisonBar({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.color,
    required this.isLight,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final percentage = maxValue > 0 ? (value / maxValue * 100) : 0.0;

    final hours = value ~/ 3600;
    final minutes = (value % 3600) ~/ 60;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: theme.typography.caption?.copyWith(
                color: isLight ? Colors.grey[130] : Colors.grey[100],
              ),
            ),
            Text(
              '${hours}h ${minutes}m',
              style: theme.typography.body?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: isLight ? Colors.grey[40] : Colors.grey[150],
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percentage / 100,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
