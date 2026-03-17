import 'package:flutter/foundation.dart';
import '../services/notification_api_service.dart';
import 'socket_provider.dart';

class ApiNotificationProvider extends ChangeNotifier {
  final NotificationApiService _service = NotificationApiService();
  late SocketProvider _socketProvider;

  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _loading = false;
  String? _error;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> initialize(SocketProvider socketProvider) async {
    _socketProvider = socketProvider;
    
    // Fetch initial notifications
    await fetchNotifications();
    
    // Listen to real-time notifications from socket
    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    _socketProvider.socketService.on('notification', (data) {
      _handleNewNotification(data);
    });
  }

  void _handleNewNotification(dynamic data) {
    try {
      final notifData = data is Map ? data['data'] ?? data : data;
      
      final notification = NotificationModel.fromJson(
        Map<String, dynamic>.from(notifData as Map),
      );

      // Add to beginning of list
      _notifications.insert(0, notification);
      _unreadCount++;

      notifyListeners();
      print('[ApiNotificationProvider] New notification: ${notification.title}');
    } catch (e) {
      print('[ApiNotificationProvider] Error handling new notification: $e');
    }
  }

  Future<void> fetchNotifications() async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      _notifications = await _service.getNotifications();
      _unreadCount = await _service.getUnreadCount();

      _loading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _service.markAsRead(notificationId);
      
      // Update local state
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index >= 0) {
        final notification = _notifications[index];
        if (!notification.isRead) {
          _notifications[index] = notification.copyWith(isRead: true);
          _unreadCount = (_unreadCount - 1).clamp(0, double.infinity).toInt();
          notifyListeners();
        }
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _service.markAllAsRead();
      
      // Update all notifications locally
      _notifications = _notifications
          .map((n) => n.copyWith(isRead: true))
          .toList();
      _unreadCount = 0;
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
