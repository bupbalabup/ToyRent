import 'package:dio/dio.dart';
import '../config/api_config.dart';

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

String _extractObjectId(dynamic value) {
  if (value is String) return value;
  if (value is num) return value.toString();
  if (value is Map<String, dynamic>) {
    final id = value['_id'];
    if (id is String) return id;
    if (id is Map) {
      final nested = _extractObjectId(Map<String, dynamic>.from(id));
      if (nested.isNotEmpty) return nested;
    }
    final idAlt = value['id'];
    if (idAlt is String) return idAlt;
    final oid = value['\$oid'];
    if (oid is String) return oid;
  }
  if (value is Map) {
    final map = Map<String, dynamic>.from(value);
    final id = map['_id'] ?? map['id'] ?? map['\$oid'];
    if (id is String) return id;
  }
  return '';
}

String _extractDioMessage(DioException error, {String fallback = 'Request failed'}) {
  final data = error.response?.data;
  if (data is Map<String, dynamic>) {
    final message = data['message'];
    if (message is String && message.trim().isNotEmpty) {
      return message;
    }
  }
  return fallback;
}

String _asString(dynamic value, [String fallback = '']) {
  if (value is String) return value;
  return value?.toString() ?? fallback;
}

int _asInt(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

bool _asBool(dynamic value, [bool fallback = false]) {
  if (value is bool) return value;
  if (value is String) {
    if (value.toLowerCase() == 'true') return true;
    if (value.toLowerCase() == 'false') return false;
  }
  return fallback;
}

class ChatUserModel {
  final String id;
  final String name;
  final String email;
  final String? avatar;

  ChatUserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
  });

  factory ChatUserModel.fromJson(Map<String, dynamic> json) {
    return ChatUserModel(
      id: _extractObjectId(json),
      name: _asString(json['name'], 'Unknown'),
      email: _asString(json['email']),
      avatar: json['avatar'] as String?,
    );
  }
}

class ChatMessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String message;
  final bool isRead;
  final String createdAt;
  final ChatUserModel? sender;
  final ChatUserModel? receiver;

  ChatMessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.sender,
    this.receiver,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    final senderRaw = json['senderId'];
    final receiverRaw = json['receiverId'];
    final senderMap = _asMap(senderRaw);
    final receiverMap = _asMap(receiverRaw);

    return ChatMessageModel(
      id: _extractObjectId(json['_id']),
      senderId: _extractObjectId(senderRaw),
      receiverId: _extractObjectId(receiverRaw),
      message: _asString(json['message']),
      isRead: _asBool(json['isRead']),
      createdAt: _asString(json['createdAt'], DateTime.now().toIso8601String()),
      sender: senderMap.isNotEmpty ? ChatUserModel.fromJson(senderMap) : null,
      receiver: receiverMap.isNotEmpty ? ChatUserModel.fromJson(receiverMap) : null,
    );
  }
}

class ChatConversationModel {
  final String conversationId;
  final ChatUserModel otherUser;
  final String lastMessage;
  final String lastMessageTime;
  final int unreadCount;
  final bool isFromOtherUser;

  ChatConversationModel({
    required this.conversationId,
    required this.otherUser,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
    required this.isFromOtherUser,
  });

  factory ChatConversationModel.fromJson(Map<String, dynamic> json, String currentUserId) {
    final sender = ChatUserModel.fromJson(_asMap(json['sender']));
    final receiver = ChatUserModel.fromJson(_asMap(json['receiver']));
    final lastMessage = _asMap(json['lastMessage']);
    final lastSenderId = _extractObjectId(lastMessage['senderId']);
    final isFromSender = lastSenderId == currentUserId;

    return ChatConversationModel(
      conversationId: _extractObjectId(json['_id']),
      otherUser: isFromSender ? receiver : sender,
      lastMessage: _asString(lastMessage['message']),
      lastMessageTime: _asString(lastMessage['createdAt']),
      unreadCount: _asInt(json['unreadCount']),
      isFromOtherUser: !isFromSender,
    );
  }
}

class ChatApiService {
  final Dio _dio = ApiConfig.dio;

  Future<List<ChatMessageModel>> getMessages(String userId) async {
    try {
      final response = await _dio.get('/chat/$userId');
        final responsePayload = _asMap(response.data);
        final data = _asMap(responsePayload['data']);
        final messagesList = (data['messages'] as List<dynamic>? ?? [])
          .map((e) => ChatMessageModel.fromJson(_asMap(e)))
          .toList();
      return messagesList;
    } catch (e) {
      throw Exception('Failed to fetch messages: $e');
    }
  }

  Future<List<ChatConversationModel>> getConversations({
    bool isAdmin = false,
    required String currentUserId,
  }) async {
    try {
      final response = await _dio.get(
        '/chat',
        queryParameters: {'isAdmin': isAdmin.toString()},
      );
      final responsePayload = _asMap(response.data);
      final data = _asMap(responsePayload['data']);

      final conversationsList = (data['conversations'] as List<dynamic>? ?? [])
          .map((e) => ChatConversationModel.fromJson(
            _asMap(e),
            currentUserId,
          ))
          .toList();
      return conversationsList;
    } catch (e) {
      throw Exception('Failed to fetch conversations: $e');
    }
  }

  Future<List<ChatUserModel>> getChatTargets() async {
    try {
      final response = await _dio.get('/chat/targets');
      final responsePayload = _asMap(response.data);
      final data = _asMap(responsePayload['data']);
      final users = (data['users'] as List<dynamic>? ?? [])
        .map((e) => ChatUserModel.fromJson(_asMap(e)))
          .toList();
      return users;
    } catch (e) {
      throw Exception('Failed to fetch chat targets: $e');
    }
  }

  Future<ChatMessageModel> sendMessage(String receiverId, String message) async {
    try {
      final response = await _dio.post(
        '/chat',
        data: {
          'receiverId': receiverId,
          'message': message,
        },
      );
      final responsePayload = _asMap(response.data);
      final data = _asMap(responsePayload['data']);
      return ChatMessageModel.fromJson(_asMap(data['message']));
    } on DioException catch (e) {
      throw Exception('Failed to send message: ${_extractDioMessage(e, fallback: 'Server rejected the message')}');
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  Future<void> markChatAsRead(String userId) async {
    try {
      await _dio.patch('/chat/$userId/read');
    } catch (e) {
      throw Exception('Failed to mark chat as read: $e');
    }
  }

  Future<void> deleteConversation(String userId) async {
    try {
      await _dio.delete('/chat/$userId');
    } catch (e) {
      throw Exception('Failed to delete conversation: $e');
    }
  }
}
