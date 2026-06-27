import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'app.dart';
import 'core/storage/hive_boxes.dart';
import 'data/subscription_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _loadEnv();
  await HiveBoxes.init();
  // Seed default topics once, before the first build reads them (keeps the
  // subscriptions notifier's build() pure).
  SubscriptionRepository(
    Hive.box<dynamic>(HiveBoxes.subscriptions),
    Hive.box<dynamic>(HiveBoxes.meta),
  ).seedDefaultsIfNeeded();
  runApp(const ProviderScope(child: FeedDigestApp()));
}

Future<void> _loadEnv() async {
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    if (kDebugMode) debugPrint('dotenv: .env not loaded ($e)');
  }
}
