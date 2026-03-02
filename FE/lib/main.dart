import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_constants.dart';
import 'core/routes/app_router.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/order_provider.dart';
import 'providers/toy_provider.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/location_service.dart';
import 'services/local_storage_service.dart';
import 'services/notification_service.dart';
import 'services/order_service.dart';
import 'services/payment_service.dart';
import 'services/toy_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.init();

  final localStorageService = LocalStorageService();
  final apiService = ApiService(localStorageService.getToken);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(AuthService(apiService), localStorageService),
        ),
        ChangeNotifierProvider<ToyProvider>(
          create: (_) => ToyProvider(ToyService(apiService)),
        ),
        ChangeNotifierProvider<CartProvider>(create: (_) => CartProvider()),
        ChangeNotifierProvider<OrderProvider>(
          create: (_) => OrderProvider(OrderService(apiService)),
        ),
        Provider<LocationService>(create: (_) => LocationService(apiService)),
        Provider<PaymentService>(create: (_) => PaymentService(apiService)),
      ],
      child: const ToyflixApp(),
    ),
  );
}

class ToyflixApp extends StatelessWidget {
  const ToyflixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppConstants.appName,
      theme: AppTheme.darkTheme,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
