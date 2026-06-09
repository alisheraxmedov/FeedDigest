import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/reddit_post.dart';
import 'feed_providers.dart';

/// Local, optimistic vote overrides keyed by post id. The override is the new
/// direction (1 up / -1 down / 0 none); absence means "use the post's own
/// server value".
final votesProvider =
    NotifierProvider<VotesController, Map<String, int>>(VotesController.new);

class VotesController extends Notifier<Map<String, int>> {
  @override
  Map<String, int> build() => const {};

  /// Toggles a vote optimistically and reverts on failure.
  Future<void> vote(RedditPost post, int dir) async {
    final currentDir = state[post.id] ?? post.voteDirection;
    final newDir = currentDir == dir ? 0 : dir; // tapping the active arrow clears
    final previous = state[post.id];

    state = {...state, post.id: newDir};
    try {
      await ref
          .read(redditRepositoryProvider)
          .vote(fullname: post.fullname, dir: newDir);
    } catch (_) {
      // Revert to the prior override (or remove it entirely).
      final reverted = {...state};
      if (previous == null) {
        reverted.remove(post.id);
      } else {
        reverted[post.id] = previous;
      }
      state = reverted;
      rethrow;
    }
  }
}

/// Effective vote direction + score for a post, applying any local override.
@immutable
class VoteView {
  const VoteView({required this.direction, required this.score});

  final int direction;
  final int score;

  bool get isUp => direction == 1;
  bool get isDown => direction == -1;
}

VoteView voteViewFor(RedditPost post, Map<String, int> overrides) {
  final dir = overrides[post.id] ?? post.voteDirection;
  // Adjust the base score by the delta between the server vote and the current.
  final score = post.score - post.voteDirection + dir;
  return VoteView(direction: dir, score: score);
}
