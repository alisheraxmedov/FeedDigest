import '../../../core/config/app_config.dart';
import 'models/reddit_comment.dart';
import 'models/reddit_page.dart';
import 'models/reddit_post.dart';
import 'models/subreddit.dart';
import 'reddit_repository.dart';

/// In-memory Reddit source used when no credentials are configured.
///
/// Produces realistic, varied sample posts (self + link + image types) so the
/// entire UI — feed, search, pagination, AI summary — is fully demoable before
/// any API keys are added to `.env`.
class MockRedditRepository implements RedditRepository {
  const MockRedditRepository();

  @override
  Future<RedditPage> fetchFeed({
    required String subreddit,
    required FeedSort sort,
    String? after,
  }) async {
    await _simulateLatency();
    final isFirstPage = after == null;
    final posts = _generate(subreddit, page: isFirstPage ? 0 : 1);
    return RedditPage(
      posts: posts,
      // Offer exactly one extra page so infinite-scroll is demonstrable.
      after: isFirstPage ? '${subreddit}_p2' : null,
    );
  }

  @override
  Future<RedditPage> search({
    required String query,
    String? subreddit,
    String? after,
  }) async {
    await _simulateLatency();
    final base = _generate(subreddit ?? 'all', page: 0);
    final q = query.toLowerCase();
    final matches = base
        .map((p) => p.copyWithTitle('${p.title} — $query'))
        .where((p) => p.title.toLowerCase().contains(q) || q.isNotEmpty)
        .toList();
    return RedditPage(posts: matches.take(8).toList(), after: null);
  }

  @override
  Future<List<RedditComment>> fetchComments({
    required String subreddit,
    required String postId,
    int limit = 12,
  }) async {
    await _simulateLatency();
    return List.generate(_mockComments.length, (i) {
      final c = _mockComments[i];
      return RedditComment(
        id: '${postId}_c$i',
        author: c.$1,
        body: c.$2,
        score: c.$3,
        createdUtc: DateTime.now()
                .subtract(Duration(hours: i + 1))
                .millisecondsSinceEpoch ~/
            1000,
        isSubmitter: i == 0,
      );
    });
  }

  @override
  Future<RedditPage> fetchHomeFeed({
    required FeedSort sort,
    String? after,
  }) =>
      fetchFeed(subreddit: 'popular', sort: sort, after: after);

  @override
  Future<List<Subreddit>> fetchMySubreddits() async {
    await _simulateLatency();
    return const [
      Subreddit(
          name: 'FlutterDev',
          title: 'Flutter Development',
          subscribers: 220000,
          iconUrl: ''),
      Subreddit(
          name: 'programming',
          title: 'Programming',
          subscribers: 6400000,
          iconUrl: ''),
      Subreddit(
          name: 'androiddev',
          title: 'Android Dev',
          subscribers: 280000,
          iconUrl: ''),
    ];
  }

  @override
  Future<void> setSubscribed({
    required String subreddit,
    required bool subscribe,
  }) async {
    await _simulateLatency();
  }

