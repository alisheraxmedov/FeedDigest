import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:feeddigest/app.dart';
import 'package:feeddigest/core/config/app_config.dart';
import 'package:feeddigest/features/auth/application/auth_providers.dart';
import 'package:feeddigest/features/auth/data/auth_token_store.dart';
import 'package:feeddigest/features/feed/application/feed_providers.dart';
import 'package:feeddigest/features/feed/data/models/reddit_comment.dart';
import 'package:feeddigest/features/feed/data/models/reddit_page.dart';
import 'package:feeddigest/features/feed/data/models/reddit_post.dart';
import 'package:feeddigest/features/feed/data/models/subreddit.dart';
import 'package:feeddigest/features/feed/data/reddit_repository.dart';
import 'package:feeddigest/features/settings/application/settings_providers.dart';

/// Deterministic repository: no delay, no network images — keeps widget tests
/// free of pending timers and real HTTP.
class _FakeRepo implements RedditRepository {
  @override
  Future<RedditPage> fetchFeed({
    required String subreddit,
    required FeedSort sort,
    String? after,
  }) async =>
      RedditPage(posts: [_post(subreddit)], after: null);

  @override
  Future<RedditPage> search({
    required String query,
    String? subreddit,
    String? after,
  }) async =>
      const RedditPage(posts: []);

  @override
  Future<List<RedditComment>> fetchComments({
    required String subreddit,
    required String postId,
    int limit = 12,
  }) async =>
      const [];

  @override
  Future<RedditPage> fetchHomeFeed({
    required FeedSort sort,
    String? after,
  }) async =>
      RedditPage(posts: [_post('home')], after: null);

  @override
  Future<List<Subreddit>> fetchMySubreddits() async => const [];

  @override
  Future<void> setSubscribed({
    required String subreddit,
    required bool subscribe,
  }) async {}

  @override
  Future<void> vote({required String fullname, required int dir}) async {}

  RedditPost _post(String subreddit) => _buildPost(subreddit);
}

/// Avoids touching the platform secure-storage channel in tests.
class _FakeTokenStore extends AuthTokenStore {
  @override
  Future<String?> readRefreshToken() async => null;
  @override
  Future<String?> readUsername() async => null;
  @override
  Future<void> save({
    required String refreshToken,
    required String username,
  }) async {}
  @override
  Future<void> clear() async {}
}

RedditPost _buildPost(String subreddit) => RedditPost(
        id: 'p1',
        title: 'Test post in $subreddit',
        selftext: 'Body',
        author: 'tester',
        subreddit: subreddit,
        permalink: '/r/$subreddit/comments/p1/',
        url: 'https://reddit.com',
        imageUrl: '',
        thumbnailUrl: '',
        score: 10,
        numComments: 2,
        createdUtc: 1700000000,
        domain: 'self.$subreddit',
        isSelf: true,
        isVideo: false,
        over18: false,
      );

Future<void> _pumpApp(WidgetTester tester, {bool loggedIn = false}) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        redditRepositoryProvider.overrideWithValue(_FakeRepo()),
        authTokenStoreProvider.overrideWithValue(_FakeTokenStore()),
        if (loggedIn) isLoggedInProvider.overrideWithValue(true),
      ],
      child: const FeedDigestApp(),
    ),
  );
  await tester.pump(); // resolve the auth restore (cold-start gate)
  await tester.pump(); // resolve the fake feed / subscriptions futures
}

void main() {
  testWidgets('boots: brand, topic tabs and a post render', (tester) async {
    await _pumpApp(tester);

    expect(find.text(AppConfig.appName), findsOneWidget);
    expect(find.textContaining('Flutter'), findsWidgets); // a topic tab
    expect(find.textContaining('Test post'), findsWidgets); // a loaded card
  });

  testWidgets('AI summary sheet shows both sections (mock)', (tester) async {
    await _pumpApp(tester);

    // Tap the card's AI summary button (gradient, auto_awesome icon).
    await tester.tap(find.byIcon(Icons.auto_awesome_rounded).first);
    await tester.pump(); // open the sheet (loading)
    await tester.pump(const Duration(seconds: 1)); // mock AI delay resolves

    expect(find.text('Post xulosasi'), findsOneWidget);
    expect(find.text('Izohlar xulosasi'), findsOneWidget);
  });

  testWidgets('tapping a card opens the detail screen', (tester) async {
    await _pumpApp(tester);

    await tester.tap(find.textContaining('Test post').first);
    await tester.pump(); // start route transition
    await tester.pump(const Duration(milliseconds: 400)); // settle transition

    // Detail screen renders its comments header.
    expect(find.text('Izohlar'), findsOneWidget);
  });

  testWidgets('logged-in: home tab renders and optimistic upvote 10→11',
      (tester) async {
    await _pumpApp(tester, loggedIn: true);
    await tester.pump(); // resolve home feed + subscriptions

    expect(find.text('Bosh sahifa'), findsOneWidget);
    expect(find.text('10'), findsWidgets); // base score on the card

    // Upvote the first post; optimistic state should bump the score.
    await tester.tap(find.byIcon(Icons.arrow_upward_rounded).first);
    await tester.pump();

    expect(find.text('11'), findsWidgets);
  });
}
