import 'package:flutter/material.dart';

import '../../services/admin_order_service.dart';
import '../../services/admin_product_service.dart';
import 'admin_orders_screen.dart';
import 'admin_product_form_screen.dart';

class AdminOverviewScreen extends StatefulWidget {
  const AdminOverviewScreen({super.key});

  @override
  State<AdminOverviewScreen> createState() => _AdminOverviewScreenState();
}

class _AdminOverviewScreenState extends State<AdminOverviewScreen> {
  final AdminProductService _productService = AdminProductService();
  final AdminOrderService _orderService = AdminOrderService();

  late Future<Map<String, dynamic>> _productStats;
  late Future<Map<String, dynamic>> _orderStats;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  void _loadStats() {
    _productStats = _productService.getProductStats();
    _orderStats = _orderService.getOrderStats();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        setState(_loadStats);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 16),
          const Text(
            'Dashboard Overview',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          // Product Stats
          FutureBuilder<Map<String, dynamic>>(
            future: _productStats,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const _StatCardSkeleton();
              }
              final data = snapshot.data ?? {};
              return _StatCard(
                title: 'Total Products',
                value: '${data['totalProducts'] ?? 0}',
                icon: Icons.shopping_bag,
                color: Colors.blue,
              );
            },
          ),
          const SizedBox(height: 12),
          // Order Stats
          FutureBuilder<Map<String, dynamic>>(
            future: _orderStats,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const _StatCardSkeleton();
              }
              final data = snapshot.data ?? {};
              return Column(
                children: [
                  _StatCard(
                    title: 'Total Orders',
                    value: '${data['totalOrders'] ?? 0}',
                    icon: Icons.receipt,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 12),
                  _StatCard(
                    title: 'Pending Orders',
                    value: '${data['pendingOrders'] ?? 0}',
                    icon: Icons.schedule,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 12),
                  _StatCard(
                    title: 'Total Revenue',
                    value: '\$${(data['totalRevenue'] ?? 0.0).toStringAsFixed(2)}',
                    icon: Icons.trending_up,
                    color: Colors.purple,
                  ),
                  const SizedBox(height: 12),
                  _StatCard(
                    title: 'Completed Orders',
                    value: '${data['completedOrders'] ?? 0}',
                    icon: Icons.check_circle,
                    color: Colors.teal,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 32),
          // Quick Actions
          const Text(
            'Quick Actions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _QuickActionButton(
                  label: 'Add Product',
                  icon: Icons.add,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AdminProductFormScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionButton(
                  label: 'View Orders',
                  icon: Icons.list,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AdminOrdersScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCardSkeleton extends StatelessWidget {
  const _StatCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      height: 80,
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _QuickActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFF6600),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }
}
