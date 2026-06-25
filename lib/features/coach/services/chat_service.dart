import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/firebase_backend.dart';
import '../../../core/services/firebase_collections.dart';
import '../models/chat_message.dart';
import 'coach_response_service.dart';

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

  factory ConversationSummary.fromJson(Map<String, dynamic> json) =>
      ConversationSummary(
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

  factory ConversationMessage.fromJson(Map<String, dynamic> json) =>
      ConversationMessage(
        role: json['role'] as String? ?? 'user',
        content: json['content'] as String? ?? '',
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
      );
}

class ChatService {
  static const _keyChatMessages = 'coach_chat_messages';
  static const _keyConversationId = 'coach_conversation_id';

  final _coachResponseService = CoachResponseService();

  Future<List<ConversationSummary>> getConversations() async {
    final snapshot = await FirebaseBackend.userCollection(
      FirebaseCollections.conversationsPath,
    ).orderBy('updatedAt', descending: true).get();
    return snapshot.docs
        .map(
          (doc) => ConversationSummary.fromJson({'id': doc.id, ...doc.data()}),
        )
        .toList();
  }

  Future<List<ConversationMessage>> getConversation(String id) async {
    final snapshot =
        await FirebaseBackend.userCollection(
              FirebaseCollections.conversationsPath,
            )
            .doc(id)
            .collection(FirebaseCollections.messagesPath)
            .orderBy('createdAt')
            .get();
    return snapshot.docs
        .map((doc) => ConversationMessage.fromJson(doc.data()))
        .toList();
  }

  Future<({String reply, String conversationId})> sendToFirebase({
    required String message,
    required CoachContext coachContext,
    String? conversationId,
  }) async {
    final conversations = FirebaseBackend.userCollection(
      FirebaseCollections.conversationsPath,
    );
    final conversationRef = conversationId == null
        ? conversations.doc()
        : conversations.doc(conversationId);
    final now = DateTime.now().toIso8601String();
    final reply = _coachResponseService.reply(message, coachContext);
    await conversationRef.set({
      'title': message.length > 40 ? '${message.substring(0, 40)}...' : message,
      'lastMessage': reply,
      'updatedAt': now,
      'messageCount': FieldValue.increment(2),
    }, SetOptions(merge: true));
    final messages = conversationRef.collection(
      FirebaseCollections.messagesPath,
    );
    await messages.add({'role': 'user', 'content': message, 'createdAt': now});
    await messages.add({
      'role': 'coach',
      'content': reply,
      'createdAt': DateTime.now().toIso8601String(),
    });
    return (reply: reply, conversationId: conversationRef.id);
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
