import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/product_provider.dart';
import 'providers/category_provider.dart';
import 'providers/socket_provider.dart';
import 'providers/socket_order_provider.dart';
import 'providers/api_notification_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/admin_product_provider.dart';
import 'providers/admin_order_provider.dart';
import 'providers/admin_category_provider.dart';
import 'widgets/socket_initializer.dart';
import 'screens/login_screen.dart';
import 'screens/main_app.dart';
import 'screens/admin/admin_dashboard_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => ProductProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => CartProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => CategoryProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => SocketProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => SocketOrderProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => ApiNotificationProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => NotificationProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => ChatProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => AdminProductProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => AdminOrderProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => AdminCategoryProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'RentToys',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme(),
        home: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            if (!auth.isLoggedIn || auth.user == null) {
              return const LoginScreen();
            }

            if (auth.isAdmin) {
              return const SocketInitializer(
                child: AdminDashboardScreen(),
              );
            }

            return const SocketInitializer(
              child: MainApp(),
            );
          },
        ),
      ),
    );
  }
}
