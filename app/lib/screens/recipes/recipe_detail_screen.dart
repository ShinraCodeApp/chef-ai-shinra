import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/diet_tags.dart';
import '../../core/health_conditions.dart';
import '../../core/notifications_service.dart';
import '../../core/quantity_format.dart';
import '../../core/api_client.dart';
import '../../core/cooking.dart';
import '../../providers/inventory_provider.dart';
import 'cooking_mode_screen.dart';
import '../../core/recipe_images.dart';
import '../../models/missing_ingredient.dart';
import '../../models/recipe.dart';
import '../../providers/recipes_provider.dart';
import '../../providers/shopping_lists_provider.dart';
import '../../widgets/app_loading.dart';
import '../../core/i18n.dart';

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
  final _tts = FlutterTts();
  bool _isSpeaking = false;
  Map<String, dynamic>? _costData;
  bool _loadingCost = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialRecipe != null) {
      _recipe = widget.initialRecipe;
      _loadEstimatedCost(widget.initialRecipe!.id);
    } else {
      context.read<RecipesProvider>().fetchOne(widget.recipeId!).then((recipe) {
        if (mounted) {
          setState(() => _recipe = recipe);
          _loadEstimatedCost(recipe.id);
        }
      });
    }
    _tts.setLanguage(AppLanguage.instance.ttsLanguage);
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _isSpeaking = false);
    });
  }

  Future<void> _loadEstimatedCost(String recipeId) async {
    setState(() => _loadingCost = true);
    try {
      final res = await ApiClient.instance.dio.get('/recipes/$recipeId/estimated-cost');
      if (mounted) setState(() => _costData = res.data as Map<String, dynamic>);
    } catch (_) {}
    if (mounted) setState(() => _loadingCost = false);
  }

  /// Total del costo: con "≈" si algún precio se aproximó; si no hay ningún
  /// precio cargado, el costo que estimó la IA al generar la receta.
  String _totalCostLabel(Recipe recipe) {
    final total = _costData?['totalCost'] as num?;
    if (total != null) {
      final approx = _costData!['approximate'] == true ? '≈ ' : '';
      return '$approx\$${total.toStringAsFixed(0)}';
    }
    final aiEstimate = recipe.estimatedCostTotal;
    if (aiEstimate != null) return '≈ \$${aiEstimate.toStringAsFixed(0)}';
    return tr('Sin datos de precios');
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _toggleSpeak(Recipe recipe) async {
    if (_isSpeaking) {
      await _tts.stop();
      setState(() => _isSpeaking = false);
      return;
    }
    final buffer = StringBuffer()
      ..writeln(recipe.title)
      ..writeln(recipe.description)
      ..writeln(tr('Ingredientes:'));
    for (final ri in recipe.recipeIngredients) {
      buffer.writeln(tr('{unit} de {ri}.', {'unit': formatQuantity(ri.quantity, ri.unit), 'ri': ri.ingredient.name}));
    }
    buffer.writeln(tr('Preparación:'));
    for (final step in recipe.instructions) {
      buffer.writeln(tr('Paso {order}. {instruction}', {'order': step.order, 'instruction': step.instruction}));
    }
    setState(() => _isSpeaking = true);
    await _tts.speak(buffer.toString());
  }

  Future<void> _shareRecipe(Recipe recipe) async {
    final buffer = StringBuffer()
      ..writeln(recipe.title)
      ..writeln()
      ..writeln(recipe.description)
      ..writeln()
      ..writeln(tr('⏱ {prepTimeMinutes} min · 🍽 {servings} porciones', {'prepTimeMinutes': recipe.prepTimeMinutes, 'servings': recipe.servings}))
      ..writeln()
      ..writeln(tr('Ingredientes:'));
    for (final ri in recipe.recipeIngredients) {
      buffer.writeln('• ${formatQuantity(ri.quantity, ri.unit)} — ${ri.ingredient.name}');
    }
    buffer.writeln();
    buffer.writeln(tr('Preparación:'));
    for (final step in recipe.instructions) {
      buffer.writeln('${step.order}. ${step.instruction}');
    }
    buffer.writeln();
    buffer.writeln(tr('Compartido desde Chef Ai by Shinra'));
    await SharePlus.instance.share(ShareParams(text: buffer.toString(), subject: recipe.title));
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
        SnackBar(
          content: Text(tr('¡Buen provecho! Se descontó del inventario.')),
        ),
      );
      if (missing.isNotEmpty) {
        await NotificationsService.instance.showNow(
          title: tr('Te quedaste sin ingredientes'),
          body: missing.map((m) => m.name).join(', '),
        );
        await _offerAddMissingToShoppingList(missing);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('No se pudo marcar como cocinada.'))),
        );
      }
    } finally {
      if (mounted) setState(() => _isCooking = false);
    }
  }

  Future<void> _openCookingMode(Recipe recipe) async {
    final finished = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => CookingModeScreen(recipe: recipe)),
    );
    if (finished != true || !mounted) return;
    final deduct = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('¡Buen provecho!')),
        content: Text(tr('¿Descontamos los ingredientes de tu inventario?')),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(tr('No'))),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(tr('Sí'))),
        ],
      ),
    );
    if (deduct == true && mounted) await _cook();
  }

  /// Antes de ir a comprar: compara la receta con el inventario.
  Future<void> _checkMissing(Recipe recipe) async {
    final inventory = context.read<InventoryProvider>();
    await inventory.load();
    if (!mounted) return;
    final missing = missingFromInventory(recipe, inventory.items);
    if (missing.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('¡Tenés todo para esta receta!'))),
      );
      return;
    }
    await _offerAddMissingToShoppingList(missing, title: tr('Te falta para esta receta'));
  }

  Future<void> _offerAddMissingToShoppingList(
      List<MissingIngredient> missing,
      {String? title}) async {
    final shouldAdd = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title ?? tr('Te faltaron ingredientes')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr('¿Los agregamos a tu lista de compras?')),
            const SizedBox(height: 12),
            ...missing.map(
              (item) => Text(
                  '• ${formatQuantity(item.quantity, item.unit)} — ${item.name}'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false), child: Text(tr('No'))),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true), child: Text(tr('Sí'))),
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
            ? tr('Ingredientes agregados a tu lista de compras.')
            : tr('No se pudieron agregar a la lista de compras.')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recipe = _recipe;
    return Scaffold(
      appBar: AppBar(
        title: Text(recipe?.title ?? tr('Receta')),
        actions: recipe == null
            ? null
            : [
                IconButton(
                  icon: Icon(_isSpeaking ? Icons.stop_circle_outlined : Icons.volume_up_outlined),
                  tooltip: _isSpeaking ? tr('Detener') : tr('Escuchar receta'),
                  onPressed: () => _toggleSpeak(recipe),
                ),
                IconButton(
                  icon: const Icon(Icons.share_outlined),
                  tooltip: tr('Compartir receta'),
                  onPressed: () => _shareRecipe(recipe),
                ),
                IconButton(
                  icon: Icon(
                    recipe.isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: recipe.isFavorite ? Theme.of(context).colorScheme.error : null,
                  ),
                  onPressed: _toggleFavorite,
                ),
              ],
      ),
      body: SafeArea(
        child: recipe == null
          ? const AppLoading()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Builder(builder: (context) {
                    final imageUrl = recipeImageUrl(recipe.title) ?? recipe.imageUrl;
                    final placeholder = Container(
                      height: 200,
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Icon(Icons.restaurant,
                          size: 48, color: Theme.of(context).colorScheme.outline),
                    );
                    Widget? image;
                    if (imageUrl != null && imageUrl.isNotEmpty) {
                      image = Image.network(
                        imageUrl,
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
                        errorBuilder: (context, error, stackTrace) => placeholder,
                      );
                    }
                    if (image == null) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(borderRadius: BorderRadius.circular(16), child: image),
                        const SizedBox(height: 16),
                      ],
                    );
                  }),
                  Text(recipe.description,
                      style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _infoChip(Icons.timer_outlined, tr('{prepTimeMinutes} min', {'prepTimeMinutes': recipe.prepTimeMinutes})),
                      _infoChip(Icons.people_outline, tr('{servings} porciones', {'servings': recipe.servings})),
                      _infoChip(Icons.bar_chart, difficultyLabel(recipe.difficulty)),
                      if (recipe.estimatedCostTotal != null)
                        _infoChip(Icons.attach_money,
                            recipe.estimatedCostTotal!.toStringAsFixed(0)),
                      ...recipe.dietTags.map((tag) => Chip(label: Text(dietTagLabel(tag)))),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(tr('Ingredientes'), style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ...recipe.recipeIngredients.map(
                    (ri) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text('• ${formatQuantity(ri.quantity, ri.unit)} — ${ri.ingredient.name}'),
                    ),
                  ),
                  // Costo estimado
                  if (_loadingCost)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: LinearProgressIndicator(),
                    )
                  else if (_costData != null) ...[
                    const SizedBox(height: 20),
                    Text(tr('Costo estimado'), style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ...(_costData!['breakdown'] as List).map((b) {
                      final lineCost = b['lineCost'] as num?;
                      // ≈: las unidades del precio y de la receta no coincidían
                      // (ej. precio por lata y receta en gramos)
                      final approx = b['approximate'] == true ? '≈ ' : '';
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '• ${b['ingredientName']} (${b['quantity']} ${b['unit']})',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                            Text(
                              lineCost != null
                                  ? '$approx\$${lineCost.toStringAsFixed(0)}'
                                  : tr('sin precio'),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: lineCost == null
                                        ? Theme.of(context).colorScheme.onSurfaceVariant
                                        : null,
                                  ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _costData!['hasPartialPrices'] == true
                                ? tr('Total estimado (parcial)')
                                : tr('Total estimado'),
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                          ),
                          Text(
                            _totalCostLabel(recipe),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Text(tr('Preparación'), style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ...recipe.instructions.map(
                    (step) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text('${step.order}. ${step.instruction}'),
                    ),
                  ),
                  if (recipe.tips.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(tr('Consejos'), style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ...recipe.tips.map(
                      (tip) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text('• $tip'),
                      ),
                    ),
                  ],
                  if (recipe.nutrition != null) ...[
                    const SizedBox(height: 20),
                    Text(tr('Nutrición (aprox.)'),
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        _nutritionChip(tr('Calorías'), recipe.nutrition!.calories, ''),
                        _nutritionChip(tr('Proteína'), recipe.nutrition!.proteinG, 'g'),
                        _nutritionChip(tr('Grasas'), recipe.nutrition!.fatG, 'g'),
                        _nutritionChip(tr('Carbs'), recipe.nutrition!.carbsG, 'g'),
                        _nutritionChip(tr('Fibra'), recipe.nutrition!.fiberG, 'g'),
                        _nutritionChip(tr('Azúcares'), recipe.nutrition!.sugarG, 'g'),
                        _nutritionChip(tr('Sodio'), recipe.nutrition!.sodiumMg, 'mg'),
                      ],
                    ),
                  ],
                  ..._healthSection(recipe),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: () => _openCookingMode(recipe),
                          icon: const Icon(Icons.soup_kitchen_outlined),
                          label: Text(tr('Modo cocina')),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _checkMissing(recipe),
                          icon: const Icon(Icons.shopping_cart_outlined),
                          label: Text(tr('¿Qué me falta?')),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _isCooking ? null : _cook,
                    icon: _isCooking
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.restaurant),
                    label: Text(tr('Cocinar')),
                  ),
                ],
              ),
            ),
      ),
    );
  }

  /// Sección al pie de la receta: para qué dietas es apta y en qué condiciones
  /// de salud puede ayudar.
  List<Widget> _healthSection(Recipe recipe) {
    final conditions = healthConditionsFor(recipe);
    if (conditions.isEmpty) return const [];
    final textTheme = Theme.of(context).textTheme;
    return [
      const SizedBox(height: 20),
      Text(tr('Dietas y salud: puede ayudar en…'), style: textTheme.titleMedium),
      const SizedBox(height: 8),
      ...conditions.map(
        (c) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.health_and_safety_outlined,
                  size: 18, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text.rich(TextSpan(children: [
                  TextSpan(
                      text: '${tr(c.name)}: ',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: tr(c.reason)),
                ])),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 6),
      Text(
        tr('Información orientativa: no reemplaza la indicación de tu médico o nutricionista.'),
        style: textTheme.bodySmall,
      ),
    ];
  }

  Widget _infoChip(IconData icon, String label) {
    return Chip(avatar: Icon(icon, size: 16), label: Text(label));
  }

  Widget _nutritionChip(String label, double value, String unit) {
    return Chip(label: Text('$label: ${value.toStringAsFixed(0)}$unit'));
  }
}
