import 'dart:io';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart' as acrylic;
import 'package:system_theme/system_theme.dart';
import 'package:system_tray/system_tray.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/screen_time_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/home_screen.dart';
import 'screens/statistics_screen.dart';
import 'screens/settings_screen.dart';

// Global window effect manager
class WindowEffectManager {
  static acrylic.WindowEffect currentEffect = acrylic.WindowEffect.mica;
  static bool isDark = true;
  
  static Future<void> setEffect(acrylic.WindowEffect effect, {required bool dark}) async {
    currentEffect = effect;
    isDark = dark;
    
    // Color is important for the effect to show properly
    // For Mica/Acrylic on Windows, use a semi-transparent color
    Color effectColor;
    if (effect == acrylic.WindowEffect.solid || effect == acrylic.WindowEffect.disabled) {
      // Solid/Disabled needs an opaque color
      effectColor = dark ? const Color(0xFF1F1F1F) : const Color(0xFFF3F3F3);
    } else if (effect == acrylic.WindowEffect.acrylic) {
      // Acrylic needs a semi-transparent color for the tint
      effectColor = dark ? const Color(0xCC222222) : const Color(0x22DDDDDD);
    } else {
      // Mica/Tabbed work best with transparent
      effectColor = Colors.transparent;
    }
    
    await acrylic.Window.setEffect(
      effect: effect,
      color: effectColor,
      dark: dark,
    );
  }
  
  static Future<void> updateTheme(bool dark) async {
    isDark = dark;
    await setEffect(currentEffect, dark: dark);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize flutter_acrylic FIRST
  await acrylic.Window.initialize();
  
  // Hide native window controls since we use custom ones
  if (Platform.isWindows) {
    await acrylic.Window.hideWindowControls();
  }
  
  // Initialize window manager
  await windowManager.ensureInitialized();
  await windowManager.setPreventClose(true);
  
  // Initialize system theme for accent color
  await SystemTheme.accentColor.load();
  
  // Load saved preferences
  final prefs = await SharedPreferences.getInstance();

  // Configure window with window_manager
  await windowManager.setBackgroundColor(Colors.transparent);
  await windowManager.setSize(const Size(1100, 750));
  await windowManager.setMinimumSize(const Size(900, 600));
  await windowManager.center();
  await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
  await windowManager.setTitle('Screen Time');
  
  // Show window
  await windowManager.show();
  await windowManager.focus();
  
  // Apply Mica effect after window is shown
  if (Platform.isWindows) {
    await WindowEffectManager.setEffect(
      acrylic.WindowEffect.mica,
      dark: true,
    );
  }

  // Initialize settings provider
  final settingsProvider = SettingsProvider();
  await settingsProvider.initialize();

  runApp(ScreenTimeApp(prefs: prefs, settingsProvider: settingsProvider));
}

class ScreenTimeApp extends StatefulWidget {
  final SharedPreferences prefs;
  final SettingsProvider settingsProvider;
  
  const ScreenTimeApp({super.key, required this.prefs, required this.settingsProvider});

  @override
  State<ScreenTimeApp> createState() => _ScreenTimeAppState();
}

class _ScreenTimeAppState extends State<ScreenTimeApp> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ScreenTimeProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider(widget.prefs)),
        ChangeNotifierProvider.value(value: widget.settingsProvider),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          // Update window effect when theme changes
          WindowEffectManager.updateTheme(themeProvider.isDarkMode);
          
          final effectiveThemeMode = themeProvider.isDarkMode 
              ? ThemeMode.dark 
              : ThemeMode.light;
          
          return FluentApp(
            title: 'Screen Time',
            debugShowCheckedModeBanner: false,
            themeMode: effectiveThemeMode,
            darkTheme: FluentThemeData(
              brightness: Brightness.dark,
              accentColor: SystemTheme.accentColor.accent.toAccentColor(),
              visualDensity: VisualDensity.standard,
              scaffoldBackgroundColor: Colors.transparent,
              micaBackgroundColor: Colors.transparent,
              navigationPaneTheme: const NavigationPaneThemeData(
                backgroundColor: Colors.transparent,
              ),
            ),
            theme: FluentThemeData(
              brightness: Brightness.light,
              accentColor: SystemTheme.accentColor.accent.toAccentColor(),
              visualDensity: VisualDensity.standard,
              scaffoldBackgroundColor: Colors.transparent,
              micaBackgroundColor: Colors.transparent,
              navigationPaneTheme: const NavigationPaneThemeData(
                backgroundColor: Colors.transparent,
              ),
            ),
            home: const MainWindow(),
          );
        },
      ),
    );
  }
}

