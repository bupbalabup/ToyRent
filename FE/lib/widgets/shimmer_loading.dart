import 'package:flutter/material.dart';

/// Shimmer loading card placeholder
class ShimmerLoadingCard extends StatefulWidget {
  const ShimmerLoadingCard({Key? key}) : super(key: key);

  @override
  State<ShimmerLoadingCard> createState() => _ShimmerLoadingCardState();
}

class _ShimmerLoadingCardState extends State<ShimmerLoadingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder
          _buildShimmer(height: 140),
          // Content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildShimmer(height: 14, width: 80),
                const SizedBox(height: 6),
                _buildShimmer(height: 12, width: 100),
                const SizedBox(height: 8),
                _buildShimmer(height: 13, width: double.infinity),
                const SizedBox(height: 4),
                _buildShimmer(height: 13, width: 120),
                const SizedBox(height: 8),
                _buildShimmer(height: 12, width: 70),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer({required double height, double? width}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(6),
      ),
      child: ShaderMask(
        shaderCallback: (bounds) {
          return LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Colors.white.withOpacity(0.0),
              Colors.white.withOpacity(0.3),
              Colors.white.withOpacity(0.0),
            ],
            stops: [
              _animController.value - 0.3,
              _animController.value,
              _animController.value + 0.3,
            ],
          ).createShader(bounds);
        },
        child: Container(
          color: Colors.white,
        ),
      ),
    );
  }
}
