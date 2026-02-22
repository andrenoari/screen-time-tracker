import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import '../models/app_usage.dart';
import 'database_service.dart';

enum ExportFormat { json, csv }

class DataSyncService {
  final DatabaseService _databaseService = DatabaseService.instance;

  static final DataSyncService _instance = DataSyncService._internal();

  factory DataSyncService() {
    return _instance;
  }

  DataSyncService._internal();

  /// Export existing AppUsage data to the local disk in the chosen format.
  /// Returns `true` if successful, `false` otherwise.
  Future<bool> exportData(ExportFormat format) async {
    try {
      final usageLogs = await _databaseService.getAllUsage();
      if (usageLogs.isEmpty) return false;

      final extension = format == ExportFormat.json ? 'json' : 'csv';
      
      // Let user pick save destination
      final String? selectedPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Export Screen Time Data',
        fileName: 'screen_time_export.$extension',
        type: FileType.custom,
        allowedExtensions: [extension],
      );

      if (selectedPath == null) {
        return false; // User canceled the picker
      }

      final file = File(selectedPath);
      
      if (format == ExportFormat.json) {
        // Convert logs to JSON maps
        final jsonList = usageLogs.map((log) => log.toMap()).toList();
        final jsonString = JsonEncoder.withIndent('  ').convert(jsonList);
        await file.writeAsString(jsonString);
      } else {
        // Convert to CSV
        final List<List<dynamic>> csvData = [
          // Header
          ['ID', 'Process Name', 'Window Title', 'App Path', 'Usage Seconds', 'Date', 'Last Active'],
          // Rows
          ...usageLogs.map((log) => [
            log.id,
            log.processName,
            log.windowTitle,
            log.appPath,
            log.usageSeconds,
            log.date.toIso8601String().split('T')[0],
            log.lastActive.toIso8601String()
          ])
        ];
        
        final csvString = CsvCodec().encode(csvData);
        await file.writeAsString(csvString);
      }
      
      return true;
    } catch (e) {
      print('Export error: $e');
      return false;
    }
  }

  /// Import external JSON or CSV backup data into the sql database.
  Future<bool> importData() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Import Screen Time Data',
        type: FileType.custom,
        allowedExtensions: ['json', 'csv'],
      );

      if (result == null || result.files.single.path == null) {
        return false; // User canceled
      }

      final file = File(result.files.single.path!);
      final extension = result.files.single.extension?.toLowerCase();
      final contentSize = await file.length();
      
      if (contentSize == 0) return false;

      if (extension == 'json') {
        final content = await file.readAsString();
        final List<dynamic> decoded = jsonDecode(content);
        
        for (var item in decoded) {
          final usage = AppUsage.fromMap(item as Map<String, dynamic>);
          await _databaseService.upsertAppUsage(usage);
        }
      } else if (extension == 'csv') {
        final content = await file.readAsString();
        final List<List<dynamic>> csvTable = CsvCodec().decode(content);
        
        if (csvTable.length <= 1) return false; // Only headers or empty

        // Iterate past header row
        for (int i = 1; i < csvTable.length; i++) {
          final row = csvTable[i];
          if (row.length < 7) continue;

          final usage = AppUsage(
            id: int.tryParse(row[0].toString()),
            processName: row[1].toString(),
            windowTitle: row[2].toString(),
            appPath: row[3]?.toString(),
            usageSeconds: int.tryParse(row[4].toString()) ?? 0,
            date: DateTime.parse(row[5].toString()),
            lastActive: DateTime.parse(row[6].toString()),
          );
          
          await _databaseService.upsertAppUsage(usage);
        }
      } else {
        return false; // Unsupported format
      }

      return true;
    } catch (e) {
      print('Import error: $e');
      return false;
    }
  }
}
