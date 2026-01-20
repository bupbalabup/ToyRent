import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../providers/category_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/product_card.dart';
import '../widgets/shimmer_loading.dart';
import 'order_history_screen.dart';
import 'product_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late TextEditingController _searchController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late ScrollController _scrollController;
  late AnimationController _categoryAnimationController;
  int _currentBannerIndex = 0;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _scrollController = ScrollController();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _categoryAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    // Trigger animations and load data
    Future.microtask(() {
      _fadeController.forward();
      _loadInitialData();
    });

    // Listen for scroll to load more
    _scrollController.addListener(_onScroll);
  }

  void _loadInitialData() {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);

    productProvider.fetchProducts();
    categoryProvider.fetchCategories();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 500) {
      // User scrolled near bottom - load more
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      productProvider.loadMore();
    }
  }

  void _handleSearch() {
    final query = _searchController.text.trim();
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    productProvider.searchProducts(query);
  }

  void _clearSearch() {
    _searchController.clear();
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    productProvider.fetchProducts();
  }

  Future<void> _handleRefresh() async {
    _loadInitialData();
    // Wait a bit for the refresh indicator to show
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fadeController.dispose();
    _categoryAnimationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFFFFF),
        body: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: const Color(0xFFFF6600),
          backgroundColor: Colors.white,
          displacement: 40.0,
          child: _buildCustomScrollView(),
        ),
      ),
    );
  }

  Widget _buildCustomScrollView() {
    return CustomScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Sticky AppBar
        SliverAppBar(
          backgroundColor: const Color(0xFFFFFFFF),
          elevation: 0,
          scrolledUnderElevation: 2,
          floating: true,
          snap: true,
          pinned: false,
          automaticallyImplyLeading: false,
          title: const Text(
            'RentToys',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFFFF6600),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(
                Icons.receipt_long_outlined,
                color: Color(0xFF1A1A1A),
                size: 24,
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
                );
              },
            ),
            IconButton(
              icon: const Icon(
                Icons.logout,
                color: Color(0xFF1A1A1A),
                size: 24,
              ),
              onPressed: () {
                Provider.of<AuthProvider>(context, listen: false).logout();
              },
            ),
          ],
        ),
        // Main content
        SliverToBoxAdapter(
          child: _buildBody(),
        ),
      ],
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Search Bar
          _buildSearchBar(),
          const SizedBox(height: 20),
          // Banner Carousel
          _buildBannerCarousel(),
          const SizedBox(height: 12),
          // Banner Indicators
          _buildBannerIndicators(),
          // Categories Section
          _buildCategoriesSection(),
          const SizedBox(height: 24),
          // Popular Toys Section
          _buildPopularToysSection(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FB),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: 'Search toys, games...',
            hintStyle: const TextStyle(
              color: Color(0xFFBDBDBD),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.all(12),
              child: Icon(
                Icons.search,
                color: const Color(0xFFA0A0A0),
                size: 20,
              ),
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? GestureDetector(
                    onTap: _clearSearch,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Icon(
                        Icons.close,
                        color: const Color(0xFFA0A0A0),
                        size: 20,
                      ),
                    ),
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
          ),
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _handleSearch(),
          style: const TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildBannerCarousel() {
    final banners = [
      const Color(0xFFFF6600),
      const Color(0xFFFF8A00),
      const Color(0xFFFF5500),
    ];

    return SizedBox(
      height: 160,
      child: PageView.builder(
        onPageChanged: (index) => setState(() => _currentBannerIndex = index),
        itemCount: banners.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    banners[index],
                    banners[index].withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: banners[index].withOpacity(0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Special Offer',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Up to 40% off\non rental prices',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    right: 20,
                    child: Icon(
                      Icons.shopping_bag,
                      size: 80,
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBannerIndicators() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          3,
          (index) => Container(
            width: index == _currentBannerIndex ? 24 : 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: index == _currentBannerIndex
                  ? const Color(0xFFFF6600)
                  : const Color(0xFFDDDDDD),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return Consumer<CategoryProvider>(
      builder: (context, categoryProvider, _) {
        if (categoryProvider.isLoading) {
          return _buildCategoriesLoading();
        }

        final categories = categoryProvider.categories;
        if (categories.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Categories',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildCategoryChip(
                    name: 'All',
                    icon: Icons.all_inclusive,
                    isSelected: categoryProvider.selectedCategoryId == null,
                    onTap: () {
                      categoryProvider.clearSelection();
                      final productProvider =
                          Provider.of<ProductProvider>(context, listen: false);
                      productProvider.filterByCategory(null);
                    },
                  ),
                  ...categories.map((category) {
                    return _buildCategoryChip(
                      name: category.name,
                      icon: _getCategoryIcon(category.icon),
                      isSelected: categoryProvider.selectedCategoryId == category.id,
                      onTap: () {
                        categoryProvider.selectCategory(category.id);
                        final productProvider =
                            Provider.of<ProductProvider>(context, listen: false);
                        productProvider.filterByCategory(category.id);
                      },
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryChip({
    required String name,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        // Trigger animation on selection change
        _categoryAnimationController.forward(from: 0.0);
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            ScaleTransition(
              scale: Tween<double>(begin: 1.0, end: 1.05).animate(
                CurvedAnimation(
                  parent: _categoryAnimationController,
                  curve: Curves.elasticOut,
                ),
              ),
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFFF6600)
                      : const Color(0xFFF8F9FB),
                  borderRadius: BorderRadius.circular(16),
                  border: isSelected
                      ? null
                      : Border.all(
                          color: const Color(0xFFE0E0E0),
                          width: 1.5,
                        ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFFFF6600).withOpacity(0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  icon,
                  color: isSelected ? Colors.white : const Color(0xFFFF6600),
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 70,
              child: Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? const Color(0xFFFF6600)
                      : const Color(0xFF666666),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String? icon) {
    switch (icon?.toLowerCase()) {
      case 'action':
        return Icons.sports_basketball;
      case 'adventure':
        return Icons.explore;
      case 'puzzle':
        return Icons.extension;
      case 'educational':
        return Icons.school;
      case 'outdoor':
        return Icons.park;
      case 'sports':
        return Icons.sports_soccer;
      default:
        return Icons.shopping_bag;
    }
  }

  Widget _buildCategoriesLoading() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 100,
        child: ListView(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          children: List.generate(4, (index) {
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Column(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 60,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildPopularToysSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Popular Toys',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              GestureDetector(
                onTap: () {
                  // TODO: Navigate to see all
                },
                child: const Text(
                  'See All',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFF6600),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Consumer<ProductProvider>(
          builder: (context, productProvider, _) {
            // Loading state
            if (productProvider.isLoading) {
              return _buildProductsLoading();
            }

            // Error state
            if (productProvider.errorMessage != null) {
              return _buildErrorState(
                message: productProvider.errorMessage!,
                onRetry: _loadInitialData,
              );
            }

            // Empty state
            if (productProvider.products.isEmpty) {
              return _buildEmptyState();
            }

            // Products grid
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.45,
                    ),
                    itemCount: productProvider.products.length,
                    itemBuilder: (context, index) {
                      final product = productProvider.products[index];
                      return ProductCard(
                        id: product.id,
                        name: product.name,
                        rentalPrice: product.rentalPrice,
                        depositAmount: product.depositAmount,
                        imageUrl: product.imageUrl,
                        inStock: product.inStock,
                        onTap: () {
                          // Navigate to product detail with Hero animation
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ProductDetailScreen(
                                productId: product.id,
                                name: product.name,
                                rentalPrice: product.rentalPrice,
                                depositAmount: product.depositAmount,
                                imageUrl: product.imageUrl,
                                inStock: product.inStock,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  // Load more button
                  if (productProvider.hasMore)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: _buildLoadMoreButton(productProvider),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLoadMoreButton(ProductProvider productProvider) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: productProvider.isLoadingMore
            ? null
            : () => productProvider.loadMore(),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF6600),
          disabledBackgroundColor: const Color(0xFFFFCC99),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: productProvider.isLoadingMore
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withOpacity(0.8),
                  ),
                ),
              )
            : const Text(
                'Load More',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildProductsLoading() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 16,
          childAspectRatio: 0.45,
        ),
        itemCount: 6,
        itemBuilder: (context, index) => const ShimmerLoadingCard(),
      ),
    );
  }

  Widget _buildErrorState({
    required String message,
    required VoidCallback onRetry,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: const Color(0xFFEF5350),
          ),
          const SizedBox(height: 12),
          const Text(
            'Oops! Something went wrong',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6600),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Try Again',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 48,
            color: const Color(0xFFDDDDDD),
          ),
          const SizedBox(height: 12),
          const Text(
            'No toys found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try adjusting your search or filters',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }
}
