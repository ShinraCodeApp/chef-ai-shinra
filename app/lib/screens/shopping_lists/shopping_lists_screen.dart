import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/shopping_lists_provider.dart';
import '../../widgets/empty_state.dart';

class ShoppingListsScreen extends StatefulWidget {
  const ShoppingListsScreen({super.key});

  @override
  State<ShoppingListsScreen> createState() => _ShoppingListsScreenState();
}

const _units = ['g', 'kg', 'ml', 'l', 'unidad'];

class _ShoppingListsScreenState extends State<ShoppingListsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShoppingListsProvider>().load();
    });
  }

  Future<void> _createList() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nueva lista de compras'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nombre de la lista'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(
                controller.text.trim().isEmpty ? 'Lista de compras' : controller.text.trim()),
            child: const Text('Crear'),
          ),
        ],
      ),
    );
    if (name == null || !mounted) return;
    final ok = await context.read<ShoppingListsProvider>().createList(name);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('No se pudo crear la lista.')));
    }
  }

  Future<void> _addItem(String listId) async {
    final nameController = TextEditingController();
    final quantityController = TextEditingController(text: '1');
    var unit = 'unidad';
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Agregar ítem'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Ítem'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: quantityController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Cantidad'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: unit,
                      decoration: const InputDecoration(labelText: 'Unidad'),
                      items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                      onChanged: (value) => setDialogState(() => unit = value ?? 'unidad'),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Agregar')),
          ],
        ),
      ),
    );
    if (result != true || !mounted) return;
    final name = nameController.text.trim();
    final quantity = double.tryParse(quantityController.text) ?? 1;
    if (name.isEmpty) return;
    final ok = await context
        .read<ShoppingListsProvider>()
        .addCustomItem(listId, name: name, quantity: quantity, unit: unit);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('No se pudo agregar el ítem.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ShoppingListsProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Listas de compras')),
      body: provider.isLoading && provider.lists.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => provider.load(),
              child: provider.lists.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 80),
                    EmptyState(
                      icon: Icons.shopping_cart_outlined,
                      message:
                          'No tenés listas todavía. Generá una desde un plan semanal.',
                    ),
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: provider.lists.length,
                  itemBuilder: (context, index) {
                    final list = provider.lists[index];
                    final byCategory = <String, List<dynamic>>{};
                    for (final item in list.items) {
                      byCategory.putIfAbsent(item.category, () => []).add(item);
                    }
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ExpansionTile(
                        title: Text(list.name),
                        subtitle: Text('${list.items.length} ítems'),
                        children: byCategory.entries.expand((entry) {
                          return [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(entry.key,
                                    style: Theme.of(context).textTheme.labelLarge),
                              ),
                            ),
                            ...entry.value.map((item) => CheckboxListTile(
                                  value: item.isChecked,
                                  title: Text(
                                    item.displayName,
                                    style: item.isChecked
                                        ? const TextStyle(decoration: TextDecoration.lineThrough)
                                        : null,
                                  ),
                                  subtitle: Text('${item.quantity} ${item.unit}'),
                                  onChanged: (_) => context
                                      .read<ShoppingListsProvider>()
                                      .toggleItem(list.id, item.id),
                                  secondary: IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () => context
                                        .read<ShoppingListsProvider>()
                                        .removeItem(list.id, item.id),
                                  ),
                                )),
                          ];
                        }).toList()
                          ..add(
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: OutlinedButton.icon(
                                onPressed: () => _addItem(list.id),
                                icon: const Icon(Icons.add),
                                label: const Text('Agregar ítem'),
                              ),
                            ),
                          ),
                      ),
                    );
                  },
                ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createList,
        tooltip: 'Nueva lista',
        child: const Icon(Icons.add),
      ),
    );
  }
}