  @override
  Future<void> vote({required String fullname, required int dir}) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }

  Future<void> _simulateLatency() =>
      Future<void>.delayed(const Duration(milliseconds: 650));

  /// (author, body, score) tuples for synthesised comments.
  static const List<(String, String, int)> _mockComments = [
    (
      'op_author',
      'Qo‘shimcha: men buni real loyihada sinab ko‘rdim va natija ajoyib '
          'bo‘ldi. Savollaringiz bo‘lsa, yozing!',
      842
    ),
    (
      'senior_dev',
      'Yaxshi yondashuv, lekin katta jamoalarda dependency injection ni '
          'unutmaslik kerak. Aks holda test yozish qiyinlashadi.',
      516
    ),
    (
      'curious_learner',
      'Bu menga juda foydali bo‘ldi, rahmat! Boshlovchilar uchun ajoyib '
          'tushuntirish.',
      298
    ),
    (
      'skeptic_42',
      'Men rozi emasman — bu yondashuv kichik loyihalar uchun ortiqcha '
          'murakkablik qo‘shadi. Oddiyroq yechim ham bor.',
      174
    ),
    (
      'helpful_guy',
      'Hujjatlarga havola qoldiraman, u yerda bularning hammasi batafsil '
          'yozilgan.',
      95
    ),
  ];

  List<RedditPost> _generate(String subreddit, {required int page}) {
    final offset = page * _templates.length;
    return List.generate(_templates.length, (i) {
      final t = _templates[i];
      final index = offset + i;
      return RedditPost(
        id: '${subreddit}_$index',
        title: t.title,
        selftext: t.body,
        author: t.author,
        subreddit: subreddit,
        permalink: '/r/$subreddit/comments/${subreddit}_$index/',
        url: t.image.isNotEmpty ? t.image : 'https://www.reddit.com',
        imageUrl: t.image,
        thumbnailUrl: t.image,
        score: t.score - index * 37,
        numComments: t.comments - index * 5,
        // Each post a few hours older than the previous one.
        createdUtc: DateTime.now()
                .subtract(Duration(hours: index * 5 + 1))
                .millisecondsSinceEpoch ~/
            1000,
        domain: t.image.isNotEmpty ? 'i.redd.it' : 'self.$subreddit',
        isSelf: t.image.isEmpty,
        isVideo: false,
        over18: false,
      );
    });
  }

  static const List<_Template> _templates = [
    _Template(
      title: 'State management 2026-yilda: qaysi yondashuv eng yaxshi?',
      body:
          'Jamoamiz katta loyihada Riverpod va Bloc ni solishtirdik. '
          'Tajribalaringiz qanday? Qaysi biri ko‘proq mos keldi?',
      author: 'dev_aziz',
      image: '',
      score: 1240,
      comments: 318,
    ),
    _Template(
      title: 'Yangi reliz: ajoyib performance yaxshilanishlari bilan',
      body: '',
      author: 'release_bot',
      image: 'https://picsum.photos/seed/flutter1/800/450',
      score: 3580,
      comments: 642,
    ),
    _Template(
      title: 'Clean Architecture haqida amaliy qo‘llanma (3-qism)',
      body:
          'Bu maqolada feature-first papka strukturasi, repository pattern va '
          'dependency injection ni real misollar bilan ko‘rib chiqamiz.',
      author: 'arch_master',
      image: 'https://picsum.photos/seed/arch2/800/500',
      score: 920,
      comments: 144,
    ),
    _Template(
      title: 'Men 6 oyda mobil dasturchi bo‘ldim — yo‘l xaritam',
      body:
          'Noldan boshlab qanday o‘rganganim, qaysi resurslardan foydalanganim '
          'va eng katta xatolarim haqida.',
      author: 'newbie_grows',
      image: '',
      score: 5210,
      comments: 870,
    ),
    _Template(
      title: 'Bu UI ni qanday qilib chiroyliroq qilsam bo‘ladi?',
      body: '',
      author: 'design_curious',
      image: 'https://picsum.photos/seed/ui3/800/600',
      score: 410,
      comments: 96,
    ),
    _Template(
      title: 'AI yordamida kod yozish: foydami yoki zararmi?',
      body:
          'So‘nggi paytlarda AI yordamchilaridan ko‘p foydalanyapman. '
          'Mahsuldorlik oshdi, lekin ba’zida xatoliklarni sezmay qolaman.',
      author: 'thoughtful_dev',
      image: '',
      score: 1880,
      comments: 503,
    ),
  ];
}

/// Lightweight template used to synthesise mock posts.
class _Template {
  const _Template({
    required this.title,
    required this.body,
    required this.author,
    required this.image,
    required this.score,
    required this.comments,
  });

  final String title;
  final String body;
  final String author;
  final String image;
  final int score;
  final int comments;
}

extension on RedditPost {
  RedditPost copyWithTitle(String title) => RedditPost(
        id: id,
        title: title,
        selftext: selftext,
        author: author,
        subreddit: subreddit,
        permalink: permalink,
        url: url,
        imageUrl: imageUrl,
        thumbnailUrl: thumbnailUrl,
        score: score,
        numComments: numComments,
        createdUtc: createdUtc,
        domain: domain,
        isSelf: isSelf,
        isVideo: isVideo,
        over18: over18,
      );
}
