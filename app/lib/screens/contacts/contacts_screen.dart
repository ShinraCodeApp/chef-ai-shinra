import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/contact.dart';
import '../../providers/contacts_provider.dart';
import 'contact_inventory_screen.dart';
import 'phone_contacts_screen.dart';
import '../../core/i18n.dart';

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
    final provider = context.read<ContactsProvider>();
    final error = await provider.sendInvite(email);
    if (!mounted) return;
    if (error == null) {
      _emailController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('Invitación enviada'))),
      );
    } else if (provider.lastInviteUserNotFound) {
      await _offerDownloadInvite(email);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  /// La persona no tiene cuenta: en vez de un error, ofrecemos mandarle el link
  /// de Chef AI (WhatsApp, mail, etc.). Cuando se registre con ese email, ya se
  /// la puede agregar.
  Future<void> _offerDownloadInvite(String email) async {
    final share = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('Todavía no tiene Chef AI')),
        content: Text(tr(
          '{email} no tiene una cuenta en Chef AI. ¿Querés mandarle el link para descargarla? Cuando se registre con ese email, la vas a poder agregar.',
          {'email': email},
        )),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(tr('Ahora no'))),
          FilledButton.icon(
            onPressed: () => Navigator.of(ctx).pop(true),
            icon: const Icon(Icons.share),
            label: Text(tr('Invitar a descargar')),
          ),
        ],
      ),
    );
    if (share != true || !mounted) return;
    await SharePlus.instance.share(ShareParams(
      text: tr(
        '¡Usemos Chef AI juntos! 🍳 Genera recetas con lo que tenés en casa y podemos compartir el inventario. Descargala acá: {link}',
        {'link': 'https://play.google.com/store/apps/details?id=com.shinracode.chefai'},
      ),
      subject: 'Chef AI',
    ));
  }

  Future<void> _removeContact(Contact contact) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('Eliminar contacto')),
        content: Text(tr('¿Eliminar a {contact} de tus contactos?', {'contact': contact.name})),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(tr('Cancelar'))),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(tr('Eliminar'))),
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
        title: Text(tr('Contactos')),
        actions: [
          IconButton(
            icon: const Icon(Icons.contacts_outlined),
            tooltip: tr('Buscar contactos con la app'),
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
                  Text(tr('Invitar por email'), style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    tr('O usá el ícono de contactos arriba para ver quiénes ya tienen la app.'),
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
                          decoration: InputDecoration(hintText: tr('Email del usuario…')),
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
                    Text(tr('Invitaciones pendientes'),
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
                                  tooltip: tr('Aceptar'),
                                  onPressed: () => provider.respondInvite(inv.contactId, true),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.red),
                                  tooltip: tr('Rechazar'),
                                  onPressed: () => provider.respondInvite(inv.contactId, false),
                                ),
                              ],
                            ),
                          ),
                        )),
                    const SizedBox(height: 24),
                  ],

                  // Contactos aceptados
                  Text(tr('Mis contactos'), style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (provider.contacts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          tr('Todavía no tenés contactos.\nInvitá a alguien por email o buscá tus contactos del celular.'),
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
                                  tooltip: c.isFavorite ? tr('Quitar favorito') : tr('Agregar a favoritos'),
                                  onPressed: () => provider.toggleFavorite(c.contactId),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  tooltip: tr('Eliminar contacto'),
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
