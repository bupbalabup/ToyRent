import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../models/toy_model.dart';
import '../../../../providers/toy_provider.dart';
import '../widgets/toy_grid_card.dart';
import 'toy_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<void> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<ToyProvider>().fetchToys();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ToyProvider>();

    return FutureBuilder<void>(
      future: _future,
      builder: (context, snapshot) {
        if (provider.isLoading && provider.toys.isEmpty) {
          return const AppLoader();
        }

        if (provider.error != null && provider.toys.isEmpty) {
          return AppErrorView(
            message: provider.error!,
            onRetry: () => setState(() => _future = provider.fetchToys()),
          );
        }

        return RefreshIndicator(
          onRefresh: provider.fetchToys,
          child: CustomScrollView(
            slivers: <Widget>[
              const SliverAppBar(
                floating: true,
                title: Text('TOYFLIX'),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(<Widget>[
                    if (provider.featured.isNotEmpty)
                      _HeroBanner(toy: provider.featured.first)
                    else
                      const SizedBox.shrink(),
                    const SizedBox(height: 14),
                    SearchBar(
                      hintText: 'Search toys',
                      leading: const Icon(Icons.search_rounded),
                      onChanged: provider.setSearchQuery,
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 42,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: provider.categories.length,
                        itemBuilder: (context, index) {
                          final category = provider.categories[index];
                          final selected = provider.selectedCategory == category;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(category),
                              selected: selected,
                              onSelected: (_) => provider.setCategory(category),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 14),
                  ]),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid.builder(
                  itemCount: provider.visibleToys.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.65,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  itemBuilder: (context, index) {
                    final toy = provider.visibleToys[index];
                    return ToyGridCard(
                      toy: toy,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(builder: (_) => ToyDetailScreen(toyId: toy.id)),
                        );
                      },
                    );
                  },
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
            ],
          ),
        );
      },
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.toy});

  final ToyModel toy;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => ToyDetailScreen(toyId: toy.id)),
        );
      },
      child: Hero(
        tag: 'toy-${toy.id}',
        child: Container(
          height: 210,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            image: DecorationImage(image: NetworkImage(toy.imageUrl), fit: BoxFit.cover),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[Colors.transparent, Colors.black.withValues(alpha: 0.8)],
              ),
            ),
            alignment: Alignment.bottomLeft,
            padding: const EdgeInsets.all(16),
            child: Text(
              toy.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}
