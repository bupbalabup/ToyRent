import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/admin_order_provider.dart';
import '../../providers/socket_provider.dart';
import '../../providers/socket_order_provider.dart';
import 'admin_create_order_screen.dart';
import 'admin_order_detail_screen.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  String _selectedStatus = 'All';

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => context.read<AdminOrderProvider>().fetchOrders(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Management'),
        backgroundColor: const Color(0xFFFF6600),
        elevation: 0,
        actions: [
          // Socket connection indicator
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Consumer<SocketProvider>(
                builder: (context, socketProvider, _) {
                  return Tooltip(
                    message: socketProvider.isConnected ? 'Live updates connected' : 'Connecting...',
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: socketProvider.isConnected ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: socketProvider.isConnected ? Colors.green : Colors.orange,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            socketProvider.isConnected ? 'Live' : 'Connecting',
                            style: TextStyle(
                              fontSize: 12,
                              color: socketProvider.isConnected ? Colors.green : Colors.orange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      body: Consumer2<AdminOrderProvider, SocketOrderProvider>(
        builder: (context, adminProvider, socketProvider, _) {
          return Column(
            children: [
              // Filter tabs
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: List.generate(
                    adminProvider.orderStatuses.length,
                    (index) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FilterChip(
                        label: Text(adminProvider.orderStatuses[index]),
                        selected: _selectedStatus == adminProvider.orderStatuses[index],
                        onSelected: (selected) {
                          if (selected) {
                            setState(
                              () => _selectedStatus = adminProvider.orderStatuses[index],
                            );
                            adminProvider.fetchOrders(
                              status: _selectedStatus == 'All'
                                  ? null
                                  : _selectedStatus,
                            );
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ),
              // Orders list
              Expanded(
                child: _buildOrdersList(context, adminProvider, socketProvider),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const AdminCreateOrderScreen()),
          );
          if (created == true && context.mounted) {
            context.read<AdminOrderProvider>().fetchOrders(
              status: _selectedStatus == 'All' ? null : _selectedStatus,
            );
          }
        },
        backgroundColor: const Color(0xFFFF6600),
        icon: const Icon(Icons.play_arrow, color: Colors.white),
        label: const Text('Start Rental', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildOrdersList(BuildContext context, AdminOrderProvider adminProvider, SocketOrderProvider socketProvider) {
    if (adminProvider.loading && adminProvider.orders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (adminProvider.error != null && adminProvider.orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(adminProvider.error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => adminProvider.fetchOrders(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Use socket provider orders if available (real-time), otherwise use admin provider orders
    final List<dynamic> baseOrders = socketProvider.orders.isNotEmpty
      ? socketProvider.orders
      : adminProvider.orders;

    final List<dynamic> displayOrders = _selectedStatus == 'All'
      ? baseOrders
      : baseOrders
        .where((order) => (order.orderStatus?.toString().toUpperCase() ?? '') == _selectedStatus)
        .toList();

    if (displayOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No orders found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => adminProvider.fetchOrders(
        status: _selectedStatus == 'All' ? null : _selectedStatus,
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: displayOrders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final order = displayOrders[index];
          final isLastUpdated = order.id == socketProvider.lastUpdatedOrderId;
          
          return _OrderCard(
            order: order,
            isLastUpdated: isLastUpdated,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AdminOrderDetailScreen(orderId: order.id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final dynamic order;
  final VoidCallback onTap;
  final bool isLastUpdated;

  const _OrderCard({
    required this.order,
    required this.onTap,
    this.isLastUpdated = false,
  });

  @override
  Widget build(BuildContext context) {
    final o = order as dynamic;
    final orderId = o.id.toString();
    final shortOrderId = orderId.length > 8 ? orderId.substring(0, 8) : orderId;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isLastUpdated ? Colors.green.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isLastUpdated ? Border.all(color: Colors.green, width: 2) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Order #$shortOrderId',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (isLastUpdated)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Updated',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        o.userEmail ?? 'Unknown',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${((o.totalPrice ?? o.totalAmount ?? 0) as num).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF6600),
                      ),
                    ),
                    const SizedBox(height: 4),
                    _StatusBadge(status: o.orderStatus),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Payment: ',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                _PaymentStatusBadge(status: o.paymentStatus),
                const SizedBox(width: 12),
                Text(
                  o.paymentMethod,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            if (o.items.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '${o.items.length} item(s)',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  Color _getStatusColor() {
    switch (status) {
      case 'PENDING':
        return Colors.orange;
      case 'ACTIVE':
        return Colors.blue;
      case 'SUCCESS':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      case 'FAILED':
        return Colors.red.shade800;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

class _PaymentStatusBadge extends StatelessWidget {
  final String status;

  const _PaymentStatusBadge({required this.status});

  Color _getColor() {
    return status == 'paid' ? Colors.green : Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
