/*
Network reachability. connectivity_plus only reports whether a network
*interface* is up (Wi-Fi / mobile), not whether the internet is actually
reachable — a Wi-Fi with no uplink still reads "connected". So this service
confirms real connectivity with a lightweight probe to Google's
`generate_204` endpoint, which returns an empty 204 only when the request
reaches the internet (a captive portal answers 200 with a body instead).
*/
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';

class ConnectivityService {
  ConnectivityService({Connectivity? connectivity, Dio? probeClient})
    : _connectivity = connectivity ?? Connectivity(),
      _probe =
          probeClient ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 3),
              receiveTimeout: const Duration(seconds: 3),
              sendTimeout: const Duration(seconds: 3),
              // Don't throw on the 204 we expect; we inspect the code ourselves.
              validateStatus: (_) => true,
            ),
          );

  final Connectivity _connectivity;
  final Dio _probe;

  static final Uri _probeUri = Uri.parse(
    'https://www.gstatic.com/generate_204',
  );

  Stream<List<ConnectivityResult>> get onChanged =>
      _connectivity.onConnectivityChanged;

  Future<List<ConnectivityResult>> current() =>
      _connectivity.checkConnectivity();

  /// True only when an interface is up AND the reachability probe returns the
  /// bare 204 (so captive portals and dead uplinks read as offline).
  Future<bool> isOnline([List<ConnectivityResult>? results]) async {
    final res = results ?? await current();
    if (res.isEmpty || res.every((r) => r == ConnectivityResult.none)) {
      return false;
    }
    return _reachable();
  }

  Future<bool> _reachable() async {
    try {
      final response = await _probe.headUri<void>(_probeUri);
      return response.statusCode == 204;
    } on DioException {
      return false;
    }
  }
}
