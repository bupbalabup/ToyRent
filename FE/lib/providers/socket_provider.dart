import 'package:flutter/material.dart';

import '../services/socket_service.dart';

class SocketProvider with ChangeNotifier {
  final SocketService _socketService = SocketService();

  bool _isConnected = false;
  String? _error;
  bool _isInitializing = false;

  bool get isConnected => _isConnected;
  String? get error => _error;
  bool get isInitializing => _isInitializing;
  SocketService get socketService => _socketService;

  /// Initialize socket connection
  Future<void> initializeSocket({
    required String token,
    required String userId,
  }) async {
    if (_isConnected || _isInitializing) {
      print('[SocketProvider] Already connected or initializing');
      return;
    }

    _isInitializing = true;
    _error = null;
    notifyListeners();

    try {
      await _socketService.connect(token: token, userId: userId);

      // Listen for internal connection events
      _socketService.on('_connected', (_) {
        _isConnected = true;
        _error = null;
        notifyListeners();
      });

      _socketService.on('_disconnected', (_) {
        _isConnected = false;
        notifyListeners();
      });

      _socketService.on('_connection_error', (data) {
        _error = data['error'].toString();
        notifyListeners();
      });

      _isConnected = await _socketService.checkConnection();
      _isInitializing = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isInitializing = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Disconnect socket
  Future<void> disconnect() async {
    await _socketService.disconnect();
    _isConnected = false;
    notifyListeners();
  }

  /// Listen for order_created events
  void onOrderCreated(Function(Map<String, dynamic>) callback) {
    _socketService.on('order_created', (data) {
      callback(data);
    });
  }

  /// Listen for order_updated events
  void onOrderUpdated(Function(Map<String, dynamic>) callback) {
    _socketService.on('order_updated', (data) {
      callback(data);
    });
  }

  /// Listen for payment_success events
  void onPaymentSuccess(Function(Map<String, dynamic>) callback) {
    _socketService.on('payment_success', (data) {
      callback(data);
    });
  }

  /// Listen for payment_failed events
  void onPaymentFailed(Function(Map<String, dynamic>) callback) {
    _socketService.on('payment_failed', (data) {
      callback(data);
    });
  }

  /// Listen for order_status_changed events
  void onOrderStatusChanged(Function(Map<String, dynamic>) callback) {
    _socketService.on('order_status_changed', (data) {
      callback(data);
    });
  }

  /// Stop listening to all socket events (cleanup on dispose)
  void cleanup() {
    _socketService.offAll('order_created');
    _socketService.offAll('order_updated');
    _socketService.offAll('payment_success');
    _socketService.offAll('payment_failed');
    _socketService.offAll('order_status_changed');
  }
}
