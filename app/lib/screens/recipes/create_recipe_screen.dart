import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/diet_tags.dart';
import '../../core/ingredients_api.dart';
import '../../models/ingredient.dart';
import '../../providers/recipes_provider.dart';
import 'recipe_detail_screen.dart';

const _units = ['g', 'kg', 'ml', 'l', 'unidad'];
const _difficulties = {'easy': 'Fácil', 'medium': 'Media', 'hard': 'Difícil'};
const _dietTagOptions = [
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

class _IngredientRow {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  String unit = 'unidad';
  Ingredient? selected;
  List<Ingredient> results = [];
  Timer? debounce;

  void dispose() {
    debounce?.cancel();
    nameController.dispose();
    quantityController.dispose();
  }
}

class CreateRecipeScreen extends StatefulWidget {
  const CreateRecipeScreen({super.key});

  @override
  State<CreateRecipeScreen> createState() => _CreateRecipeScreenState();
}

class _CreateRecipeScreenState extends State<CreateRecipeScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _servingsController = TextEditingController(text: '4');
  final _prepTimeController = TextEditingController();
  final _costController = TextEditingController();
  String _difficulty = 'easy';
  final Set<String> _dietTags = {};
  final List<TextEditingController> _stepControllers = [TextEditingController()];
  final List<_IngredientRow> _ingredientRows = [_IngredientRow()];
  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _servingsController.dispose();
    _prepTimeController.dispose();
    _costController.dispose();
    for (final c in _stepControllers) {
      c.dispose();
    }
    for (final row in _ingredientRows) {
      row.dispose();
    }
    super.dispose();
  }

  void _onIngredientNameChanged(_IngredientRow row, String value) {
    row.selected = null;
    row.debounce?.cancel();
    row.debounce = Timer(const Duration(milliseconds: 350), () async {
      if (value.trim().isEmpty) {
        setState(() => row.results = []);
        return;
      }
      final results = await IngredientsApi.search(value.trim());
      if (mounted) setState(() => row.results = results);
    });
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) {
      setState(() => _error = 'Ponele un título a la receta.');
      return;
    }
    final servings = int.tryParse(_servingsController.text);
    final prepTime = int.tryParse(_prepTimeController.text);
    if (servings == null || servings <= 0 || prepTime == null || prepTime < 0) {
      setState(() => _error = 'Revisá las porciones y el tiempo de preparación.');
      return;
    }
    final steps = _stepControllers
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (steps.isEmpty) {
      setState(() => _error = 'Agregá al menos un paso de preparación.');
      return;
    }
    final ingredients = <Map<String, dynamic>>[];
    for (final row in _ingredientRows) {
      if (row.selected == null) continue;
      final quantity = double.tryParse(row.quantityController.text);
      if (quantity == null || quantity <= 0) continue;
      ingredients.add({
        'ingredientId': row.selected!.id,
        'quantity': quantity,
        'unit': row.unit,
      });
    }
    if (ingredients.isEmpty) {
      setState(() => _error = 'Agregá al menos un ingrediente (elegido de la lista).');
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      final recipe = await context.read<RecipesProvider>().create(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim().isEmpty
                ? _titleController.text.trim()
                : _descriptionController.text.trim(),
            instructions: steps,
            servings: servings,
            prepTimeMinutes: prepTime,
            difficulty: _difficulty,
            estimatedCostTotal: double.tryParse(_costController.text),
            dietTags: _dietTags.toList(),
            ingredients: ingredients,
          );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => RecipeDetailScreen(initialRecipe: recipe)),
      );
    } catch (_) {
      setState(() => _error = 'No se pudo guardar la receta.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Compartir mi receta')),
      body: SafeArea(
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Título de la receta'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Descripción'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _servingsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Porciones'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _prepTimeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Tiempo (min)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _difficulty,
                    decoration: const InputDecoration(labelText: 'Dificultad'),
                    items: _difficulties.entries
                        .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                        .toList(),
                    onChanged: (value) => setState(() => _difficulty = value ?? 'easy'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _costController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Costo estimado (opcional)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Categorías / dietas', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _dietTagOptions
                  .map((tag) => FilterChip(
                        label: Text(dietTagLabel(tag)),
                        selected: _dietTags.contains(tag),
                        onSelected: (selected) => setState(() {
                          selected ? _dietTags.add(tag) : _dietTags.remove(tag);
                        }),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 20),
            Text('Ingredientes', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ..._ingredientRows.asMap().entries.map((entry) {
              final index = entry.key;
              final row = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: row.nameController,
                            onChanged: (value) => _onIngredientNameChanged(row, value),
                            decoration: InputDecoration(
                              labelText: 'Ingrediente',
                              suffixIcon: row.selected != null
                                  ? const Icon(Icons.check_circle, color: Colors.green)
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: row.quantityController,
                            keyboardType:
                                const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Cant.'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 90,
                          child: DropdownButtonFormField<String>(
                            initialValue: row.unit,
                            items: _units
                                .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                                .toList(),
                            onChanged: (value) =>
                                setState(() => row.unit = value ?? 'unidad'),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: _ingredientRows.length == 1
                              ? null
                              : () => setState(() {
                                    row.dispose();
                                    _ingredientRows.removeAt(index);
                                  }),
                        ),
                      ],
                    ),
                    if (row.results.isNotEmpty)
                      Card(
                        child: Column(
                          children: row.results
                              .map((ing) => ListTile(
                                    dense: true,
                                    title: Text(ing.name),
                                    onTap: () => setState(() {
                                      row.selected = ing;
                                      row.nameController.text = ing.name;
                                      row.unit = ing.unit;
                                      row.results = [];
                                    }),
                                  ))
                              .toList(),
                        ),
                      ),
                  ],
                ),
              );
            }),
            TextButton.icon(
              onPressed: () => setState(() => _ingredientRows.add(_IngredientRow())),
              icon: const Icon(Icons.add),
              label: const Text('Agregar ingrediente'),
            ),
            const SizedBox(height: 20),
            Text('Preparación', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ..._stepControllers.asMap().entries.map((entry) {
              final index = entry.key;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: Text('${index + 1}.'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: entry.value,
                        maxLines: 2,
                        decoration: const InputDecoration(hintText: 'Describí el paso'),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: _stepControllers.length == 1
                          ? null
                          : () => setState(() {
                                entry.value.dispose();
                                _stepControllers.removeAt(index);
                              }),
                    ),
                  ],
                ),
              );
            }),
            TextButton.icon(
              onPressed: () => setState(() => _stepControllers.add(TextEditingController())),
              icon: const Icon(Icons.add),
              label: const Text('Agregar paso'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.share),
              label: const Text('Compartir receta'),
            ),
          ],
        ),
        ),
      ),
    );
  }
}
