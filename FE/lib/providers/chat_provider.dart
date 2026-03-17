import 'package:flutter/foundation.dart';
import '../services/chat_api_service.dart';
import 'auth_provider.dart';
import 'socket_provider.dart';

class ChatProvider extends ChangeNotifier {
  final ChatApiService _service = ChatApiService();
  late SocketProvider _socketProvider;
  late AuthProvider _authProvider;

  // Current chat conversation
  String? _currentChatUserId;
  List<ChatMessageModel> _messages = [];
  bool _loadingMessages = false;

  // Chat list
  List<ChatConversationModel> _conversations = [];
  List<ChatUserModel> _chatTargets = [];
  bool _loadingConversations = false;
  
  // Typing indicator
  bool _isOtherUserTyping = false;
  
  // Error handling
  String? _error;
  String? _messageError;

  // Getters
  String? get currentChatUserId => _currentChatUserId;
  List<ChatMessageModel> get messages => _messages;
  List<ChatConversationModel> get conversations => _conversations;
  List<ChatUserModel> get chatTargets => _chatTargets;
  bool get loadingMessages => _loadingMessages;
  bool get loadingConversations => _loadingConversations;
  bool get isOtherUserTyping => _isOtherUserTyping;
  String? get error => _error;
  String? get messageError => _messageError;
  String? get currentUserId => _authProvider.user?.id;
  bool get isAdmin => _authProvider.user?.role == 'admin';

  bool _isLikelyObjectId(String value) {
    final normalized = value.trim();
    final objectIdRegex = RegExp(r'^[a-fA-F0-9]{24}$');
    return objectIdRegex.hasMatch(normalized);
  }

  int getTotalUnreadCount() {
    return _conversations.fold<int>(
      0,
      (sum, conv) => sum + conv.unreadCount,
    );
  }

  Future<void> initialize(SocketProvider socketProvider, AuthProvider authProvider) async {
    _socketProvider = socketProvider;
    _authProvider = authProvider;
    
    // Fetch conversations
    await fetchConversations();
    
    // Setup socket listeners
    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    // Listen for incoming messages
    _socketProvider.socketService.on('receive_message', (data) {
      _handleIncomingMessage(data);
    });

    // Listen for typing indicator
    _socketProvider.socketService.on('user_typing', (data) {
      _handleTypingIndicator(data);
    });
  }

  void _handleIncomingMessage(dynamic data) {
    try {
      final msgData = data is Map ? data['data'] ?? data : data;
      final message = ChatMessageModel.fromJson(
        Map<String, dynamic>.from(msgData as Map),
      );

      // Check if this is for the current chat
      if (message.senderId == _currentChatUserId) {
        // Add to current messages list (if viewing this conversation)
        _messages.add(message);
        notifyListeners();
      }

      // Update conversations list
      _updateConversationWithNewMessage(message);
      
      print('[ChatProvider] New message from ${message.senderId}');
    } catch (e) {
      print('[ChatProvider] Error handling incoming message: $e');
    }
  }

  void _handleTypingIndicator(dynamic data) {
    try {
      final indicatorData = data is Map ? data['data'] ?? data : data;
      final senderId = indicatorData['senderId'];
      final isTyping = indicatorData['isTyping'] ?? false;

      if (senderId == _currentChatUserId) {
        _isOtherUserTyping = isTyping;
        notifyListeners();
      }
    } catch (e) {
      print('[ChatProvider] Error handling typing indicator: $e');
    }
  }

  void _updateConversationWithNewMessage(ChatMessageModel message) {
    final currentUserId = _authProvider.user?.id;
    final otherUserId = message.senderId == currentUserId
        ? message.receiverId
        : message.senderId;

    final index = _conversations.indexWhere(
      (c) => c.otherUser.id == otherUserId,
    );

    if (index >= 0) {
      // Move to top (most recent)
      final conv = _conversations.removeAt(index);
      final updatedConv = ChatConversationModel(
        conversationId: conv.conversationId,
        otherUser: conv.otherUser,
        lastMessage: message.message,
        lastMessageTime: message.createdAt,
        unreadCount: message.senderId == currentUserId
            ? conv.unreadCount
            : conv.unreadCount + 1,
        isFromOtherUser: message.senderId != currentUserId,
      );
      _conversations.insert(0, updatedConv);
    } else {
      // Create new conversation
      _conversations.insert(0, ChatConversationModel(
        conversationId: '',
        otherUser: ChatUserModel(
          id: otherUserId,
          name: '',
          email: '',
        ),
        lastMessage: message.message,
        lastMessageTime: message.createdAt,
        unreadCount: message.senderId == currentUserId ? 0 : 1,
        isFromOtherUser: message.senderId != currentUserId,
      ));
    }

    notifyListeners();
  }

  Future<void> fetchConversations() async {
    try {
      _loadingConversations = true;
      _error = null;
      notifyListeners();

      final isAdmin = _authProvider.user?.role == 'admin';
      _conversations = await _service.getConversations(
        isAdmin: isAdmin,
        currentUserId: _authProvider.user?.id ?? '',
      );
      _chatTargets = await _service.getChatTargets();

      _loadingConversations = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _loadingConversations = false;
      notifyListeners();
    }
  }

  Future<void> openChat(String userId, String userName) async {
    try {
      if (userId.trim().isEmpty || !_isLikelyObjectId(userId)) {
        _messageError = 'Conversation target is invalid. Please refresh chat list.';
        notifyListeners();
        return;
      }

      _currentChatUserId = userId;
      _messages = [];
      _loadingMessages = true;
      _error = null;
      _messageError = null;
      notifyListeners();

      // Fetch messages
      _messages = await _service.getMessages(userId);

      // Mark as read
      await _service.markChatAsRead(userId);

      // Join chat room
      _socketProvider.socketService.emit('join_chat_room', {
        'otherUserId': userId,
      });

      _loadingMessages = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _loadingMessages = false;
      notifyListeners();
    }
  }

  Future<bool> sendMessage(String message) async {
    if (_currentChatUserId == null ||
        _currentChatUserId!.trim().isEmpty ||
        !_isLikelyObjectId(_currentChatUserId!) ||
        message.trim().isEmpty) {
      _messageError = 'Message or receiver is invalid.';
      notifyListeners();
      return false;
    }

    try {
      _messageError = null;
      final sentMessage = await _service.sendMessage(_currentChatUserId!, message);
      
      // Add to local messages
      _messages.add(sentMessage);

      // Update conversation in list
      _updateConversationWithNewMessage(sentMessage);

      notifyListeners();
      return true;
    } catch (e) {
      _messageError = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteConversation(String otherUserId) async {
    try {
      _error = null;
      notifyListeners();

      await _service.deleteConversation(otherUserId);
      _conversations.removeWhere((item) => item.otherUser.id == otherUserId);

      if (_currentChatUserId == otherUserId) {
        _currentChatUserId = null;
        _messages = [];
        _isOtherUserTyping = false;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void setTyping(bool isTyping) {
    if (_currentChatUserId == null) return;

    _socketProvider.socketService.emit('typing', {
      'receiverId': _currentChatUserId,
      'isTyping': isTyping,
    });
  }

  void closeChat() {
    _currentChatUserId = null;
    _messages = [];
    _isOtherUserTyping = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    _messageError = null;
    notifyListeners();
  }

  void clearMessageError() {
    _messageError = null;
    notifyListeners();
  }
}
