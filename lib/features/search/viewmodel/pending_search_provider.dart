/*
A one-shot search query pushed into the Search screen from outside (voice
search). The Search screen consumes it — fills its field, runs the search — then
resets it to null so it isn't re-applied on rebuild.
*/
import 'package:flutter_riverpod/flutter_riverpod.dart';

final pendingSearchProvider =
    NotifierProvider<PendingSearchController, String?>(
      PendingSearchController.new,
    );

class PendingSearchController extends Notifier<String?> {
  @override
  String? build() => null;

  void submit(String query) => state = query;

  void consume() => state = null;
}
