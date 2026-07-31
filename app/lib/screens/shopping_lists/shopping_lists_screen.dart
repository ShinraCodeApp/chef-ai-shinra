import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/shopping_lists_provider.dart';
import '../../widgets/empty_state.dart';

class ShoppingListsScreen extends StatefulWidget {
  const ShoppingListsScreen({super.key});

  @override
  State<ShoppingListsScreen> createState() => _ShoppingListsScreenState();
}

class _ShoppingListsScreenState extends State<ShoppingListsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShoppingListsProvider>().load();
    });
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
                        }).toList(),
                      ),
                    );
                  },
                ),
            ),
    );
  }
}
