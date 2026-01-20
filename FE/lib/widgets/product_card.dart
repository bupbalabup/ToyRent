import 'package:flutter/material.dart';

/// Beautiful product card component
class ProductCard extends StatefulWidget {
  final String id;
  final String name;
  final double rentalPrice;
  final double depositAmount;
  final String? imageUrl;
  final bool inStock;
  final VoidCallback onTap;

  const ProductCard({
    Key? key,
    required this.id,
    required this.name,
    required this.rentalPrice,
    required this.depositAmount,
    this.imageUrl,
    required this.inStock,
    required this.onTap,
  }) : super(key: key);

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onTapDown() {
    _animController.forward();
  }

  void _onTapUp() {
    _animController.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    _animController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 1.0, end: 0.95).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
      ),
      child: GestureDetector(
        onTapDown: (_) => _onTapDown(),
        onTapUp: (_) => _onTapUp(),
        onTapCancel: _onTapCancel,
        child: _buildCard(),
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            _buildImage(),
            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Price Section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '\$${widget.rentalPrice.toStringAsFixed(2)}/day',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFFF6600),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Deposit: \$${widget.depositAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF999999),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Name
                  Text(
                    widget.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Stock Status
                  _buildStockStatus(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    return Hero(
      tag: 'product_image_${widget.id}',
      flightShuttleBuilder: (flightContext, animation, flightDirection,
          fromContext, toContext) {
        return Material(
          color: Colors.transparent,
          child: ScaleTransition(
            scale: animation.drive(
              Tween<double>(begin: 0.0, end: 1.0),
            ),
            child: toContext.widget,
          ),
        );
      },
      child: Container(
        width: double.infinity,
        height: 140,
        color: const Color(0xFFF5F5F5),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image
            if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty)
              Image.network(
                widget.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildPlaceholder();
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        strokeWidth: 2,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFFFF6600),
                        ),
                      ),
                    ),
                  );
                },
              )
            else
              _buildPlaceholder(),
            // Out of stock overlay
            if (!widget.inStock)
              Container(
                color: Colors.black.withOpacity(0.4),
                child: const Center(
                  child: Text(
                    'Out of Stock',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFFF8F9FB),
      child: const Center(
        child: Icon(
          Icons.shopping_bag_outlined,
          size: 48,
          color: Color(0xFFDDDDDD),
        ),
      ),
    );
  }

  Widget _buildStockStatus() {
    if (widget.inStock) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'In Stock',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4CAF50),
          ),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'Out of Stock',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFFEF5350),
          ),
        ),
      );
    }
  }
}
