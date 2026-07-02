import 'package:flutter/foundation.dart';

/// A single turn in the per-article chat. `user` is what the reader asked;
/// `model` is Gemini's reply grounded in the article text.
enum ChatRole { user, model }

@immutable
class ChatMessage {
  const ChatMessage({required this.role, required this.text});

  final ChatRole role;
  final String text;

  bool get isUser => role == ChatRole.user;
}
