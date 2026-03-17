import 'package:socket_io_client/socket_io_client.dart' as io;

import '../config/api_config.dart';

typedef OnOrderEvent = Function(Map<String, dynamic> data);

class SocketService {
  static final SocketService _instance = SocketService._internal();
  late io.Socket _socket;
  bool _isConnected = false;

  // Event callbacks
  final Map<String, List<OnOrderEvent>> _eventListeners = {};

  // Private constructor
  SocketService._internal();

  // Factory constructor
  factory SocketService() {
    return _instance;
  }

  bool get isConnected => _isConnected;

  /// Initialize socket connection
  Future<void> connect({
    required String token,
    required String userId,
  }) async {
    if (_isConnected) {
      print('[Socket] Already connected');
      return;
    }

    try {
      final baseUrl = _getSocketUrl();
      print('[Socket] Connecting to $baseUrl');

      _socket = io.io(
        baseUrl,
        io.OptionBuilder()
            .setTransports(['websocket'])
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionAttempts(5)
            .setReconnectionDelay(1000)
            .disableForceNew()
            .build(),
      );

      // Set authentication
      _socket.auth = {
        'token': token,
        'userId': userId,
      };

      // Connection events
      _socket.on('connect', (_) {
        _isConnected = true;
        print('[Socket] Connected successfully');
        _notifyListeners('_connected', {});
      });

      _socket.on('disconnect', (_) {
        _isConnected = false;
        print('[Socket] Disconnected');
        _notifyListeners('_disconnected', {});
      });

      _socket.on('connect_error', (error) {
        print('[Socket] Connection error: $error');
        _notifyListeners('_connection_error', {'error': error.toString()});
      });

      // Order events
      _socket.on('order_created', (data) {
        print('[Socket] Received order_created event');
        _notifyListeners('order_created', data ?? {});
      });

      _socket.on('order_updated', (data) {
        print('[Socket] Received order_updated event');
        _notifyListeners('order_updated', data ?? {});
      });

      _socket.on('payment_success', (data) {
        print('[Socket] Received payment_success event');
        _notifyListeners('payment_success', data ?? {});
      });

      _socket.on('payment_failed', (data) {
        print('[Socket] Received payment_failed event');
        _notifyListeners('payment_failed', data ?? {});
      });

      _socket.on('order_status_changed', (data) {
        print('[Socket] Received order_status_changed event');
        _notifyListeners('order_status_changed', data ?? {});
      });

      // Connect
      _socket.connect();

      // Wait for connection with timeout
      await Future.delayed(const Duration(seconds: 2));
    } catch (e) {
      print('[Socket] Connection error: $e');
      rethrow;
    }
  }

  /// Disconnect from socket
  Future<void> disconnect() async {
    if (_isConnected) {
      _socket.disconnect();
      _isConnected = false;
      print('[Socket] Disconnected manually');
    }
  }

  /// Subscribe to socket event
  void on(String event, OnOrderEvent callback) {
    if (!_eventListeners.containsKey(event)) {
      _eventListeners[event] = [];
    }
    _eventListeners[event]!.add(callback);
  }

  /// Unsubscribe from socket event
  void off(String event, OnOrderEvent callback) {
    if (_eventListeners.containsKey(event)) {
      _eventListeners[event]!.remove(callback);
    }
  }

  /// Clear all listeners for an event
  void offAll(String event) {
    _eventListeners.remove(event);
  }

  /// Notify all listeners for an event
  void _notifyListeners(String event, Map<String, dynamic> data) {
    if (_eventListeners.containsKey(event)) {
      for (final listener in _eventListeners[event]!) {
        try {
          listener(data);
        } catch (e) {
          print('[Socket] Error in listener for $event: $e');
        }
      }
    }
  }

  /// Get socket URL based on platform
  String _getSocketUrl() {
    // Use the same base URL as API
    final baseUrl = ApiConfig.baseUrl;
    // Convert http://... to ws://...
    return baseUrl
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://')
        .replaceFirst('/api', '');
  }

  /// Check if socket is connected
  Future<bool> checkConnection() async {
    return Future.delayed(
      const Duration(milliseconds: 500),
      () => _isConnected,
    );
  }

  /// Emit event to server
  void emit(String event, [dynamic data]) {
    if (_isConnected) {
      _socket.emit(event, data);
      print('[Socket] Emitted $event');
    } else {
      print('[Socket] Cannot emit $event - not connected');
    }
  }

  /// Get underlying socket instance
  io.Socket get socket => _socket;
}
