import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../providers/order_provider.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  late Future<void> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<OrderProvider>().fetchOrders();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Order history')),
      body: FutureBuilder<void>(
        future: _future,
        builder: (context, snapshot) {
          if (provider.isLoading && provider.orders.isEmpty) {
            return const AppLoader();
          }

          if (provider.error != null && provider.orders.isEmpty) {
            return AppErrorView(
              message: provider.error!,
              onRetry: () {
                setState(() => _future = context.read<OrderProvider>().fetchOrders());
              },
            );
          }

          if (provider.orders.isEmpty) {
            return const Center(child: Text('No orders yet'));
          }

          return ListView.separated(
            itemCount: provider.orders.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final order = provider.orders[index];
              return ListTile(
                title: Text('Order #${order.id}'),
                subtitle: Text('${order.items.length} items • ${order.createdAt.substring(0, 10)}'),
                trailing: Text('\$${order.totalPrice.toStringAsFixed(2)}'),
              );
            },
          );
        },
      ),
    );
  }
}
