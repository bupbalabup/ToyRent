import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../models/toy_model.dart';
import '../../../../providers/toy_provider.dart';

class ToyFormScreen extends StatefulWidget {
  const ToyFormScreen({super.key, this.toy});

  final ToyModel? toy;

  @override
  State<ToyFormScreen> createState() => _ToyFormScreenState();
}

class _ToyFormScreenState extends State<ToyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _image;
  late final TextEditingController _price;
  late final TextEditingController _category;
  late final TextEditingController _rating;
  late final TextEditingController _stock;
  bool _isFeatured = false;

  @override
  void initState() {
    super.initState();
    final toy = widget.toy;
    _name = TextEditingController(text: toy?.name ?? '');
    _description = TextEditingController(text: toy?.description ?? '');
    _image = TextEditingController(text: toy?.imageUrl ?? '');
    _price = TextEditingController(text: toy?.price.toString() ?? '0');
    _category = TextEditingController(text: toy?.category ?? 'General');
    _rating = TextEditingController(text: toy?.rating.toString() ?? '4.0');
    _stock = TextEditingController(text: toy?.stock.toString() ?? '1');
    _isFeatured = toy?.isFeatured ?? false;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _image.dispose();
    _price.dispose();
    _category.dispose();
    _rating.dispose();
    _stock.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<ToyProvider>();

    final model = ToyModel(
      id: widget.toy?.id ?? '',
      name: _name.text.trim(),
      description: _description.text.trim(),
      imageUrl: _image.text.trim(),
      price: double.parse(_price.text.trim()),
      category: _category.text.trim(),
      rating: double.parse(_rating.text.trim()),
      stock: int.parse(_stock.text.trim()),
      isFeatured: _isFeatured,
    );

    if (widget.toy == null) {
      await provider.createToy(model);
    } else {
      await provider.updateToy(model);
    }

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.toy == null ? 'Add toy' : 'Edit toy')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              _input(_name, 'Name'),
              _input(_description, 'Description', maxLines: 3),
              _input(_image, 'Image URL'),
              _input(_price, 'Price', number: true),
              _input(_category, 'Category'),
              _input(_rating, 'Rating', number: true),
              _input(_stock, 'Stock', number: true),
              SwitchListTile(
                value: _isFeatured,
                title: const Text('Featured'),
                onChanged: (value) => setState(() => _isFeatured = value),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton(onPressed: _save, child: const Text('Save')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _input(
    TextEditingController controller,
    String label, {
    bool number = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        validator: (value) => value == null || value.trim().isEmpty ? '$label is required' : null,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
