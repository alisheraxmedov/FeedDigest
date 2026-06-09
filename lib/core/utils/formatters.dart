/// Small pure formatting helpers used across the UI.
class Formatters {
  const Formatters._();

  /// Compacts large counts: 1234 -> "1.2k", 1500000 -> "1.5m".
  static String compactNumber(int value) {
    if (value < 1000) return '$value';
    if (value < 1000000) {
      final k = value / 1000;
      return '${_trim(k)}k';
    }
    final m = value / 1000000;
    return '${_trim(m)}m';
  }

  static String _trim(double v) {
    // One decimal, but drop a trailing ".0" (1.0k -> 1k).
    final s = v.toStringAsFixed(1);
    return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
  }

  /// Relative time from a Unix timestamp (seconds) in short Uzbek units.
  static String timeAgo(int epochSeconds) {
    final created =
        DateTime.fromMillisecondsSinceEpoch(epochSeconds * 1000, isUtc: true);
    final diff = DateTime.now().toUtc().difference(created);

    if (diff.inSeconds < 60) return 'hozir';
    if (diff.inMinutes < 60) return '${diff.inMinutes} daq';
    if (diff.inHours < 24) return '${diff.inHours} soat';
    if (diff.inDays < 7) return '${diff.inDays} kun';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} hafta';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()} oy';
    return '${(diff.inDays / 365).floor()} yil';
  }

  /// Reddit JSON sometimes returns HTML-escaped URLs (`&amp;` etc.).
  /// Requesting with `raw_json=1` avoids this, but we decode defensively.
  static String unescapeHtml(String input) {
    return input
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&#x200B;', '');
  }
}
