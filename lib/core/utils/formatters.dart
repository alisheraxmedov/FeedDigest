class Formatters {
  static final _htmlTags = RegExp(r'<[^>]+>');
  static final _whitespace = RegExp(r'\s+');

  static String plainSnippet(String body) =>
      body.replaceAll(_htmlTags, ' ').replaceAll(_whitespace, ' ').trim();

  static String compactScore(int score) {
    if (score >= 1000000) return '${(score / 1000000).toStringAsFixed(1)}M';
    if (score >= 1000) return '${(score / 1000).toStringAsFixed(1)}k';
    return '$score';
  }

  static String timeAgo(
    DateTime created, {
    DateTime? now,
    String nowLabel = 'hozir',
  }) {
    final diff = (now ?? DateTime.now()).difference(created);
    if (diff.inDays >= 7) return '${diff.inDays ~/ 7}w';
    if (diff.inDays >= 1) return '${diff.inDays}d';
    if (diff.inHours >= 1) return '${diff.inHours}h';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}m';
    return nowLabel;
  }

  static int readingMinutes(String text) {
    final words = text.trim().split(_whitespace).where((w) => w.isNotEmpty);
    final minutes = (words.length / 200).ceil();
    return minutes < 1 ? 1 : minutes;
  }
}
