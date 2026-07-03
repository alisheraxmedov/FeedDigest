import 'package:flutter_test/flutter_test.dart';
import 'package:feeddigest/features/chat/viewmodel/article_chat_viewmodel.dart';
import 'package:feeddigest/models/chat_message.dart';

void main() {
  group('sanitizeChatHistory', () {
    test(
      'drops a trailing unanswered user turn so history never ends on user',
      () {
        final messages = [
          const ChatMessage(role: ChatRole.user, text: 'q1'),
          const ChatMessage(role: ChatRole.model, text: 'a1'),
          const ChatMessage(role: ChatRole.user, text: 'q2-failed'),
        ];
        // Sending this raw would put two consecutive user turns in the Gemini
        // payload once a new question is appended.
        expect(sanitizeChatHistory(messages).map((m) => m.text).toList(), [
          'q1',
          'a1',
        ]);
      },
    );

    test('leaves a well-formed history ending on a model turn untouched', () {
      final messages = [
        const ChatMessage(role: ChatRole.user, text: 'q1'),
        const ChatMessage(role: ChatRole.model, text: 'a1'),
      ];
      expect(sanitizeChatHistory(messages).length, 2);
    });

    test('empty history stays empty', () {
      expect(sanitizeChatHistory(const []), isEmpty);
    });
  });
}
