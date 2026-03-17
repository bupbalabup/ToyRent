import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/socket_order_provider.dart';
import '../providers/socket_provider.dart';
import '../providers/api_notification_provider.dart';
import '../providers/chat_provider.dart';

class SocketInitializer extends StatefulWidget {
  final Widget child;

  const SocketInitializer({
    super.key,
    required this.child,
  });

  @override
  State<SocketInitializer> createState() => _SocketInitializerState();
}

class _SocketInitializerState extends State<SocketInitializer> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_initialized) {
      _initializeSocket();
      _initialized = true;
    }
  }

  Future<void> _initializeSocket() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final socketProvider = context.read<SocketProvider>();
      final socketOrderProvider = context.read<SocketOrderProvider>();
      final notificationProvider = context.read<ApiNotificationProvider>();
      final chatProvider = context.read<ChatProvider>();

      // Only initialize if user is logged in
      if (authProvider.isLoggedIn && authProvider.user != null && authProvider.token != null) {
        print('[SocketInitializer] Initializing socket connection...');

        // Initialize socket connection
        await socketProvider.initializeSocket(
          token: authProvider.token!,
          userId: authProvider.user!.id,
        );

        // Initialize order listeners
        socketOrderProvider.initializeOrderListeners();

        // Initialize notification provider
        await notificationProvider.initialize(socketProvider);

        // Initialize chat provider
        await chatProvider.initialize(socketProvider, authProvider);

        print('[SocketInitializer] All providers initialized successfully');
      }
    } catch (e) {
      print('[SocketInitializer] Error initializing providers: $e');
    }
  }

  @override
  void dispose() {
    final socketProvider = context.read<SocketProvider>();
    final socketOrderProvider = context.read<SocketOrderProvider>();

    socketProvider.cleanup();
    socketOrderProvider.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
