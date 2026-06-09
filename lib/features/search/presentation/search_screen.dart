import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/state_views.dart';
import '../../feed/data/models/reddit_post.dart';
import '../../feed/presentation/widgets/post_card.dart';
import '../application/search_providers.dart';

/// Search screen with debounced input over Reddit submissions.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      ref.read(searchQueryProvider.notifier).set(value);
    });
  }

  void _clear() {
    _controller.clear();
    _debounce?.cancel();
    ref.read(searchQueryProvider.notifier).clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final results = ref.watch(searchResultsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Qidiruv'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _controller,
              autofocus: false,
              textInputAction: TextInputAction.search,
              onChanged: (v) {
                setState(() {}); // refresh suffix icon
                _onChanged(v);
              },
              decoration: InputDecoration(
                hintText: 'Maqola yoki mavzu qidiring…',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _controller.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: _clear,
                      ),
              ),
            ),
          ),
        ),
      ),
      body: _buildBody(query, results),
    );
  }

  Widget _buildBody(String query, AsyncValue<List<RedditPost>> results) {
    if (query.trim().isEmpty) {
      return const AppEmptyView(
        icon: Icons.search_rounded,
        title: 'Nimani qidiramiz?',
        message: 'Reddit bo‘ylab maqolalarni qidirish uchun '
            'yuqoridagi maydonga yozing.',
      );
    }

    return results.when(
      loading: () => const AppLoadingView(label: 'Qidirilmoqda…'),
      error: (error, _) => AppErrorView(
        message: _messageFor(error),
        onRetry: () => ref.invalidate(searchResultsProvider),
      ),
      data: (items) {
        if (items.isEmpty) {
          return AppEmptyView(
            icon: Icons.sentiment_dissatisfied_rounded,
            title: 'Hech narsa topilmadi',
            message: '"$query" bo‘yicha natija yo‘q. Boshqa so‘z bilan urinib '
                'ko‘ring.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) => PostCard(post: items[index]),
        );
      },
    );
  }

  String _messageFor(Object error) {
    final msg = error.toString();
    final idx = msg.indexOf(': ');
    return idx >= 0 ? msg.substring(idx + 2) : msg;
  }
}
