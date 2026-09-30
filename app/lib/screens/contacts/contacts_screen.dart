import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/contact.dart';
import '../../providers/contacts_provider.dart';
import 'contact_inventory_screen.dart';
import 'phone_contacts_screen.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ContactsProvider>().loadAll();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendInvite() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;
    final error = await context.read<ContactsProvider>().sendInvite(email);
    if (!mounted) return;
    if (error == null) {
      _emailController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invitación enviada')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<void> _removeContact(Contact contact) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar contacto'),
        content: Text('¿Eliminar a ${contact.name} de tus contactos?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final error = await context.read<ContactsProvider>().removeContact(contact.contactId);
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ContactsProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contactos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.contacts_outlined),
            tooltip: 'Buscar contactos con la app',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PhoneContactsScreen()),
            ),
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => provider.loadAll(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  // Invitar por email
                  Text('Invitar por email', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    'O usá el ícono de contactos arriba para ver quiénes ya tienen la app.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(hintText: 'Email del usuario…'),
                          onSubmitted: (_) => _sendInvite(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: _sendInvite,
                        icon: const Icon(Icons.person_add),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Invitaciones pendientes recibidas
                  if (provider.pendingInvites.isNotEmpty) ...[
                    Text('Invitaciones pendientes',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ...provider.pendingInvites.map((inv) => Card(
                          child: ListTile(
                            leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                            title: Text(inv.from.name),
                            subtitle: Text(inv.from.email),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.check, color: Colors.green),
                                  tooltip: 'Aceptar',
                                  onPressed: () => provider.respondInvite(inv.contactId, true),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.red),
                                  tooltip: 'Rechazar',
                                  onPressed: () => provider.respondInvite(inv.contactId, false),
                                ),
                              ],
                            ),
                          ),
                        )),
                    const SizedBox(height: 24),
                  ],

                  // Contactos aceptados
                  Text('Mis contactos', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (provider.contacts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'Todavía no tenés contactos.\nInvitá a alguien por email o buscá tus contactos del celular.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                    )
                  else
                    ...provider.contacts.map((c) => Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: c.isFavorite
                                  ? Theme.of(context).colorScheme.primaryContainer
                                  : null,
                              child: Text(c.name[0].toUpperCase()),
                            ),
                            title: Row(
                              children: [
                                Text(c.name),
                                if (c.isFavorite) ...[
                                  const SizedBox(width: 4),
                                  Icon(Icons.favorite,
                                      size: 14,
                                      color: Theme.of(context).colorScheme.error),
                                ],
                              ],
                            ),
                            subtitle: Text(c.email),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    c.isFavorite ? Icons.favorite : Icons.favorite_border,
                                    color: c.isFavorite
                                        ? Theme.of(context).colorScheme.error
                                        : null,
                                  ),
                                  tooltip: c.isFavorite ? 'Quitar favorito' : 'Agregar a favoritos',
                                  onPressed: () => provider.toggleFavorite(c.contactId),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  tooltip: 'Eliminar contacto',
                                  onPressed: () => _removeContact(c),
                                ),
                              ],
                            ),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ContactInventoryScreen(contact: c),
                              ),
                            ),
                          ),
                        )),
                ],
              ),
            ),
    );
  }
}
