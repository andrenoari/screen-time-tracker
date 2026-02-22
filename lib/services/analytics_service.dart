import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  static const String _mixpanelToken = 'fe9eb0e2dd67cfb5778e9a8378f8294d'; // User should replace this
  static const String _mixpanelUrl = 'https://api.mixpanel.com/track';
  static const String _distinctIdKey = 'analytics_distinct_id';

  String? _distinctId;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _distinctId = prefs.getString(_distinctIdKey);

    if (_distinctId == null) {
      _distinctId = const Uuid().v4();
      await prefs.setString(_distinctIdKey, _distinctId!);
    }
    
    debugPrint('Analytics: Initialized with distinctId: $_distinctId');
  }

  Future<void> trackEvent(String eventName, [Map<String, dynamic>? properties]) async {
    if (_mixpanelToken == 'YOUR_MIXPANEL_TOKEN_HERE') {
      debugPrint('Analytics: Mixpanel token not set. Skipping event: $eventName');
      return;
    }

    if (_distinctId == null) {
      await initialize();
    }

    final Map<String, dynamic> data = {
      'event': eventName,
      'properties': {
        'token': _mixpanelToken,
        'distinct_id': _distinctId,
        'platform': 'Windows',
        ...?properties,
      },
    };

    final String base64Data = base64Encode(utf8.encode(jsonEncode(data)));

    try {
      final response = await http.post(
        Uri.parse('$_mixpanelUrl?data=$base64Data'),
      );

      if (response.statusCode == 200) {
        debugPrint('Analytics: Event tracked: $eventName');
      } else {
        debugPrint('Analytics: Failed to track event: $eventName (Status: ${response.statusCode})');
      }
    } catch (e) {
      debugPrint('Analytics: Error tracking event: $e');
    }
  }
}
