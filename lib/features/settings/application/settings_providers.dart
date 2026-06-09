import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/models/topic.dart';
import '../data/settings_repository.dart';

/// Bound to a real instance in `main()` via a `ProviderScope` override.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('SharedPreferences must be overridden'),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(sharedPreferencesProvider)),
);

/// The user's editable list of topics (persisted on every mutation).
final topicsProvider =
    NotifierProvider<TopicsNotifier, List<Topic>>(TopicsNotifier.new);

class TopicsNotifier extends Notifier<List<Topic>> {
  SettingsRepository get _repo => ref.read(settingsRepositoryProvider);

  @override
  List<Topic> build() => _repo.loadTopics();

  void add(Topic topic) {
    if (state.contains(topic)) return; // de-dupe by subreddit
    _commit([...state, topic]);
  }

  void update(int index, Topic topic) {
    if (index < 0 || index >= state.length) return;
    final next = [...state]..[index] = topic;
    _commit(next);
  }

  void removeAt(int index) {
    if (index < 0 || index >= state.length) return;
    final next = [...state]..removeAt(index);
    _commit(next);
  }

  /// For `ReorderableListView.onReorderItem`, whose [newIndex] is already
  /// adjusted for the removed item (no off-by-one correction needed).
  void move(int oldIndex, int newIndex) {
    final next = [...state];
    final item = next.removeAt(oldIndex);
    next.insert(newIndex, item);
    _commit(next);
  }

  void resetToDefaults() {
    state = [];
    _repo.saveTopics([]); // clearing persists defaults on next load
    state = _repo.loadTopics();
    _repo.saveTopics(state);
  }

  void _commit(List<Topic> next) {
    state = next;
    _repo.saveTopics(next);
  }
}

/// App theme mode (light / dark / system), persisted.
final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  SettingsRepository get _repo => ref.read(settingsRepositoryProvider);

  @override
  ThemeMode build() => _repo.loadThemeMode();

  void set(ThemeMode mode) {
    state = mode;
    _repo.saveThemeMode(mode);
  }
}
