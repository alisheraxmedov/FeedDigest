import 'package:hive_ce_flutter/hive_ce_flutter.dart';

class HiveBoxes {
  static const String favorites = 'favorites';
  static const String summaries = 'summaries';
  static const String subscriptions = 'subscriptions';
  static const String meta = 'meta';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox<dynamic>(favorites),
      Hive.openBox<dynamic>(summaries),
      Hive.openBox<dynamic>(subscriptions),
      Hive.openBox<dynamic>(meta),
    ]);
  }
}
