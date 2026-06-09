import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/application/auth_providers.dart';
import '../../application/feed_providers.dart';
import '../../application/subscriptions_providers.dart';

/// Subscribe / unsubscribe toggle for a subreddit. Reflects the live
/// subscription set and prompts login when used while logged out.
class SubscribeButton extends ConsumerStatefulWidget {
  const SubscribeButton({super.key, required this.subreddit});

  final String subreddit;

  @override
  ConsumerState<SubscribeButton> createState() => _SubscribeButtonState();
}

class _SubscribeButtonState extends ConsumerState<SubscribeButton> {
  bool _busy = false;

  Future<void> _toggle(bool currentlySubscribed) async {
    if (!ref.read(isLoggedInProvider)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Obuna bo‘lish uchun Sozlamalardan Reddit hisobiga kiring.'),
        ),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      await ref.read(redditRepositoryProvider).setSubscribed(
            subreddit: widget.subreddit,
            subscribe: !currentlySubscribed,
          );
      ref.invalidate(subscriptionsProvider);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_messageFor(error))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _messageFor(Object error) {
    final msg = error.toString();
    final idx = msg.indexOf(': ');
    return idx >= 0 ? msg.substring(idx + 2) : msg;
  }

  @override
  Widget build(BuildContext context) {
    final subscribed = ref
        .watch(subscribedNamesProvider)
        .contains(widget.subreddit.toLowerCase());

    final child = _busy
        ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Text(subscribed ? 'Obuna bo‘lingan' : 'Obuna bo‘lish');

    final onPressed = _busy ? null : () => _toggle(subscribed);

    return subscribed
        ? OutlinedButton.icon(
            onPressed: onPressed,
            icon: _busy
                ? const SizedBox.shrink()
                : const Icon(Icons.check_rounded, size: 18),
            label: child,
          )
        : FilledButton.icon(
            onPressed: onPressed,
            icon: _busy
                ? const SizedBox.shrink()
                : const Icon(Icons.add_rounded, size: 18),
            label: child,
          );
  }
}
