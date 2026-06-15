import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/chat_message.dart';

class ChatService {
  static const _keyChatMessages = 'coach_chat_messages';

  Future<List<ChatMessage>> loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_keyChatMessages);
    if (stored == null) return [];

    return stored
        .map((entry) => ChatMessage.fromJson(jsonDecode(entry) as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveMessages(List<ChatMessage> messages) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = messages.map((message) => jsonEncode(message.toJson())).toList();
    await prefs.setStringList(_keyChatMessages, encoded);
  }

  Future<void> clearMessages() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyChatMessages);
  }
}
