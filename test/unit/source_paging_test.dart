import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:feeddigest/core/sources/devto_source.dart';
import 'package:feeddigest/core/sources/hacker_news_source.dart';
import 'package:flutter_test/flutter_test.dart';

/// Captures the outgoing request URI and returns a canned empty payload so the
/// source's parse step succeeds without a real network call.
class _CaptureAdapter implements HttpClientAdapter {
  _CaptureAdapter(this.body);

  final String body;
  Uri? lastUri;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastUri = options.uri;
    return ResponseBody.fromString(
      body,
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('HackerNews sends 0-indexed page (ui page 2 -> page=1)', () async {
    final adapter = _CaptureAdapter('{"hits":[]}');
    final dio = Dio()..httpClientAdapter = adapter;
    await HackerNewsSource(dio).topPosts('flutter', page: 2);
    expect(adapter.lastUri!.queryParameters['page'], '1');
  });

  test('Hacker News search pins to first page (page=0)', () async {
    final adapter = _CaptureAdapter('{"hits":[]}');
    final dio = Dio()..httpClientAdapter = adapter;
    await HackerNewsSource(dio).search('flutter');
    expect(adapter.lastUri!.queryParameters['page'], '0');
  });

  test('dev.to sends 1-indexed page (ui page 2 -> page=2)', () async {
    final adapter = _CaptureAdapter('[]');
    final dio = Dio()..httpClientAdapter = adapter;
    await DevtoSource(dio).topPosts('flutter', page: 2);
    expect(adapter.lastUri!.queryParameters['page'], '2');
  });
}
