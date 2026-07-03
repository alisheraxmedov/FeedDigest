import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'app.dart';
import 'core/storage/hive_boxes.dart';
import 'data/subscription_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveBoxes.init();
  // Seed default topics once, before the first build reads them (keeps the
  // subscriptions notifier's build() pure).
  await SubscriptionRepository(
    Hive.box<dynamic>(HiveBoxes.subscriptions),
    Hive.box<dynamic>(HiveBoxes.meta),
  ).seedDefaultsIfNeeded();
  runApp(const ProviderScope(child: FeedDigestApp()));
}
