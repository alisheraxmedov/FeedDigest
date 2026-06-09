import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../feed/data/models/reddit_post.dart';
import '../application/summary_providers.dart';
import '../data/ai_summary.dart';

/// Opens the AI summary bottom sheet for [post].
Future<void> showSummarySheet(BuildContext context, RedditPost post) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => SummarySheet(post: post),
  );
}

class SummarySheet extends ConsumerWidget {
  const SummarySheet({super.key, required this.post});

  final RedditPost post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final summary = ref.watch(summaryProvider(post));
    final isRealAi = ref.watch(isRealAiProvider);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 4,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.75,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SheetHeader(isRealAi: isRealAi),
              const SizedBox(height: 4),
              Text(
                post.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: summary.when(
                    loading: () => const _SummaryLoading(),
                    error: (error, _) => _SummaryError(
                      message: _messageFor(error),
                      onRetry: () =>
                          ref.invalidate(summaryProvider(post)),
                    ),
                    data: (s) => _SummaryBody(summary: s),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              summary.maybeWhen(
                data: (s) => _Actions(
                  onCopy: () async {
                    final combined = '📝 Post xulosasi:\n${s.postSummary}\n\n'
                        '💬 Izohlar xulosasi:\n${s.commentsSummary}';
                    await Clipboard.setData(ClipboardData(text: combined));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Nusxalandi')),
                      );
                    }
                  },
                  onRegenerate: () => ref.invalidate(summaryProvider(post)),
                ),
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _messageFor(Object error) {
    final msg = error.toString();
    // ApiException.toString carries the localized message after the colon.
    final idx = msg.indexOf(': ');
    return idx >= 0 ? msg.substring(idx + 2) : msg;
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.isRealAi});

  final bool isRealAi;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: AppColors.aiGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.auto_awesome_rounded,
              color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          'AI Xulosa',
          style:
              theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const Spacer(),
        if (!isRealAi)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: theme.colorScheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'DEMO',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onTertiaryContainer,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
      ],
    );
  }
}

class _SummaryLoading extends StatelessWidget {
  const _SummaryLoading();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          const CircularProgressIndicator(strokeWidth: 2.6),
          const SizedBox(height: 18),
          Text(
            'Gemini maqolani tahlil qilmoqda…',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _SummaryError extends StatelessWidget {
  const _SummaryError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Icon(Icons.error_outline_rounded, color: scheme.error, size: 44),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Qayta urinish'),
          ),
        ],
      ),
    );
  }
}

class _SummaryBody extends StatelessWidget {
  const _SummaryBody({required this.summary});

  final AiSummary summary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SummarySection(
          icon: '📝',
          title: 'Post xulosasi',
          body: summary.postSummary,
        ),
        const SizedBox(height: 18),
        _SummarySection(
          icon: '💬',
          title: 'Izohlar xulosasi',
          body: summary.hasComments
              ? summary.commentsSummary
              : 'Hozircha izohlar yo‘q.',
        ),
      ],
    );
  }
}

class _SummarySection extends StatelessWidget {
  const _SummarySection({
    required this.icon,
    required this.title,
    required this.body,
  });

  final String icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          body,
          style: theme.textTheme.bodyLarge?.copyWith(height: 1.55),
        ),
      ],
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.onCopy, required this.onRegenerate});

  final VoidCallback onCopy;
  final VoidCallback onRegenerate;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onCopy,
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: const Text('Nusxalash'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: onRegenerate,
            icon: const Icon(Icons.autorenew_rounded, size: 18),
            label: const Text('Qayta yaratish'),
          ),
        ),
      ],
    );
  }
}
