import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/recipe.dart';
import '../../providers/recipes_provider.dart';
import '../recipes/recipe_detail_screen.dart';

/// Panel de admin para ver y eliminar cualquier receta de la plataforma
/// (propias, compartidas por usuarios o generadas por IA).
class AdminRecipesScreen extends StatefulWidget {
  const AdminRecipesScreen({super.key});

  @override
  State<AdminRecipesScreen> createState() => _AdminRecipesScreenState();
}

class _AdminRecipesScreenState extends State<AdminRecipesScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<RecipesProvider>();
      provider.search = '';
      provider.dietTag = null;
      provider.loadRecipes();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _delete(Recipe recipe) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar receta'),
        content: Text('¿Seguro que querés eliminar "${recipe.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final ok = await context.read<RecipesProvider>().deleteRecipe(recipe.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Receta eliminada.' : 'No se pudo eliminar la receta.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecipesProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Recetas')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Buscar receta…',
                prefixIcon: Icon(Icons.search),
              ),
              onSubmitted: (value) {
                provider.search = value;
                provider.loadRecipes();
              },
            ),
          ),
          Expanded(
            child: provider.isLoading && provider.recipes.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => provider.loadRecipes(),
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: provider.recipes.length + 1,
                      itemBuilder: (context, index) {
                        if (index == provider.recipes.length) {
                          if (provider.page < provider.totalPages) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: TextButton(
                                  onPressed: provider.loadNextPage,
                                  child: const Text('Cargar más'),
                                ),
                              ),
                            );
                          }
                          return const SizedBox(height: 24);
                        }
                        final recipe = provider.recipes[index];
                        return ListTile(
                          title: Text(recipe.title),
                          subtitle: Text(
                            [
                              if (recipe.isAiGenerated) 'Generada por IA',
                              '${recipe.servings} porciones',
                              ...recipe.dietTags,
                            ].join(' · '),
                          ),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => RecipeDetailScreen(recipeId: recipe.id),
                            ),
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.delete_outline,
                                color: Theme.of(context).colorScheme.error),
                            tooltip: 'Eliminar receta',
                            onPressed: () => _delete(recipe),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
