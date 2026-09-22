import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/nutrition.dart';
import '../../models/inventory_item.dart';
import '../../providers/inventory_provider.dart';
import '../../widgets/empty_state.dart';
import '../generate_recipe/voice_inventory_screen.dart';
import 'add_inventory_item_screen.dart';

const _stateLabels = {
  'fresh': 'Fresco',
  'frozen': 'Congelado',
  'opened': 'Abierto',
  'cooked': 'Cocido',
  'expired': 'Vencido',
};

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventoryProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi inventario'),
        actions: [
          IconButton(
            icon: const Icon(Icons.mic_outlined),
            tooltip: 'Dictar por voz',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const VoiceInventoryScreen()),
              );
              if (context.mounted) context.read<InventoryProvider>().load();
            },
          ),
        ],
      ),
      body: provider.isLoading && provider.items.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => context.read<InventoryProvider>().load(),
              child: provider.items.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 80),
                        EmptyState(
                          icon: Icons.kitchen_outlined,
                          message:
                              'Tu inventario está vacío. Agregá lo que tenés en casa.',
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: provider.items.length,
                      itemBuilder: (context, index) {
                        final item = provider.items[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            title: Text(item.ingredient.name),
                            subtitle: _ItemSubtitle(item: item),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () =>
                                  context.read<InventoryProvider>().removeItem(item.id),
                            ),
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddInventoryItemScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Agregar'),
      ),
    );
  }
}

class _ItemSubtitle extends StatelessWidget {
  final InventoryItem item;

  const _ItemSubtitle({required this.item});

  @override
  Widget build(BuildContext context) {
    final nutrition = nutritionFor(item.ingredient, item.quantity, item.unit);
    final macro = macroLabel(item.ingredient);
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${item.quantity} ${item.unit} · ${_stateLabels[item.state] ?? item.state}'
          '${item.expirationDate != null ? ' · vence ${item.expirationDate}' : ''}',
        ),
        if (nutrition.hasData || macro != null) ...[
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              if (nutrition.calories != null)
                _macroChip('${nutrition.calories!.toStringAsFixed(0)} kcal'),
              if (nutrition.proteinG != null)
                _macroChip('Proteína: ${nutrition.proteinG!.toStringAsFixed(1)}g'),
              if (nutrition.carbsG != null)
                _macroChip('Carbs: ${nutrition.carbsG!.toStringAsFixed(1)}g'),
              if (macro != null)
                Chip(
                  label: Text(macro, style: const TextStyle(fontSize: 11)),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: macro == 'Proteico'
                      ? scheme.primaryContainer
                      : scheme.tertiaryContainer,
                  padding: EdgeInsets.zero,
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _macroChip(String label) => Chip(
        label: Text(label, style: const TextStyle(fontSize: 11)),
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
      );
}
