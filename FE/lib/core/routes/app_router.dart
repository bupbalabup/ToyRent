import 'package:flutter/material.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/cart/presentation/screens/checkout_screen.dart';
import '../../features/home/presentation/screens/manage_toys_screen.dart';
import '../../features/home/presentation/screens/toy_form_screen.dart';
import '../../features/navigation/main_navigation_screen.dart';
import '../../features/profile/presentation/screens/order_history_screen.dart';
import '../../features/profile/presentation/screens/statistics_screen.dart';
import '../../features/splash/splash_screen.dart';
import 'app_routes.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return _buildRoute(const SplashScreen(), settings);
      case AppRoutes.login:
        return _buildRoute(const LoginScreen(), settings);
      case AppRoutes.register:
        return _buildRoute(const RegisterScreen(), settings);
      case AppRoutes.main:
        return _buildRoute(const MainNavigationScreen(), settings);
      case AppRoutes.orderHistory:
        return _buildRoute(const OrderHistoryScreen(), settings);
      case AppRoutes.statistics:
        return _buildRoute(const StatisticsScreen(), settings);
      case AppRoutes.manageToys:
        return _buildRoute(const ManageToysScreen(), settings);
      case AppRoutes.toyForm:
        return _buildRoute(const ToyFormScreen(), settings);
      case AppRoutes.checkout:
        return _buildRoute(const CheckoutScreen(), settings);
      default:
        return _buildRoute(const SplashScreen(), settings);
    }
  }

  static PageRouteBuilder<void> _buildRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder<void>(
      settings: settings,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0.04, 0), end: Offset.zero).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 320),
    );
  }
}
