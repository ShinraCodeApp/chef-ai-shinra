import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/recipes_provider.dart';
import '../../widgets/recipe_card.dart';
import '../../widgets/empty_state.dart';
import 'recipe_detail_screen.dart';
import '../../core/i18n.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecipesProvider>().loadFavorites();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecipesProvider>();
    return Scaffold(
      appBar: AppBar(title: Text(tr('Favoritos'))),
      body: provider.isLoadingFavorites && provider.favorites.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => provider.loadFavorites(),
              child: provider.favorites.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: 80),
                        EmptyState(
                          icon: Icons.favorite_border,
                          message:
                              tr('Todavía no marcaste ninguna receta como favorita.'),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: provider.favorites.length + (provider.favoritesOffline ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (provider.favoritesOffline) {
                          if (index == 0) {
                            return Card(
                              child: ListTile(
                                leading: Icon(Icons.cloud_off),
                                title: Text(tr('Sin conexión')),
                                subtitle: Text(tr('Mostrando tus favoritas guardadas en el celular.')),
                              ),
                            );
                          }
                          index--;
                        }
                        final recipe = provider.favorites[index];
                        return RecipeCard(
                          recipe: recipe,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  RecipeDetailScreen(recipeId: recipe.id),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
