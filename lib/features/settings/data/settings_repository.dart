import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/app_config.dart';
import '../../../core/models/topic.dart';

/// Persists user preferences (topic list + theme mode) via SharedPreferences.
///
/// All reads are tolerant of corrupt/empty data and fall back to sensible
/// defaults, so a bad write can never brick the app.
class SettingsRepository {
  const SettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  // --- Topics ---------------------------------------------------------------

  List<Topic> loadTopics() {
    final raw = _prefs.getString(AppConfig.prefsTopics);
    if (raw == null || raw.isEmpty) return AppConfig.defaultTopics;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return AppConfig.defaultTopics;
      final topics = decoded
          .whereType<Map>()
          .map((e) => Topic.fromJson(Map<String, dynamic>.from(e)))
          .where((t) => t.subreddit.isNotEmpty)
          .toList();
      return topics.isEmpty ? AppConfig.defaultTopics : topics;
    } catch (_) {
      return AppConfig.defaultTopics;
    }
  }

  Future<void> saveTopics(List<Topic> topics) {
    final raw = jsonEncode(topics.map((t) => t.toJson()).toList());
    return _prefs.setString(AppConfig.prefsTopics, raw);
  }

  // --- Theme ----------------------------------------------------------------

  ThemeMode loadThemeMode() {
    final index = _prefs.getInt(AppConfig.prefsThemeMode);
    if (index == null || index < 0 || index >= ThemeMode.values.length) {
      return ThemeMode.system;
    }
    return ThemeMode.values[index];
  }

  Future<void> saveThemeMode(ThemeMode mode) {
    return _prefs.setInt(AppConfig.prefsThemeMode, mode.index);
  }
}
