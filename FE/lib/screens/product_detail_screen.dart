import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../services/rental_service.dart';
import 'paypal_webview_screen.dart';

/// Product Detail Screen with Hero animation
class ProductDetailScreen extends StatefulWidget {
  final String productId;
  final String name;
  final double rentalPrice;
  final double depositAmount;
  final String? imageUrl;
  final bool inStock;

  const ProductDetailScreen({
    Key? key,
    required this.productId,
    required this.name,
    required this.rentalPrice,
    required this.depositAmount,
    this.imageUrl,
    required this.inStock,
  }) : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late ScrollController _scrollController;
  final RentalService _rentalService = RentalService();
  bool _isAppBarCollapsed = false;
  bool _processingCheckout = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    bool isCollapsed = _scrollController.offset > 200;
    if (isCollapsed != _isAppBarCollapsed) {
      setState(() {
        _isAppBarCollapsed = isCollapsed;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Sticky AppBar with collapse animation
          SliverAppBar(
            backgroundColor: _isAppBarCollapsed
                ? const Color(0xFFFFFFFF)
                : Colors.transparent,
            elevation: _isAppBarCollapsed ? 2 : 0,
            scrolledUnderElevation: 0,
            pinned: true,
            automaticallyImplyLeading: true,
            leading: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Color(0xFF1A1A1A),
                  size: 24,
                ),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.favorite_outline,
                  color: Color(0xFFFF6600),
                  size: 24,
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
          // Hero Image
          SliverAppBar(
            backgroundColor: Colors.transparent,
            expandedHeight: 300,
            elevation: 0,
            scrolledUnderElevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'product_image_${widget.productId}',
                child: Container(
                  color: const Color(0xFFF5F5F5),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty)
                        Image.network(
                          widget.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.broken_image_outlined,
                              size: 48,
                              color: Color(0xFFDDDDDD),
                            );
                          },
                        )
                      else
                        const Icon(
                          Icons.shopping_bag_outlined,
                          size: 48,
                          color: Color(0xFFDDDDDD),
                        ),
                      // Stock status overlay
                      if (!widget.inStock)
                        Container(
                          color: Colors.black.withOpacity(0.5),
                          child: const Center(
                            child: Text(
                              'Out of Stock',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Product Details
          SliverToBoxAdapter(
            child: _buildProductDetails(),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildProductDetails() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Name
            Text(
              widget.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
                height: 1.3,
              ),
            ),
            const SizedBox(height: 16),

            // Stock Status
            if (widget.inStock)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'In Stock',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4CAF50),
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Out of Stock',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFEF5350),
                  ),
                ),
              ),
            const SizedBox(height: 20),

            // Pricing Section
            Container(
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
                    'Pricing',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Daily Rental',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF666666),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '\$${widget.rentalPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFFF6600),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: const Color(0xFFDDDDDD),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Security Deposit',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF666666),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '\$${widget.depositAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Description Section
            const Text(
              'About this product',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Premium quality toy available for rent. Perfect for children aged 5 and above. Comes with all original accessories and instructions. Must be returned in clean condition.',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF666666),
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Features Section
            const Text(
              'Features',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 12),
            _buildFeatureItem('✓', 'Cleaned and sanitized before each rental'),
            _buildFeatureItem('✓', 'Includes all original parts and accessories'),
            _buildFeatureItem('✓', 'Instructions and manual provided'),
            _buildFeatureItem('✓', 'Flexible rental duration'),
            _buildFeatureItem('✓', 'Easy return process'),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            icon,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFFFF6600),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF666666),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: widget.inStock && !_processingCheckout
                    ? _startCheckout
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6600),
                  disabledBackgroundColor: const Color(0xFFFFCC99),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
                child: _processingCheckout
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Rent Now',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startCheckout() async {
    final paymentMethod = await _pickPaymentMethod();
    if (paymentMethod == null) {
      return;
    }

    setState(() {
      _processingCheckout = true;
    });

    try {
      final now = DateTime.now();
      final startDate = now.add(const Duration(minutes: 10));
      final endDate = startDate.add(const Duration(hours: 24));

      final order = await _rentalService.createOrder(
        toyId: widget.productId,
        quantity: 1,
        rentalDurationHours: 24,
        startDate: startDate,
        endDate: endDate,
        paymentMethod: paymentMethod,
      );

      if (paymentMethod == 'cash') {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order placed. Cash payment recorded.')),
        );
        Navigator.of(context).pop();
        return;
      }

      final checkout = await _rentalService.checkout(
        orderId: order.id,
        paymentMethod: paymentMethod,
        returnUrl: '${ApiConfig.baseUrl}/payment/success',
      );

      if (checkout.paymentUrl == null || checkout.paypalOrderId == null) {
        throw Exception('PayPal checkout URL was not returned by server');
      }

      if (!mounted) return;
      final result = await Navigator.of(context).push<PaypalWebviewResult>(
        MaterialPageRoute(
          builder: (_) => PaypalWebviewScreen(paymentUrl: checkout.paymentUrl!),
        ),
      );

      if (!mounted || result == null || result.cancelled || !result.success) {
        return;
      }

      final paypalOrderId = result.paypalOrderId ?? checkout.paypalOrderId;
      if (paypalOrderId == null || paypalOrderId.isEmpty) {
        throw Exception('Missing PayPal order id from callback');
      }

      await _rentalService.capturePaypalPayment(
        orderId: order.id,
        paypalOrderId: paypalOrderId,
      );

      await _rentalService.syncPaypalPayment(
        orderId: order.id,
        paypalOrderId: paypalOrderId,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment successful. Order confirmed.')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Checkout failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _processingCheckout = false;
        });
      }
    }
  }

  Future<String?> _pickPaymentMethod() async {
    return showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.payments_outlined),
                title: const Text('Cash'),
                subtitle: const Text('Confirm order immediately'),
                onTap: () => Navigator.of(context).pop('cash'),
              ),
              ListTile(
                leading: const Icon(Icons.account_balance_wallet_outlined),
                title: const Text('PayPal'),
                subtitle: const Text('Complete payment in PayPal'),
                onTap: () => Navigator.of(context).pop('paypal'),
              ),
            ],
          ),
        );
      },
    );
  }
}