class MainWindow extends StatefulWidget {
  const MainWindow({super.key});

  @override
  State<MainWindow> createState() => _MainWindowState();
}

class _MainWindowState extends State<MainWindow> with WindowListener {
  int _currentIndex = 0;
  final SystemTray _systemTray = SystemTray();
  final Menu _menu = Menu();

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _initSystemTray();
  }

  Future<void> _initSystemTray() async {
    String path = Platform.isWindows ? 'windows/runner/resources/app_icon.ico' : 'AppIcon';

    // We first init the systray menu
    await _systemTray.initSystemTray(
      title: "Screen Time",
      iconPath: path,
    );

    // create context menu
    await _menu.buildFrom([
      MenuItemLabel(label: 'Show', onClicked: (menuItem) => windowManager.show()),
      MenuItemLabel(label: 'Hide', onClicked: (menuItem) => windowManager.hide()),
      MenuSeparator(),
      MenuItemLabel(label: 'Exit', onClicked: (menuItem) async {
        await windowManager.destroy();
      }),
    ]);

    // set context menu
    await _systemTray.setContextMenu(_menu);

    // handle system tray event
    _systemTray.registerSystemTrayEventHandler((eventName) {
      if (eventName == kSystemTrayEventClick) {
        Platform.isWindows ? windowManager.show() : _systemTray.popUpContextMenu();
      } else if (eventName == kSystemTrayEventRightClick) {
        Platform.isWindows ? _systemTray.popUpContextMenu() : windowManager.show();
      }
    });
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    
    return NavigationView(
      appBar: NavigationAppBar(
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: Icon(
            FluentIcons.timer,
            size: 20,
            color: theme.typography.body?.color,
          ),
        ),
        title: DragToMoveArea(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Screen Time',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.typography.body?.color,
              ),
            ),
          ),
        ),
        actions: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const _TrackingStatusBadge(),
            const SizedBox(width: 8),
            SizedBox(
              width: 138,
              height: 50,
              child: WindowCaption(
                brightness: theme.brightness,
                backgroundColor: Colors.transparent,
              ),
            ),
          ],
        ),
      ),
      pane: NavigationPane(
        selected: _currentIndex,
        onChanged: (index) => setState(() => _currentIndex = index),
        displayMode: PaneDisplayMode.compact,
        items: [
          PaneItem(
            icon: const Icon(FluentIcons.home),
            title: const Text('Dashboard'),
            body: _AnimatedBody(
              key: const ValueKey('dashboard'),
              child: const HomeScreen(),
            ),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.chart),
            title: const Text('Statistics'),
            body: _AnimatedBody(
              key: const ValueKey('statistics'),
              child: const StatisticsScreen(),
            ),
          ),
        ],
        footerItems: [
          PaneItem(
            icon: const Icon(FluentIcons.settings),
            title: const Text('Settings'),
            body: _AnimatedBody(
              key: const ValueKey('settings'),
              child: const SettingsScreen(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void onWindowClose() async {
    final settings = context.read<SettingsProvider>();
    if (settings.minimizeToTray) {
      await windowManager.hide();
    } else {
      await windowManager.destroy();
    }
  }
}

class _TrackingStatusBadge extends StatelessWidget {
  const _TrackingStatusBadge();

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final isLight = theme.brightness == Brightness.light;
    
    return Consumer<ScreenTimeProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: provider.isTracking
                ? Colors.green.withOpacity(isLight ? 0.15 : 0.1)
                : (isLight ? Colors.grey[50] : Colors.grey.withOpacity(0.1)),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: provider.isTracking
                  ? Colors.green.withOpacity(0.4)
                  : Colors.grey.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: provider.isTracking ? Colors.green : Colors.grey,
                  shape: BoxShape.circle,
                  boxShadow: provider.isTracking
                      ? [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.5),
                            blurRadius: 4,
                            spreadRadius: 1,
                          )
                        ]
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                provider.isTracking ? 'Tracking' : 'Paused',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: provider.isTracking
                      ? (isLight ? Colors.green.darker : Colors.green.lighter)
                      : theme.typography.body?.color,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Animated wrapper for page bodies with smooth entrance animation
class _AnimatedBody extends StatefulWidget {
  final Widget child;

  const _AnimatedBody({
    super.key,
    required this.child,
  });

  @override
  State<_AnimatedBody> createState() => _AnimatedBodyState();
}

class _AnimatedBodyState extends State<_AnimatedBody>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.02),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}
