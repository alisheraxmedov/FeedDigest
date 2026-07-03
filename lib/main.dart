import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/storage/hive_boxes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveBoxes.init();
  // Subscriptions are seeded by the first-run interests picker (or its Skip
  // action), so nothing is seeded here.
  runApp(const ProviderScope(child: FeedDigestApp()));
}
