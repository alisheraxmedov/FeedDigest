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
