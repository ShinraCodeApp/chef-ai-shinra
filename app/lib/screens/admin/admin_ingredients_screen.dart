import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/ingredient.dart';
import '../../providers/admin_provider.dart';
import 'admin_ingredient_edit_screen.dart';

/// Panel de admin para ver, crear, editar y eliminar ingredientes del catálogo.
class AdminIngredientsScreen extends StatefulWidget {
  const AdminIngredientsScreen({super.key});

  @override
  State<AdminIngredientsScreen> createState() => _AdminIngredientsScreenState();
}

class _AdminIngredientsScreenState extends State<AdminIngredientsScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadIngredients();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _delete(Ingredient ingredient) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar ingrediente'),
        content: Text(
            '¿Seguro que querés eliminar "${ingredient.name}"? Puede fallar si está en uso en recetas o inventarios.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final ok = await context.read<AdminProvider>().deleteIngredient(ingredient.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Ingrediente eliminado.' : 'No se pudo eliminar (¿está en uso?).')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ingredientes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Nuevo ingrediente',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AdminIngredientEditScreen()),
              );
              if (mounted) context.read<AdminProvider>().loadIngredients();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Buscar ingrediente…',
                prefixIcon: Icon(Icons.search),
              ),
              onSubmitted: (value) {
                provider.ingredientsSearch = value;
                provider.loadIngredients();
              },
            ),
          ),
          Expanded(
            child: provider.isLoadingIngredients && provider.ingredients.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => provider.loadIngredients(),
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: provider.ingredients.length + 1,
                      itemBuilder: (context, index) {
                        if (index == provider.ingredients.length) {
                          if (provider.ingredientsPage < provider.ingredientsTotalPages) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: TextButton(
                                  onPressed: provider.loadNextIngredientsPage,
                                  child: const Text('Cargar más'),
                                ),
                              ),
                            );
                          }
                          return const SizedBox(height: 24);
                        }
                        final ingredient = provider.ingredients[index];
                        return ListTile(
                          title: Text(ingredient.name),
                          subtitle: Text('${ingredient.category} · ${ingredient.unit}'),
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AdminIngredientEditScreen(ingredient: ingredient),
                              ),
                            );
                            if (mounted) context.read<AdminProvider>().loadIngredients();
                          },
                          trailing: IconButton(
                            icon: Icon(Icons.delete_outline,
                                color: Theme.of(context).colorScheme.error),
                            tooltip: 'Eliminar ingrediente',
                            onPressed: () => _delete(ingredient),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
