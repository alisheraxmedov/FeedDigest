/*
Exports the user's data so they own it and can move it elsewhere — no backend
or account needed. Writes a JSON backup (subscriptions + saved articles) and an
OPML file (topics, for RSS/reader import) to a temp dir and opens the share
sheet. This is the data-ownership signal the read-later market rewards.
*/
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/article.dart';
import '../../models/subscription.dart';

class ExportService {
  Future<void> shareBackup({
    required List<Subscription> subscriptions,
    required List<Article> favorites,
    required int nowMs,
  }) async {
    final dir = await getTemporaryDirectory();
    final backup = const JsonEncoder.withIndent('  ').convert({
      'app': 'FeedDigest',
      'version': 1,
      'exportedAt': nowMs,
      'subscriptions': subscriptions.map((s) => s.toJson()).toList(),
      'favorites': favorites.map((a) => a.toJson()).toList(),
    });
    final jsonFile = File('${dir.path}/feeddigest_backup.json');
    final opmlFile = File('${dir.path}/feeddigest_topics.opml');
    await jsonFile.writeAsString(backup);
    await opmlFile.writeAsString(_opml(subscriptions));
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(jsonFile.path), XFile(opmlFile.path)],
        subject: 'FeedDigest backup',
      ),
    );
  }

  String _opml(List<Subscription> subs) {
    final b = StringBuffer()
      ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
      ..writeln('<opml version="2.0">')
      ..writeln('  <head><title>FeedDigest topics</title></head>')
      ..writeln('  <body>');
    for (final s in subs) {
      final label = _esc(s.label);
      b.writeln(
        '    <outline text="$label" title="$label" '
        'type="topic" topic="${_esc(s.topic)}"/>',
      );
    }
    b
      ..writeln('  </body>')
      ..writeln('</opml>');
    return b.toString();
  }

  String _esc(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');
}
