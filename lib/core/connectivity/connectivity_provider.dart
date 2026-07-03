/*
App-wide online/offline state. Subscribes to connectivity_plus interface
changes and confirms each with the reachability probe in ConnectivityService,
then exposes a simple NetStatus the UI (the top banner) watches.
*/
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'connectivity_service.dart';

enum NetStatus { online, offline }

final connectivityServiceProvider = Provider<ConnectivityService>(
  (ref) => ConnectivityService(),
);

final connectivityProvider =
    NotifierProvider<ConnectivityController, NetStatus>(
      ConnectivityController.new,
    );

class ConnectivityController extends Notifier<NetStatus> {
  StreamSubscription<List<ConnectivityResult>>? _sub;
  int _generation = 0;

  @override
  NetStatus build() {
    final service = ref.read(connectivityServiceProvider);
    _sub = service.onChanged.listen((results) {
      unawaited(_evaluate(results));
    });
    ref.onDispose(() => _sub?.cancel());
    // Kick off the initial probe; state flips when it resolves.
    unawaited(_evaluate(null));
    return NetStatus.online; // optimistic until the first probe completes
  }

  Future<void> _evaluate(List<ConnectivityResult>? results) async {
    final generation = ++_generation;
    final online = await ref
        .read(connectivityServiceProvider)
        .isOnline(results);
    // Drop stale probes (a newer change superseded this one) and any write
    // after the notifier is disposed.
    if (!ref.mounted || generation != _generation) return;
    state = online ? NetStatus.online : NetStatus.offline;
  }
}
