import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../providers/cart_provider.dart';
import '../../../../providers/order_provider.dart';
import '../../../../services/location_service.dart';
import '../../../../services/order_service.dart';
import '../../../../services/payment_service.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _streetController = TextEditingController();
  final _voucherController = TextEditingController();

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 1));
  String _fulfillmentType = 'pickup';
  String _paymentMethod = 'cash';
  bool _isSubmitting = false;

  List<LocationOption> _provinces = <LocationOption>[];
  List<LocationOption> _districts = <LocationOption>[];
  List<LocationOption> _wards = <LocationOption>[];
  LocationOption? _selectedProvince;
  LocationOption? _selectedDistrict;
  LocationOption? _selectedWard;

  @override
  void initState() {
    super.initState();
    _loadProvinces();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _voucherController.dispose();
    super.dispose();
  }

  Future<void> _loadProvinces() async {
    final service = context.read<LocationService>();
    final provinces = await service.fetchProvinces();
    if (!mounted) return;
    setState(() => _provinces = provinces);
  }

  Future<void> _onProvinceChanged(LocationOption? value) async {
    if (value == null) return;
    setState(() {
      _selectedProvince = value;
      _selectedDistrict = null;
      _selectedWard = null;
      _districts = <LocationOption>[];
      _wards = <LocationOption>[];
    });

    final service = context.read<LocationService>();
    final districts = await service.fetchDistricts(value.code);
    if (!mounted) return;
    setState(() => _districts = districts);
  }

  Future<void> _onDistrictChanged(LocationOption? value) async {
    if (value == null) return;
    setState(() {
      _selectedDistrict = value;
      _selectedWard = null;
      _wards = <LocationOption>[];
    });

    final service = context.read<LocationService>();
    final wards = await service.fetchWards(value.code);
    if (!mounted) return;
    setState(() => _wards = wards);
  }

  Future<void> _pickDate({required bool start}) async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 1),
      initialDate: start ? _startDate : _endDate,
    );

    if (selected == null) return;

    setState(() {
      if (start) {
        _startDate = selected;
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate.add(const Duration(days: 1));
        }
      } else {
        _endDate = selected;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_fulfillmentType == 'delivery' &&
        (_selectedProvince == null || _selectedDistrict == null || _selectedWard == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select province, district and ward')),
      );
      return;
    }

    final cartProvider = context.read<CartProvider>();
    if (cartProvider.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart is empty')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final orderProvider = context.read<OrderProvider>();
      final paymentService = context.read<PaymentService>();

      final shippingAddress = _fulfillmentType == 'delivery'
          ? ShippingAddressPayload(
              fullName: _fullNameController.text.trim(),
              phone: _phoneController.text.trim(),
              province: _selectedProvince!.name,
              district: _selectedDistrict!.name,
              ward: _selectedWard!.name,
              street: _streetController.text.trim(),
            )
          : null;

      final order = await orderProvider.createOrder(
        items: cartProvider.items.map((e) => (e.toy, e.quantity)).toList(growable: false),
        rentalStartDate: _startDate,
        rentalEndDate: _endDate,
        fulfillmentType: _fulfillmentType,
        paymentMethod: _paymentMethod,
        shippingAddress: shippingAddress,
        voucherCode: _voucherController.text.trim().isEmpty ? null : _voucherController.text.trim(),
      );

      if (order == null) {
        throw Exception(orderProvider.error ?? 'Create order failed');
      }

      final paymentResult = await paymentService.checkout(
            orderId: order.id,
            paymentMethod: _paymentMethod,
          );

      if (!mounted) return;
      cartProvider.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            paymentResult['paymentUrl'] != null
                ? 'Order created. Open payment link from response.'
                : 'Order and payment processed successfully',
          ),
        ),
      );
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Text('Rental Dates', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickDate(start: true),
                    child: Text('Start: ${_startDate.toString().substring(0, 10)}'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickDate(start: false),
                    child: Text('End: ${_endDate.toString().substring(0, 10)}'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Delivery option', style: Theme.of(context).textTheme.titleMedium),
            SegmentedButton<String>(
              segments: const <ButtonSegment<String>>[
                ButtonSegment<String>(value: 'pickup', label: Text('Thuê tại quán')),
                ButtonSegment<String>(value: 'delivery', label: Text('Ship tận nhà')),
              ],
              selected: <String>{_fulfillmentType},
              onSelectionChanged: (selection) {
                setState(() => _fulfillmentType = selection.first);
              },
            ),
            if (_fulfillmentType == 'delivery') ...<Widget>[
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(labelText: 'Họ tên người nhận'),
                validator: (value) =>
                    _fulfillmentType == 'delivery' && (value == null || value.trim().isEmpty)
                        ? 'Required'
                        : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Số điện thoại'),
                validator: (value) =>
                    _fulfillmentType == 'delivery' && (value == null || value.trim().isEmpty)
                        ? 'Required'
                        : null,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<LocationOption>(
                initialValue: _selectedProvince,
                items: _provinces
                    .map((item) => DropdownMenuItem(value: item, child: Text(item.name)))
                    .toList(growable: false),
                onChanged: _onProvinceChanged,
                decoration: const InputDecoration(labelText: 'Tỉnh / Thành'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<LocationOption>(
                initialValue: _selectedDistrict,
                items: _districts
                    .map((item) => DropdownMenuItem(value: item, child: Text(item.name)))
                    .toList(growable: false),
                onChanged: _onDistrictChanged,
                decoration: const InputDecoration(labelText: 'Quận / Huyện'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<LocationOption>(
                initialValue: _selectedWard,
                items: _wards
                    .map((item) => DropdownMenuItem(value: item, child: Text(item.name)))
                    .toList(growable: false),
                onChanged: (value) => setState(() => _selectedWard = value),
                decoration: const InputDecoration(labelText: 'Phường / Xã'),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _streetController,
                decoration: const InputDecoration(labelText: 'Số nhà, đường'),
                validator: (value) =>
                    _fulfillmentType == 'delivery' && (value == null || value.trim().isEmpty)
                        ? 'Required'
                        : null,
              ),
            ],
            const SizedBox(height: 16),
            Text('Payment method', style: Theme.of(context).textTheme.titleMedium),
            SegmentedButton<String>(
              segments: const <ButtonSegment<String>>[
                ButtonSegment<String>(value: 'cash', label: Text('Tiền mặt')),
                ButtonSegment<String>(value: 'momo', label: Text('MoMo')),
                ButtonSegment<String>(value: 'sepay', label: Text('SePay')),
              ],
              selected: <String>{_paymentMethod},
              onSelectionChanged: (selection) {
                setState(() => _paymentMethod = selection.first);
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _voucherController,
              decoration: const InputDecoration(labelText: 'Voucher code (optional)'),
            ),
            const SizedBox(height: 16),
            Text(
              'Total: \$${cartProvider.totalPrice.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Place order'),
            ),
          ],
        ),
      ),
    );
  }
}
