# Screen Time Tracker

A beautiful Windows desktop application to track your screen time and application usage built with Flutter.

![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter)
![Windows](https://img.shields.io/badge/Platform-Windows-0078D6?logo=windows)
![License](https://img.shields.io/badge/License-MIT-green)

## Features

- 📊 **Real-time Tracking** - Monitors active applications automatically
- 🎨 **Beautiful UI** - Windows 11 Fluent Design with Mica effect
- 📈 **Statistics** - Daily, weekly, and monthly usage analytics
- 🥧 **Visual Charts** - Pie charts and bar graphs for usage breakdown
- ⚙️ **Customizable** - Idle timeout, tracking precision, ignored apps
- 🔒 **Privacy** - Blur app names, pause on screen lock
- 🎯 **Goals** - Set daily screen time limits
- ☕ **Break Reminders** - Get reminded to take breaks

## Screenshots

Coming soon...

## Installation

### Option 1: Download Installer
Download the latest installer from [Releases](../../releases).

### Option 2: Build from Source

#### Prerequisites
- Flutter SDK 3.x
- Visual Studio 2022 with C++ desktop development workload
- Windows 10/11

#### Steps
```bash
# Clone the repository
git clone https://github.com/your-username/screen-time-tracker.git
cd screen-time-tracker

# Get dependencies
flutter pub get

# Run in debug mode
flutter run -d windows

# Build release version
flutter build windows --release
```

### Creating an Installer

1. Download and install [Inno Setup](https://jrsoftware.org/isdl.php)
2. Build the release version:
   ```bash
   flutter build windows --release
   ```
3. Open `installer.iss` with Inno Setup Compiler
4. Click **Build > Compile** (or press Ctrl+F9)
5. The installer will be created in the `installer` folder

Or simply run `build_installer.bat` which guides you through the process.

## Project Structure

```
lib/
├── main.dart              # App entry point and navigation
├── models/
│   └── app_usage.dart     # Data models
├── providers/
│   ├── screen_time_provider.dart  # Usage data management
│   ├── settings_provider.dart     # Settings persistence
│   └── theme_provider.dart        # Theme management
├── screens/
│   ├── home_screen.dart      # Dashboard
│   ├── statistics_screen.dart # Analytics
│   └── settings_screen.dart   # Configuration
└── services/
    ├── database_service.dart        # SQLite storage
    └── process_tracker_service.dart # Windows API tracking
```

## Tech Stack

- **Framework**: Flutter
- **UI**: Fluent UI (Windows 11 design)
- **State Management**: Provider
- **Database**: SQLite (sqflite_common_ffi)
- **Charts**: fl_chart
- **Windows API**: win32, ffi

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
