import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/admin_order_provider.dart';
import '../../services/admin_order_service.dart';

class AdminOrderDetailScreen extends StatefulWidget {
  final String orderId;

  const AdminOrderDetailScreen({super.key, required this.orderId});

  @override
  State<AdminOrderDetailScreen> createState() => _AdminOrderDetailScreenState();
}

class _AdminOrderDetailScreenState extends State<AdminOrderDetailScreen> {
  late Future<AdminOrderItem> _orderFuture;
  String? _newStatus;
  Timer? _countdownTimer;
  Duration? _remaining;
  String? _countdownKey;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _loadOrder() {
    _orderFuture = context.read<AdminOrderProvider>().getOrderDetails(widget.orderId);
  }

  void _startCountdown(AdminOrderItem order) {
    final nextKey = '${order.id}_${order.rentalEndTime?.toIso8601String()}_${order.orderStatus}';
    if (_countdownKey == nextKey) {
      return;
    }
    _countdownKey = nextKey;

    _countdownTimer?.cancel();

    if (order.rentalType != 'HOURLY' || order.rentalEndTime == null || order.orderStatus != 'ACTIVE') {
      _remaining = null;
      return;
    }

    void updateRemaining() {
      final diff = order.rentalEndTime!.difference(DateTime.now());
      if (!mounted) return;
      setState(() {
        _remaining = diff;
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      updateRemaining();
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      updateRemaining();
    });
  }

  Future<void> _updateStatus(AdminOrderItem order) async {
    if (_newStatus == null || _newStatus == order.orderStatus || !order.isEditable) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Update Status'),
        content: Text('Update order status to $_newStatus?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await context.read<AdminOrderProvider>().updateOrderStatus(widget.orderId, _newStatus!);
      if (!mounted) return;
      _loadOrder();
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status updated')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $e')),
      );
    }
  }

  Future<void> _endRental(AdminOrderItem order) async {
    if (order.orderStatus != 'ACTIVE') {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('End Rental'),
        content: const Text('Confirm ending this rental now?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('End Rental'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await context.read<AdminOrderProvider>().endRental(order.id);
      if (!mounted) return;
      _loadOrder();
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rental ended successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to end rental: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Invoice'),
        backgroundColor: const Color(0xFFFF6600),
      ),
      body: FutureBuilder<AdminOrderItem>(
        future: _orderFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(_loadOrder);
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final order = snapshot.data!;
          _newStatus ??= order.orderStatus;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _startCountdown(order);
          });

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(order),
                const SizedBox(height: 12),
                _buildStatusActions(order),
                const SizedBox(height: 12),
                _buildCustomerCard(order),
                const SizedBox(height: 12),
                _buildRentalInfo(order),
                const SizedBox(height: 12),
                _buildItems(order),
                const SizedBox(height: 12),
                _buildSummary(order),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(AdminOrderItem order) {
    final shortId = order.id.length > 8 ? order.id.substring(0, 8) : order.id;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF2E8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order #$shortId',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'Total: \$${order.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFFF6600),
                  ),
                ),
              ],
            ),
          ),
          _StatusBadge(status: order.orderStatus),
        ],
      ),
    );
  }

  Widget _buildStatusActions(AdminOrderItem order) {
    const statuses = ['PENDING', 'ACTIVE', 'SUCCESS', 'CANCELLED', 'FAILED'];

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
          const Text('Admin Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _newStatus,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: statuses
                .map((status) => DropdownMenuItem(
                      value: status,
                      child: Text(status),
                    ))
                .toList(),
            onChanged: order.isEditable
                ? (value) => setState(() => _newStatus = value)
                : null,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: order.isEditable ? () => _updateStatus(order) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6600),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Update Status'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: order.orderStatus == 'ACTIVE' ? () => _endRental(order) : null,
                  child: const Text('End Rental'),
                ),
              ),
            ],
          ),
          if (!order.isEditable) ...[
            const SizedBox(height: 8),
            const Text(
              'Order is locked because status is SUCCESS or CANCELLED.',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomerCard(AdminOrderItem order) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Customer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _InfoRow(label: 'Name', value: order.userName ?? 'Unknown'),
          const SizedBox(height: 6),
          _InfoRow(label: 'Email', value: order.userEmail ?? 'N/A'),
        ],
      ),
    );
  }

  Widget _buildRentalInfo(AdminOrderItem order) {
    final isExpired = _remaining != null && _remaining!.inSeconds < 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Rental Info', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _InfoRow(label: 'Type', value: order.rentalType),
          const SizedBox(height: 6),
          _InfoRow(
            label: 'Start Time',
            value: _formatDate(order.rentalStartTime),
          ),
          const SizedBox(height: 6),
          _InfoRow(
            label: 'End Time',
            value: _formatDate(order.rentalEndTime),
          ),
          const SizedBox(height: 6),
          _InfoRow(
            label: 'Actual End',
            value: _formatDate(order.actualEndTime),
          ),
          if (order.rentalType == 'HOURLY' && order.rentalEndTime != null && order.orderStatus == 'ACTIVE') ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isExpired ? Colors.red.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isExpired ? Colors.red.shade200 : Colors.orange.shade200,
                ),
              ),
              child: Text(
                isExpired
                    ? 'Đã hết thời gian thuê'
                    : 'Countdown: ${_formatDuration(_remaining!)}',
                style: TextStyle(
                  color: isExpired ? Colors.red.shade700 : Colors.orange.shade700,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItems(AdminOrderItem order) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Products', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ...order.items.asMap().entries.map((entry) {
            final item = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.toyName ?? 'Unknown product',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Qty ${item.quantity} • ${item.rentalDurationHours}h • \$${item.rentalPrice.toStringAsFixed(2)}/h',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '\$${(item.rentalPrice * item.quantity * (item.rentalDurationHours > 0 ? item.rentalDurationHours : 1)).toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildSummary(AdminOrderItem order) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Payment Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _InfoRow(label: 'Rental Price', value: '\$${order.totalPrice.toStringAsFixed(2)}'),
          const SizedBox(height: 6),
          _InfoRow(label: 'Deposit', value: '\$${order.depositAmount.toStringAsFixed(2)}'),
          const SizedBox(height: 6),
          _InfoRow(label: 'Total Amount', value: '\$${order.totalAmount.toStringAsFixed(2)}'),
          const SizedBox(height: 6),
          _InfoRow(label: 'Payment Method', value: order.paymentMethod.toUpperCase()),
          const SizedBox(height: 6),
          _InfoRow(label: 'Payment Status', value: order.paymentStatus.toUpperCase()),
          const SizedBox(height: 6),
          _InfoRow(label: 'Created At', value: _formatDate(order.createdAt)),
        ],
      ),
    );
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'N/A';
    return DateFormat('dd/MM/yyyy HH:mm').format(dt);
  }

  String _formatDuration(Duration duration) {
    final positive = duration.isNegative
        ? Duration(seconds: duration.inSeconds.abs())
        : duration;
    final hours = positive.inHours;
    final minutes = positive.inMinutes.remainder(60);
    final seconds = positive.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'PENDING' => Colors.orange,
      'ACTIVE' => Colors.blue,
      'SUCCESS' => Colors.green,
      'CANCELLED' => Colors.red,
      'FAILED' => Colors.red.shade800,
      _ => Colors.grey,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
