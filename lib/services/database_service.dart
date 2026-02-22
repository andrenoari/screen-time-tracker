import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/app_usage.dart';

class DatabaseService {
  static Database? _database;
  static final DatabaseService instance = DatabaseService._init();

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    // Initialize FFI for Windows
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final appDir = await getApplicationSupportDirectory();
    final dbPath = join(appDir.path, 'screen_time.db');

    // Ensure directory exists
    await Directory(appDir.path).create(recursive: true);

    return await databaseFactoryFfi.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: _createDB,
      ),
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE app_usage (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        process_name TEXT NOT NULL,
        window_title TEXT NOT NULL,
        app_path TEXT,
        usage_seconds INTEGER NOT NULL DEFAULT 0,
        date TEXT NOT NULL,
        last_active TEXT NOT NULL,
        UNIQUE(process_name, date)
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_date ON app_usage(date)
    ''');

    await db.execute('''
      CREATE INDEX idx_process ON app_usage(process_name)
    ''');

    // Create settings table
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  /// Insert or update app usage record
  Future<void> upsertAppUsage(AppUsage usage) async {
    final db = await database;
    final dateStr = usage.date.toIso8601String().split('T')[0];

    // Check if record exists
    final existing = await db.query(
      'app_usage',
      where: 'process_name = ? AND date = ?',
      whereArgs: [usage.processName, dateStr],
    );

    if (existing.isEmpty) {
      await db.insert('app_usage', {
        'process_name': usage.processName,
        'window_title': usage.windowTitle,
        'app_path': usage.appPath,
        'usage_seconds': usage.usageSeconds,
        'date': dateStr,
        'last_active': usage.lastActive.toIso8601String(),
      });
    } else {
      await db.update(
        'app_usage',
        {
          'usage_seconds': (existing.first['usage_seconds'] as int) + usage.usageSeconds,
          'window_title': usage.windowTitle,
          'last_active': usage.lastActive.toIso8601String(),
        },
        where: 'process_name = ? AND date = ?',
        whereArgs: [usage.processName, dateStr],
      );
    }
  }

  /// Get all usage for a specific date
  Future<List<AppUsage>> getUsageForDate(DateTime date) async {
    final db = await database;
    final dateStr = date.toIso8601String().split('T')[0];

    final results = await db.query(
      'app_usage',
      where: 'date = ?',
      whereArgs: [dateStr],
      orderBy: 'usage_seconds DESC',
    );

    return results.map((map) => AppUsage.fromMap(map)).toList();
  }

  /// Get all recorded usage from the database
  Future<List<AppUsage>> getAllUsage() async {
    final db = await database;

    final results = await db.query(
      'app_usage',
      orderBy: 'date DESC, usage_seconds DESC',
    );

    return results.map((map) => AppUsage.fromMap(map)).toList();
  }

  /// Get usage for date range
  Future<List<AppUsage>> getUsageForDateRange(DateTime start, DateTime end) async {
    final db = await database;
    final startStr = start.toIso8601String().split('T')[0];
    final endStr = end.toIso8601String().split('T')[0];

    final results = await db.query(
      'app_usage',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startStr, endStr],
      orderBy: 'date DESC, usage_seconds DESC',
    );

    return results.map((map) => AppUsage.fromMap(map)).toList();
  }

  /// Get total usage seconds for a date
  Future<int> getTotalUsageForDate(DateTime date) async {
    final db = await database;
    final dateStr = date.toIso8601String().split('T')[0];

    final result = await db.rawQuery(
      'SELECT SUM(usage_seconds) as total FROM app_usage WHERE date = ?',
      [dateStr],
    );

    return (result.first['total'] as int?) ?? 0;
  }

  /// Get top apps for a date range
  Future<List<Map<String, dynamic>>> getTopApps(DateTime start, DateTime end, {int limit = 10}) async {
    final db = await database;
    final startStr = start.toIso8601String().split('T')[0];
    final endStr = end.toIso8601String().split('T')[0];

    return await db.rawQuery('''
      SELECT process_name, SUM(usage_seconds) as total_seconds
      FROM app_usage
      WHERE date >= ? AND date <= ?
      GROUP BY process_name
      ORDER BY total_seconds DESC
      LIMIT ?
    ''', [startStr, endStr, limit]);
  }

  /// Get daily usage totals for the past N days
  Future<List<Map<String, dynamic>>> getDailyUsage(int days) async {
    final db = await database;
    final startDate = DateTime.now().subtract(Duration(days: days - 1));
    final startStr = startDate.toIso8601String().split('T')[0];

    return await db.rawQuery('''
      SELECT date, SUM(usage_seconds) as total_seconds
      FROM app_usage
      WHERE date >= ?
      GROUP BY date
      ORDER BY date ASC
    ''', [startStr]);
  }

  /// Save a setting
  Future<void> saveSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get a setting
  Future<String?> getSetting(String key) async {
    final db = await database;
    final results = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
    );

    if (results.isEmpty) return null;
    return results.first['value'] as String;
  }

  /// Delete old records (older than specified days)
  Future<int> deleteOldRecords(int daysToKeep) async {
    final db = await database;
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
    final cutoffStr = cutoffDate.toIso8601String().split('T')[0];

    return await db.delete(
      'app_usage',
      where: 'date < ?',
      whereArgs: [cutoffStr],
    );
  }

  /// Clear all usage records from the database
  Future<void> clearAllUsage() async {
    final db = await database;
    await db.delete('app_usage');
  }

  /// Close the database
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  /// Get usage for a specific process on a specific date
  Future<AppUsage?> getAppUsageForProcess(String processName, DateTime date) async {
    final db = await database;
    final dateStr = date.toIso8601String().split('T')[0];

    final results = await db.query(
      'app_usage',
      where: 'process_name = ? AND date = ?',
      whereArgs: [processName, dateStr],
    );

    if (results.isEmpty) return null;
    return AppUsage.fromMap(results.first);
  }
}
