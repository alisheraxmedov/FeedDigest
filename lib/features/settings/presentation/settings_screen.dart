import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../../core/models/topic.dart';
import '../../auth/application/auth_providers.dart';
import '../application/settings_providers.dart';
import 'topic_editor_sheet.dart';

/// Settings: appearance, API key status, and full topic management.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final topics = ref.watch(topicsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Sozlamalar')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _SectionTitle('Reddit hisobi'),
          const _AccountSection(),
          const SizedBox(height: 24),
          _SectionTitle('Ko‘rinish'),
          _ThemeSelector(
            mode: themeMode,
            onChanged: (m) => ref.read(themeModeProvider.notifier).set(m),
          ),
          const SizedBox(height: 24),
          _SectionTitle('API holati'),
          const _ApiStatusCard(),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _SectionTitle('Mavzular')),
              TextButton.icon(
                onPressed: () => _addTopic(context, ref),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Qo‘shish'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _TopicsList(topics: topics),
          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              onPressed: () => _confirmReset(context, ref),
              icon: const Icon(Icons.restart_alt_rounded, size: 18),
              label: const Text('Standart mavzularni tiklash'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addTopic(BuildContext context, WidgetRef ref) async {
    final topic = await showTopicEditor(context);
    if (topic == null || !context.mounted) return;
    final notifier = ref.read(topicsProvider.notifier);
    if (ref.read(topicsProvider).contains(topic)) {
      _snack(context, 'Bu subreddit allaqachon qo‘shilgan.');
      return;
    }
    notifier.add(topic);
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tiklash'),
        content: const Text(
            'Barcha mavzular standart holatga qaytariladi. Davom etamizmi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Bekor qilish'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Tiklash'),
          ),
        ],
      ),
    );
    if (ok == true) {
      ref.read(topicsProvider.notifier).resetToDefaults();
    }
  }

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _AccountSection extends ConsumerWidget {
  const _AccountSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final theme = Theme.of(context);

    Widget content;
    if (auth.isLoading) {
      content = Row(
        children: [
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
          const SizedBox(width: 14),
          Text('Reddit bilan ulanmoqda…', style: theme.textTheme.bodyMedium),
        ],
      );
    } else {
      final state = auth.value;
      if (state != null && state.isLoggedIn) {
        content = _LoggedInRow(
          username: state.username ?? 'reddit',
          onLogout: () => ref.read(authControllerProvider.notifier).logout(),
        );
      } else {
        content = _LoggedOutRow(
          error: auth.hasError ? _messageFor(auth.error!) : null,
          onLogin: () => ref.read(authControllerProvider.notifier).login(),
        );
      }
    }

    return Card(
      child: Padding(padding: const EdgeInsets.all(16), child: content),
    );
  }

  String _messageFor(Object error) {
    final msg = error.toString();
    final idx = msg.indexOf(': ');
    return idx >= 0 ? msg.substring(idx + 2) : msg;
  }
}

class _LoggedInRow extends StatelessWidget {
  const _LoggedInRow({required this.username, required this.onLogout});

  final String username;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Text(
            username.isNotEmpty ? username[0].toUpperCase() : '?',
            style: TextStyle(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('u/$username',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              Text('Reddit hisobiga kirgansiz',
                  style: theme.textTheme.bodySmall),
            ],
          ),
        ),
        OutlinedButton.icon(
          onPressed: onLogout,
          icon: const Icon(Icons.logout_rounded, size: 18),
          label: const Text('Chiqish'),
        ),
      ],
    );
  }
}

class _LoggedOutRow extends StatelessWidget {
  const _LoggedOutRow({required this.error, required this.onLogin});

  final String? error;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasClient = Env.hasRedditAuth;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Obuna bo‘lish, ovoz berish va shaxsiy "Bosh sahifa" feedi uchun '
          'Reddit hisobingizga kiring.',
          style: theme.textTheme.bodyMedium,
        ),
        if (error != null) ...[
          const SizedBox(height: 10),
          Text(error!,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.error)),
        ],
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: hasClient ? onLogin : null,
          icon: const Icon(Icons.login_rounded, size: 18),
          label: const Text('Reddit bilan kirish'),
        ),
        if (!hasClient)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Avval `.env` fayliga REDDIT_CLIENT_ID qo‘shing.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
      ],
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector({required this.mode, required this.onChanged});

  final ThemeMode mode;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<ThemeMode>(
      segments: const [
        ButtonSegment(
          value: ThemeMode.system,
          icon: Icon(Icons.brightness_auto_rounded),
          label: Text('Tizim'),
        ),
        ButtonSegment(
          value: ThemeMode.light,
          icon: Icon(Icons.light_mode_rounded),
          label: Text('Yorug‘'),
        ),
        ButtonSegment(
          value: ThemeMode.dark,
          icon: Icon(Icons.dark_mode_rounded),
          label: Text('Tungi'),
        ),
      ],
      selected: {mode},
      onSelectionChanged: (s) => onChanged(s.first),
      showSelectedIcon: false,
    );
  }
}

class _ApiStatusCard extends StatelessWidget {
  const _ApiStatusCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _StatusRow(
              icon: Icons.auto_awesome_rounded,
              title: 'Gemini AI',
              isLive: Env.hasGemini,
              liveText: 'Faol — real o‘zbekcha xulosa',
              demoText: 'Demo — GEMINI_API_KEY qo‘shing',
            ),
            const Divider(height: 24),
            _StatusRow(
              icon: Icons.public_rounded,
              title: 'Reddit',
              isLive: Env.useRealReddit,
              liveText: 'Jonli ma‘lumot',
              demoText: 'Demo ma‘lumot — REDDIT_CLIENT_ID qo‘shing',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Kalitlarni loyiha ildizidagi `.env` fayliga qo‘shing. '
                      'Namuna uchun `.env.example` ga qarang.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.icon,
    required this.title,
    required this.isLive,
    required this.liveText,
    required this.demoText,
  });

  final IconData icon;
  final String title;
  final bool isLive;
  final String liveText;
  final String demoText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isLive ? Colors.green : theme.colorScheme.tertiary;
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(isLive ? liveText : demoText,
                  style: theme.textTheme.bodySmall),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            isLive ? 'LIVE' : 'DEMO',
            style: theme.textTheme.labelSmall
                ?.copyWith(color: color, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _TopicsList extends ConsumerWidget {
  const _TopicsList({required this.topics});

  final List<Topic> topics;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(topicsProvider.notifier);

    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: true,
      itemCount: topics.length,
      onReorderItem: notifier.move,
      itemBuilder: (context, index) {
        final topic = topics[index];
        return Card(
          key: ValueKey('${topic.subreddit}_$index'),
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            title: Text(topic.label,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(topic.displayName),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Tahrirlash',
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: () async {
                    final edited =
                        await showTopicEditor(context, initial: topic);
                    if (edited != null) notifier.update(index, edited);
                  },
                ),
                IconButton(
                  tooltip: 'O‘chirish',
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  onPressed: () => notifier.removeAt(index),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
