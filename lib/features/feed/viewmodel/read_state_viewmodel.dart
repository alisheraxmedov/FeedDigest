/*
Reactive set of read article ids. The feed/search/saved cards watch this to dim
articles the reader has already opened; the detail screen calls markRead when it
opens. Kept in memory as a Set so card rebuilds are cheap.
*/
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';

final readStateProvider =
    NotifierProvider<ReadStateViewModel, Set<String>>(ReadStateViewModel.new);

class ReadStateViewModel extends Notifier<Set<String>> {
  @override
  Set<String> build() => ref.read(readStateRepositoryProvider).allRead();

  Future<void> markRead(String id, {required int nowMs}) async {
    if (state.contains(id)) return;
    await ref.read(readStateRepositoryProvider).markRead(id, nowMs);
    state = {...state, id};
  }
}
