import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:feeddigest/core/network/reddit_client.dart';
import 'package:feeddigest/data/reddit_repository.dart';

class _FakeClient extends RedditClient {
  _FakeClient(this.payload) : super(Dio());
  final dynamic payload;
  String? lastPath;
  Map<String, dynamic>? lastQuery;

  @override
  Future<dynamic> getJson(String path, Map<String, dynamic> query) async {
    lastPath = path;
    lastQuery = query;
    return payload;
  }
}

void main() {
  test('topPosts parses array-form listing', () async {
    final raw =
        jsonDecode(File('test/fixtures/top_example.json').readAsStringSync());
    final client = _FakeClient(raw);
    final repo = RedditRepository(client);
    final posts = await repo.topPosts('FlutterDev');
    expect(posts, isNotEmpty);
    expect(client.lastPath, '/r/FlutterDev/top.json');
    expect(client.lastQuery!['t'], 'week');
  });

  test('searchPosts parses single-object listing and builds path', () async {
    final raw = jsonDecode(
        File('test/fixtures/search_example.json').readAsStringSync());
    final client = _FakeClient(raw);
    final repo = RedditRepository(client);
    final posts = await repo.searchPosts('flutter');
    expect(posts, isNotEmpty);
    expect(client.lastPath, '/search.json');
    expect(client.lastQuery!['type'], 'link');
  });

  test('searchPosts restricts to subreddit when given', () async {
    final raw = jsonDecode(
        File('test/fixtures/search_example.json').readAsStringSync());
    final client = _FakeClient(raw);
    final repo = RedditRepository(client);
    await repo.searchPosts('state', subreddit: 'FlutterDev');
    expect(client.lastPath, '/r/FlutterDev/search.json');
    expect(client.lastQuery!['restrict_sr'], 'true');
  });

  test('searchSubreddits parses only t5 children', () async {
    final payload = {
      'data': {
        'children': [
          {
            'kind': 't5',
            'data': {'display_name': 'FlutterDev', 'subscribers': 100}
          },
          {
            'kind': 't3',
            'data': {'id': 'x'}
          },
        ]
      }
    };
    final client = _FakeClient(payload);
    final repo = RedditRepository(client);
    final subs = await repo.searchSubreddits('flutter');
    expect(subs.length, 1);
    expect(subs.first.name, 'FlutterDev');
    expect(client.lastPath, '/subreddits/search.json');
  });
}
