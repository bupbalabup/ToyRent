import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/category_provider.dart';
import '../providers/product_provider.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({Key? key}) : super(key: key);

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<CategoryProvider>(context, listen: false).fetchCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Categories',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
          ),
        ),
        centerTitle: false,
        automaticallyImplyLeading: false,
      ),
      body: Consumer<CategoryProvider>(
        builder: (context, categoryProvider, _) {
          if (categoryProvider.isLoading) {
            return _buildLoadingState();
          }

          if (categoryProvider.categories.isEmpty) {
            return _buildEmptyState();
          }

          return _buildCategoriesList(categoryProvider);
        },
      ),
    );
  }

  Widget _buildCategoriesList(CategoryProvider categoryProvider) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // All button
          Padding(
            padding: const EdgeInsets.all(16),
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedCategoryId = null);
                Provider.of<ProductProvider>(context, listen: false)
                    .filterByCategory(null);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _selectedCategoryId == null
                      ? const Color(0xFFFF6600)
                      : const Color(0xFFF8F9FB),
                  borderRadius: BorderRadius.circular(16),
                  border: _selectedCategoryId == null
                      ? null
                      : Border.all(
                          color: const Color(0xFFE0E0E0),
                          width: 1.5,
                        ),
                  boxShadow: _selectedCategoryId == null
                      ? [
                          BoxShadow(
                            color:
                                const Color(0xFFFF6600).withOpacity(0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.all_inclusive,
                      size: 32,
                      color: _selectedCategoryId == null
                          ? Colors.white
                          : const Color(0xFFFF6600),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'All Categories',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _selectedCategoryId == null
                            ? Colors.white
                            : const Color(0xFF1A1A1A),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Category list
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: categoryProvider.categories.length,
            itemBuilder: (context, index) {
              final category = categoryProvider.categories[index];
              final isSelected = _selectedCategoryId == category.id;

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: GestureDetector(
                  onTap: () {
                    setState(() => _selectedCategoryId = category.id);
                    Provider.of<ProductProvider>(context, listen: false)
                        .filterByCategory(category.id);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
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
                                color: const Color(0xFFFF6600)
                                    .withOpacity(0.2),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getCategoryIcon(category.icon),
                          size: 32,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFFFF6600),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                category.name,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF1A1A1A),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF999999),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                Color(0xFFFF6600),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Loading categories...',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.category_outlined,
            size: 64,
            color: const Color(0xFFDDDDDD),
          ),
          const SizedBox(height: 16),
          const Text(
            'No categories found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Check back later',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
            ),
          ),
        ],
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
        return Icons.sports_football;
      default:
        return Icons.shopping_bag;
    }
  }
}
