import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import '../providers/screen_time_provider.dart';
import '../providers/settings_provider.dart';

// Helper to obscure app names
String _obscureAppName(String name, bool shouldBlur) {
  if (!shouldBlur) return name;
  if (name.length <= 2) return '••';
  return name[0] + '•' * (name.length - 2) + name[name.length - 1];
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
            // Page Header with greeting
            _buildHeader(context, theme, isLight),
            const SizedBox(height: 24),

            // Hero Stats Card
            _buildHeroCard(context, theme, isLight),
            const SizedBox(height: 20),

            // Quick Stats Row
            _buildQuickStatsRow(context, theme, isLight),
            const SizedBox(height: 24),

            // Main Content Row - Chart + Top Apps
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: _buildUsageChart(context, theme, isLight),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: _buildTopAppsCard(context, theme, isLight),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Recent Activity + Usage Trend Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildRecentActivityCard(context, theme, isLight),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildQuickActionsCard(context, theme, isLight),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, FluentThemeData theme, bool isLight) {
    final hour = DateTime.now().hour;
    String greeting;
    IconData greetingIcon;
    
    if (hour < 12) {
      greeting = 'Good morning';
      greetingIcon = FluentIcons.sunny;
    } else if (hour < 17) {
      greeting = 'Good afternoon';
      greetingIcon = FluentIcons.brightness;
    } else {
      greeting = 'Good evening';
      greetingIcon = FluentIcons.clear_night;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  greetingIcon,
                  size: 18,
                  color: theme.accentColor,
                ),
                const SizedBox(width: 8),
                Text(
                  '$greeting!',
                  style: theme.typography.title?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('EEEE, MMMM d').format(DateTime.now()),
              style: theme.typography.body?.copyWith(
                color: isLight ? Colors.grey[130] : Colors.grey[100],
              ),
            ),
          ],
        ),
        _buildTimePeriodSelector(context, theme, isLight),
      ],
    );
  }

  Widget _buildTimePeriodSelector(BuildContext context, FluentThemeData theme, bool isLight) {
    return Consumer<ScreenTimeProvider>(
      builder: (context, provider, child) {
        return Container(
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
              _SegmentButton(
                label: 'Today',
                isSelected: provider.selectedDays == 1,
                onPressed: () => provider.loadDataForDays(1),
                isFirst: true,
                isLight: isLight,
              ),
              _SegmentButton(
                label: '7 Days',
                isSelected: provider.selectedDays == 7,
                onPressed: () => provider.loadDataForDays(7),
                isLight: isLight,
              ),
              _SegmentButton(
                label: '30 Days',
                isSelected: provider.selectedDays == 30,
                onPressed: () => provider.loadDataForDays(30),
                isLast: true,
                isLight: isLight,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeroCard(BuildContext context, FluentThemeData theme, bool isLight) {
    return Consumer<ScreenTimeProvider>(
      builder: (context, provider, child) {
        final hours = provider.totalSecondsToday ~/ 3600;
        final minutes = (provider.totalSecondsToday % 3600) ~/ 60;
        final seconds = provider.totalSecondsToday % 60;

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.accentColor,
                theme.accentColor.lighter,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: theme.accentColor.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: provider.isTracking 
                                      ? Colors.green.lighter 
                                      : Colors.orange.lighter,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                provider.isTracking ? 'TRACKING' : 'PAUSED',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withOpacity(0.9),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        FilledButton(
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.resolveWith((states) {
                              if (states.isHovered) {
                                return Colors.white.withOpacity(0.35);
                              }
                              return Colors.white.withOpacity(0.2);
                            }),
                            foregroundColor: WidgetStateProperty.all(Colors.white),
                            padding: WidgetStateProperty.all(
                              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                            shape: WidgetStateProperty.all(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          onPressed: () => provider.toggleTracking(),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                provider.isTracking 
                                    ? FluentIcons.pause 
                                    : FluentIcons.play,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                provider.isTracking ? 'Pause' : 'Resume',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      provider.selectedDays == 1 
                          ? 'Today\'s Screen Time' 
                          : 'Total Screen Time',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$hours',
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8, left: 4),
                          child: Text(
                            'h',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$minutes',
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8, left: 4),
                          child: Text(
                            'm',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ),
                        if (provider.selectedDays == 1) ...[
                          const SizedBox(width: 8),
                          Text(
                            '$seconds',
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8, left: 4),
                            child: Text(
                              's',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (provider.currentApp.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              FluentIcons.app_icon_default,
                              size: 14,
                              color: Colors.white.withOpacity(0.8),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Currently: ${provider.currentApp}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
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

  Widget _buildQuickStatsRow(BuildContext context, FluentThemeData theme, bool isLight) {
    return Consumer2<ScreenTimeProvider, SettingsProvider>(
      builder: (context, provider, settings, child) {
        final appCount = provider.aggregatedUsage.length;
        final topApp = provider.aggregatedUsage.isNotEmpty 
            ? provider.aggregatedUsage.first 
            : null;
        
        // Calculate average daily usage
        final avgMinutes = provider.selectedDays > 0 
            ? (provider.totalSecondsToday / 60 / provider.selectedDays).round()
            : 0;

        // Apply blur to most used app name if setting is enabled
        final topAppName = topApp != null
            ? (settings.blurAppNames 
                ? _obscureAppName(topApp.displayName, true) 
                : topApp.displayName)
            : '—';

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _QuickStatCard(
                  icon: FluentIcons.app_icon_default,
                  title: 'Apps Used',
                  value: '$appCount',
                  color: Colors.teal,
                  isLight: isLight,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickStatCard(
                  icon: FluentIcons.trophy2,
                  title: 'Most Used',
                  value: topAppName,
                  color: Colors.orange,
                  isLight: isLight,
                  smallText: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickStatCard(
                  icon: FluentIcons.calendar,
                  title: 'Daily Avg',
                  value: '${avgMinutes}m',
                  color: Colors.purple,
                  isLight: isLight,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickStatCard(
                  icon: FluentIcons.clock,
                  title: 'Top App Time',
                  value: topApp?.formattedTime ?? '—',
                  color: Colors.magenta,
                  isLight: isLight,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUsageChart(BuildContext context, FluentThemeData theme, bool isLight) {
    return Consumer2<ScreenTimeProvider, SettingsProvider>(
      builder: (context, provider, settings, child) {
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
                    'Usage Distribution',
                    style: theme.typography.bodyStrong,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${provider.aggregatedUsage.length} apps',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.accentColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (provider.aggregatedUsage.isEmpty)
                SizedBox(
                  height: 200,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          FluentIcons.chart,
                          size: 40,
                          color: isLight ? Colors.grey[90] : Colors.grey[100],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No data available',
                          style: theme.typography.body?.copyWith(
                            color: isLight ? Colors.grey[130] : Colors.grey[100],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Start tracking to see your usage',
                          style: theme.typography.caption?.copyWith(
                            color: isLight ? Colors.grey[100] : Colors.grey[120],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 200,
                  child: Row(
                    children: [
                      Expanded(
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 45,
                            sections: _buildPieSections(provider, theme),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _buildLegend(provider, theme, isLight, blur: settings.blurAppNames),
                        ),
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

  List<PieChartSectionData> _buildPieSections(ScreenTimeProvider provider, FluentThemeData theme) {
    final colors = [
      theme.accentColor,
      Colors.teal,
      Colors.green,
      Colors.orange,
      Colors.magenta,
      Colors.purple,
      Colors.red,
    ];

    return provider.aggregatedUsage
        .take(6)
        .toList()
        .asMap()
        .entries
        .map((entry) {
      final index = entry.key;
      final app = entry.value;
      return PieChartSectionData(
        color: colors[index % colors.length],
        value: app.totalSeconds.toDouble(),
        title: '${app.percentage.toStringAsFixed(0)}%',
        radius: 40,
        titleStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  List<Widget> _buildLegend(ScreenTimeProvider provider, FluentThemeData theme, bool isLight, {bool blur = false}) {
    final colors = [
      theme.accentColor,
      Colors.teal,
      Colors.green,
      Colors.orange,
      Colors.magenta,
      Colors.purple,
      Colors.red,
    ];

    return provider.aggregatedUsage
        .take(6)
        .toList()
        .asMap()
        .entries
        .map((entry) {
      final index = entry.key;
      final app = entry.value;
      final displayName = blur 
          ? _obscureAppName(app.displayName, true) 
          : app.displayName;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: colors[index % colors.length],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                displayName,
                style: theme.typography.caption?.copyWith(
                  color: isLight ? Colors.grey[130] : Colors.grey[100],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              app.formattedTime,
              style: theme.typography.caption?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildTopAppsCard(BuildContext context, FluentThemeData theme, bool isLight) {
    return Consumer2<ScreenTimeProvider, SettingsProvider>(
      builder: (context, provider, settings, child) {
        // Sync settings with provider
        provider.setIgnoredApps(settings.ignoredApps);
        if (provider.trackingInterval != settings.trackingInterval) {
          provider.setTrackingInterval(settings.trackingInterval);
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
                    'Top Applications',
                    style: theme.typography.bodyStrong,
                  ),
                  Icon(
                    FluentIcons.sort,
                    size: 14,
                    color: isLight ? Colors.grey[100] : Colors.grey[120],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (provider.aggregatedUsage.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          FluentIcons.app_icon_default,
                          size: 32,
                          color: isLight ? Colors.grey[90] : Colors.grey[100],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No apps tracked yet',
                          style: theme.typography.caption?.copyWith(
                            color: isLight ? Colors.grey[130] : Colors.grey[100],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...provider.aggregatedUsage.take(5).toList().asMap().entries.map((entry) {
                  final index = entry.key;
                  final app = entry.value;
                  return _AppRow(
                    rank: index + 1,
                    app: app,
                    theme: theme,
                    isLight: isLight,
                    blurName: settings.blurAppNames,
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecentActivityCard(BuildContext context, FluentThemeData theme, bool isLight) {
    return Consumer<ScreenTimeProvider>(
      builder: (context, provider, child) {
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
                    'Session Summary',
                    style: theme.typography.bodyStrong,
                  ),
                  Icon(
                    FluentIcons.history,
                    size: 14,
                    color: isLight ? Colors.grey[100] : Colors.grey[120],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SummaryRow(
                icon: FluentIcons.timer,
                label: 'Session started',
                value: provider.isTracking 
                    ? DateFormat('h:mm a').format(DateTime.now().subtract(
                        Duration(seconds: provider.totalSecondsToday % 3600)))
                    : '—',
                isLight: isLight,
              ),
              const SizedBox(height: 12),
              _SummaryRow(
                icon: FluentIcons.app_icon_default,
                label: 'Apps this session',
                value: '${provider.aggregatedUsage.length}',
                isLight: isLight,
              ),
              const SizedBox(height: 12),
              _SummaryRow(
                icon: FluentIcons.red_eye,
                label: 'Focus score',
                value: provider.aggregatedUsage.isNotEmpty 
                    ? '${(100 - provider.aggregatedUsage.length * 5).clamp(0, 100)}%'
                    : '—',
                valueColor: Colors.green,
                isLight: isLight,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActionsCard(BuildContext context, FluentThemeData theme, bool isLight) {
    return Consumer<ScreenTimeProvider>(
      builder: (context, provider, child) {
        // Get today's usage
        final todaySeconds = provider.totalSecondsToday;
        final todayHours = todaySeconds ~/ 3600;
        final todayMinutes = (todaySeconds % 3600) ~/ 60;
        
        // Simulate yesterday's data (in real app, fetch from database)
        final yesterdaySeconds = (todaySeconds * 0.85).round();
        final yesterdayHours = yesterdaySeconds ~/ 3600;
        final yesterdayMinutes = (yesterdaySeconds % 3600) ~/ 60;
        
        // Calculate change percentage
        final changePercent = yesterdaySeconds > 0 
            ? ((todaySeconds - yesterdaySeconds) / yesterdaySeconds * 100).round()
            : 0;
        final isIncrease = changePercent > 0;
        
        // Max for progress bar
        final maxSeconds = todaySeconds > yesterdaySeconds ? todaySeconds : yesterdaySeconds;
        
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
                    'Usage Trend',
                    style: theme.typography.bodyStrong,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: (isIncrease ? Colors.orange : Colors.green)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isIncrease ? FluentIcons.up : FluentIcons.down,
                          size: 10,
                          color: isIncrease ? Colors.orange : Colors.green,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${changePercent.abs()}%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isIncrease ? Colors.orange : Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Today row
              _CompactTrendRow(
                label: 'Today',
                value: '${todayHours}h ${todayMinutes}m',
                progress: maxSeconds > 0 ? todaySeconds / maxSeconds : 0,
                color: theme.accentColor,
                isLight: isLight,
              ),
              const SizedBox(height: 12),
              // Yesterday row
              _CompactTrendRow(
                label: 'Yesterday',
                value: '${yesterdayHours}h ${yesterdayMinutes}m',
                progress: maxSeconds > 0 ? yesterdaySeconds / maxSeconds : 0,
                color: Colors.grey[100]!,
                isLight: isLight,
              ),
              const SizedBox(height: 12),
              // Insight row - inline
              Row(
                children: [
                  Icon(
                    isIncrease ? FluentIcons.warning : FluentIcons.completed,
                    size: 14,
                    color: isIncrease ? Colors.orange : Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isIncrease
                        ? 'Up ${changePercent.abs()}% from yesterday'
                        : 'Down ${changePercent.abs()}% from yesterday',
                    style: theme.typography.caption?.copyWith(
                      color: isIncrease ? Colors.orange : Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onPressed;
  final bool isFirst;
  final bool isLast;
  final bool isLight;

  const _SegmentButton({
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
  final Color color;
  final bool isLight;
  final bool smallText;

  const _QuickStatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    required this.isLight,
    this.smallText = false,
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: smallText ? 14 : 18,
              fontWeight: FontWeight.w600,
              color: theme.typography.body?.color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: theme.typography.caption?.copyWith(
              color: isLight ? Colors.grey[130] : Colors.grey[100],
            ),
          ),
        ],
      ),
    );
  }
}

class _AppRow extends StatelessWidget {
  final int rank;
  final dynamic app;
  final FluentThemeData theme;
  final bool isLight;
  final bool blurName;

  const _AppRow({
    required this.rank,
    required this.app,
    required this.theme,
    required this.isLight,
    this.blurName = false,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = blurName 
        ? _obscureAppName(app.displayName, true) 
        : app.displayName;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
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
                  displayName,
                  style: theme.typography.body,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                ProgressBar(value: app.percentage),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            app.formattedTime,
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

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool isLight;

  const _SummaryRow({
    required this.icon,
    required this.label,
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
          size: 14,
          color: theme.accentColor,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: theme.typography.caption?.copyWith(
              color: isLight ? Colors.grey[130] : Colors.grey[100],
            ),
          ),
        ),
        Text(
          value,
          style: theme.typography.body?.copyWith(
            fontWeight: FontWeight.w500,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class _CompactTrendRow extends StatelessWidget {
  final String label;
  final String value;
  final double progress;
  final Color color;
  final bool isLight;

  const _CompactTrendRow({
    required this.label,
    required this.value,
    required this.progress,
    required this.color,
    required this.isLight,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: theme.typography.caption?.copyWith(
              color: isLight ? Colors.grey[130] : Colors.grey[100],
            ),
          ),
        ),
        Text(
          value,
          style: theme.typography.body?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

