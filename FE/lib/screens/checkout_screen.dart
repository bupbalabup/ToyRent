import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/api_config.dart';
import '../providers/cart_provider.dart';
import '../providers/socket_provider.dart';
import '../services/order_service.dart';
import '../services/payment_service.dart';
import 'order_history_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final List<String> selectedItems;

  const CheckoutScreen({
    Key? key,
    required this.selectedItems,
  }) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Checkout',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
          ),
        ),
        centerTitle: false,
        automaticallyImplyLeading: true,
      ),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, _) {
          final selectedItems =
              cartProvider.getSelectedItems(widget.selectedItems);

          if (selectedItems.isEmpty) {
            return const Center(
              child: Text('No selected items'),
            );
          }

          return _buildCheckoutContent(context, selectedItems, cartProvider);
        },
      ),
    );
  }

  Widget _buildCheckoutContent(
    BuildContext context,
    List<CartItem> selectedItems,
    CartProvider cartProvider,
  ) {
    double totalRental = selectedItems.fold<double>(
      0,
      (sum, item) => sum + item.rentalTotal,
    );
    double totalDeposit = selectedItems.fold<double>(
      0,
      (sum, item) => sum + item.depositTotal,
    );
    double totalAmount = totalRental + totalDeposit;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // Order Summary
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFE0E0E0),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Order Summary',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Items List
                  ...selectedItems.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  maxLines: 1,
                                  overflow:
                                      TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight:
                                        FontWeight.w600,
                                    color:
                                        Color(0xFF1A1A1A),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${item.rentalDurationHours} hours × Qty ${item.quantity}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color:
                                        Color(0xFF999999),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '\$${item.itemTotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight:
                                  FontWeight.w700,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(
                    color: Color(0xFFE0E0E0),
                    height: 16,
                  ),
                  // Totals
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Rental Total:',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF666666),
                        ),
                      ),
                      Text(
                        '\$${totalRental.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Deposit:',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF666666),
                        ),
                      ),
                      Text(
                        '\$${totalDeposit.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEDDD),
                      borderRadius:
                          BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Order Total:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        Text(
                          '\$${totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFFF6600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Error Message
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFEF5350),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Color(0xFFEF5350),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFEF5350),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Payment Method
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFE0E0E0),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment Method',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFFF6600),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.payment,
                          size: 24,
                          color:
                              const Color(0xFFFF6600),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Text(
                                'PayPal',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight:
                                      FontWeight.w700,
                                  color: Color(
                                      0xFF1A1A1A),
                                ),
                              ),
                              SizedBox(
                                height: 2,
                              ),
                              Text(
                                'Secure online payment',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(
                                      0xFF666666),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.check_circle,
                          color: Color(0xFFFF6600),
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Pay Button
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed:
                    _isLoading
                        ? null
                        : () =>
                            _handlePayment(
                              context,
                              selectedItems,
                              totalAmount,
                            ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFFFF6600),
                  disabledBackgroundColor:
                      const Color(0xFFFFCC99),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<
                                  Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        'Pay \$${totalAmount.toStringAsFixed(2)} with PayPal',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight:
                              FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePayment(
    BuildContext context,
    List<CartItem> selectedItems,
    double totalAmount,
  ) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final orderService = OrderService();
      final paymentService = PaymentService();

      // Create order items
      final items = selectedItems
          .map(
            (item) => OrderItem(
              toyId: item.productId,
              rentalPrice: item.rentalPrice,
              rentalDurationHours:
                  item.rentalDurationHours,
              quantity: item.quantity,
            ),
          )
          .toList();

      final startDate = DateTime.now().add(const Duration(minutes: 10));
      final maxDurationHours = selectedItems
          .map((item) => item.rentalDurationHours)
          .fold<int>(1, (a, b) => a > b ? a : b);
      final endDate = startDate.add(Duration(hours: maxDurationHours));

      // Create order
      final order = await orderService.createOrder(
        CreateOrderRequest(
          items: items,
          paymentMethod: 'paypal',
          rentalStartDate: startDate.toIso8601String(),
          rentalEndDate: endDate.toIso8601String(),
          rentalDurationHours: maxDurationHours,
        ),
      );

      // Set up real-time payment listener via socket
      final socketProvider = context.read<SocketProvider>();
      var paymentSucceeded = false;
      
      socketProvider.onPaymentSuccess((paymentData) {
        if (paymentData['orderId'] == order.id) {
          paymentSucceeded = true;
          
          if (context.mounted) {
            setState(() => _isLoading = false);

            // Clear cart and navigate immediately on payment success
            Provider.of<CartProvider>(
              context,
              listen: false,
            ).clearCart();

            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
              (route) => route.isFirst,
            );
          }
        }
      });

      socketProvider.onPaymentFailed((paymentData) {
        if (paymentData['orderId'] == order.id) {
          if (context.mounted) {
            setState(() {
              _isLoading = false;
              _errorMessage = paymentData['reason'] ?? 'Payment failed. Please try again.';
            });
          }
        }
      });

      // Initiate checkout
      final checkout = await paymentService.checkout(
        orderId: order.id,
        paymentMethod: 'paypal',
        returnUrl: '${ApiConfig.baseUrl.replaceFirst('/api', '')}/api/payment/success',
      );

      // Open payment URL
      if (checkout.paymentUrl != null && checkout.paypalOrderId != null) {
        final String paymentUrl = checkout.paymentUrl!;
        if (await canLaunchUrl(Uri.parse(paymentUrl))) {
          await launchUrl(
            Uri.parse(paymentUrl),
            mode: LaunchMode.externalApplication,
          );

          if (context.mounted) {
            setState(() => _isLoading = false);

            await Future.delayed(
              const Duration(seconds: 3),
            );

            if (context.mounted && !paymentSucceeded) {
              try {
                await paymentService.capturePayment(order.id, checkout.paypalOrderId!);
                final payment = await paymentService.syncPaymentStatus(order.id, checkout.paypalOrderId!);

                if (payment.paymentStatus == 'paid') {
                  if (context.mounted) {
                    Provider.of<CartProvider>(
                      context,
                      listen: false,
                    ).clearCart();

                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
                      (route) => route.isFirst,
                    );
                  }
                } else {
                  setState(() {
                    _errorMessage =
                        'Payment not completed. Please try again.';
                  });
                }
              } catch (syncError) {
                setState(() {
                  _errorMessage = 'Could not verify payment status. Please check your account.';
                });
              }
            }
          }
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }
}
