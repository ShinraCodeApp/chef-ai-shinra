import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  String? _error;

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
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => RecipeDetailScreen(initialRecipe: recipe)),
      );
    } catch (_) {
      setState(() => _error =
          'No se pudo generar la receta. Revisá que el backend tenga GEMINI_API_KEY configurada.');
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
            Text('¿Qué ingredientes tenés?',
                style: Theme.of(context).textTheme.titleMedium),
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
