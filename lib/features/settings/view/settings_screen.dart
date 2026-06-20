import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../subscriptions/view/subscription_editor_sheet.dart';
import '../viewmodel/settings_viewmodel.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _key = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _key.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await ref.read(settingsActionsProvider).saveKey(_key.text);
    if (!mounted) return;
    _key.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Kalit saqlandi')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyPresent = ref.watch(geminiKeyPresentProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Sozlamalar')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Gemini API kaliti',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          keyPresent.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (present) => Text(
              present ? 'Kalit kiritilgan' : 'Kalit kiritilmagan',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _key,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: 'API kalit',
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(onPressed: _save, child: const Text('Saqlash')),
          const Divider(height: 32),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Obunalarni boshqarish'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showSubscriptionEditor(context),
          ),
        ],
      ),
    );
  }
}
