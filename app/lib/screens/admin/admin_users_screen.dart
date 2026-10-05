import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/i18n.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadUsers();
    });
  }

  // Ya no se cambian roles desde acá: el único admin es admin@chefai.com
  // (el servidor rechaza hacer admin a otra cuenta).

  Future<void> _deleteUser(User user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('Eliminar usuario')),
        content: Text(
            tr('¿Seguro que querés eliminar a {user} ({email})? Se borran también su inventario, recetas propias, favoritos y listas.', {'user': user.name, 'email': user.email})),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(tr('Cancelar'))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(tr('Eliminar')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final ok = await context.read<AdminProvider>().deleteUser(user.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? tr('Usuario eliminado.') : tr('No se pudo eliminar el usuario.'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final currentUserId = context.watch<AuthProvider>().currentUser?.id;
    return Scaffold(
      appBar: AppBar(title: Text(tr('Usuarios'))),
      body: provider.isLoadingUsers && provider.users.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => provider.loadUsers(),
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: provider.users.length + 1,
                itemBuilder: (context, index) {
                  if (index == provider.users.length) {
                    if (provider.page < provider.totalPages) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: TextButton(
                            onPressed: provider.loadNextUsersPage,
                            child: Text(tr('Cargar más')),
                          ),
                        ),
                      );
                    }
                    return const SizedBox(height: 24);
                  }
                  final user = provider.users[index];
                  final isSelf = user.id == currentUserId;
                  return ListTile(
                    title: Text(user.name),
                    subtitle: Text(user.email),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Chip(
                          label: Text(user.role),
                          backgroundColor: user.role == 'admin'
                              ? Theme.of(context).colorScheme.primaryContainer
                              : null,
                        ),
                        Tooltip(
                          message: user.aiUnlimited ? tr('IA ilimitada activa') : tr('IA limitada'),
                          child: IconButton(
                            icon: Icon(
                              user.aiUnlimited ? Icons.all_inclusive : Icons.auto_awesome_outlined,
                              color: user.aiUnlimited
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                            onPressed: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              final ok = await context
                                  .read<AdminProvider>()
                                  .setAiUnlimited(user.id, !user.aiUnlimited);
                              if (!mounted) return;
                              messenger.showSnackBar(SnackBar(
                                content: Text(ok
                                    ? (!user.aiUnlimited
                                        ? tr('IA ilimitada activada para {user}', {'user': user.name})
                                        : tr('IA ilimitada desactivada para {user}', {'user': user.name}))
                                    : tr('No se pudo actualizar')),
                              ));
                            },
                          ),
                        ),
                        if (!isSelf)
                          IconButton(
                            icon: Icon(Icons.delete_outline,
                                color: Theme.of(context).colorScheme.error),
                            tooltip: tr('Eliminar usuario'),
                            onPressed: () => _deleteUser(user),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}
