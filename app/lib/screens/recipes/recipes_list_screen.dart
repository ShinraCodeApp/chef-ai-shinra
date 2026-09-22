import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/diet_tags.dart';
import '../../providers/recipes_provider.dart';
import '../../widgets/recipe_card.dart';
import '../../widgets/empty_state.dart';
import 'recipe_detail_screen.dart';
import 'create_recipe_screen.dart';

const _dietTagOptions = [
  'proteico',
  'vegetariano',
  'vegano',
  'sin_tacc',
  'keto',
  'fitness',
  'economico',
  'comida_cruda',
  'hipotiroidismo',
  'hipertiroidismo',
];

class RecipesListScreen extends StatefulWidget {
  final String? initialDietTag;

  const RecipesListScreen({super.key, this.initialDietTag});

  @override
  State<RecipesListScreen> createState() => _RecipesListScreenState();
}

class _RecipesListScreenState extends State<RecipesListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<RecipesProvider>();
      if (widget.initialDietTag != null) {
        provider.dietTag = widget.initialDietTag;
      }
      provider.loadRecipes();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _titleFor(String? dietTag) {
    switch (dietTag) {
      case 'proteico':
        return 'Comida proteica';
      case 'vegano':
        return 'Comida vegana';
      case 'hipotiroidismo':
        return 'Recetas para hipotiroidismo';
      case 'hipertiroidismo':
        return 'Recetas para hipertiroidismo';
      default:
        return 'Recetas';
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecipesProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text(_titleFor(widget.initialDietTag)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Compartir mi receta',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CreateRecipeScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
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
                const SizedBox(width: 8),
                PopupMenuButton<String?>(
                  icon: const Icon(Icons.filter_list),
                  onSelected: (value) {
                    provider.dietTag = value;
                    provider.loadRecipes();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: null, child: Text('Todas')),
                    ..._dietTagOptions.map(
                      (tag) => PopupMenuItem(value: tag, child: Text(dietTagLabel(tag))),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (provider.dietTag != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Chip(
                  label: Text('Filtro: ${dietTagLabel(provider.dietTag!)}'),
                  onDeleted: () {
                    provider.dietTag = null;
                    provider.loadRecipes();
                  },
                ),
              ),
            ),
          Expanded(
            child: provider.isLoading && provider.recipes.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => provider.loadRecipes(),
                    child: provider.recipes.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 80),
                          EmptyState(
                            icon: Icons.menu_book_outlined,
                            message: 'Todavía no hay recetas. ¡Generá una con IA!',
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
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
          ),
        ],
      ),
    );
  }
}
