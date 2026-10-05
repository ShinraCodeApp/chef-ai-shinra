import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/nutrition.dart';
import '../../models/inventory_item.dart';
import '../../providers/inventory_provider.dart';
import '../../widgets/empty_state.dart';
import '../generate_recipe/voice_inventory_screen.dart';
import 'add_inventory_item_screen.dart';
import '../../core/i18n.dart';

Map<String, String> get _stateLabels => {
  'fresh': tr('Fresco'),
  'frozen': tr('Congelado'),
  'opened': tr('Abierto'),
  'cooked': tr('Cocido'),
  'expired': tr('Vencido'),
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
        title: Text(tr('Mi inventario')),
        actions: [
          IconButton(
            icon: const Icon(Icons.mic_outlined),
            tooltip: tr('Dictar por voz'),
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
                      children: [
                        SizedBox(height: 80),
                        EmptyState(
                          icon: Icons.kitchen_outlined,
                          message:
                              tr('Tu inventario está vacío. Agregá lo que tenés en casa.'),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
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
        label: Text(tr('Agregar')),
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
                _macroChip(tr('{v} kcal', {'v': nutrition.calories!.toStringAsFixed(0)})),
              if (nutrition.proteinG != null)
                _macroChip(tr('Proteína: {v}g', {'v': nutrition.proteinG!.toStringAsFixed(1)})),
              if (nutrition.carbsG != null)
                _macroChip(tr('Carbs: {v}g', {'v': nutrition.carbsG!.toStringAsFixed(1)})),
              if (macro != null)
                Chip(
                  label: Text(macro, style: const TextStyle(fontSize: 11)),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: macro == tr('Proteico')
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
