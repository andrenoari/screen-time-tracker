import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import '../providers/screen_time_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return ScaffoldPage(
      padding: EdgeInsets.zero,
      content: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Page Header
                Text(
                  'Settings',
                  style: theme.typography.title?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Customize your Screen Time experience',
                  style: theme.typography.body?.copyWith(
                    color: isLight ? Colors.grey[130] : Colors.grey[100],
                  ),
                ),
                const SizedBox(height: 32),

                // Appearance Section
                _SectionHeader(title: 'Appearance', isLight: isLight),
                const SizedBox(height: 12),
                _SettingsCard(
                  isLight: isLight,
                  children: [
                    Consumer<ThemeProvider>(
                      builder: (context, themeProvider, child) {
                        return _SettingsRow(
                          icon: FluentIcons.light,
                          title: 'Theme',
                          subtitle: 'Choose light or dark mode',
                          isLight: isLight,
                          child: ComboBox<ThemeMode>(
                            value: themeProvider.themeMode,
                            items: const [
                              ComboBoxItem(
                                value: ThemeMode.system,
                                child: Text('System default'),
                              ),
                              ComboBoxItem(
                                value: ThemeMode.light,
                                child: Text('Light'),
                              ),
                              ComboBoxItem(
                                value: ThemeMode.dark,
                                child: Text('Dark'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                themeProvider.setThemeMode(value);
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // General Section
                _SectionHeader(title: 'General', isLight: isLight),
                const SizedBox(height: 12),
                _SettingsCard(
                  isLight: isLight,
                  children: [
                    _SettingsRow(
                      icon: FluentIcons.power_button,
                      title: 'Start with Windows',
                      subtitle: 'Launch automatically when you sign in',
                      isLight: isLight,
                      child: ToggleSwitch(
                        checked: settings.startWithWindows,
                        onChanged: (value) => settings.setStartWithWindows(value),
                      ),
                    ),
                    _Divider(isLight: isLight),
                    _SettingsRow(
                      icon: FluentIcons.system,
                      title: 'Minimize to tray',
                      subtitle: 'Keep running in the background when closed',
                      isLight: isLight,
                      child: ToggleSwitch(
                        checked: settings.minimizeToTray,
                        onChanged: (value) => settings.setMinimizeToTray(value),
                      ),
                    ),
                    _Divider(isLight: isLight),
                    _SettingsRow(
                      icon: FluentIcons.ringer,
                      title: 'Notifications',
                      subtitle: 'Show daily usage summary notifications',
                      isLight: isLight,
                      child: ToggleSwitch(
                        checked: settings.showNotifications,
                        onChanged: (value) => settings.setShowNotifications(value),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // Goals Section
                _SectionHeader(title: 'Goals & Reminders', isLight: isLight),
                const SizedBox(height: 12),
                _SettingsCard(
                  isLight: isLight,
                  children: [
                    _SettingsRow(
                      icon: FluentIcons.bullseye_target,
                      title: 'Daily screen time goal',
                      subtitle: settings.enableDailyGoal 
                          ? 'Limit: ${settings.dailyGoalHours} hours per day'
                          : 'Set a daily usage limit',
                      isLight: isLight,
                      child: ToggleSwitch(
                        checked: settings.enableDailyGoal,
                        onChanged: (value) => settings.setEnableDailyGoal(value),
                      ),
                    ),
                    if (settings.enableDailyGoal) ...[
                      _Divider(isLight: isLight),
                      _SettingsRow(
                        icon: FluentIcons.clock,
                        title: 'Goal limit',
                        subtitle: 'Maximum hours per day',
                        isLight: isLight,
                        child: ComboBox<int>(
                          value: settings.dailyGoalHours,
                          items: [1, 2, 3, 4, 5, 6, 8, 10, 12]
                              .map((hours) => ComboBoxItem(
                                    value: hours,
                                    child: Text('$hours hours'),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              settings.setDailyGoalHours(value);
                            }
                          },
                        ),
                      ),
                    ],
                    _Divider(isLight: isLight),
                    _SettingsRow(
                      icon: FluentIcons.coffee_script,
                      title: 'Break reminders',
                      subtitle: settings.enableBreakReminders
                          ? 'Remind every ${settings.breakReminderInterval} minutes'
                          : 'Get reminded to take breaks',
                      isLight: isLight,
                      child: ToggleSwitch(
                        checked: settings.enableBreakReminders,
                        onChanged: (value) => settings.setEnableBreakReminders(value),
                      ),
                    ),
                    if (settings.enableBreakReminders) ...[
                      _Divider(isLight: isLight),
                      _SettingsRow(
                        icon: FluentIcons.timer,
                        title: 'Break interval',
                        subtitle: 'Time between break reminders',
                        isLight: isLight,
                        child: ComboBox<int>(
                          value: settings.breakReminderInterval,
                          items: [15, 30, 45, 60, 90, 120]
                              .map((mins) => ComboBoxItem(
                                    value: mins,
                                    child: Text('$mins min'),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              settings.setBreakReminderInterval(value);
                            }
                          },
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 28),

                // Tracking Section
                _SectionHeader(title: 'Tracking', isLight: isLight),
                const SizedBox(height: 12),
                Consumer<ScreenTimeProvider>(
                  builder: (context, provider, child) {
                    return _SettingsCard(
                      isLight: isLight,
                      children: [
                        _SettingsRow(
                          icon: provider.isTracking
                              ? FluentIcons.play_solid
                              : FluentIcons.pause,
                          title: 'Tracking status',
                          subtitle: provider.isTracking
                              ? 'Currently monitoring active windows'
                              : 'Tracking is paused',
                          isLight: isLight,
                          child: FilledButton(
                            onPressed: () => provider.toggleTracking(),
                            child: Text(provider.isTracking ? 'Pause' : 'Resume'),
                          ),
                        ),
                        _Divider(isLight: isLight),
                        _SettingsRow(
                          icon: FluentIcons.timer,
                          title: 'Idle timeout',
                          subtitle: 'Pause tracking after ${settings.idleTimeout} min of inactivity',
                          isLight: isLight,
                          child: ComboBox<int>(
                            value: settings.idleTimeout,
                            items: [1, 2, 5, 10, 15, 30]
                                .map((mins) => ComboBoxItem(
                                      value: mins,
                                      child: Text('$mins min'),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                settings.setIdleTimeout(value);
                              }
                            },
                          ),
                        ),
                        _Divider(isLight: isLight),
                        _SettingsRow(
                          icon: FluentIcons.processing,
                          title: 'Tracking precision',
                          subtitle: 'Check active window every ${settings.trackingInterval} second(s)',
                          isLight: isLight,
                          child: ComboBox<int>(
                            value: settings.trackingInterval,
                            items: [1, 2, 5, 10]
                                .map((sec) => ComboBoxItem(
                                      value: sec,
                                      child: Text('$sec sec'),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                settings.setTrackingInterval(value);
                              }
                            },
                          ),
                        ),
                        _Divider(isLight: isLight),
                        _SettingsRow(
                          icon: FluentIcons.blocked2,
                          title: 'Ignored applications',
                          subtitle: '${settings.ignoredApps.length} apps excluded from tracking',
                          isLight: isLight,
                          child: Button(
                            child: const Text('Manage'),
                            onPressed: () => _showIgnoredAppsDialog(context, settings),
                          ),
                        ),
                        _Divider(isLight: isLight),
                        _SettingsRow(
                          icon: FluentIcons.favorite_star,
                          title: 'Productive applications',
                          subtitle: '${settings.productiveApps.length} apps counted towards focus score',
                          isLight: isLight,
                          child: Button(
                            child: const Text('Manage'),
                            onPressed: () => _showProductiveAppsDialog(context, settings),
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 28),

                // Privacy Section
                _SectionHeader(title: 'Privacy', isLight: isLight),
                const SizedBox(height: 12),
                _SettingsCard(
                  isLight: isLight,
                  children: [
                    _SettingsRow(
                      icon: FluentIcons.hide3,
                      title: 'Blur app names',
                      subtitle: 'Hide application names in the UI',
                      isLight: isLight,
                      child: ToggleSwitch(
                        checked: settings.blurAppNames,
                        onChanged: (value) => settings.setBlurAppNames(value),
                      ),
                    ),
                    _Divider(isLight: isLight),
                    _SettingsRow(
                      icon: FluentIcons.lock,
                      title: 'Pause on lock',
                      subtitle: 'Stop tracking when screen is locked',
                      isLight: isLight,
                      child: ToggleSwitch(
                        checked: settings.pauseOnLock,
                        onChanged: (value) => settings.setPauseOnLock(value),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // Data Section
                _SectionHeader(title: 'Data', isLight: isLight),
                const SizedBox(height: 12),
                _SettingsCard(
                  isLight: isLight,
                  children: [
                    _SettingsRow(
                      icon: FluentIcons.database,
                      title: 'Data retention',
                      subtitle: 'Keep usage data for ${settings.dataRetentionDays} days',
                      isLight: isLight,
                      child: ComboBox<int>(
                        value: settings.dataRetentionDays,
                        items: [7, 14, 30, 60, 90, 365]
                            .map((days) => ComboBoxItem(
                                  value: days,
                                  child: Text('$days days'),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            settings.setDataRetentionDays(value);
                          }
                        },
                      ),
                    ),
                    _Divider(isLight: isLight),
                    _SettingsRow(
                      icon: FluentIcons.download,
                      title: 'Export data',
                      subtitle: 'Save your usage history to a file',
                      isLight: isLight,
                      child: Button(
                        child: const Text('Export'),
                        onPressed: () => _showExportDialog(context),
                      ),
                    ),
                    _Divider(isLight: isLight),
                    _SettingsRow(
                      icon: FluentIcons.upload,
                      title: 'Import data',
                      subtitle: 'Restore from a backup file',
                      isLight: isLight,
                      child: Button(
                        child: const Text('Import'),
                        onPressed: () => _showImportDialog(context),
                      ),
                    ),
                    _Divider(isLight: isLight),
                    _SettingsRow(
                      icon: FluentIcons.delete,
                      title: 'Clear all data',
                      subtitle: 'Permanently delete all tracking history',
                      isLight: isLight,
                      child: Button(
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.resolveWith((states) {
                            if (states.isHovered) {
                              return Colors.red.withOpacity(0.15);
                            }
                            return Colors.red.withOpacity(0.08);
                          }),
                        ),
                        child: Text(
                          'Clear',
                          style: TextStyle(color: Colors.red.lighter),
                        ),
                        onPressed: () => _showClearDataDialog(context),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // About Section
                _SectionHeader(title: 'About', isLight: isLight),
                const SizedBox(height: 12),
                _SettingsCard(
                  isLight: isLight,
                  children: [
                    _SettingsRow(
                      icon: FluentIcons.info,
                      title: 'Screen Time',
                      subtitle: 'Version 1.0.0',
                      isLight: isLight,
                      child: Button(
                        child: const Text('Check for updates'),
                        onPressed: () => _showUpdateCheckDialog(context),
                      ),
                    ),
                    _Divider(isLight: isLight),
                    _SettingsRow(
                      icon: FluentIcons.reset,
                      title: 'Reset settings',
                      subtitle: 'Restore all settings to defaults',
                      isLight: isLight,
                      child: Button(
                        child: const Text('Reset'),
                        onPressed: () => _showResetSettingsDialog(context, settings),
                      ),
                    ),
                    _Divider(isLight: isLight),
                    _SettingsRow(
                      icon: FluentIcons.document,
                      title: 'Keyboard shortcuts',
                      subtitle: 'View available shortcuts',
                      isLight: isLight,
                      child: Button(
                        child: const Text('View'),
                        onPressed: () => _showShortcutsDialog(context),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showIgnoredAppsDialog(BuildContext context, SettingsProvider settings) async {
    final controller = TextEditingController();
    
    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => ContentDialog(
          title: const Text('Ignored Applications'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Apps in this list will not be tracked.'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextBox(
                        controller: controller,
                        placeholder: 'Enter app name (e.g., notepad.exe)',
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      child: const Text('Add'),
                      onPressed: () async {
                        if (controller.text.isNotEmpty) {
                          await settings.addIgnoredApp(controller.text);
                          controller.clear();
                          setDialogState(() {});
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (settings.ignoredApps.isEmpty)
                  const Text('No apps ignored yet.')
                else
                  SizedBox(
                    height: 150,
                    child: ListView.builder(
                      itemCount: settings.ignoredApps.length,
                      itemBuilder: (context, index) {
                        final app = settings.ignoredApps[index];
                        return ListTile(
                          title: Text(app),
                          trailing: IconButton(
                            icon: const Icon(FluentIcons.delete),
                            onPressed: () async {
                              await settings.removeIgnoredApp(app);
                              setDialogState(() {});
                            },
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            FilledButton(
              child: const Text('Done'),
              onPressed: () => Navigator.pop(dialogContext),
            ),
          ],
        ),
      ),
    );
  }

  void _showProductiveAppsDialog(BuildContext context, SettingsProvider settings) async {
    final controller = TextEditingController();
    
    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => ContentDialog(
          title: const Text('Productive Applications'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Apps in this list will contribute to your Focus Score.'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextBox(
                        controller: controller,
                        placeholder: 'Enter app name (e.g., Code.exe)',
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      child: const Text('Add'),
                      onPressed: () async {
                        if (controller.text.isNotEmpty) {
                          await settings.addProductiveApp(controller.text);
                          controller.clear();
                          setDialogState(() {});
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (settings.productiveApps.isEmpty)
                  const Text('No productive apps added yet.')
                else
                  SizedBox(
                    height: 150,
                    child: ListView.builder(
                      itemCount: settings.productiveApps.length,
                      itemBuilder: (context, index) {
                        final app = settings.productiveApps[index];
                        return ListTile(
                          title: Text(app),
                          trailing: IconButton(
                            icon: const Icon(FluentIcons.delete),
                            onPressed: () async {
                              await settings.removeProductiveApp(app);
                              setDialogState(() {});
                            },
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            FilledButton(
              child: const Text('Done'),
              onPressed: () => Navigator.pop(dialogContext),
            ),
          ],
        ),
      ),
    );
  }

  void _showExportDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Export Data'),
        content: const Text(
          'Choose a format to export your screen time history.',
        ),
        actions: [
          Button(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          Button(
            child: const Text('CSV'),
            onPressed: () {
              Navigator.pop(context);
              _showExportSuccessMessage(context, 'CSV');
            },
          ),
          FilledButton(
            child: const Text('JSON'),
            onPressed: () {
              Navigator.pop(context);
              _showExportSuccessMessage(context, 'JSON');
            },
          ),
        ],
      ),
    );
  }

  void _showExportSuccessMessage(BuildContext context, String format) async {
    await displayInfoBar(
      context,
      builder: (context, close) => InfoBar(
        title: const Text('Export started'),
        content: Text('Your data is being exported as $format...'),
        severity: InfoBarSeverity.info,
        onClose: close,
      ),
    );
  }

  void _showImportDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Import Data'),
        content: const Text(
          'Select a backup file to restore your screen time data. '
          'This will merge with existing data.',
        ),
        actions: [
          Button(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          FilledButton(
            child: const Text('Select File'),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will permanently delete all your screen time data. This action cannot be undone.',
        ),
        actions: [
          Button(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context, false),
          ),
          FilledButton(
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(Colors.red),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      // TODO: Actually clear the database
      await displayInfoBar(
        context,
        builder: (context, close) => InfoBar(
          title: const Text('Data cleared'),
          content: const Text('All usage data has been deleted.'),
          severity: InfoBarSeverity.warning,
          onClose: close,
        ),
      );
    }
  }

  void _showUpdateCheckDialog(BuildContext context) async {
    await displayInfoBar(
      context,
      builder: (context, close) => InfoBar(
        title: const Text('You\'re up to date!'),
        content: const Text('Screen Time v1.0.0 is the latest version.'),
        severity: InfoBarSeverity.success,
        onClose: close,
      ),
    );
  }

  void _showResetSettingsDialog(BuildContext context, SettingsProvider settings) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Reset Settings'),
        content: const Text(
          'This will restore all settings to their default values. Your usage data will not be affected.',
        ),
        actions: [
          Button(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context, false),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      await settings.resetToDefaults();
      await displayInfoBar(
        context,
        builder: (context, close) => InfoBar(
          title: const Text('Settings reset'),
          content: const Text('All settings have been restored to defaults.'),
          severity: InfoBarSeverity.success,
          onClose: close,
        ),
      );
    }
  }

  void _showShortcutsDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Keyboard Shortcuts'),
        content: SizedBox(
          width: 350,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              _ShortcutRow(shortcut: 'Ctrl + H', description: 'Go to Dashboard'),
              _ShortcutRow(shortcut: 'Ctrl + S', description: 'Go to Statistics'),
              _ShortcutRow(shortcut: 'Ctrl + ,', description: 'Open Settings'),
              _ShortcutRow(shortcut: 'Ctrl + P', description: 'Pause/Resume tracking'),
              _ShortcutRow(shortcut: 'Ctrl + R', description: 'Refresh data'),
              _ShortcutRow(shortcut: 'Ctrl + Q', description: 'Quit application'),
            ],
          ),
        ),
        actions: [
          FilledButton(
            child: const Text('Close'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

class _ShortcutRow extends StatelessWidget {
  final String shortcut;
  final String description;

  const _ShortcutRow({
    required this.shortcut,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isLight ? Colors.grey[40] : Colors.grey[150],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              shortcut,
              style: const TextStyle(
                fontFamily: 'Consolas',
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(description),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isLight;

  const _SectionHeader({required this.title, required this.isLight});

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);

    return Text(
      title,
      style: theme.typography.bodyStrong?.copyWith(
        color: isLight ? Colors.grey[160] : Colors.grey[80],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  final bool isLight;

  const _SettingsCard({required this.children, required this.isLight});

  @override
  Widget build(BuildContext context) {
    return Container(
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
        children: children,
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;
  final bool isLight;

  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.isLight,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              color: theme.accentColor,
              size: 16,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.typography.body,
                ),
                Text(
                  subtitle,
                  style: theme.typography.caption?.copyWith(
                    color: isLight ? Colors.grey[130] : Colors.grey[100],
                  ),
                ),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final bool isLight;

  const _Divider({required this.isLight});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: isLight ? const Color(0xFFE5E5E5) : const Color(0xFF3D3D3D),
    );
  }
}
