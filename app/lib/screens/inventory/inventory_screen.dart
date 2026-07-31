import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/inventory_provider.dart';
import '../../widgets/empty_state.dart';
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
      appBar: AppBar(title: const Text('Mi inventario')),
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
                            subtitle: Text(
                              '${item.quantity} ${item.unit} · ${_stateLabels[item.state] ?? item.state}'
                              '${item.expirationDate != null ? ' · vence ${item.expirationDate}' : ''}',
                            ),
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
