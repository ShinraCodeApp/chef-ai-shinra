import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import 'admin_ingredients_screen.dart';
import 'admin_recipes_screen.dart';
import 'admin_users_screen.dart';
import '../../core/i18n.dart';

class AdminStatsScreen extends StatefulWidget {
  const AdminStatsScreen({super.key});

  @override
  State<AdminStatsScreen> createState() => _AdminStatsScreenState();
}

class _AdminStatsScreenState extends State<AdminStatsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final stats = provider.stats;
    return Scaffold(
      appBar: AppBar(title: Text(tr('Panel de administración'))),
      body: RefreshIndicator(
        onRefresh: () => provider.loadStats(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            if (provider.isLoadingStats && stats == null)
              const Padding(
                padding: EdgeInsets.only(top: 60),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (stats != null) ...[
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: [
                  _StatCard(label: tr('Usuarios'), value: stats.totalUsers, icon: Icons.people_outline),
                  _StatCard(
                      label: tr('Recetas'), value: stats.totalRecipes, icon: Icons.menu_book_outlined),
                  _StatCard(
                      label: tr('Generadas por IA'),
                      value: stats.aiGeneratedRecipes,
                      icon: Icons.auto_awesome),
                  _StatCard(
                      label: tr('Ingredientes'),
                      value: stats.totalIngredients,
                      icon: Icons.egg_outlined),
                  _StatCard(
                      label: tr('Ítems en inventarios'),
                      value: stats.totalInventoryItems,
                      icon: Icons.kitchen_outlined),
                ],
              ),
            ],
            const SizedBox(height: 24),
            Card(
              child: ListTile(
                leading: const Icon(Icons.manage_accounts_outlined),
                title: Text(tr('Gestionar usuarios')),
                subtitle: Text(tr('Ver y eliminar usuarios')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AdminUsersScreen()),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.menu_book_outlined),
                title: Text(tr('Gestionar recetas')),
                subtitle: Text(tr('Ver y eliminar cualquier receta')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AdminRecipesScreen()),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.egg_outlined),
                title: Text(tr('Gestionar ingredientes')),
                subtitle: Text(tr('Catálogo, info nutricional y precios')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AdminIngredientsScreen()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;

  const _StatCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: scheme.onPrimaryContainer),
            const SizedBox(height: 8),
            Text('$value',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(color: scheme.onPrimaryContainer)),
            Text(label, style: TextStyle(color: scheme.onPrimaryContainer)),
          ],
        ),
      ),
    );
  }
}
