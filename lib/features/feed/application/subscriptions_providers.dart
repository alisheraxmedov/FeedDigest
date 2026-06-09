import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../data/models/subreddit.dart';
import 'feed_providers.dart';

/// The logged-in user's subscribed subreddits (empty when logged out).
final subscriptionsProvider =
    FutureProvider.autoDispose<List<Subreddit>>((ref) async {
  if (!ref.watch(isLoggedInProvider)) return const [];
  final repo = ref.watch(redditRepositoryProvider);
  return repo.fetchMySubreddits();
});

/// Fast membership lookup of subscribed subreddit names (lower-cased).
final subscribedNamesProvider = Provider.autoDispose<Set<String>>((ref) {
  final subs = ref.watch(subscriptionsProvider).value ?? const [];
  return subs.map((s) => s.name.toLowerCase()).toSet();
});
