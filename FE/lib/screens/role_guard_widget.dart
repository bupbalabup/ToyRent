import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../widgets/socket_initializer.dart';
import 'admin/admin_dashboard_screen.dart';
import 'login_screen.dart';
import 'main_app.dart';

class RoleGuardWidget extends StatefulWidget {
  const RoleGuardWidget({super.key});

  @override
  State<RoleGuardWidget> createState() => _RoleGuardWidgetState();
}

class _RoleGuardWidgetState extends State<RoleGuardWidget> {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.isLoggedIn || auth.user == null) {
      return const LoginScreen();
    }

    if (auth.isAdmin) {
      return SocketInitializer(
        child: const AdminDashboardScreen(),
      );
    }

    return SocketInitializer(
      child: const MainApp(),
    );
  }
}
