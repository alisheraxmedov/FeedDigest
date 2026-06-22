# FeedDigest MVVM Scraping Rebuild — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild `lib/` as a clean, comment-free, serverless Flutter app that scrapes Reddit via public `.json` endpoints (no OAuth), summarizes posts into Uzbek with Gemini (BYOK), and saves favorites — structured as MVVM with Riverpod Notifier ViewModels.

**Architecture:** MVVM. Model = `models/` (pure data classes) + `data/` (repositories/services). ViewModel = Riverpod `Notifier`/`AsyncNotifier`. View = screens/widgets reading state via `ref.watch`. Shared Model layer; feature-scoped ViewModel/View.

**Tech Stack:** Flutter, Dart, flutter_riverpod 3.x, dio, hive_ce + hive_ce_flutter, flutter_secure_storage, cached_network_image, url_launcher, google_fonts.

**Hard rules:** No comments in any Dart file. Lean models (only fields the UI uses). Tolerant `fromJson`. Always `Map<String,dynamic>.from(...)` on Hive reads. `Uri.https` for all Reddit requests.

---

## Task 0: Dependencies and clean slate

**Files:**
- Modify: `pubspec.yaml`
- Delete: `lib/` (all), `test/unit/`, `test/widget_test.dart`, `.env` asset reference

- [ ] **Step 1: Swap dependencies**

Run:
```bash
flutter pub remove flutter_web_auth_2 shared_preferences flutter_dotenv
flutter pub add hive_ce hive_ce_flutter
```
Expected: `pubspec.yaml` gains `hive_ce`, `hive_ce_flutter`; loses the three removed packages.

- [ ] **Step 2: Remove the `.env` asset entry from `pubspec.yaml`**

Delete these lines under `flutter:`:
```yaml
  assets:
    - .env
```

- [ ] **Step 3: Delete the old source and tests**

Run:
```bash
rm -rf lib test/unit test/widget_test.dart
mkdir -p lib/core/config lib/core/network lib/core/storage lib/core/theme lib/core/utils lib/core/widgets lib/models lib/data
mkdir -p lib/features/shell/view lib/features/feed/view/widgets lib/features/feed/viewmodel
mkdir -p lib/features/search/view lib/features/search/viewmodel
mkdir -p lib/features/favorites/view lib/features/favorites/viewmodel
mkdir -p lib/features/summary/view lib/features/summary/viewmodel
mkdir -p lib/features/settings/view lib/features/settings/viewmodel
mkdir -p test/unit test/fixtures
```

- [ ] **Step 4: Create test fixtures from the research samples**

Run:
```bash
cp docs/researches/example.json test/fixtures/top_example.json
cp docs/researches/search_example.json test/fixtures/search_example.json
```

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "chore: reset lib, swap deps to hive_ce, add fixtures"
```

---

## Task 1: App config

**Files:**
- Create: `lib/core/config/app_config.dart`

- [ ] **Step 1: Write `app_config.dart`**

```dart
import '../../models/topic.dart';

class AppConfig {
  static const String userAgent = 'UzSummaryApp/1.0 (shaxsiy)';

  static const List<String> redditHosts = [
    'www.reddit.com',
    'old.reddit.com',
    'redlib.catsarch.com',
  ];

  static const String geminiEndpoint =
      'https://generativelanguage.googleapis.com/v1beta/models';
  static const String geminiModel = 'gemini-2.5-flash';

  static const String topPeriod = 'week';
  static const int feedLimit = 10;
  static const int searchLimit = 25;

  static const List<Topic> defaultTopics = [
    Topic(label: 'Flutter', subreddit: 'FlutterDev'),
    Topic(label: 'Programming', subreddit: 'programming'),
    Topic(label: 'Technology', subreddit: 'technology'),
  ];
}
```

- [ ] **Step 2: Verify it analyzes (after Task 2 models exist it resolves; for now expect the import to be unresolved)**

Run: `flutter analyze lib/core/config/app_config.dart`
Expected: only an unresolved-import warning for `topic.dart` until Task 2. Proceed.

- [ ] **Step 3: Commit**

```bash
git add lib/core/config/app_config.dart
git commit -m "feat: add app config constants"
```

---

## Task 2: Topic model

**Files:**
- Create: `lib/models/topic.dart`
- Test: `test/unit/topic_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:feeddigest/models/topic.dart';

void main() {
  test('round-trips through json', () {
    const t = Topic(label: 'Flutter', subreddit: 'FlutterDev');
    final back = Topic.fromJson(t.toJson());
    expect(back.label, 'Flutter');
    expect(back.subreddit, 'FlutterDev');
  });

  test('displayName prefixes r/', () {
    const t = Topic(label: 'X', subreddit: 'rust');
    expect(t.displayName, 'r/rust');
  });

  test('equality is case-insensitive on subreddit', () {
    expect(const Topic(label: 'A', subreddit: 'Rust'),
        const Topic(label: 'B', subreddit: 'rust'));
  });
}
```

- [ ] **Step 2: Run test, expect failure**

Run: `flutter test test/unit/topic_test.dart`
Expected: FAIL — `topic.dart` not found.

- [ ] **Step 3: Write `lib/models/topic.dart`**

```dart
import 'package:flutter/foundation.dart';

@immutable
class Topic {
  const Topic({required this.label, required this.subreddit});

  final String label;
  final String subreddit;

  String get displayName => 'r/$subreddit';

  Topic copyWith({String? label, String? subreddit}) => Topic(
        label: label ?? this.label,
        subreddit: subreddit ?? this.subreddit,
      );

