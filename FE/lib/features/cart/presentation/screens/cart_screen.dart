import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/cart_provider.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: Column(
        children: <Widget>[
          Expanded(
            child: cartProvider.items.isEmpty
                ? const Center(child: Text('Your cart is empty'))
                : ListView.separated(
                    itemCount: cartProvider.items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = cartProvider.items[index];
                      return ListTile(
                        title: Text(item.toy.name),
                        subtitle: Text(
                          '${item.quantity} x \$${item.toy.price.toStringAsFixed(2)}',
                        ),
                        trailing: IconButton(
                          onPressed: () => cartProvider.removeItem(item.toy.id),
                          icon: const Icon(Icons.delete_outline_rounded),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Text(
                        '\$${cartProvider.totalPrice.toStringAsFixed(2)}',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: cartProvider.items.isEmpty
                          ? null
                          : () async {
                              final user = authProvider.user;
                              if (user == null) return;

                              Navigator.pushNamed(context, AppRoutes.checkout);
                            },
                      child: const Text('Checkout'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
