import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/contact.dart';
import '../../providers/contacts_provider.dart';
import '../../core/i18n.dart';

class PhoneContactsScreen extends StatefulWidget {
  const PhoneContactsScreen({super.key});

  @override
  State<PhoneContactsScreen> createState() => _PhoneContactsScreenState();
}

class _PhoneContactsScreenState extends State<PhoneContactsScreen> {
  List<PhoneContactWithApp>? _results;
  bool _loading = true;
  String? _error;
  final Set<String> _invited = {};
  final Set<String> _sending = {};

  @override
  void initState() {
    super.initState();
    _scan();
  }

  Future<void> _scan() async {
    setState(() { _loading = true; _error = null; });
    final provider = context.read<ContactsProvider>();
    final results = await provider.findContactsWithApp();
    if (!mounted) return;
    if (results.isEmpty) {
      // Mensaje según el motivo: antes era uno solo para todo y no se sabía qué pasaba
      final message = switch (provider.lastScanStatus) {
        ContactScanStatus.noPermission =>
          tr('Chef AI necesita permiso para leer tus contactos. Activalo en Ajustes → Apps → Chef AI → Permisos.'),
        ContactScanStatus.noEmails =>
          tr('Ninguno de tus contactos tiene email guardado. Chef AI encuentra a tus amigos por su email: invitalos escribiendo su email en la pantalla anterior.'),
        ContactScanStatus.serverError =>
          tr('No se pudo conectar con el servidor. Probá de nuevo en un minuto.'),
        _ => tr('Revisamos {count} emails de tus contactos y ninguno tiene Chef AI todavía. ¡Invitalos a descargarla!',
            {'count': '${provider.lastScanEmailCount}'}),
      };
      setState(() {
        _results = [];
        _loading = false;
        _error = message;
      });
    } else {
      setState(() { _results = results; _loading = false; });
    }
  }

  Future<void> _invite(PhoneContactWithApp contact) async {
    setState(() => _sending.add(contact.userId));
    final error = await context.read<ContactsProvider>().sendInvite(contact.email);
    if (!mounted) return;
    setState(() { _sending.remove(contact.userId); });
    if (error == null) {
      setState(() => _invited.add(contact.userId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('Invitación enviada a {contact}', {'contact': contact.name}))),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Contactos con Chef AI')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: tr('Volver a escanear'),
            onPressed: _loading ? null : _scan,
          ),
        ],
      ),
      body: _loading
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(tr('Buscando contactos con la app…')),
                ],
              ),
            )
          : _error != null && (_results == null || _results!.isEmpty)
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _results!.length,
                  itemBuilder: (context, index) {
                    final c = _results![index];
                    final alreadyContact = c.isContact;
                    final alreadyInvited = _invited.contains(c.userId);
                    final isSending = _sending.contains(c.userId);

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(child: Text(c.name[0].toUpperCase())),
                        title: Text(c.name),
                        subtitle: Text(c.email),
                        trailing: alreadyContact
                            ? Chip(
                                label: Text(tr('Contacto')),
                                avatar: Icon(
                                  Icons.check_circle,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              )
                            : alreadyInvited
                                ? Chip(label: Text(tr('Invitado')))
                                : isSending
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : FilledButton.tonal(
                                        onPressed: () => _invite(c),
                                        child: Text(tr('Invitar')),
                                      ),
                      ),
                    );
                  },
                ),
    );
  }
}
