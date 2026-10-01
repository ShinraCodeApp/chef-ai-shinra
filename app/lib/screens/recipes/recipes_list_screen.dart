import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/diet_tags.dart';
import '../../models/recipe.dart';
import '../../providers/recipes_provider.dart';
import '../../widgets/recipe_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/voice_text_field.dart';
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
  'bajo_yodo',
  'anime',
];

class RecipesListScreen extends StatefulWidget {
  final String? initialDietTag;

  const RecipesListScreen({super.key, this.initialDietTag});

  @override
  State<RecipesListScreen> createState() => _RecipesListScreenState();
}

class _RecipesListScreenState extends State<RecipesListScreen> {
  final _searchController = TextEditingController();
  final _multiIngredientController = TextEditingController();
  bool _searchByIngredient = false;
  bool _multiIngredientMode = false;

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
    _multiIngredientController.dispose();
    super.dispose();
  }

  void _addIngredient(RecipesProvider provider) {
    final value = _multiIngredientController.text.trim();
    if (value.isEmpty) return;
    if (!provider.ingredients.contains(value)) {
      provider.ingredients = [...provider.ingredients, value];
      provider.loadRecipes();
    }
    _multiIngredientController.clear();
  }

  void _removeIngredient(RecipesProvider provider, String ing) {
    provider.ingredients = provider.ingredients.where((i) => i != ing).toList();
    provider.loadRecipes();
  }

  void _clearMultiMode(RecipesProvider provider) {
    provider.ingredients = [];
    _multiIngredientController.clear();
    setState(() => _multiIngredientMode = false);
    provider.loadRecipes();
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
      case 'bajo_yodo':
        return 'Recetas bajas en yodo';
      case 'anime':
        return 'Platos anime';
      default:
        return 'Recetas';
    }
  }

  /// Cuando se busca por ingrediente, arma la lista intercalando encabezados
  /// (String) entre las recetas donde el ingrediente buscado es el principal
  /// y las que sólo lo contienen. Fuera de esa búsqueda, devuelve las recetas
  /// tal cual, sin encabezados.
  List<Object> _buildDisplayItems(RecipesProvider provider) {
    if (provider.ingredient.isEmpty) {
      return provider.recipes;
    }
    final mainMatches = provider.recipes
        .where((r) => r.isMainIngredientMatch == true)
        .toList();
    final otherMatches = provider.recipes
        .where((r) => r.isMainIngredientMatch != true)
        .toList();
    return [
      if (mainMatches.isNotEmpty) 'Ingrediente principal',
      ...mainMatches,
      if (otherMatches.isNotEmpty) 'También lo contienen',
      ...otherMatches,
    ];
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
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
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: Row(
                children: [
                  Expanded(
                    child: _multiIngredientMode
                        ? TextField(
                            controller: _multiIngredientController,
                            decoration: InputDecoration(
                              hintText: 'Agregar ingrediente…',
                              prefixIcon: const Icon(Icons.add),
                              suffixIcon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  VoiceInputButton(
                                    onResult: (text) {
                                      _multiIngredientController.text = text;
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.check),
                                    onPressed: () => _addIngredient(provider),
                                  ),
                                ],
                              ),
                            ),
                            onSubmitted: (_) => _addIngredient(provider),
                            textInputAction: TextInputAction.done,
                          )
                        : TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: _searchByIngredient
                                  ? 'Buscar por ingrediente…'
                                  : 'Buscar receta…',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: VoiceInputButton(
                                onResult: (text) {
                                  _searchController.text = text;
                                  if (_searchByIngredient) {
                                    provider.ingredient = text;
                                    provider.search = '';
                                  } else {
                                    provider.search = text;
                                    provider.ingredient = '';
                                  }
                                  provider.loadRecipes();
                                },
                              ),
                            ),
                            onSubmitted: (value) {
                              if (_searchByIngredient) {
                                provider.ingredient = value;
                                provider.search = '';
                              } else {
                                provider.search = value;
                                provider.ingredient = '';
                              }
                              provider.loadRecipes();
                            },
                          ),
                  ),
                  const SizedBox(width: 4),
                  // Botón modo multi-ingrediente
                  IconButton(
                    icon: Icon(
                      _multiIngredientMode
                          ? Icons.kitchen
                          : Icons.kitchen_outlined,
                      color: _multiIngredientMode
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    tooltip: '¿Qué puedo cocinar?',
                    onPressed: () {
                      setState(() {
                        _multiIngredientMode = !_multiIngredientMode;
                        if (!_multiIngredientMode) {
                          _clearMultiMode(provider);
                        } else {
                          // desactivar modo ingrediente simple
                          _searchByIngredient = false;
                          provider.ingredient = '';
                          provider.search = '';
                          _searchController.clear();
                        }
                      });
                    },
                  ),
                  if (!_multiIngredientMode) ...[
                    const SizedBox(width: 4),
                    IconButton(
                      icon: Icon(
                        _searchByIngredient
                            ? Icons.egg_alt
                            : Icons.egg_alt_outlined,
                      ),
                      tooltip: _searchByIngredient
                          ? 'Buscando por ingrediente'
                          : 'Buscar por ingrediente',
                      onPressed: () {
                        setState(
                          () => _searchByIngredient = !_searchByIngredient,
                        );
                        final value = _searchController.text;
                        if (_searchByIngredient) {
                          provider.ingredient = value;
                          provider.search = '';
                        } else {
                          provider.search = value;
                          provider.ingredient = '';
                        }
                        if (value.isNotEmpty) provider.loadRecipes();
                      },
                    ),
                  ],
                  const SizedBox(width: 4),
                  PopupMenuButton<String?>(
                    icon: const Icon(Icons.filter_list),
                    onSelected: (value) {
                      provider.dietTag = value;
                      provider.loadRecipes();
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: null, child: Text('Todas')),
                      ..._dietTagOptions.map(
                        (tag) => PopupMenuItem(
                          value: tag,
                          child: Text(dietTagLabel(tag)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Chips de ingredientes en modo multi
            if (_multiIngredientMode)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (provider.ingredients.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          'Agregá los ingredientes que tenés y encontrá recetas',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      )
                    else
                      Wrap(
                        spacing: 6,
                        children: [
                          ...provider.ingredients.map(
                            (ing) => Chip(
                              label: Text(ing),
                              onDeleted: () =>
                                  _removeIngredient(provider, ing),
                            ),
                          ),
                          ActionChip(
                            label: const Text('Limpiar todo'),
                            onPressed: () => _clearMultiMode(provider),
                          ),
                        ],
                      ),
                    const SizedBox(height: 4),
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
            if (provider.ingredient.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Chip(
                    label: Text('Ingrediente: ${provider.ingredient}'),
                    onDeleted: () {
                      provider.ingredient = '';
                      _searchController.clear();
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
                                  message:
                                      'Todavía no hay recetas. ¡Generá una con IA!',
                                ),
                              ],
                            )
                          : Builder(builder: (context) {
                              final displayItems = _buildDisplayItems(provider);
                              return ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: displayItems.length + 1,
                                itemBuilder: (context, index) {
                                  if (index == displayItems.length) {
                                    if (provider.page < provider.totalPages) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
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
                                  final item = displayItems[index];
                                  if (item is String) {
                                    return _sectionHeader(context, item);
                                  }
                                  final recipe = item as Recipe;
                                  return RecipeCard(
                                    recipe: recipe,
                                    hiddenTag: provider.dietTag,
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => RecipeDetailScreen(
                                          recipeId: recipe.id,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            }),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
