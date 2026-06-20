import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';

import '../data/favorites_repository.dart';
import '../data/gemini_repository.dart';
import '../data/settings_repository.dart';
import '../data/subscription_repository.dart';
import '../data/summary_cache_repository.dart';
import 'sources/article_source.dart';
import 'sources/devto_source.dart';
import 'sources/hacker_news_source.dart';
import 'storage/hive_boxes.dart';
import 'storage/secure_store.dart';

final dioProvider = Provider<Dio>((ref) => Dio());

final metaBoxProvider =
    Provider<Box<dynamic>>((ref) => Hive.box<dynamic>(HiveBoxes.meta));

final hackerNewsSourceProvider =
    Provider<ArticleSource>((ref) => HackerNewsSource(ref.watch(dioProvider)));

final devtoSourceProvider =
    Provider<ArticleSource>((ref) => DevtoSource(ref.watch(dioProvider)));

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
