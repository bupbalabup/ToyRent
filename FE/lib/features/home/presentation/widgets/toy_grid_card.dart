import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../models/toy_model.dart';
import '../../../../providers/toy_provider.dart';

class ToyGridCard extends StatelessWidget {
  const ToyGridCard({
    super.key,
    required this.toy,
    required this.onTap,
  });

  final ToyModel toy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ToyProvider>();

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Hero(
                    tag: 'toy-${toy.id}',
                    child: Image.network(
                      toy.imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        toy.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: <Widget>[
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                          Text(' ${toy.rating}'),
                          const Spacer(),
                          Text('\$${toy.price.toStringAsFixed(0)}'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton.filledTonal(
                onPressed: () => provider.toggleFavorite(toy.id),
                icon: Icon(
                  provider.isFavorite(toy.id)
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: provider.isFavorite(toy.id) ? Colors.redAccent : Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
