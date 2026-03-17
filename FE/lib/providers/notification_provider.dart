import 'package:flutter/foundation.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  
  List<NotificationData> _notifications = [];
  bool _isLoading = false;

  List<NotificationData> get notifications => _notifications;
  List<NotificationData> get unreadNotifications =>
      _notifications.where((n) => !n.isRead).toList();
  bool get isLoading => _isLoading;
  int get unreadCount => unreadNotifications.length;

  /// Initialize notification service
  Future<void> initialize() async {
    try {
      await _notificationService.initialize();
    } catch (e) {
      print('Error initializing notifications: $e');
    }
  }

  /// Add notification
  void addNotification(NotificationData notification) {
    _notifications.insert(0, notification);
    notifyListeners();
  }

  /// Show immediate notification
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      await _notificationService.showNotification(
        title: title,
        body: body,
        payload: payload,
      );
    } catch (e) {
      print('Error showing notification: $e');
    }
  }

  /// Schedule rental reminder (1 hour before expiration)
  Future<void> scheduleRentalReminder({
    required String orderId,
    required String productName,
    required DateTime expirationTime,
  }) async {
    try {
      await _notificationService.scheduleRentalReminder(
        orderId: orderId,
        productName: productName,
        expirationTime: expirationTime,
      );
    } catch (e) {
      print('Error scheduling reminder: $e');
    }
  }

  /// Schedule expiration notification
  Future<void> scheduleExpirationNotification({
    required String orderId,
    required String productName,
    required DateTime expirationTime,
  }) async {
    try {
      await _notificationService.scheduleExpirationNotification(
        orderId: orderId,
        productName: productName,
        expirationTime: expirationTime,
      );
    } catch (e) {
      print('Error scheduling expiration notification: $e');
    }
  }

  /// Mark notification as read
  void markAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index >= 0) {
      _notifications[index] = NotificationData(
        id: _notifications[index].id,
        title: _notifications[index].title,
        message: _notifications[index].message,
        orderId: _notifications[index].orderId,
        isRead: true,
        createdAt: _notifications[index].createdAt,
      );
      notifyListeners();
    }
  }

  /// Clear all read notifications
  void clearReadNotifications() {
    _notifications.removeWhere((n) => n.isRead);
    notifyListeners();
  }

  /// Clear all notifications
  void clearAllNotifications() {
    _notifications.clear();
    notifyListeners();
  }
}
