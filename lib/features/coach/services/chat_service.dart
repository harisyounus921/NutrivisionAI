import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/api_client.dart';
import '../models/chat_message.dart';

class ConversationSummary {
  const ConversationSummary({
    required this.id,
    required this.title,
    required this.lastMessage,
    required this.updatedAt,
    required this.messageCount,
  });

  final String id;
  final String title;
  final String? lastMessage;
  final DateTime updatedAt;
  final int messageCount;

  factory ConversationSummary.fromJson(Map<String, dynamic> json) => ConversationSummary(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? 'Conversation',
        lastMessage: json['lastMessage'] as String?,
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : DateTime.now(),
        messageCount: json['messageCount'] as int? ?? 0,
      );
}

class ConversationMessage {
  const ConversationMessage({
    required this.role,
    required this.content,
    required this.createdAt,
  });

  final String role;
  final String content;
  final DateTime createdAt;

  factory ConversationMessage.fromJson(Map<String, dynamic> json) => ConversationMessage(
        role: json['role'] as String? ?? 'user',
        content: json['content'] as String? ?? '',
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
      );
}

class ChatService {
  ChatService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  static const _keyChatMessages = 'coach_chat_messages';
  static const _keyConversationId = 'coach_conversation_id';

  final ApiClient _api;

  Future<List<ConversationSummary>> getConversations() async {
    final data = await _api.get('/coach/conversations') as List<dynamic>? ?? [];
    return data.cast<Map<String, dynamic>>().map(ConversationSummary.fromJson).toList();
  }

  Future<List<ConversationMessage>> getConversation(String id) async {
    final data = await _api.get('/coach/conversations/$id') as Map<String, dynamic>;
    final messages = (data['messages'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    return messages.map(ConversationMessage.fromJson).toList();
  }

  Future<({String reply, String conversationId})> sendToApi({
    required String message,
    String? conversationId,
  }) async {
    final data = await _api.post('/coach/chat', body: {
      'message': message,
      'conversationId': ?conversationId,
    }) as Map<String, dynamic>;

    return (
      reply: data['reply'] as String,
      conversationId: data['conversationId'] as String,
    );
  }

  Future<String?> getConversationId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyConversationId);
  }

  Future<void> saveConversationId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyConversationId, id);
  }

  Future<void> clearConversationId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyConversationId);
  }

  Future<List<ChatMessage>> loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_keyChatMessages);
    if (stored == null) return [];
    return stored
        .map((e) => ChatMessage.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveMessages(List<ChatMessage> messages) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _keyChatMessages,
      messages.map((m) => jsonEncode(m.toJson())).toList(),
    );
  }

  Future<void> clearMessages() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyChatMessages);
    await prefs.remove(_keyConversationId);
  }
}
