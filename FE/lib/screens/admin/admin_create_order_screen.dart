import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/admin_order_provider.dart';
import '../../services/admin_order_service.dart';
import '../../services/admin_product_service.dart';
import '../../services/admin_user_service.dart';

class AdminCreateOrderScreen extends StatefulWidget {
  const AdminCreateOrderScreen({super.key});

  @override
  State<AdminCreateOrderScreen> createState() => _AdminCreateOrderScreenState();
}

class _AdminCreateOrderScreenState extends State<AdminCreateOrderScreen> {
  final AdminUserService _userService = AdminUserService();
  final AdminProductService _productService = AdminProductService();

  final List<_OrderLine> _lines = [
    _OrderLine(),
  ];

  bool _loadingOptions = true;
  bool _submitting = false;
  String? _selectedUserId;
  String _rentalType = 'HOURLY';
  int _durationHours = 1;
  String? _error;

  List<AdminUserItem> _users = [];
  List<AdminProductItem> _products = [];

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    setState(() {
      _loadingOptions = true;
      _error = null;
    });

    try {
      final usersPage = await _userService.getAllUsers(status: 'active', limit: 100);
      final products = await _productService.getAllProducts(limit: 100);

      if (!mounted) return;
      setState(() {
        _users = usersPage.users.where((u) => u.role == 'user').toList();
        _products = products.where((p) => p.isActive && p.stock > 0).toList();
        _loadingOptions = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loadingOptions = false;
      });
    }
  }

  Future<void> _submit() async {
    final selectedLines = _lines.where((line) => line.productId != null && line.quantity > 0).toList();

    if (_selectedUserId == null || selectedLines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select user and at least one product')),
      );
      return;
    }

    if (_rentalType == 'HOURLY' && _durationHours < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Duration must be at least 1 hour')),
      );
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      await context.read<AdminOrderProvider>().createOrderByAdmin(
            userId: _selectedUserId!,
            items: selectedLines
                .map((line) => AdminCreateOrderItem(
                      toyId: line.productId!,
                      quantity: line.quantity,
                    ))
                .toList(),
            rentalType: _rentalType,
            durationHours: _rentalType == 'HOURLY' ? _durationHours : null,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rental started successfully')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create order: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Rental Order'),
        backgroundColor: const Color(0xFFFF6600),
      ),
      body: _loadingOptions
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _loadOptions, child: const Text('Retry')),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text('Customer', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedUserId,
                      items: _users
                          .map((u) => DropdownMenuItem(
                                value: u.id,
                                child: Text('${u.name} (${u.email})'),
                              ))
                          .toList(),
                      onChanged: _submitting ? null : (value) => setState(() => _selectedUserId = value),
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    const Text('Rental Type', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _rentalType,
                      items: const [
                        DropdownMenuItem(value: 'HOURLY', child: Text('HOURLY')),
                        DropdownMenuItem(value: 'MANUAL', child: Text('MANUAL')),
                      ],
                      onChanged: _submitting
                          ? null
                          : (value) {
                              if (value != null) {
                                setState(() => _rentalType = value);
                              }
                            },
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                    ),
                    if (_rentalType == 'HOURLY') ...[
                      const SizedBox(height: 12),
                      const Text('Duration (hours)', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          IconButton(
                            onPressed: _submitting || _durationHours <= 1
                                ? null
                                : () => setState(() => _durationHours -= 1),
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          Text('$_durationHours h', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          IconButton(
                            onPressed: _submitting
                                ? null
                                : () => setState(() => _durationHours += 1),
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    const Text('Products', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ..._lines.asMap().entries.map((entry) {
                      final index = entry.key;
                      final line = entry.value;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              DropdownButtonFormField<String>(
                                value: line.productId,
                                items: _products
                                    .map((p) => DropdownMenuItem(
                                          value: p.id,
                                          child: Text('${p.name} (Stock: ${p.stock})'),
                                        ))
                                    .toList(),
                                onChanged: _submitting
                                    ? null
                                    : (value) {
                                        setState(() {
                                          line.productId = value;
                                        });
                                      },
                                decoration: const InputDecoration(
                                  labelText: 'Product',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Text('Qty'),
                                  const SizedBox(width: 12),
                                  IconButton(
                                    onPressed: _submitting || line.quantity <= 1
                                        ? null
                                        : () => setState(() => line.quantity -= 1),
                                    icon: const Icon(Icons.remove),
                                  ),
                                  Text('${line.quantity}'),
                                  IconButton(
                                    onPressed: _submitting
                                        ? null
                                        : () => setState(() => line.quantity += 1),
                                    icon: const Icon(Icons.add),
                                  ),
                                  const Spacer(),
                                  if (_lines.length > 1)
                                    TextButton.icon(
                                      onPressed: _submitting
                                          ? null
                                          : () => setState(() => _lines.removeAt(index)),
                                      icon: const Icon(Icons.delete_outline),
                                      label: const Text('Remove'),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: _submitting
                            ? null
                            : () => setState(() => _lines.add(_OrderLine())),
                        icon: const Icon(Icons.add),
                        label: const Text('Add product'),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6600),
                          foregroundColor: Colors.white,
                        ),
                        child: _submitting
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Start Rental'),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _OrderLine {
  String? productId;
  int quantity;

  _OrderLine()
      : productId = null,
        quantity = 1;
}
