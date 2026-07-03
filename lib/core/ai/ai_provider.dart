/*
The AI backends the app can run its text features through (summary, digest,
translate, chat). Voice search is Gemini-only — no other provider accepts
inline audio — so the voice FAB is gated on the active provider being gemini.
Models are fixed per provider: stable, small, cheap enough for summaries.
*/
import 'package:flutter/material.dart';

enum AiProvider {
  gemini(
    id: 'gemini',
    label: 'Gemini',
    model: 'gemini-2.5-flash',
    keyHint: 'AIza...',
    icon: Icons.auto_awesome,
  ),
  openai(
    id: 'openai',
    label: 'OpenAI',
    model: 'gpt-4.1-mini',
    keyHint: 'sk-...',
    icon: Icons.all_inclusive,
  ),
  claude(
    id: 'claude',
    label: 'Claude',
    model: 'claude-haiku-4-5',
    keyHint: 'sk-ant-...',
    icon: Icons.brightness_7,
  ),
  deepseek(
    id: 'deepseek',
    label: 'DeepSeek',
    model: 'deepseek-v4-flash',
    keyHint: 'sk-...',
    icon: Icons.waves,
  ),
  grok(
    id: 'grok',
    label: 'Grok',
    model: 'grok-4-1-fast-non-reasoning',
    keyHint: 'xai-...',
    icon: Icons.bolt,
  );

  const AiProvider({
    required this.id,
    required this.label,
    required this.model,
    required this.keyHint,
    required this.icon,
  });

  final String id;
  final String label;
  final String model;
  final String keyHint;
  final IconData icon;

  /// Secure-storage key for this provider's API key. Gemini keeps its legacy
  /// name so existing users don't have to re-enter their key.
  String get storageKey =>
      this == AiProvider.gemini ? 'gemini_api_key' : 'ai_key_$id';

  static AiProvider fromId(String? id) => AiProvider.values.firstWhere(
    (p) => p.id == id,
    orElse: () => AiProvider.gemini,
  );
}
