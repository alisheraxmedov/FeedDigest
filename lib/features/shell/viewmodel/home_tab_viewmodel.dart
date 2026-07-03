/*
Which HomeShell tab is visible. Lifting this out of HomeShell's local state lets
other flows (e.g. voice search) switch tabs — voice search jumps to Search after
it resolves a spoken query.
*/
import 'package:flutter_riverpod/flutter_riverpod.dart';

final homeTabProvider = NotifierProvider<HomeTabController, int>(
  HomeTabController.new,
);

class HomeTabController extends Notifier<int> {
  static const int feed = 0;
  static const int search = 1;
  static const int saved = 2;
  static const int settings = 3;

  @override
  int build() => feed;

  void select(int index) => state = index;
}
