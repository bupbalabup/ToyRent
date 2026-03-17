import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/admin_category_provider.dart';
import '../../providers/admin_product_provider.dart';
import '../../services/admin_product_service.dart';

class AdminProductFormScreen extends StatefulWidget {
  final AdminProductItem? product;

  const AdminProductFormScreen({super.key, this.product});

  @override
  State<AdminProductFormScreen> createState() => _AdminProductFormScreenState();
}

class _AdminProductFormScreenState extends State<AdminProductFormScreen> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _depositController;
  late TextEditingController _stockController;
  late TextEditingController _imageUrlController;

  String? _selectedCategoryId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.product?.description ?? '');
    _priceController = TextEditingController(
      text: (widget.product?.rentalPrice ?? 0).toString(),
    );
    _depositController = TextEditingController(
      text: (widget.product?.depositAmount ?? 0).toString(),
    );
    _stockController = TextEditingController(
      text: (widget.product?.stock ?? 0).toString(),
    );
    _imageUrlController = TextEditingController(
      text: widget.product?.images.isNotEmpty == true
          ? widget.product!.images.join('\n')
          : (widget.product?.imageUrl ?? ''),
    );
    _selectedCategoryId = widget.product?.categoryId;

    Future.microtask(
      () => context.read<AdminCategoryProvider>().fetchCategories(),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _depositController.dispose();
    _stockController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    final categoryProvider = context.read<AdminCategoryProvider>();
    final availableCategoryIds = categoryProvider.categories.map((c) => c.id).toSet();

    final parsedImages = _imageUrlController.text
      .split(RegExp(r'[\n,]'))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

    if (_nameController.text.isEmpty ||
        _priceController.text.isEmpty ||
        _depositController.text.isEmpty ||
        _stockController.text.isEmpty ||
      parsedImages.isEmpty ||
        _selectedCategoryId == null ||
        !availableCategoryIds.contains(_selectedCategoryId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields and select a valid category')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final provider = context.read<AdminProductProvider>();

      if (widget.product == null) {
        // Create new product
        await provider.createProduct(
          name: _nameController.text,
          description: _descriptionController.text,
          rentalPrice: double.parse(_priceController.text),
          depositAmount: double.parse(_depositController.text),
          stock: int.parse(_stockController.text),
          categoryId: _selectedCategoryId!,
          images: parsedImages,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product created successfully')),
          );
          Navigator.pop(context);
        }
      } else {
        // Update existing product
        await provider.updateProduct(
          productId: widget.product!.id,
          name: _nameController.text,
          description: _descriptionController.text,
          rentalPrice: double.parse(_priceController.text),
          depositAmount: double.parse(_depositController.text),
          stock: int.parse(_stockController.text),
          categoryId: _selectedCategoryId!,
          images: parsedImages,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product updated successfully')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'Add Product' : 'Edit Product'),
        backgroundColor: const Color(0xFFFF6600),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTextField(
              controller: _nameController,
              label: 'Product Name',
              hint: 'Enter product name',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _descriptionController,
              label: 'Description',
              hint: 'Enter product description',
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _imageUrlController,
              label: 'Image URLs (one per line or comma-separated)',
              hint: 'https://example.com/toy-1.jpg',
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            Consumer<AdminCategoryProvider>(
              builder: (context, categoryProvider, _) {
                return _buildCategoryDropdown(categoryProvider);
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _priceController,
              label: 'Rental Price per Hour (\$)',
              hint: 'Enter hourly rental price',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _depositController,
              label: 'Refundable Deposit (\$)',
              hint: 'Returned after toy is returned safely',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _stockController,
              label: 'Stock Quantity',
              hint: 'Enter stock quantity',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6600),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : Text(widget.product == null ? 'Create Product' : 'Update Product'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown(AdminCategoryProvider categoryProvider) {
    final categoryIds = categoryProvider.categories.map((c) => c.id).toSet();
    final selectedValue = categoryIds.contains(_selectedCategoryId)
        ? _selectedCategoryId
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Category',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (categoryProvider.loading)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(child: CircularProgressIndicator()),
          )
        else
          DropdownButtonFormField<String>(
            value: selectedValue,
            hint: const Text('Select category'),
            items: categoryProvider.categories
                .map(
                  (cat) => DropdownMenuItem(
                    value: cat.id,
                    child: Text(cat.name),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _selectedCategoryId = value),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
          ),
      ],
    );
  }
}
