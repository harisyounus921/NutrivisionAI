import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';

import '../models/chat_message.dart';
import '../services/chat_service.dart';
import '../services/coach_response_service.dart';

class ChatProvider extends ChangeNotifier {
  ChatProvider({ChatService? chatService})
    : _chatService = chatService ?? ChatService();

  final ChatService _chatService;

  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isReplying = false;

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isReplying => _isReplying;

  Future<void> loadMessages() async {
    _d('loadMessages — reading local chat history');
    _isLoading = true;
    notifyListeners();

    _messages = await _chatService.loadMessages();
    if (_messages.isEmpty) {
      _d('loadMessages — no history, seeding welcome message');
      _messages = [_welcomeMessage()];
      await _chatService.saveMessages(_messages);
    } else {
      _d('loadMessages — loaded ${_messages.length} messages');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> sendMessage(String text, CoachContext coachContext) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    _d(
      'sendMessage — POST /coach/chat: "${trimmed.length > 60 ? '${trimmed.substring(0, 60)}…' : trimmed}"',
    );

    _messages = [
      ..._messages,
      ChatMessage(
        id: _generateId(),
        role: ChatRole.user,
        text: trimmed,
        sentAt: DateTime.now(),
      ),
    ];
    _isReplying = true;
    notifyListeners();
    await _chatService.saveMessages(_messages);

    try {
      final conversationId = await _chatService.getConversationId();
      _d('sendMessage — conversationId: $conversationId');
      final result = await _chatService.sendToFirebase(
        message: trimmed,
        conversationId: conversationId,
        coachContext: coachContext,
      );
      await _chatService.saveConversationId(result.conversationId);
      _d(
        'sendMessage — reply received (${result.reply.length} chars), conversationId: ${result.conversationId}',
      );

      _messages = [
        ..._messages,
        ChatMessage(
          id: _generateId(),
          role: ChatRole.coach,
          text: result.reply,
          sentAt: DateTime.now(),
        ),
      ];
    } catch (e) {
      _d('sendMessage — error: $e — showing fallback message');
      _messages = [
        ..._messages,
        ChatMessage(
          id: _generateId(),
          role: ChatRole.coach,
          text:
              'Sorry, I couldn\'t reach the coach right now. Please try again.',
          sentAt: DateTime.now(),
        ),
      ];
    }

    _isReplying = false;
    notifyListeners();
    await _chatService.saveMessages(_messages);
  }

  static void _d(String msg) {
    if (kDebugMode) dev.log(msg, name: 'MealNudge·Coach');
  }

  ChatMessage _welcomeMessage() => ChatMessage(
    id: _generateId(),
    role: ChatRole.coach,
    text:
        "Hi! I'm your AI diet coach. Ask me about your calories, macros, or what to "
        "eat next, and I'll tailor it to your profile and today's log.",
    sentAt: DateTime.now(),
  );

  String _generateId() => DateTime.now().microsecondsSinceEpoch.toString();
}
