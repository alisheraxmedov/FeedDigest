import 'package:flutter/material.dart';

import '../../../core/models/topic.dart';

/// Opens the add/edit topic sheet. Returns the new/updated [Topic], or null if
/// the user cancelled.
Future<Topic?> showTopicEditor(BuildContext context, {Topic? initial}) {
  return showModalBottomSheet<Topic>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _TopicEditorSheet(initial: initial),
  );
}

class _TopicEditorSheet extends StatefulWidget {
  const _TopicEditorSheet({this.initial});

  final Topic? initial;

  @override
  State<_TopicEditorSheet> createState() => _TopicEditorSheetState();
}

class _TopicEditorSheetState extends State<_TopicEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _label;
  late final TextEditingController _subreddit;

  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    _label = TextEditingController(text: widget.initial?.label ?? '');
    _subreddit = TextEditingController(text: widget.initial?.subreddit ?? '');
  }

  @override
  void dispose() {
    _label.dispose();
    _subreddit.dispose();
    super.dispose();
  }

  String _normalizeSubreddit(String value) {
    var v = value.trim();
    if (v.toLowerCase().startsWith('r/')) v = v.substring(2);
    if (v.toLowerCase().startsWith('/r/')) v = v.substring(3);
    return v.replaceAll(RegExp(r'\s+'), '');
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      Topic(
        label: _label.text.trim(),
        subreddit: _normalizeSubreddit(_subreddit.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 4,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isEditing ? 'Mavzuni tahrirlash' : 'Yangi mavzu',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _label,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nomi',
                hintText: 'Masalan: Flutter',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Nom kiriting' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _subreddit,
              decoration: const InputDecoration(
                labelText: 'Subreddit',
                hintText: 'Masalan: FlutterDev',
                prefixText: 'r/',
              ),
              validator: (v) {
                final s = _normalizeSubreddit(v ?? '');
                if (s.isEmpty) return 'Subreddit kiriting';
                if (!RegExp(r'^[A-Za-z0-9_]+$').hasMatch(s)) {
                  return 'Faqat harf, raqam va _ ruxsat etiladi';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _save,
                icon: Icon(_isEditing
                    ? Icons.check_rounded
                    : Icons.add_rounded),
                label: Text(_isEditing ? 'Saqlash' : 'Qo‘shish'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
