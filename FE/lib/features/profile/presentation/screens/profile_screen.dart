import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/cart_provider.dart';
import '../../../../providers/toy_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final toys = context.watch<ToyProvider>();
    final cart = context.watch<CartProvider>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        const CircleAvatar(
          radius: 42,
          child: Icon(Icons.person_rounded, size: 42),
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            auth.user?.name ?? 'Guest',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        Center(child: Text(auth.user?.email ?? '')),
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                _StatBlock(label: 'Favorites', value: toys.favorites.length.toString()),
                _StatBlock(label: 'Cart', value: cart.totalQuantity.toString()),
                _StatBlock(label: 'Toys', value: toys.toys.length.toString()),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.history_rounded),
                title: const Text('Order history'),
                onTap: () => Navigator.pushNamed(context, AppRoutes.orderHistory),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.bar_chart_rounded),
                title: const Text('Statistics'),
                onTap: () => Navigator.pushNamed(context, AppRoutes.statistics),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.inventory_2_outlined),
                title: const Text('Manage toys (CRUD)'),
                onTap: () => Navigator.pushNamed(context, AppRoutes.manageToys),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.logout_rounded),
                title: const Text('Logout'),
                onTap: () async {
                  await context.read<AuthProvider>().logout();
                  if (!context.mounted) return;
                  Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatBlock extends StatelessWidget {
  const _StatBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(value, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 2),
        Text(label),
      ],
    );
  }
}
