import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/ingredient.dart';
import '../../providers/admin_provider.dart';

const _units = ['g', 'kg', 'ml', 'l', 'unidad'];
const _categories = [
  'carnes',
  'verduras',
  'frutas',
  'lacteos',
  'congelados',
  'bebidas',
  'panaderia',
  'limpieza',
  'condimentos',
  'otros',
];

/// Formulario de admin para crear o editar un ingrediente del catálogo,
/// incluyendo su información nutricional por cada 100g.
class AdminIngredientEditScreen extends StatefulWidget {
  final Ingredient? ingredient;

  const AdminIngredientEditScreen({super.key, this.ingredient});

  @override
  State<AdminIngredientEditScreen> createState() => _AdminIngredientEditScreenState();
}

class _AdminIngredientEditScreenState extends State<AdminIngredientEditScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _barcodeController;
  late final TextEditingController _caloriesController;
  late final TextEditingController _proteinController;
  late final TextEditingController _fatController;
  late final TextEditingController _carbsController;
  late final TextEditingController _fiberController;
  late final TextEditingController _sugarController;
  late final TextEditingController _sodiumController;
  late String _category;
  late String _unit;
  bool _isSaving = false;
  String? _error;

  bool get _isEditing => widget.ingredient != null;

  @override
  void initState() {
    super.initState();
    final ing = widget.ingredient;
    _nameController = TextEditingController(text: ing?.name ?? '');
    _barcodeController = TextEditingController(text: ing?.barcode ?? '');
    _caloriesController = TextEditingController(text: ing?.caloriesPer100g?.toString() ?? '');
    _proteinController = TextEditingController(text: ing?.proteinPer100g?.toString() ?? '');
    _fatController = TextEditingController(text: ing?.fatPer100g?.toString() ?? '');
    _carbsController = TextEditingController(text: ing?.carbsPer100g?.toString() ?? '');
    _fiberController = TextEditingController(text: ing?.fiberPer100g?.toString() ?? '');
    _sugarController = TextEditingController(text: ing?.sugarPer100g?.toString() ?? '');
    _sodiumController = TextEditingController(text: ing?.sodiumPer100g?.toString() ?? '');
    _category = ing?.category ?? 'otros';
    _unit = ing?.unit ?? 'unidad';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _fatController.dispose();
    _carbsController.dispose();
    _fiberController.dispose();
    _sugarController.dispose();
    _sodiumController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'El nombre es obligatorio.');
      return;
    }
    setState(() {
      _isSaving = true;
      _error = null;
    });
    final data = {
      'name': name,
      'category': _category,
      'unit': _unit,
      if (_barcodeController.text.trim().isNotEmpty)
        'barcode': _barcodeController.text.trim(),
      if (_caloriesController.text.isNotEmpty)
        'caloriesPer100g': double.tryParse(_caloriesController.text),
      if (_proteinController.text.isNotEmpty)
        'proteinPer100g': double.tryParse(_proteinController.text),
      if (_fatController.text.isNotEmpty) 'fatPer100g': double.tryParse(_fatController.text),
      if (_carbsController.text.isNotEmpty)
        'carbsPer100g': double.tryParse(_carbsController.text),
      if (_fiberController.text.isNotEmpty)
        'fiberPer100g': double.tryParse(_fiberController.text),
      if (_sugarController.text.isNotEmpty)
        'sugarPer100g': double.tryParse(_sugarController.text),
      if (_sodiumController.text.isNotEmpty)
        'sodiumPer100g': double.tryParse(_sodiumController.text),
    };
    final provider = context.read<AdminProvider>();
    final ok = _isEditing
        ? await provider.updateIngredient(widget.ingredient!.id, data)
        : await provider.createIngredient(data);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _isSaving = false;
        _error = 'No se pudo guardar el ingrediente.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Editar ingrediente' : 'Nuevo ingrediente')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _category,
                    decoration: const InputDecoration(labelText: 'Categoría'),
                    items: _categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (value) => setState(() => _category = value ?? 'otros'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _unit,
                    decoration: const InputDecoration(labelText: 'Unidad'),
                    items: _units
                        .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                        .toList(),
                    onChanged: (value) => setState(() => _unit = value ?? 'unidad'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _barcodeController,
              decoration: const InputDecoration(labelText: 'Código de barras (opcional)'),
            ),
            const SizedBox(height: 20),
            Text('Info. nutricional cada 100g (opcional)',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _caloriesController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Calorías'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _proteinController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Proteína (g)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _fatController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Grasas (g)'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _carbsController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Carbs (g)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _fiberController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Fibra (g)'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _sugarController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Azúcares (g)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _sodiumController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Sodio (mg)'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
