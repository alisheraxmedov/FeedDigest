import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';

import '../data/ai_repository.dart';
import '../data/article_body_cache_repository.dart';
import '../data/favorites_repository.dart';
import '../data/read_state_repository.dart';
import '../data/settings_repository.dart';
import '../data/subscription_repository.dart';
import '../data/summary_cache_repository.dart';
import 'ai/ai_client.dart';
import 'ai/ai_provider.dart';
import 'ai/clients/anthropic_client.dart';
import 'ai/clients/gemini_client.dart';
import 'ai/clients/openai_compat_client.dart';
import 'config/app_config.dart';
import 'prefs/preferences.dart';
import 'services/export_service.dart';
import 'sources/article_source.dart';
import 'sources/devto_source.dart';
import 'sources/hacker_news_source.dart';
import 'sources/lobsters_source.dart';
import 'sources/rss_source.dart';
import 'storage/hive_boxes.dart';
import 'storage/secure_store.dart';

final dioProvider = Provider<Dio>(
  (ref) => Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 15),
    ),
  ),
);

final metaBoxProvider = Provider<Box<dynamic>>(
  (ref) => Hive.box<dynamic>(HiveBoxes.meta),
);

final hackerNewsSourceProvider = Provider<ArticleSource>(
  (ref) => HackerNewsSource(ref.watch(dioProvider)),
);

final devtoSourceProvider = Provider<ArticleSource>(
  (ref) => DevtoSource(ref.watch(dioProvider)),
);

final lobstersSourceProvider = Provider<ArticleSource>(
  (ref) => LobstersSource(ref.watch(dioProvider)),
);

// Habr filters server-side: an empty topic uses the latest-articles feed; a topic
// uses Habr's full-text search RSS (order=date for newest, relevance for popular).
final habrSourceProvider = Provider<ArticleSource>(
  (ref) => RssSource(
    ref.watch(dioProvider),
    kind: FeedSource.habr,
    serverFiltersTopic: true,
    urlBuilder: (topic, sort) {
      final query = topic.trim();
      if (query.isEmpty) return AppConfig.habrFeedUrl;
      return Uri.https(AppConfig.habrHost, '/ru/rss/search/', {
        'q': query,
        'target_type': 'posts',
        'order': sort == FeedSort.popular ? 'relevance' : 'date',
        'fl': 'ru',
      }).toString();
    },
  ),
);

// VC.ru exposes only its general feed (no per-topic RSS), so a selected topic is
// applied by RssSource's client-side keyword filter.
final vcruSourceProvider = Provider<ArticleSource>(
  (ref) => RssSource(
    ref.watch(dioProvider),
    kind: FeedSource.vcru,
    urlBuilder: (topic, sort) => AppConfig.vcruFeedUrl,
  ),
);

final secureStoreProvider = Provider<SecureStore>((ref) => SecureStore());

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(secureStoreProvider)),
);

final geminiClientProvider = Provider<GeminiClient>(
  (ref) => GeminiClient(ref.watch(dioProvider)),
);

final anthropicClientProvider = Provider<AnthropicClient>(
  (ref) => AnthropicClient(ref.watch(dioProvider)),
);

/// OpenAI, DeepSeek, and Grok all speak the same chat/completions dialect —
/// one client class, three configurations.
final openAiCompatClientProvider =
    Provider.family<OpenAiCompatClient, AiProvider>((ref, provider) {
      final (baseUrl, model) = switch (provider) {
        AiProvider.openai => (
          AppConfig.openAiBaseUrl,
          AiProvider.openai.model,
        ),
        AiProvider.deepseek => (
          AppConfig.deepSeekBaseUrl,
          AiProvider.deepseek.model,
        ),
        AiProvider.grok => (AppConfig.xaiBaseUrl, AiProvider.grok.model),
        _ => throw ArgumentError(
          'not an OpenAI-compatible provider: $provider',
        ),
      };
      return OpenAiCompatClient(
        ref.watch(dioProvider),
        baseUrl: baseUrl,
        model: model,
      );
    });

/// Rebuilds whenever the user switches providers, so every AI feature picks
/// up the new backend on its next call.
final aiRepositoryProvider = Provider<AiRepository>((ref) {
  final provider = ref.watch(aiProviderProvider);
  final AiClient client = switch (provider) {
    AiProvider.gemini => ref.watch(geminiClientProvider),
    AiProvider.claude => ref.watch(anthropicClientProvider),
    _ => ref.watch(openAiCompatClientProvider(provider)),
  };
  return AiRepository(
    ref.watch(settingsRepositoryProvider),
    provider: provider,
    client: client,
    geminiClient: ref.watch(geminiClientProvider),
  );
});

final favoritesRepositoryProvider = Provider<FavoritesRepository>(
  (ref) => FavoritesRepository(Hive.box<dynamic>(HiveBoxes.favorites)),
);

final summaryCacheRepositoryProvider = Provider<SummaryCacheRepository>(
  (ref) => SummaryCacheRepository(Hive.box<dynamic>(HiveBoxes.summaries)),
);

final readStateRepositoryProvider = Provider<ReadStateRepository>(
  (ref) => ReadStateRepository(Hive.box<dynamic>(HiveBoxes.read)),
);

final articleBodyCacheRepositoryProvider = Provider<ArticleBodyCacheRepository>(
  (ref) => ArticleBodyCacheRepository(Hive.box<dynamic>(HiveBoxes.bodies)),
);

final exportServiceProvider = Provider<ExportService>((ref) => ExportService());

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>(
  (ref) => SubscriptionRepository(
    Hive.box<dynamic>(HiveBoxes.subscriptions),
    Hive.box<dynamic>(HiveBoxes.meta),
  ),
);
