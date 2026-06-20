import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/shell/view/home_shell.dart';

class FeedDigestApp extends StatelessWidget {
  const FeedDigestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FeedDigest',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const HomeShell(),
    );
  }
}
