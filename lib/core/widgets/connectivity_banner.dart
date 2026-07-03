/*
A global, top-of-screen banner reflecting network state. It wraps the whole app
(via MaterialApp.builder) so it can float over any route. Going offline shows a
persistent error banner; regaining connection shows a brief accent "back online"
banner that auto-dismisses. Purely presentational — it watches connectivityProvider.
*/
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../connectivity/connectivity_provider.dart';
import '../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

enum _BannerMode { hidden, offline, online }

class ConnectivityBanner extends ConsumerStatefulWidget {
  const ConnectivityBanner({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends ConsumerState<ConnectivityBanner> {
  _BannerMode _mode = _BannerMode.hidden;
  Timer? _hideTimer;

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  void _onStatus(NetStatus? previous, NetStatus next) {
    if (next == NetStatus.offline) {
      _hideTimer?.cancel();
      setState(() => _mode = _BannerMode.offline);
      return;
    }
    // Back online — only announce it if we were actually offline before.
    if (previous == NetStatus.offline) {
      _hideTimer?.cancel();
      setState(() => _mode = _BannerMode.online);
      _hideTimer = Timer(const Duration(milliseconds: 2500), () {
        if (mounted) setState(() => _mode = _BannerMode.hidden);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<NetStatus>(connectivityProvider, _onStatus);
    final visible = _mode != _BannerMode.hidden;
    return Stack(
      children: [
        widget.child,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: IgnorePointer(
            ignoring: !visible,
            child: AnimatedSlide(
              offset: visible ? Offset.zero : const Offset(0, -1),
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              child: AnimatedOpacity(
                opacity: visible ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: _Bar(offline: _mode != _BannerMode.online),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.offline});

  final bool offline;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final palette = AppPalette.of(context);
    final background = offline ? scheme.error : palette.accent;
    final foreground = offline ? scheme.onError : palette.onAccent;
    return Material(
      color: background,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                offline ? Icons.wifi_off_rounded : Icons.wifi_rounded,
                size: 18,
                color: foreground,
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  offline ? l.netOffline : l.netOnline,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: foreground,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
