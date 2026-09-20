import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/missing_ingredient.dart';
import '../../models/recipe.dart';
import '../../providers/recipes_provider.dart';
import '../../providers/shopping_lists_provider.dart';
import '../../widgets/app_loading.dart';

class RecipeDetailScreen extends StatefulWidget {
  final String? recipeId;
  final Recipe? initialRecipe;

  const RecipeDetailScreen({super.key, this.recipeId, this.initialRecipe})
      : assert(recipeId != null || initialRecipe != null);

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  Recipe? _recipe;
  bool _isCooking = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialRecipe != null) {
      _recipe = widget.initialRecipe;
    } else {
      context.read<RecipesProvider>().fetchOne(widget.recipeId!).then((recipe) {
        if (mounted) setState(() => _recipe = recipe);
      });
    }
  }

  Future<void> _toggleFavorite() async {
    final favorited = await context.read<RecipesProvider>().toggleFavorite(_recipe!.id);
    setState(() => _recipe!.isFavorite = favorited);
  }

  Future<void> _cook() async {
    setState(() => _isCooking = true);
    try {
      final missing = await context.read<RecipesProvider>().cook(_recipe!.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Buen provecho! Se descontó del inventario.'),
        ),
      );
      if (missing.isNotEmpty) {
        await _offerAddMissingToShoppingList(missing);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo marcar como cocinada.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCooking = false);
    }
  }

  Future<void> _offerAddMissingToShoppingList(
      List<MissingIngredient> missing) async {
    final shouldAdd = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Te faltaron ingredientes'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('¿Los agregamos a tu lista de compras?'),
            const SizedBox(height: 12),
            ...missing.map(
              (item) => Text(
                  '• ${item.quantity.toStringAsFixed(item.quantity.truncateToDouble() == item.quantity ? 0 : 1)} ${item.unit} — ${item.name}'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false), child: const Text('No')),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Sí')),
        ],
      ),
    );
    if (shouldAdd != true || !mounted) return;
    final added =
        await context.read<ShoppingListsProvider>().addMissingItems(missing);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(added
            ? 'Ingredientes agregados a tu lista de compras.'
            : 'No se pudieron agregar a la lista de compras.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recipe = _recipe;
    return Scaffold(
      appBar: AppBar(
        title: Text(recipe?.title ?? 'Receta'),
        actions: recipe == null
            ? null
            : [
                IconButton(
                  icon: Icon(
                    recipe.isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: recipe.isFavorite ? Theme.of(context).colorScheme.error : null,
                  ),
                  onPressed: _toggleFavorite,
                ),
              ],
      ),
      body: recipe == null
          ? const AppLoading()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        recipe.imageUrl!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            height: 200,
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            child: const Center(child: CircularProgressIndicator()),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 200,
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          child: Icon(Icons.restaurant,
                              size: 48, color: Theme.of(context).colorScheme.outline),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text(recipe.description,
                      style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _infoChip(Icons.timer_outlined, '${recipe.prepTimeMinutes} min'),
                      _infoChip(Icons.people_outline, '${recipe.servings} porciones'),
                      _infoChip(Icons.bar_chart, recipe.difficulty),
                      if (recipe.estimatedCostTotal != null)
                        _infoChip(Icons.attach_money,
                            recipe.estimatedCostTotal!.toStringAsFixed(0)),
                      ...recipe.dietTags.map((tag) => Chip(label: Text(tag))),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('Ingredientes', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ...recipe.recipeIngredients.map(
                    (ri) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text('• ${ri.quantity} ${ri.unit} — ${ri.ingredient.name}'),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Preparación', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ...recipe.instructions.map(
                    (step) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text('${step.order}. ${step.instruction}'),
                    ),
                  ),
                  if (recipe.nutrition != null) ...[
                    const SizedBox(height: 20),
                    Text('Nutrición (aprox.)',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        _nutritionChip('Calorías', recipe.nutrition!.calories, ''),
                        _nutritionChip('Proteína', recipe.nutrition!.proteinG, 'g'),
                        _nutritionChip('Grasas', recipe.nutrition!.fatG, 'g'),
                        _nutritionChip('Carbs', recipe.nutrition!.carbsG, 'g'),
                        _nutritionChip('Fibra', recipe.nutrition!.fiberG, 'g'),
                        _nutritionChip('Azúcares', recipe.nutrition!.sugarG, 'g'),
                        _nutritionChip('Sodio', recipe.nutrition!.sodiumMg, 'mg'),
                      ],
                    ),
                  ],
                  const SizedBox(height: 28),
                  FilledButton.icon(
                    onPressed: _isCooking ? null : _cook,
                    icon: _isCooking
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.restaurant),
                    label: const Text('Cocinar'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Chip(avatar: Icon(icon, size: 16), label: Text(label));
  }

  Widget _nutritionChip(String label, double value, String unit) {
    return Chip(label: Text('$label: ${value.toStringAsFixed(0)}$unit'));
  }
}
