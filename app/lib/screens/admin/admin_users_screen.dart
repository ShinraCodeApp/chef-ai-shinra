import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user.dart';
import '../../providers/admin_provider.dart';

const _roles = ['user', 'admin'];

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

  Future<void> _changeRole(User user) async {
    final newRole = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text('Rol de ${user.name}'),
        children: _roles
            .map((role) => SimpleDialogOption(
                  onPressed: () => Navigator.of(ctx).pop(role),
                  child: Row(
                    children: [
                      if (role == user.role) const Icon(Icons.check, size: 18),
                      if (role == user.role) const SizedBox(width: 8),
                      Text(role),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
    if (newRole == null || newRole == user.role) return;
    final ok = await context.read<AdminProvider>().updateUserRole(user.id, newRole);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Rol actualizado.' : 'No se pudo actualizar el rol.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Usuarios')),
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
                            child: const Text('Cargar más'),
                          ),
                        ),
                      );
                    }
                    return const SizedBox(height: 24);
                  }
                  final user = provider.users[index];
                  return ListTile(
                    title: Text(user.name),
                    subtitle: Text(user.email),
                    trailing: Chip(
                      label: Text(user.role),
                      backgroundColor: user.role == 'admin'
                          ? Theme.of(context).colorScheme.primaryContainer
                          : null,
                    ),
                    onTap: () => _changeRole(user),
                  );
                },
              ),
            ),
    );
  }
}
