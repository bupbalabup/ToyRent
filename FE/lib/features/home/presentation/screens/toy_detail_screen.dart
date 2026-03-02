import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../providers/cart_provider.dart';
import '../../../../providers/toy_provider.dart';

class ToyDetailScreen extends StatelessWidget {
  const ToyDetailScreen({super.key, required this.toyId});

  final String toyId;

  @override
  Widget build(BuildContext context) {
    final toyProvider = context.watch<ToyProvider>();
    final cartProvider = context.read<CartProvider>();

    final candidates = toyProvider.toys.where((item) => item.id == toyId);
    final toy = candidates.isNotEmpty ? candidates.first : null;

    if (toy == null) {
      return const Scaffold(body: Center(child: Text('Toy not found')));
    }

    return Scaffold(
      appBar: AppBar(title: Text(toy.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Hero(
            tag: 'toy-${toy.id}',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(toy.imageUrl, height: 300, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            toy.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              const Icon(Icons.star_rounded, color: Colors.amber),
              const SizedBox(width: 4),
              Text('${toy.rating}'),
              const Spacer(),
              Text(
                '\$${toy.price.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(toy.description, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () {
              cartProvider.addToCart(toy);
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('Added to cart')));
            },
            icon: const Icon(Icons.shopping_cart_checkout_rounded),
            label: const Text('Add to cart'),
          ),
        ],
      ),
    );
  }
}
