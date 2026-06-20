import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/state_views.dart';
import '../../feed/view/widgets/post_card.dart';
import '../viewmodel/search_viewmodel.dart';
import '../viewmodel/subreddit_search_viewmodel.dart';
import 'subreddit_tile.dart';

enum _SearchMode { posts, communities }

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  _SearchMode _mode = _SearchMode.posts;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit(String query) {
    if (_mode == _SearchMode.posts) {
      ref.read(searchViewModelProvider.notifier).search(query);
    } else {
      ref.read(subredditSearchViewModelProvider.notifier).search(query);
    }
  }

  void _clear() {
    _controller.clear();
    ref.read(searchViewModelProvider.notifier).clear();
    ref.read(subredditSearchViewModelProvider.notifier).clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: 'Reddit qidirish...',
            border: InputBorder.none,
          ),
          onSubmitted: _submit,
        ),
        actions: [
          IconButton(icon: const Icon(Icons.clear), onPressed: _clear),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SegmentedButton<_SearchMode>(
              segments: const [
                ButtonSegment(
                    value: _SearchMode.posts, label: Text('Postlar')),
                ButtonSegment(
                    value: _SearchMode.communities,
                    label: Text('Hamjamiyatlar')),
              ],
              selected: {_mode},
              onSelectionChanged: (s) => setState(() => _mode = s.first),
            ),
          ),
          Expanded(
            child: _mode == _SearchMode.posts
                ? _PostsResults()
                : _CommunitiesResults(),
          ),
        ],
      ),
    );
  }
}

class _PostsResults extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(searchViewModelProvider);
    return results.when(
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(message: '$e'),
      data: (posts) {
        if (posts.isEmpty) {
          return const EmptyView(message: "Qidiruv natijasi yo'q");
        }
        return ListView.builder(
          itemCount: posts.length,
          itemBuilder: (_, i) => PostCard(post: posts[i]),
        );
      },
    );
  }
}

class _CommunitiesResults extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(subredditSearchViewModelProvider);
    return results.when(
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(message: '$e'),
      data: (subreddits) {
        if (subreddits.isEmpty) {
          return const EmptyView(message: "Hamjamiyat topilmadi");
        }
        return ListView.builder(
          itemCount: subreddits.length,
          itemBuilder: (_, i) => SubredditTile(subreddit: subreddits[i]),
        );
      },
    );
  }
}
