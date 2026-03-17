import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/admin_category_provider.dart';
import 'admin_products_screen.dart';

class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => context.read<AdminCategoryProvider>().fetchCategories(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Category Management'),
        backgroundColor: const Color(0xFFFF6600),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoryDialog(context),
        backgroundColor: const Color(0xFFFF6600),
        child: const Icon(Icons.add),
      ),
      body: Consumer<AdminCategoryProvider>(
        builder: (context, provider, _) {
          if (provider.loading && provider.categories.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.categories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.category_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No categories yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchCategories(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: provider.categories.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final category = provider.categories[index];
                return _CategoryCard(
                  category: category,
                  onViewProducts: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AdminProductsScreen.forCategory(
                          initialCategoryId: (category as dynamic).id,
                          title: 'Products: ${(category as dynamic).name}',
                        ),
                      ),
                    );
                  },
                  onEdit: () =>
                      _showCategoryDialog(context, category: category),
                  onDelete: () =>
                      _showDeleteDialog(context, category, provider),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showCategoryDialog(
    BuildContext context, {
    Object? category,
  }) {
    final nameController = TextEditingController(
      text: (category as dynamic)?.name ?? '',
    );
    final iconController = TextEditingController(
      text: (category as dynamic)?.icon ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(category == null ? 'Add Category' : 'Edit Category'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Category Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: iconController,
                decoration: InputDecoration(
                  labelText: 'Icon (optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter category name')),
                );
                return;
              }

              try {
                if (category == null) {
                  await context.read<AdminCategoryProvider>().createCategory(
                        name: nameController.text,
                        icon: iconController.text.isEmpty
                            ? null
                            : iconController.text,
                      );
                } else {
                  await context.read<AdminCategoryProvider>().updateCategory(
                        categoryId: (category as dynamic).id,
                        name: nameController.text,
                        icon: iconController.text.isEmpty
                            ? null
                            : iconController.text,
                      );
                }

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        category == null
                            ? 'Category created'
                            : 'Category updated',
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            child: Text(category == null ? 'Create' : 'Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    Object category,
    AdminCategoryProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: const Text('Are you sure you want to delete this category?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await provider.deleteCategory((category as dynamic).id);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Category deleted')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final Object category;
  final VoidCallback onViewProducts;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryCard({
    required this.category,
    required this.onViewProducts,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final c = category as dynamic;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onViewProducts,
      child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          if (c.icon != null && c.icon!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(c.icon, style: const TextStyle(fontSize: 28)),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(
                Icons.category,
                color: Colors.grey.shade400,
              ),
            ),
          Expanded(
            child: Text(
              c.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                onTap: onEdit,
                child: const Row(
                  children: [
                    Icon(Icons.edit, size: 18),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              PopupMenuItem(
                onTap: onDelete,
                child: const Row(
                  children: [
                    Icon(Icons.delete, size: 18),
                    SizedBox(width: 8),
                    Text('Delete'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }
}
