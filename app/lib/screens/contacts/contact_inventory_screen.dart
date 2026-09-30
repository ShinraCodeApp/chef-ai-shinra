import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/contact.dart';
import '../../models/inventory_item.dart';
import '../../providers/contacts_provider.dart';

class ContactInventoryScreen extends StatefulWidget {
  final Contact contact;

  const ContactInventoryScreen({super.key, required this.contact});

  @override
  State<ContactInventoryScreen> createState() => _ContactInventoryScreenState();
}

class _ContactInventoryScreenState extends State<ContactInventoryScreen> {
  List<InventoryItem>? _items;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    final items = await context.read<ContactsProvider>().getContactInventory(widget.contact.userId);
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
      if (items == null) _error = 'No se pudo cargar el inventario';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Inventario de ${widget.contact.name}'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _items!.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 80),
                            Center(child: Text('El inventario de este contacto está vacío')),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(8),
                          itemCount: _items!.length,
                          itemBuilder: (context, index) {
                            final item = _items![index];
                            return ListTile(
                              leading: const Icon(Icons.kitchen_outlined),
                              title: Text(item.ingredient.name),
                              subtitle: Text(item.state),
                              trailing: Text(
                                '${item.quantity % 1 == 0 ? item.quantity.toInt() : item.quantity} ${item.unit}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}
