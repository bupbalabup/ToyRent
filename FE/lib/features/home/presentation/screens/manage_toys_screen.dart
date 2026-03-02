import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../providers/toy_provider.dart';
import 'toy_form_screen.dart';

class ManageToysScreen extends StatelessWidget {
  const ManageToysScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ToyProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Manage toys')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.toyForm);
        },
        child: const Icon(Icons.add_rounded),
      ),
      body: ListView.separated(
        itemCount: provider.toys.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final toy = provider.toys[index];
          return ListTile(
            title: Text(toy.name),
            subtitle: Text('\$${toy.price.toStringAsFixed(2)} • ${toy.category}'),
            trailing: Wrap(
              spacing: 8,
              children: <Widget>[
                IconButton(
                  icon: const Icon(Icons.edit_rounded),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(builder: (_) => ToyFormScreen(toy: toy)),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                  onPressed: () => provider.deleteToy(toy.id),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
