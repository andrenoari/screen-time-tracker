import 'dart:ui';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';
  static const String _useSystemAccentKey = 'use_system_accent';
  static const String _customAccentKey = 'custom_accent';
  
  final SharedPreferences _prefs;
  ThemeMode _themeMode = ThemeMode.dark;
  bool _useSystemAccentColor = true;
  Color _customAccentColor = Colors.blue;

  ThemeProvider(this._prefs) {
    _loadTheme();
    _loadAccentColor();
    // Listen to system theme changes to update window effect
    PlatformDispatcher.instance.onPlatformBrightnessChanged = () {
      if (_themeMode == ThemeMode.system) {
        notifyListeners();
      }
    };
  }

  ThemeMode get themeMode => _themeMode;
  
  bool get isDarkMode {
    switch (_themeMode) {
      case ThemeMode.light:
        return false;
      case ThemeMode.dark:
        return true;
      case ThemeMode.system:
        return PlatformDispatcher.instance.platformBrightness == Brightness.dark;
    }
  }
  
  bool get isLightMode => !isDarkMode;
  bool get useSystemAccentColor => _useSystemAccentColor;
  Color get customAccentColor => _customAccentColor;

  void _loadAccentColor() {
    _useSystemAccentColor = _prefs.getBool(_useSystemAccentKey) ?? true;
    final colorValue = _prefs.getInt(_customAccentKey);
    if (colorValue != null) {
      _customAccentColor = Color(colorValue);
    }
  }

  void _loadTheme() {
    final savedMode = _prefs.getString(_themeModeKey);
    if (savedMode != null) {
      switch (savedMode) {
        case 'light':
          _themeMode = ThemeMode.light;
          break;
        case 'dark':
          _themeMode = ThemeMode.dark;
          break;
        case 'system':
          _themeMode = ThemeMode.system;
          break;
        default:
          _themeMode = ThemeMode.dark;
      }
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    
    String modeString;
    switch (mode) {
      case ThemeMode.light:
        modeString = 'light';
        break;
      case ThemeMode.dark:
        modeString = 'dark';
        break;
      case ThemeMode.system:
        modeString = 'system';
        break;
    }
    
    await _prefs.setString(_themeModeKey, modeString);
    notifyListeners();
  }

  Future<void> setUseSystemAccentColor(bool value) async {
    _useSystemAccentColor = value;
    await _prefs.setBool(_useSystemAccentKey, value);
    notifyListeners();
  }

  Future<void> setCustomAccentColor(Color color) async {
    _customAccentColor = color;
    await _prefs.setInt(_customAccentKey, color.value);
    notifyListeners();
  }

  @override
  void dispose() {
    PlatformDispatcher.instance.onPlatformBrightnessChanged = null;
    super.dispose();
  }
}
