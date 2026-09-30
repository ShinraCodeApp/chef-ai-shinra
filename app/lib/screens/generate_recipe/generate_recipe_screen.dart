import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api_client.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/recipes_provider.dart';
import '../recipes/recipe_detail_screen.dart';

class GenerateRecipeScreen extends StatefulWidget {
  const GenerateRecipeScreen({super.key});

  @override
  State<GenerateRecipeScreen> createState() => _GenerateRecipeScreenState();
}

class _GenerateRecipeScreenState extends State<GenerateRecipeScreen> {
  final _ingredientController = TextEditingController();
  final _freeTextController = TextEditingController();
  final List<String> _ingredients = [];
  String? _budget;
  int? _maxPrepTimeMinutes;
  bool _isGenerating = false;
  bool _loadingInventory = false;
  String? _error;
  int? _aiUsed;
  int? _aiLimit;
  bool _aiUnlimited = false;

  @override
  void initState() {
    super.initState();
    _loadAiInfo();
  }

  Future<void> _loadFromInventory() async {
    setState(() { _loadingInventory = true; _error = null; });
    try {
      final provider = context.read<InventoryProvider>();
      await provider.load();
      if (!mounted) return;
      final names = provider.items
          .map((item) => item.ingredient.name)
          .toSet()
          .toList();
      if (names.isEmpty) {
        setState(() => _error = 'Tu inventario está vacío.');
        return;
      }
      setState(() {
        _ingredients.clear();
        _ingredients.addAll(names);
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'No se pudo cargar el inventario.');
    } finally {
      if (mounted) setState(() => _loadingInventory = false);
    }
  }

  Future<void> _loadAiInfo() async {
    try {
      final res = await ApiClient.instance.dio.get('/users/me/ai-info');
      if (!mounted) return;
      setState(() {
        _aiUsed = res.data['used'] as int?;
        _aiLimit = res.data['limit'] as int?;
        _aiUnlimited = res.data['unlimited'] as bool? ?? false;
      });
    } catch (_) {}
  }

  void _addIngredient() {
    final value = _ingredientController.text.trim();
    if (value.isEmpty) return;
    setState(() {
      _ingredients.add(value);
      _ingredientController.clear();
    });
  }

  Future<void> _generate() async {
    if (_ingredients.isEmpty) {
      setState(() => _error = 'Agregá al menos un ingrediente.');
      return;
    }
    setState(() {
      _isGenerating = true;
      _error = null;
    });
    try {
      final recipe = await context.read<RecipesProvider>().generateFromIngredients(
            availableIngredients: _ingredients,
            budget: _budget,
            maxPrepTimeMinutes: _maxPrepTimeMinutes,
            freeTextRequest: _freeTextController.text.trim().isEmpty
                ? null
                : _freeTextController.text.trim(),
          );
      if (!mounted) return;
      _loadAiInfo();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => RecipeDetailScreen(initialRecipe: recipe)),
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      String msg = 'No se pudo generar la receta. Intentá de nuevo.';
      if (data is Map && data['message'] != null) {
        msg = data['message'].toString();
      } else if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        msg = 'Sin conexión. Verificá tu internet e intentá de nuevo.';
      }
      setState(() => _error = msg);
    } catch (e) {
      setState(() => _error = 'Error inesperado: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  void dispose() {
    _ingredientController.dispose();
    _freeTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Generar receta con IA')),
      body: SafeArea(
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_aiUsed != null && _aiLimit != null) ...[
              if (_aiUnlimited)
                Row(children: [
                  Icon(Icons.all_inclusive,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 6),
                  Text('IA ilimitada activada',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.primary)),
                ])
              else ...[
                LinearProgressIndicator(
                  value: _aiUsed! / _aiLimit!,
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                const SizedBox(height: 4),
                Text(
                  '$_aiUsed/$_aiLimit generaciones de IA usadas este mes',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Expanded(
                  child: Text('¿Qué ingredientes tenés?',
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                TextButton.icon(
                  onPressed: _loadingInventory ? null : _loadFromInventory,
                  icon: _loadingInventory
                      ? const SizedBox(
                          height: 14,
                          width: 14,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.inventory_2_outlined, size: 18),
                  label: const Text('Usar mi inventario'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ingredientController,
                    decoration: const InputDecoration(
                      hintText: 'Ej: arroz, pollo, cebolla…',
                    ),
                    onSubmitted: (_) => _addIngredient(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _addIngredient,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _ingredients
                  .map((ing) => Chip(
                        label: Text(ing),
                        onDeleted: () => setState(() => _ingredients.remove(ing)),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 24),
            Text('Preferencias (opcional)',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _budget,
              decoration: const InputDecoration(labelText: 'Presupuesto'),
              items: const [
                DropdownMenuItem(value: 'low', child: Text('Económico')),
                DropdownMenuItem(value: 'medium', child: Text('Medio')),
                DropdownMenuItem(value: 'high', child: Text('Sin restricción')),
              ],
              onChanged: (value) => setState(() => _budget = value),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Tiempo máximo de preparación (minutos)',
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) =>
                  _maxPrepTimeMinutes = int.tryParse(value),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _freeTextController,
              decoration: const InputDecoration(
                labelText: 'Pedido libre (ej: "quiero algo dulce")',
              ),
              maxLines: 2,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _isGenerating ? null : _generate,
              icon: _isGenerating
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.auto_awesome),
              label: const Text('Generar receta'),
            ),
          ],
        ),
        ),
      ),
    );
  }
}
