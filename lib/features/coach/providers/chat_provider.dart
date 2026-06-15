import 'package:flutter/foundation.dart';

import '../models/chat_message.dart';
import '../services/chat_service.dart';
import '../services/coach_response_service.dart';

class ChatProvider extends ChangeNotifier {
  ChatProvider({ChatService? chatService, CoachResponseService? coachResponseService})
      : _chatService = chatService ?? ChatService(),
        _coachResponseService = coachResponseService ?? CoachResponseService();

  final ChatService _chatService;
  final CoachResponseService _coachResponseService;

  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isReplying = false;

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isReplying => _isReplying;

  Future<void> loadMessages() async {
    _isLoading = true;
    notifyListeners();

    _messages = await _chatService.loadMessages();
    if (_messages.isEmpty) {
      _messages = [_welcomeMessage()];
      await _chatService.saveMessages(_messages);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> sendMessage(String text, CoachContext context) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    _messages = [
      ..._messages,
      ChatMessage(id: _generateId(), role: ChatRole.user, text: trimmed, sentAt: DateTime.now()),
    ];
    _isReplying = true;
    notifyListeners();
    await _chatService.saveMessages(_messages);

    final reply = _coachResponseService.reply(trimmed, context);
    _messages = [
      ..._messages,
      ChatMessage(id: _generateId(), role: ChatRole.coach, text: reply, sentAt: DateTime.now()),
    ];
    _isReplying = false;
    notifyListeners();
    await _chatService.saveMessages(_messages);
  }

  ChatMessage _welcomeMessage() => ChatMessage(
        id: _generateId(),
        role: ChatRole.coach,
        text: "Hi! I'm your AI diet coach. Ask me about your calories, macros, or what to "
            "eat next, and I'll tailor it to your profile and today's log.",
        sentAt: DateTime.now(),
      );

  String _generateId() => DateTime.now().microsecondsSinceEpoch.toString();
}
