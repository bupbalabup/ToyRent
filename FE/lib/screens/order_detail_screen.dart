import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../providers/socket_order_provider.dart';

class OrderDetailScreen extends StatelessWidget {
  final SocketOrderModel order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final shortId = order.id.length > 8 ? order.id.substring(0, 8) : order.id;

    return Scaffold(
      appBar: AppBar(
        title: Text('Order #$shortId'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Section(
            title: 'Status',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _row('Order', order.orderStatus),
                _row('Payment', '${order.paymentStatus} (${order.paymentMethod})'),
                _row('Type', order.rentalType),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _Section(
            title: 'Rental Time',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _row('Start', _formatDate(order.rentalStartTime)),
                _row('End', _formatDate(order.rentalEndTime)),
                _row('Actual End', _formatDate(order.actualEndTime)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _Section(
            title: 'Items',
            child: order.items.isEmpty
                ? const Text('No item data')
                : Column(
                    children: order.items.map((item) {
                      final map = item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{};
                      final toy = map['toyId'];
                      final toyMap = toy is Map ? Map<String, dynamic>.from(toy) : <String, dynamic>{};
                      final toyName = toyMap['name']?.toString() ?? 'Unknown item';
                      final qty = (map['quantity'] as num?)?.toInt() ?? 1;
                      final price = (map['rentalPrice'] as num?)?.toDouble() ?? 0;
                      final hours = (map['rentalDurationHours'] as num?)?.toInt() ?? 1;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FB),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    toyName,
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 4),
                                  Text('Qty $qty • ${hours}h • \$${price.toStringAsFixed(2)}/h'),
                                ],
                              ),
                            ),
                            Text(
                              '\$${(price * qty * (hours > 0 ? hours : 1)).toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 12),
          _Section(
            title: 'Summary',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _row('Rental Price', '\$${order.totalPrice.toStringAsFixed(2)}'),
                _row('Deposit', '\$${order.depositAmount.toStringAsFixed(2)}'),
                _row('Total', '\$${order.totalAmount.toStringAsFixed(2)}'),
                _row('Created', _formatDate(order.createdAt)),
                _row('Updated', _formatDate(order.updatedAt)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
