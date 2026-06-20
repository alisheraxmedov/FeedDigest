import 'package:flutter_test/flutter_test.dart';
import 'package:feeddigest/models/subreddit.dart';

void main() {
  test('prefers community_icon and strips query', () {
    final s = Subreddit.fromJson(const {
      'display_name': 'FlutterDev',
      'display_name_prefixed': 'r/FlutterDev',
      'title': 'Flutter Dev',
      'subscribers': 1234,
      'community_icon': 'https://styles/icon.png?width=256',
      'icon_img': 'https://b.thumbs/icon2.png',
      'public_description': 'Flutter community',
    });
    expect(s.name, 'FlutterDev');
    expect(s.namePrefixed, 'r/FlutterDev');
    expect(s.subscribers, 1234);
    expect(s.icon, 'https://styles/icon.png');
    expect(s.hasIcon, true);
  });

  test('falls back to icon_img when no community_icon', () {
    final s = Subreddit.fromJson(const {
      'display_name': 'rust',
      'icon_img': 'https://b.thumbs/icon2.png',
    });
    expect(s.icon, 'https://b.thumbs/icon2.png');
  });

  test('tolerates missing fields', () {
    final s = Subreddit.fromJson(const {});
    expect(s.name, '');
    expect(s.subscribers, 0);
    expect(s.hasIcon, false);
  });
}
