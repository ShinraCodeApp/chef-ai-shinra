import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/ingredients_api.dart';
import '../../models/ingredient.dart';
import '../../providers/inventory_provider.dart';

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
const _states = {
  'fresh': 'Fresco',
  'frozen': 'Congelado',
  'opened': 'Abierto',
  'cooked': 'Cocido',
};

class AddInventoryItemScreen extends StatefulWidget {
  const AddInventoryItemScreen({super.key});

  @override
  State<AddInventoryItemScreen> createState() => _AddInventoryItemScreenState();
}

class _AddInventoryItemScreenState extends State<AddInventoryItemScreen> {
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  Timer? _debounce;
  List<Ingredient> _results = [];
  Ingredient? _selected;
  String _unit = 'unidad';
  String _newIngredientCategory = 'otros';
  String _state = 'fresh';
  DateTime? _expirationDate;
  bool _isSaving = false;
  String? _error;

  void _onNameChanged(String value) {
    _selected = null;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      if (value.trim().isEmpty) {
        setState(() => _results = []);
        return;
      }
      final results = await IngredientsApi.search(value.trim());
      if (mounted) setState(() => _results = results);
    });
  }

  Future<void> _createNewIngredient() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    try {
      final ingredient = await IngredientsApi.create(
        name: name,
        category: _newIngredientCategory,
        unit: _unit,
      );
      setState(() {
        _selected = ingredient;
        _results = [];
      });
    } catch (_) {
      setState(() => _error = 'No se pudo crear el ingrediente.');
    }
  }

  Future<void> _save() async {
    if (_selected == null) {
      setState(() => _error = 'Elegí o creá un ingrediente primero.');
      return;
    }
    final quantity = double.tryParse(_quantityController.text);
    if (quantity == null || quantity <= 0) {
      setState(() => _error = 'Ingresá una cantidad válida.');
      return;
    }
    setState(() {
      _isSaving = true;
      _error = null;
    });
    final ok = await context.read<InventoryProvider>().addItem(
          ingredientId: _selected!.id,
          quantity: quantity,
          unit: _unit,
          state: _state,
          expirationDate: _expirationDate == null
              ? null
              : _expirationDate!.toIso8601String().split('T').first,
        );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _isSaving = false;
        _error = 'No se pudo agregar el ítem.';
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agregar al inventario')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              onChanged: _onNameChanged,
              decoration: InputDecoration(
                labelText: 'Ingrediente',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _selected != null
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
              ),
            ),
            if (_results.isNotEmpty)
              Card(
                child: Column(
                  children: _results
                      .map((ing) => ListTile(
                            title: Text(ing.name),
                            subtitle: Text(ing.category),
                            onTap: () => setState(() {
                              _selected = ing;
                              _nameController.text = ing.name;
                              _unit = ing.unit;
                              _results = [];
                            }),
                          ))
                      .toList(),
                ),
              ),
            if (_selected == null && _nameController.text.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('¿No está en el catálogo? Crealo:',
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 4),
              DropdownButtonFormField<String>(
                initialValue: _newIngredientCategory,
                decoration: const InputDecoration(labelText: 'Categoría'),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (value) =>
                    setState(() => _newIngredientCategory = value ?? 'otros'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _createNewIngredient,
                icon: const Icon(Icons.add),
                label: const Text('Crear ingrediente nuevo'),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _quantityController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Cantidad'),
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
            DropdownButtonFormField<String>(
              initialValue: _state,
              decoration: const InputDecoration(labelText: 'Estado'),
              items: _states.entries
                  .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (value) => setState(() => _state = value ?? 'fresh'),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_expirationDate == null
                  ? 'Sin fecha de vencimiento'
                  : 'Vence: ${_expirationDate!.toIso8601String().split('T').first}'),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now().subtract(const Duration(days: 1)),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                );
                if (picked != null) setState(() => _expirationDate = picked);
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
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
