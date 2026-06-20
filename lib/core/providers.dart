import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';

import '../data/favorites_repository.dart';
import '../data/gemini_repository.dart';
import '../data/reddit_repository.dart';
import '../data/settings_repository.dart';
import '../data/subscription_repository.dart';
import '../data/summary_cache_repository.dart';
import 'network/reddit_client.dart';
import 'storage/hive_boxes.dart';
import 'storage/secure_store.dart';

final dioProvider = Provider<Dio>((ref) => Dio());

final redditClientProvider =
    Provider<RedditClient>((ref) => RedditClient(ref.watch(dioProvider)));

final redditRepositoryProvider = Provider<RedditRepository>(
    (ref) => RedditRepository(ref.watch(redditClientProvider)));

final secureStoreProvider = Provider<SecureStore>((ref) => SecureStore());

final settingsRepositoryProvider = Provider<SettingsRepository>(
    (ref) => SettingsRepository(ref.watch(secureStoreProvider)));

final geminiRepositoryProvider = Provider<GeminiRepository>((ref) =>
    GeminiRepository(
        ref.watch(dioProvider), ref.watch(settingsRepositoryProvider)));

final favoritesRepositoryProvider = Provider<FavoritesRepository>(
    (ref) => FavoritesRepository(Hive.box<dynamic>(HiveBoxes.favorites)));

final summaryCacheRepositoryProvider = Provider<SummaryCacheRepository>(
    (ref) => SummaryCacheRepository(Hive.box<dynamic>(HiveBoxes.summaries)));

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>(
    (ref) => SubscriptionRepository(
          Hive.box<dynamic>(HiveBoxes.subscriptions),
          Hive.box<dynamic>(HiveBoxes.meta),
        ));