  factory Topic.fromJson(Map<String, dynamic> json) => Topic(
        label: json['label'] as String? ?? '',
        subreddit: json['subreddit'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {'label': label, 'subreddit': subreddit};

  @override
  bool operator ==(Object other) =>
      other is Topic &&
      other.subreddit.toLowerCase() == subreddit.toLowerCase();

  @override
  int get hashCode => subreddit.toLowerCase().hashCode;
}
```

- [ ] **Step 4: Run test, expect pass**

Run: `flutter test test/unit/topic_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/models/topic.dart test/unit/topic_test.dart
git commit -m "feat: add Topic model"
```

---

## Task 3: RedditPost model

**Files:**
- Create: `lib/models/reddit_post.dart`
- Test: `test/unit/reddit_post_test.dart`

- [ ] **Step 1: Write the failing test (uses real fixtures)**

```dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:feeddigest/models/reddit_post.dart';

Map<String, dynamic> _firstPostData(dynamic decoded) {
  final listing = decoded is List ? decoded.first : decoded;
  final children = listing['data']['children'] as List;
  final first = children.firstWhere((c) => c['kind'] == 't3');
  return Map<String, dynamic>.from(first['data'] as Map);
}

void main() {
  test('parses a post from the top fixture', () {
    final raw = File('test/fixtures/top_example.json').readAsStringSync();
    final post = RedditPost.fromJson(_firstPostData(jsonDecode(raw)));
    expect(post.id, isNotEmpty);
    expect(post.title, isNotEmpty);
  });

  test('parses a post from the search fixture', () {
    final raw = File('test/fixtures/search_example.json').readAsStringSync();
    final post = RedditPost.fromJson(_firstPostData(jsonDecode(raw)));
    expect(post.id, isNotEmpty);
  });

  test('tolerates missing fields', () {
    final post = RedditPost.fromJson(const {});
    expect(post.id, '');
    expect(post.score, 0);
    expect(post.isSelf, false);
  });

  test('hasThumbnail rejects placeholder values', () {
    expect(RedditPost.fromJson(const {'thumbnail': 'self'}).hasThumbnail, false);
    expect(
        RedditPost.fromJson(const {'thumbnail': 'https://x/y.jpg'}).hasThumbnail,
        true);
  });

  test('round-trips through json', () {
    final post = RedditPost.fromJson(const {
      'id': 'abc',
      'title': 'T',
      'score': 5,
      'created_utc': 1700000000,
    });
    final back = RedditPost.fromJson(post.toJson());
    expect(back.id, 'abc');
    expect(back.score, 5);
  });
}
```

- [ ] **Step 2: Run test, expect failure**

Run: `flutter test test/unit/reddit_post_test.dart`
Expected: FAIL — `reddit_post.dart` not found.

- [ ] **Step 3: Write `lib/models/reddit_post.dart`**

```dart
import 'package:flutter/foundation.dart';

@immutable
class RedditPost {
  const RedditPost({
    required this.id,
    required this.title,
    required this.selftext,
    required this.url,
    required this.permalink,
    required this.author,
    required this.subreddit,
    required this.subredditNamePrefixed,
    required this.score,
    required this.numComments,
    required this.createdUtc,
    required this.thumbnail,
    required this.isSelf,
    required this.over18,
    required this.domain,
    required this.upvoteRatio,
    required this.linkFlairText,
  });

  final String id;
  final String title;
  final String selftext;
  final String url;
  final String permalink;
  final String author;
  final String subreddit;
  final String subredditNamePrefixed;
  final int score;
  final int numComments;
  final double createdUtc;
  final String thumbnail;
  final bool isSelf;
  final bool over18;
  final String domain;
  final double upvoteRatio;
  final String linkFlairText;

  String get fullPermalink => 'https://www.reddit.com$permalink';

  bool get hasThumbnail =>
      thumbnail.startsWith('http') &&
      thumbnail != 'self' &&
      thumbnail != 'default' &&
      thumbnail != 'nsfw';

  String get contentText =>
      isSelf && selftext.isNotEmpty ? selftext : url;

  factory RedditPost.fromJson(Map<String, dynamic> json) => RedditPost(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        selftext: json['selftext'] as String? ?? '',
        url: json['url'] as String? ?? '',
        permalink: json['permalink'] as String? ?? '',
        author: json['author'] as String? ?? '',
        subreddit: json['subreddit'] as String? ?? '',
        subredditNamePrefixed:
            json['subreddit_name_prefixed'] as String? ?? '',
        score: (json['score'] as num?)?.toInt() ?? 0,
        numComments: (json['num_comments'] as num?)?.toInt() ?? 0,
        createdUtc: (json['created_utc'] as num?)?.toDouble() ?? 0,
        thumbnail: json['thumbnail'] as String? ?? '',
        isSelf: json['is_self'] as bool? ?? false,
        over18: json['over_18'] as bool? ?? false,
        domain: json['domain'] as String? ?? '',
        upvoteRatio: (json['upvote_ratio'] as num?)?.toDouble() ?? 0,
        linkFlairText: json['link_flair_text'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'selftext': selftext,
        'url': url,
        'permalink': permalink,
        'author': author,
        'subreddit': subreddit,
        'subreddit_name_prefixed': subredditNamePrefixed,
        'score': score,
        'num_comments': numComments,
        'created_utc': createdUtc,
        'thumbnail': thumbnail,
        'is_self': isSelf,
        'over_18': over18,
        'domain': domain,
        'upvote_ratio': upvoteRatio,
        'link_flair_text': linkFlairText,
      };

  @override
  bool operator ==(Object other) => other is RedditPost && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
```

- [ ] **Step 4: Run test, expect pass**

Run: `flutter test test/unit/reddit_post_test.dart`
Expected: PASS (5 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/models/reddit_post.dart test/unit/reddit_post_test.dart
git commit -m "feat: add lean RedditPost model"
```

---

## Task 4: AiSummary model

**Files:**
- Create: `lib/models/ai_summary.dart`
- Test: `test/unit/ai_summary_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:feeddigest/models/ai_summary.dart';

void main() {
  test('round-trips through json', () {
    const s = AiSummary(postId: 'abc', summary: 'Salom');
    final back = AiSummary.fromJson(s.toJson());
    expect(back.postId, 'abc');
    expect(back.summary, 'Salom');
  });

  test('tolerates missing fields', () {
    final s = AiSummary.fromJson(const {});
    expect(s.postId, '');
    expect(s.summary, '');
  });
}
```

- [ ] **Step 2: Run test, expect failure**

Run: `flutter test test/unit/ai_summary_test.dart`
Expected: FAIL — not found.

- [ ] **Step 3: Write `lib/models/ai_summary.dart`**

```dart
import 'package:flutter/foundation.dart';

@immutable
class AiSummary {
  const AiSummary({required this.postId, required this.summary});

  final String postId;
  final String summary;

  factory AiSummary.fromJson(Map<String, dynamic> json) => AiSummary(
        postId: json['postId'] as String? ?? '',
        summary: json['summary'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {'postId': postId, 'summary': summary};
}
```

- [ ] **Step 4: Run test, expect pass**

Run: `flutter test test/unit/ai_summary_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/models/ai_summary.dart test/unit/ai_summary_test.dart
git commit -m "feat: add AiSummary model"
```

---

## Task 5: Formatters

**Files:**
- Create: `lib/core/utils/formatters.dart`
- Test: `test/unit/formatters_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:feeddigest/core/utils/formatters.dart';

void main() {
  test('compactScore formats thousands and millions', () {
    expect(Formatters.compactScore(999), '999');
    expect(Formatters.compactScore(1500), '1.5k');
    expect(Formatters.compactScore(2000000), '2.0M');
  });

  test('timeAgo uses injected now', () {
    final now = DateTime.utc(2024, 1, 1, 12, 0, 0);
    final created =
        now.subtract(const Duration(hours: 3)).millisecondsSinceEpoch / 1000;
    expect(Formatters.timeAgo(created, now: now), '3h');
  });
}
```

- [ ] **Step 2: Run test, expect failure**

Run: `flutter test test/unit/formatters_test.dart`
Expected: FAIL — not found.

- [ ] **Step 3: Write `lib/core/utils/formatters.dart`**

```dart
class Formatters {
  static String compactScore(int score) {
    if (score >= 1000000) return '${(score / 1000000).toStringAsFixed(1)}M';
    if (score >= 1000) return '${(score / 1000).toStringAsFixed(1)}k';
    return '$score';
  }

  static String timeAgo(double createdUtc, {DateTime? now}) {
    final created =
        DateTime.fromMillisecondsSinceEpoch((createdUtc * 1000).round());
    final diff = (now ?? DateTime.now()).difference(created);
    if (diff.inDays >= 7) return '${diff.inDays ~/ 7}w';
    if (diff.inDays >= 1) return '${diff.inDays}d';
    if (diff.inHours >= 1) return '${diff.inHours}h';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}m';
    return 'hozir';
  }
}
```

- [ ] **Step 4: Run test, expect pass**

Run: `flutter test test/unit/formatters_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/core/utils/formatters.dart test/unit/formatters_test.dart
git commit -m "feat: add formatters"
```

---

## Task 6: Reddit client with host fallback

**Files:**
- Create: `lib/core/network/reddit_client.dart`

- [ ] **Step 1: Write `lib/core/network/reddit_client.dart`**

```dart
import 'package:dio/dio.dart';
import '../config/app_config.dart';

class RedditException implements Exception {
  RedditException(this.message);
  final String message;
  @override
  String toString() => 'RedditException: $message';
}

class RedditClient {
  RedditClient(this._dio);

  final Dio _dio;

  Future<dynamic> getJson(
    String path,
    Map<String, dynamic> queryParameters,
  ) async {
    Object? lastError;
    for (final host in AppConfig.redditHosts) {
      try {
        final uri = Uri.https(host, path, _stringify(queryParameters));
        final resp = await _dio.getUri<dynamic>(
          uri,
          options: Options(
            headers: {'User-Agent': AppConfig.userAgent},
            responseType: ResponseType.json,
          ),
        );
        if (resp.data != null) return resp.data;
        lastError = RedditException('Empty response from $host');
      } catch (e) {
        lastError = e;
      }
    }
    throw RedditException('All Reddit hosts failed: $lastError');
  }

  Map<String, String> _stringify(Map<String, dynamic> params) =>
      params.map((key, value) => MapEntry(key, '$value'));
}
```

- [ ] **Step 2: Analyze**

Run: `flutter analyze lib/core/network/reddit_client.dart`
Expected: No issues.

- [ ] **Step 3: Commit**

```bash
git add lib/core/network/reddit_client.dart
git commit -m "feat: add Reddit client with host fallback"
```

---

## Task 7: Reddit repository

**Files:**
- Create: `lib/data/reddit_repository.dart`
- Test: `test/unit/reddit_repository_test.dart`

- [ ] **Step 1: Write the failing test (fake client returns fixture)**

```dart
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:feeddigest/core/network/reddit_client.dart';
import 'package:feeddigest/data/reddit_repository.dart';

class _FakeClient extends RedditClient {
  _FakeClient(this.payload) : super(Dio());
  final dynamic payload;
  String? lastPath;
  Map<String, dynamic>? lastQuery;

  @override
  Future<dynamic> getJson(String path, Map<String, dynamic> query) async {
    lastPath = path;
    lastQuery = query;
    return payload;
  }
}

void main() {
  test('topPosts parses array-form listing', () async {
    final raw = jsonDecode(
        File('test/fixtures/top_example.json').readAsStringSync());
    final client = _FakeClient(raw);
    final repo = RedditRepository(client);
    final posts = await repo.topPosts('FlutterDev');
    expect(posts, isNotEmpty);
    expect(client.lastPath, '/r/FlutterDev/top.json');
    expect(client.lastQuery!['t'], 'week');
  });

  test('searchPosts parses single-object listing and builds path', () async {
    final raw = jsonDecode(
        File('test/fixtures/search_example.json').readAsStringSync());
    final client = _FakeClient(raw);
    final repo = RedditRepository(client);
    final posts = await repo.searchPosts('flutter');
    expect(posts, isNotEmpty);
    expect(client.lastPath, '/search.json');
    expect(client.lastQuery!['type'], 'link');
  });

  test('searchPosts restricts to subreddit when given', () async {
    final raw = jsonDecode(
        File('test/fixtures/search_example.json').readAsStringSync());
    final client = _FakeClient(raw);
    final repo = RedditRepository(client);
    await repo.searchPosts('state', subreddit: 'FlutterDev');
    expect(client.lastPath, '/r/FlutterDev/search.json');
    expect(client.lastQuery!['restrict_sr'], 'true');
  });
}
```

- [ ] **Step 2: Run test, expect failure**

Run: `flutter test test/unit/reddit_repository_test.dart`
Expected: FAIL — `reddit_repository.dart` not found.

- [ ] **Step 3: Write `lib/data/reddit_repository.dart`**

```dart
import '../core/config/app_config.dart';
import '../core/network/reddit_client.dart';
import '../models/reddit_post.dart';

class RedditRepository {
  RedditRepository(this._client);

  final RedditClient _client;

  Future<List<RedditPost>> topPosts(
    String subreddit, {
    String time = AppConfig.topPeriod,
    int limit = AppConfig.feedLimit,
  }) async {
    final data = await _client.getJson('/r/$subreddit/top.json', {
      't': time,
      'limit': limit,
    });
    return _parse(data);
  }

  Future<List<RedditPost>> searchPosts(
    String query, {
    String? subreddit,
    String sort = 'top',
    String time = 'month',
    int limit = AppConfig.searchLimit,
  }) async {
    final path =
        subreddit == null ? '/search.json' : '/r/$subreddit/search.json';
    final data = await _client.getJson(path, {
      'q': query,
      'sort': sort,
      't': time,
      'limit': limit,
      'type': 'link',
      if (subreddit != null) 'restrict_sr': 'true',
    });
    return _parse(data);
  }

  List<RedditPost> _parse(dynamic data) {
    final listing = data is List ? data.first : data;
    final children = (listing['data']?['children'] as List?) ?? const [];
    return children
        .where((c) =>
            c is Map && c['kind'] == 't3' && c['data'] is Map)
        .map((c) => RedditPost.fromJson(Map<String, dynamic>.from(c['data'])))
        .where((p) => p.id.isNotEmpty)
        .toList();
  }
}
```

- [ ] **Step 4: Run test, expect pass**

Run: `flutter test test/unit/reddit_repository_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/data/reddit_repository.dart test/unit/reddit_repository_test.dart
git commit -m "feat: add Reddit repository with tolerant listing parse"
```

---

## Task 8: Storage — Hive boxes and secure store

**Files:**
- Create: `lib/core/storage/hive_boxes.dart`
- Create: `lib/core/storage/secure_store.dart`

- [ ] **Step 1: Write `lib/core/storage/hive_boxes.dart`**

```dart
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

class HiveBoxes {
  static const String favorites = 'favorites';
  static const String summaries = 'summaries';
  static const String topics = 'topics';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox<dynamic>(favorites),
      Hive.openBox<dynamic>(summaries),
      Hive.openBox<dynamic>(topics),
    ]);
  }
}
```

- [ ] **Step 2: Write `lib/core/storage/secure_store.dart`**

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStore {
  SecureStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  Future<String?> read(String key) => _storage.read(key: key);

  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  Future<void> delete(String key) => _storage.delete(key: key);
}
```

- [ ] **Step 3: Analyze**

Run: `flutter analyze lib/core/storage`
Expected: No issues. (If the hive_ce_flutter import path differs, use the package's documented barrel file; confirm with `flutter pub deps`.)

- [ ] **Step 4: Commit**

```bash
git add lib/core/storage
git commit -m "feat: add Hive boxes and secure store wrappers"
```

---

## Task 9: Favorites, summary-cache, topic repositories

**Files:**
- Create: `lib/data/favorites_repository.dart`
- Create: `lib/data/summary_cache_repository.dart`
- Create: `lib/data/topic_repository.dart`
- Test: `test/unit/repositories_test.dart`

- [ ] **Step 1: Write the failing test (real Hive in a temp dir)**

```dart
import 'dart:io';
import 'package:hive_ce/hive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:feeddigest/data/favorites_repository.dart';
import 'package:feeddigest/data/summary_cache_repository.dart';
import 'package:feeddigest/data/topic_repository.dart';
import 'package:feeddigest/models/ai_summary.dart';
import 'package:feeddigest/models/reddit_post.dart';
import 'package:feeddigest/models/topic.dart';

late Directory dir;

RedditPost _post(String id) => RedditPost.fromJson({'id': id, 'title': 't$id'});

void main() {
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('feeddigest_hive');
    Hive.init(dir.path);
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await dir.delete(recursive: true);
  });

  test('favorites add/contains/remove/all', () async {
    final box = await Hive.openBox<dynamic>('favorites');
    final repo = FavoritesRepository(box);
    await repo.add(_post('a'));
    expect(repo.contains('a'), true);
    expect(repo.all().length, 1);
    await repo.toggle(_post('a'));
    expect(repo.contains('a'), false);
  });

  test('summary cache get/put dedup', () async {
    final box = await Hive.openBox<dynamic>('summaries');
    final repo = SummaryCacheRepository(box);
    expect(repo.get('a'), isNull);
    await repo.put(const AiSummary(postId: 'a', summary: 'salom'));
    expect(repo.get('a')!.summary, 'salom');
  });

  test('topic repo seeds defaults then edits', () async {
    final box = await Hive.openBox<dynamic>('topics');
    final repo = TopicRepository(box);
    expect(repo.all(), isNotEmpty);
    await repo.add(const Topic(label: 'Rust', subreddit: 'rust'));
    expect(repo.all().any((t) => t.subreddit == 'rust'), true);
    await repo.remove(const Topic(label: 'Rust', subreddit: 'rust'));
    expect(repo.all().any((t) => t.subreddit == 'rust'), false);
  });
}
```

- [ ] **Step 2: Run test, expect failure**

Run: `flutter test test/unit/repositories_test.dart`
Expected: FAIL — repository files not found.

- [ ] **Step 3: Write `lib/data/favorites_repository.dart`**

```dart
import 'package:hive_ce/hive.dart';
import '../models/reddit_post.dart';

class FavoritesRepository {
  FavoritesRepository(this._box);

  final Box<dynamic> _box;

  List<RedditPost> all() => _box.values
      .map((v) => RedditPost.fromJson(Map<String, dynamic>.from(v as Map)))
      .toList();

  bool contains(String id) => _box.containsKey(id);

  Future<void> add(RedditPost post) => _box.put(post.id, post.toJson());

  Future<void> remove(String id) => _box.delete(id);

  Future<void> toggle(RedditPost post) =>
      contains(post.id) ? remove(post.id) : add(post);
}
```

- [ ] **Step 4: Write `lib/data/summary_cache_repository.dart`**

```dart
import 'package:hive_ce/hive.dart';
import '../models/ai_summary.dart';

class SummaryCacheRepository {
  SummaryCacheRepository(this._box);

  final Box<dynamic> _box;

  AiSummary? get(String postId) {
    final value = _box.get(postId);
    if (value == null) return null;
    return AiSummary.fromJson(Map<String, dynamic>.from(value as Map));
  }

  Future<void> put(AiSummary summary) =>
      _box.put(summary.postId, summary.toJson());
}
```

- [ ] **Step 5: Write `lib/data/topic_repository.dart`**

```dart
import 'package:hive_ce/hive.dart';
import '../core/config/app_config.dart';
import '../models/topic.dart';

class TopicRepository {
  TopicRepository(this._box) {
    if (_box.isEmpty) {
      for (final topic in AppConfig.defaultTopics) {
        _box.put(topic.subreddit.toLowerCase(), topic.toJson());
      }
    }
  }

  final Box<dynamic> _box;

  List<Topic> all() => _box.values
      .map((v) => Topic.fromJson(Map<String, dynamic>.from(v as Map)))
      .toList();

  Future<void> add(Topic topic) =>
      _box.put(topic.subreddit.toLowerCase(), topic.toJson());

  Future<void> remove(Topic topic) =>
      _box.delete(topic.subreddit.toLowerCase());
}
```

- [ ] **Step 6: Run test, expect pass**

Run: `flutter test test/unit/repositories_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 7: Commit**

```bash
git add lib/data/favorites_repository.dart lib/data/summary_cache_repository.dart lib/data/topic_repository.dart test/unit/repositories_test.dart
git commit -m "feat: add favorites, summary-cache, topic repositories"
```

---

## Task 10: Settings and Gemini repositories

**Files:**
- Create: `lib/data/settings_repository.dart`
- Create: `lib/data/gemini_repository.dart`
- Test: `test/unit/gemini_test.dart`

- [ ] **Step 1: Write the failing test for the response extractor**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:feeddigest/data/gemini_repository.dart';

void main() {
  test('extractText pulls the candidate text', () {
    final data = {
      'candidates': [
        {
          'content': {
            'parts': [
              {'text': '  Bu xulosa.  '}
            ]
          }
        }
      ]
    };
    expect(GeminiRepository.extractText(data), 'Bu xulosa.');
  });

  test('extractText throws on bad shape', () {
    expect(() => GeminiRepository.extractText(const {}),
        throwsA(isA<GeminiException>()));
  });
}
```

- [ ] **Step 2: Run test, expect failure**

Run: `flutter test test/unit/gemini_test.dart`
Expected: FAIL — `gemini_repository.dart` not found.

- [ ] **Step 3: Write `lib/data/settings_repository.dart`**

```dart
import '../core/storage/secure_store.dart';

class SettingsRepository {
  SettingsRepository(this._store);

  final SecureStore _store;

  static const String _geminiKey = 'gemini_api_key';

  Future<String?> getGeminiKey() => _store.read(_geminiKey);

  Future<void> setGeminiKey(String value) =>
      _store.write(_geminiKey, value);
}
```

- [ ] **Step 4: Write `lib/data/gemini_repository.dart`**

```dart
import 'package:dio/dio.dart';
import '../core/config/app_config.dart';
import '../models/reddit_post.dart';
import 'settings_repository.dart';

class GeminiException implements Exception {
  GeminiException(this.message);
  final String message;
  @override
  String toString() => 'GeminiException: $message';
}

class GeminiRepository {
  GeminiRepository(this._dio, this._settings);

  final Dio _dio;
  final SettingsRepository _settings;

  Future<String> summarize(RedditPost post) async {
    final key = await _settings.getGeminiKey();
    if (key == null || key.isEmpty) {
      throw GeminiException('Gemini API kaliti kiritilmagan');
    }
    final prompt = "Quyidagi inglizcha Reddit postini o'zbek tilida 3-4 "
        "jumlada qisqacha yoz. Faqat o'zbekcha summary qaytar. "
        "Sarlavha: ${post.title}. Matn: ${post.contentText}";
    final resp = await _dio.post<dynamic>(
      '${AppConfig.geminiEndpoint}/${AppConfig.geminiModel}:generateContent',
      options: Options(headers: {
        'x-goog-api-key': key,
        'Content-Type': 'application/json',
      }),
      data: {
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ]
      },
    );
    return extractText(resp.data);
  }

  static String extractText(dynamic data) {
    try {
      final text = data['candidates'][0]['content']['parts'][0]['text'];
      if (text is String && text.trim().isNotEmpty) return text.trim();
    } catch (_) {
      throw GeminiException("Javobni o'qib bo'lmadi");
    }
    throw GeminiException("Bo'sh javob");
  }
}
```

- [ ] **Step 5: Run test, expect pass**

Run: `flutter test test/unit/gemini_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 6: Commit**

```bash
git add lib/data/settings_repository.dart lib/data/gemini_repository.dart test/unit/gemini_test.dart
git commit -m "feat: add settings and Gemini repositories"
```

---

## Task 11: Riverpod infrastructure providers

**Files:**
- Create: `lib/core/providers.dart`

- [ ] **Step 1: Write `lib/core/providers.dart`**

```dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';

import '../data/favorites_repository.dart';
import '../data/gemini_repository.dart';
import '../data/reddit_repository.dart';
import '../data/settings_repository.dart';
import '../data/summary_cache_repository.dart';
import '../data/topic_repository.dart';
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

final topicRepositoryProvider = Provider<TopicRepository>(
    (ref) => TopicRepository(Hive.box<dynamic>(HiveBoxes.topics)));
```

- [ ] **Step 2: Analyze**

Run: `flutter analyze lib/core/providers.dart`
Expected: No issues.

- [ ] **Step 3: Commit**

```bash
git add lib/core/providers.dart
git commit -m "feat: add Riverpod infrastructure providers"
```

---

## Task 12: ViewModels

**Files:**
- Create: `lib/features/feed/viewmodel/feed_viewmodel.dart`
- Create: `lib/features/search/viewmodel/search_viewmodel.dart`
- Create: `lib/features/favorites/viewmodel/favorites_viewmodel.dart`
- Create: `lib/features/summary/viewmodel/summary_viewmodel.dart`
- Create: `lib/features/settings/viewmodel/settings_viewmodel.dart`

- [ ] **Step 1: Write `feed_viewmodel.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../models/reddit_post.dart';
import '../../../models/topic.dart';

final selectedTopicProvider =
    NotifierProvider<SelectedTopicNotifier, Topic?>(SelectedTopicNotifier.new);

class SelectedTopicNotifier extends Notifier<Topic?> {
  @override
  Topic? build() {
    final topics = ref.watch(topicRepositoryProvider).all();
    final current = stateOrNull;
    if (current != null && topics.contains(current)) return current;
    return topics.isEmpty ? null : topics.first;
  }

  void select(Topic topic) => state = topic;
}

final feedViewModelProvider =
    AsyncNotifierProvider<FeedViewModel, List<RedditPost>>(FeedViewModel.new);

class FeedViewModel extends AsyncNotifier<List<RedditPost>> {
  @override
  Future<List<RedditPost>> build() async {
    final topic = ref.watch(selectedTopicProvider);
    if (topic == null) return const [];
    return ref.watch(redditRepositoryProvider).topPosts(topic.subreddit);
  }

  Future<void> refresh() async {
    final topic = ref.read(selectedTopicProvider);
    if (topic == null) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => ref.read(redditRepositoryProvider).topPosts(topic.subreddit));
  }
}
```

Note: `stateOrNull` is available on Riverpod `Notifier`. If the installed version lacks it, replace `final current = stateOrNull;` with a nullable field cached on the notifier. Confirm during analyze.

- [ ] **Step 2: Write `search_viewmodel.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../models/reddit_post.dart';

final searchViewModelProvider =
    AsyncNotifierProvider<SearchViewModel, List<RedditPost>>(
        SearchViewModel.new);

class SearchViewModel extends AsyncNotifier<List<RedditPost>> {
  @override
  Future<List<RedditPost>> build() async => const [];

  Future<void> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      state = const AsyncData([]);
      return;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => ref.read(redditRepositoryProvider).searchPosts(trimmed));
  }

  void clear() => state = const AsyncData([]);
}
```

- [ ] **Step 3: Write `favorites_viewmodel.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../models/reddit_post.dart';

final favoritesViewModelProvider =
    NotifierProvider<FavoritesViewModel, List<RedditPost>>(
        FavoritesViewModel.new);

class FavoritesViewModel extends Notifier<List<RedditPost>> {
  @override
  List<RedditPost> build() => ref.watch(favoritesRepositoryProvider).all();

  bool isFavorite(String id) =>
      ref.read(favoritesRepositoryProvider).contains(id);

  Future<void> toggle(RedditPost post) async {
    await ref.read(favoritesRepositoryProvider).toggle(post);
    state = ref.read(favoritesRepositoryProvider).all();
  }

  Future<void> remove(String id) async {
    await ref.read(favoritesRepositoryProvider).remove(id);
    state = ref.read(favoritesRepositoryProvider).all();
  }
}
```

- [ ] **Step 4: Write `summary_viewmodel.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../models/ai_summary.dart';
import '../../../models/reddit_post.dart';

final summaryViewModelProvider = AsyncNotifierProvider.family<SummaryViewModel,
    String, RedditPost>(SummaryViewModel.new);

class SummaryViewModel extends FamilyAsyncNotifier<String, RedditPost> {
  @override
  Future<String> build(RedditPost arg) async {
    final cache = ref.read(summaryCacheRepositoryProvider);
    final cached = cache.get(arg.id);
    if (cached != null) return cached.summary;
    final text = await ref.read(geminiRepositoryProvider).summarize(arg);
    await cache.put(AiSummary(postId: arg.id, summary: text));
    return text;
  }
}
```

Note: family `AsyncNotifier` shape varies slightly across Riverpod 3.x point releases. If `FamilyAsyncNotifier` is not exported, use `AsyncNotifier<String>` with `arg` accessed via the generated provider argument per the installed version's docs. Confirm during analyze.

- [ ] **Step 5: Write `settings_viewmodel.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../models/topic.dart';

final geminiKeyPresentProvider = FutureProvider<bool>((ref) async {
  final key = await ref.watch(settingsRepositoryProvider).getGeminiKey();
  return key != null && key.isNotEmpty;
});

final topicsViewModelProvider =
    NotifierProvider<TopicsViewModel, List<Topic>>(TopicsViewModel.new);

class TopicsViewModel extends Notifier<List<Topic>> {
  @override
  List<Topic> build() => ref.watch(topicRepositoryProvider).all();

  Future<void> add(Topic topic) async {
    await ref.read(topicRepositoryProvider).add(topic);
    state = ref.read(topicRepositoryProvider).all();
    ref.invalidate(selectedTopicRefresh);
  }

  Future<void> remove(Topic topic) async {
    await ref.read(topicRepositoryProvider).remove(topic);
    state = ref.read(topicRepositoryProvider).all();
  }
}

final selectedTopicRefresh = Provider<int>((ref) => 0);

final settingsActionsProvider =
    Provider<SettingsActions>((ref) => SettingsActions(ref));

class SettingsActions {
  SettingsActions(this._ref);
  final Ref _ref;

  Future<void> saveKey(String value) async {
    await _ref.read(settingsRepositoryProvider).setGeminiKey(value.trim());
    _ref.invalidate(geminiKeyPresentProvider);
  }
}
```

- [ ] **Step 6: Analyze**

Run: `flutter analyze lib/features`
Expected: No issues (resolve any Riverpod API notes flagged above).

- [ ] **Step 7: Commit**

```bash
git add lib/features
git commit -m "feat: add feature ViewModels"
```

---

## Task 13: Theme and shared state widgets

**Files:**
- Create: `lib/core/theme/app_colors.dart`
- Create: `lib/core/theme/app_theme.dart`
- Create: `lib/core/widgets/state_views.dart`

- [ ] **Step 1: Write `lib/core/theme/app_colors.dart`**

```dart
import 'package:flutter/material.dart';

class AppColors {
  static const Color seed = Color(0xFFFF4500);
  static const Color upvote = Color(0xFFFF4500);
  static const Color surfaceDark = Color(0xFF121212);
}
```

- [ ] **Step 2: Write `lib/core/theme/app_theme.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      brightness: brightness,
    );
    final base = ThemeData(colorScheme: scheme, useMaterial3: true);
    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme),
      appBarTheme: const AppBarTheme(centerTitle: false),
    );
  }
}
```

- [ ] **Step 3: Write `lib/core/widgets/state_views.dart`**

```dart
import 'package:flutter/material.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              FilledButton(onPressed: onRetry, child: const Text('Qayta urinish')),
            ],
          ],
        ),
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  const EmptyView({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}
```

- [ ] **Step 4: Analyze + commit**

Run: `flutter analyze lib/core/theme lib/core/widgets`
Expected: No issues.
```bash
git add lib/core/theme lib/core/widgets
git commit -m "feat: add theme and shared state views"
```

---

## Task 14: Feed widgets (post image, skeleton, card, topic bar)

**Files:**
- Create: `lib/features/feed/view/widgets/post_image.dart`
- Create: `lib/features/feed/view/widgets/post_skeleton.dart`
- Create: `lib/features/feed/view/widgets/topic_bar.dart`
- Create: `lib/features/feed/view/widgets/post_card.dart`

- [ ] **Step 1: Write `post_image.dart`**

```dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../models/reddit_post.dart';

class PostImage extends StatelessWidget {
  const PostImage({super.key, required this.post});

  final RedditPost post;

  @override
  Widget build(BuildContext context) {
    if (!post.hasThumbnail) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: post.thumbnail,
        width: 72,
        height: 72,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => const SizedBox.shrink(),
      ),
    );
  }
}
```

- [ ] **Step 2: Write `post_skeleton.dart`**

```dart
import 'package:flutter/material.dart';

class PostSkeleton extends StatelessWidget {
  const PostSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return ListView.builder(
      itemCount: 6,
      padding: const EdgeInsets.all(12),
      itemBuilder: (_, __) => Container(
        height: 96,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Write `topic_bar.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/topic.dart';
import '../../viewmodel/feed_viewmodel.dart';
import '../../../settings/viewmodel/settings_viewmodel.dart';

class TopicBar extends ConsumerWidget {
  const TopicBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topics = ref.watch(topicsViewModelProvider);
    final selected = ref.watch(selectedTopicProvider);
    if (topics.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: topics.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final Topic topic = topics[index];
          return ChoiceChip(
            label: Text(topic.label),
            selected: topic == selected,
            onSelected: (_) =>
                ref.read(selectedTopicProvider.notifier).select(topic),
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 4: Write `post_card.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../models/reddit_post.dart';
import '../../../favorites/viewmodel/favorites_viewmodel.dart';
import '../../../summary/view/summary_sheet.dart';
import 'post_image.dart';

class PostCard extends ConsumerWidget {
  const PostCard({super.key, required this.post});

  final RedditPost post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(favoritesViewModelProvider);
    final isFav = ref.read(favoritesViewModelProvider.notifier).isFavorite(post.id);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${post.subredditNamePrefixed} · u/${post.author} · ${Formatters.timeAgo(post.createdUtc)}',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    post.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(width: 8),
                PostImage(post: post),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.arrow_upward, size: 16),
                const SizedBox(width: 4),
                Text(Formatters.compactScore(post.score)),
                const SizedBox(width: 16),
                const Icon(Icons.mode_comment_outlined, size: 16),
                const SizedBox(width: 4),
                Text(Formatters.compactScore(post.numComments)),
                const Spacer(),
                IconButton(
                  icon: Icon(isFav ? Icons.favorite : Icons.favorite_border),
                  onPressed: () =>
                      ref.read(favoritesViewModelProvider.notifier).toggle(post),
                ),
                IconButton(
                  icon: const Icon(Icons.auto_awesome),
                  tooltip: 'Xulosa',
                  onPressed: () => showSummarySheet(context, post),
                ),
                IconButton(
                  icon: const Icon(Icons.open_in_new),
                  onPressed: () => launchUrl(
                    Uri.parse(post.fullPermalink),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Analyze**

Run: `flutter analyze lib/features/feed/view/widgets`
Expected: only an unresolved reference to `summary_sheet.dart`/`showSummarySheet` until Task 16. Proceed.

- [ ] **Step 6: Commit**

```bash
git add lib/features/feed/view/widgets
git commit -m "feat: add feed widgets"
```

---

## Task 15: Feed, Search, Favorites screens

**Files:**
- Create: `lib/features/feed/view/feed_screen.dart`
- Create: `lib/features/search/view/search_screen.dart`
- Create: `lib/features/favorites/view/favorites_screen.dart`

- [ ] **Step 1: Write `feed_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/state_views.dart';
import '../viewmodel/feed_viewmodel.dart';
import 'widgets/post_card.dart';
import 'widgets/post_skeleton.dart';
import 'widgets/topic_bar.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(feedViewModelProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Feed')),
      body: Column(
        children: [
          const TopicBar(),
          Expanded(
            child: feed.when(
              loading: () => const PostSkeleton(),
              error: (e, _) => ErrorView(
                message: '$e',
                onRetry: () =>
                    ref.read(feedViewModelProvider.notifier).refresh(),
              ),
              data: (posts) {
                if (posts.isEmpty) {
                  return const EmptyView(message: 'Hech narsa topilmadi');
                }
                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(feedViewModelProvider.notifier).refresh(),
                  child: ListView.builder(
                    itemCount: posts.length,
                    itemBuilder: (_, i) => PostCard(post: posts[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Write `search_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/state_views.dart';
import '../../feed/view/widgets/post_card.dart';
import '../viewmodel/search_viewmodel.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(searchViewModelProvider);
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: 'Reddit qidirish...',
            border: InputBorder.none,
          ),
          onSubmitted: (q) =>
              ref.read(searchViewModelProvider.notifier).search(q),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _controller.clear();
              ref.read(searchViewModelProvider.notifier).clear();
            },
          ),
        ],
      ),
      body: results.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(message: '$e'),
        data: (posts) {
          if (posts.isEmpty) {
            return const EmptyView(message: 'Qidiruv natijasi yo\'q');
          }
          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (_, i) => PostCard(post: posts[i]),
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 3: Write `favorites_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/state_views.dart';
import '../../feed/view/widgets/post_card.dart';
import '../viewmodel/favorites_viewmodel.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesViewModelProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Saqlanganlar')),
      body: favorites.isEmpty
          ? const EmptyView(message: 'Hali saqlangan post yo\'q')
          : ListView.builder(
              itemCount: favorites.length,
              itemBuilder: (_, i) => PostCard(post: favorites[i]),
            ),
    );
  }
}
```

- [ ] **Step 4: Analyze + commit**

Run: `flutter analyze lib/features/feed/view/feed_screen.dart lib/features/search lib/features/favorites`
Expected: only unresolved `summary_sheet` until Task 16.
```bash
git add lib/features/feed/view/feed_screen.dart lib/features/search lib/features/favorites
git commit -m "feat: add feed, search, favorites screens"
```

---

## Task 16: Summary sheet

**Files:**
- Create: `lib/features/summary/view/summary_sheet.dart`

- [ ] **Step 1: Write `summary_sheet.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/state_views.dart';
import '../../../models/reddit_post.dart';
import '../viewmodel/summary_viewmodel.dart';

Future<void> showSummarySheet(BuildContext context, RedditPost post) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => SummarySheet(post: post),
  );
}

class SummarySheet extends ConsumerWidget {
  const SummarySheet({super.key, required this.post});

  final RedditPost post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(summaryViewModelProvider(post));
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(post.title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          summary.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: LoadingView(),
            ),
            error: (e, _) => ErrorView(
              message: '$e',
              onRetry: () => ref.invalidate(summaryViewModelProvider(post)),
            ),
            data: (text) => Text(
              text,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Analyze**

Run: `flutter analyze lib/features/summary lib/features/feed`
Expected: No issues (the earlier unresolved `showSummarySheet` now resolves).

- [ ] **Step 3: Commit**

```bash
git add lib/features/summary/view/summary_sheet.dart
git commit -m "feat: add summary sheet"
```

---

## Task 17: Settings screen and topic editor

**Files:**
- Create: `lib/features/settings/view/topic_editor_sheet.dart`
- Create: `lib/features/settings/view/settings_screen.dart`

- [ ] **Step 1: Write `topic_editor_sheet.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/topic.dart';
import '../viewmodel/settings_viewmodel.dart';

Future<void> showTopicEditor(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const TopicEditorSheet(),
  );
}

class TopicEditorSheet extends ConsumerStatefulWidget {
  const TopicEditorSheet({super.key});

  @override
  ConsumerState<TopicEditorSheet> createState() => _TopicEditorSheetState();
}

class _TopicEditorSheetState extends ConsumerState<TopicEditorSheet> {
  final _label = TextEditingController();
  final _subreddit = TextEditingController();

  @override
  void dispose() {
    _label.dispose();
    _subreddit.dispose();
    super.dispose();
  }

  void _add() {
    final label = _label.text.trim();
    final sub = _subreddit.text.trim();
    if (sub.isEmpty) return;
    ref.read(topicsViewModelProvider.notifier).add(
          Topic(label: label.isEmpty ? sub : label, subreddit: sub),
        );
    _label.clear();
    _subreddit.clear();
  }

  @override
  Widget build(BuildContext context) {
    final topics = ref.watch(topicsViewModelProvider);
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mavzular', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          TextField(
            controller: _label,
            decoration: const InputDecoration(labelText: 'Nom (ixtiyoriy)'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _subreddit,
            decoration: const InputDecoration(
              labelText: 'Subreddit',
              prefixText: 'r/',
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(onPressed: _add, child: const Text("Qo'shish")),
          ),
          const Divider(),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final topic in topics)
                  ListTile(
                    title: Text(topic.label),
                    subtitle: Text(topic.displayName),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => ref
                          .read(topicsViewModelProvider.notifier)
                          .remove(topic),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Write `settings_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodel/settings_viewmodel.dart';
import 'topic_editor_sheet.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _key = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _key.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await ref.read(settingsActionsProvider).saveKey(_key.text);
    if (!mounted) return;
    _key.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Kalit saqlandi')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyPresent = ref.watch(geminiKeyPresentProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Sozlamalar')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Gemini API kaliti',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          keyPresent.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (present) => Text(
              present ? 'Kalit kiritilgan' : 'Kalit kiritilmagan',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _key,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: 'API kalit',
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(onPressed: _save, child: const Text('Saqlash')),
          const Divider(height: 32),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Mavzularni boshqarish'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showTopicEditor(context),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Analyze + commit**

Run: `flutter analyze lib/features/settings`
Expected: No issues.
```bash
git add lib/features/settings/view
git commit -m "feat: add settings screen and topic editor"
```

---

## Task 18: Shell, app, main

**Files:**
- Create: `lib/features/shell/view/home_shell.dart`
- Create: `lib/app.dart`
- Create: `lib/main.dart`

- [ ] **Step 1: Write `home_shell.dart`**

```dart
import 'package:flutter/material.dart';
import '../../favorites/view/favorites_screen.dart';
import '../../feed/view/feed_screen.dart';
import '../../search/view/search_screen.dart';
import '../../settings/view/settings_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _screens = [
    FeedScreen(),
    SearchScreen(),
    FavoritesScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Feed'),
          NavigationDestination(
              icon: Icon(Icons.search), label: 'Qidiruv'),
          NavigationDestination(
              icon: Icon(Icons.favorite_border), label: 'Saqlangan'),
          NavigationDestination(
              icon: Icon(Icons.settings_outlined), label: 'Sozlama'),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Write `lib/app.dart`**

```dart
import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/shell/view/home_shell.dart';

class FeedDigestApp extends StatelessWidget {
  const FeedDigestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FeedDigest',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const HomeShell(),
    );
  }
}
```

- [ ] **Step 3: Write `lib/main.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/storage/hive_boxes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveBoxes.init();
  runApp(const ProviderScope(child: FeedDigestApp()));
}
```

- [ ] **Step 4: Analyze the whole project**

Run: `flutter analyze`
Expected: No issues. Fix any Riverpod API mismatches flagged in Task 12 notes here.

- [ ] **Step 5: Commit**

```bash
git add lib/features/shell lib/app.dart lib/main.dart
git commit -m "feat: add shell, app root, and bootstrap"
```

---

## Task 19: Smoke widget test and full verification

**Files:**
- Create: `test/widget_test.dart`

- [ ] **Step 1: Write a boot smoke test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:feeddigest/features/feed/view/feed_screen.dart';

void main() {
  testWidgets('feed screen renders an app bar', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: FeedScreen()),
      ),
    );
    await tester.pump();
    expect(find.text('Feed'), findsOneWidget);
  });
}
```

Note: `FeedScreen` reads `feedViewModelProvider`, which depends on `topicRepositoryProvider` → `Hive.box(...)`. In the test, that box is not open, so the provider will surface an error state rather than crash the pump; the app-bar assertion still holds. If the box access throws during build, override `topicRepositoryProvider` in the test `ProviderScope` with a fake returning `[]`. Keep the test green.

- [ ] **Step 2: Run the full suite**

Run: `flutter test`
Expected: PASS — all unit tests plus the smoke test.

- [ ] **Step 3: Final analyze**

Run: `flutter analyze`
Expected: No issues.

- [ ] **Step 4: Confirm no comments in Dart sources**

Run: `! grep -rEn '(^|[^:])//|/\*' lib --include='*.dart'`
Expected: command succeeds (exit 0) meaning no `//` or `/*` comment markers found. If any line matches, remove the comment. (URLs like `https://` contain `//`; this command excludes the `://` case by requiring a non-colon char before `//`. Manually verify any remaining hits are real comments.)

- [ ] **Step 5: Commit**

```bash
git add test/widget_test.dart
git commit -m "test: add boot smoke test"
```

---

## Task 20: Run the app

- [ ] **Step 1: Launch on a device/emulator**

Run: `flutter run`
Expected: App boots to the Feed tab with the topic bar; switching tabs works; entering a Gemini key in Settings then tapping the summarize icon on a post produces an Uzbek summary; the heart toggles favorites; favorites persist across restart.

- [ ] **Step 2: Final commit if any tweaks were needed**

```bash
git add -A
git commit -m "chore: finalize MVVM scraping rebuild"
```

---

## Self-Review Notes (author)

- **Spec coverage:** scraping (Task 6-7), Gemini BYOK (Task 10), Hive 2-box + dedup (Task 8-9, summary VM Task 12), lean models (Task 2-4), multi-topic feed (Task 12, 14-15), on-demand summary (Task 16), 4-tab nav (Task 18), no-comments rule (Task 19 Step 4). All covered.
- **Riverpod API caveats:** `stateOrNull` (Task 12 Step 1) and `FamilyAsyncNotifier` (Task 12 Step 4) flagged for version confirmation during analyze — these are the only version-sensitive spots.
- **Type consistency:** provider names (`feedViewModelProvider`, `searchViewModelProvider`, `favoritesViewModelProvider`, `summaryViewModelProvider`, `topicsViewModelProvider`, `selectedTopicProvider`, `settingsActionsProvider`, `geminiKeyPresentProvider`) are used identically across viewmodels and views. Repository provider names match `core/providers.dart`.
- **Hive read rule:** every box read uses `Map<String,dynamic>.from(...)` (Tasks 9). Two separate boxes confirmed (Task 8).
```
