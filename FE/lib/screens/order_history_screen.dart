import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/socket_provider.dart';
import '../providers/socket_order_provider.dart';
import '../services/rental_service.dart' show RentalService;
import 'order_detail_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final RentalService _rentalService = RentalService();
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final orders = await _rentalService.getMyOrders();
      if (!mounted) return;
      
      // Set orders in socket provider for real-time updates
      if (mounted) {
        context.read<SocketOrderProvider>().setOrders(
          orders.map((o) => SocketOrderModel(
            id: o.id,
            totalAmount: o.totalAmount,
            totalPrice: o.totalPrice,
            orderStatus: o.orderStatus,
            paymentStatus: o.paymentStatus,
            paymentMethod: o.paymentMethod,
            rentalType: o.rentalType,
            depositAmount: o.depositAmount,
            userId: o.userId,
            userEmail: o.userEmail,
            rentalStartTime: o.rentalStartTime,
            rentalEndTime: o.rentalEndTime,
            actualEndTime: o.actualEndTime,
            isEditable: o.isEditable,
            createdAt: o.createdAt,
            updatedAt: o.updatedAt,
            items: o.items,
          )).toList(),
        );
      }

      setState(() {
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
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
      body: RefreshIndicator(
        onRefresh: _loadOrders,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _loadOrders,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // Watch socket order provider for real-time updates
    return Consumer<SocketOrderProvider>(
      builder: (context, orderProvider, _) {
        final orders = orderProvider.orders;
        
        if (orders.isEmpty) {
          return ListView(
            children: const [
              SizedBox(height: 120),
              Center(child: Text('No orders yet')),
            ],
          );
        }

        return ListView.separated(
          itemCount: orders.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final order = orders[index];
            final isLastUpdated = order.id == orderProvider.lastUpdatedOrderId;
            
            return Container(
              color: isLastUpdated ? Colors.green.withOpacity(0.1) : null,
              child: ListTile(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => OrderDetailScreen(order: order),
                    ),
                  );
                },
                title: Row(
                  children: [
                    Expanded(
                      child: Text('Order ${order.id.substring(0, order.id.length > 8 ? 8 : order.id.length)}'),
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
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      'Status: ${order.orderStatus} | Payment: ${order.paymentStatus} (${order.paymentMethod})',
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Updated: ${_formatTime(order.updatedAt)}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    if (order.rentalType == 'HOURLY' && order.rentalEndTime != null)
                      Text(
                        _buildCountdown(order.rentalEndTime!),
                        style: TextStyle(
                          fontSize: 12,
                          color: DateTime.now().isAfter(order.rentalEndTime!)
                              ? Colors.red
                              : Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
                trailing: Text('\$${order.totalAmount.toStringAsFixed(2)}'),
              ),
            );
          },
        );
      },
    );
  }

  String _formatTime(DateTime? dateTime) {
    try {
      if (dateTime == null) {
        return 'Recently';
      }
      final dt = dateTime;
      final now = DateTime.now();
      final diff = now.difference(dt);
      
      if (diff.inSeconds < 60) {
        return 'Just now';
      } else if (diff.inMinutes < 60) {
        return '${diff.inMinutes}m ago';
      } else if (diff.inHours < 24) {
        return '${diff.inHours}h ago';
      } else {
        return '${diff.inDays}d ago';
      }
    } catch (_) {
      return 'Recently';
    }
  }

  String _buildCountdown(DateTime endTime) {
    final now = DateTime.now();
    if (now.isAfter(endTime)) {
      return 'Đã hết thời gian thuê';
    }
    final diff = endTime.difference(now);
    final h = diff.inHours;
    final m = diff.inMinutes.remainder(60);
    final s = diff.inSeconds.remainder(60);
    return 'Time left: ${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
