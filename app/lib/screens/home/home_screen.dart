import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../generate_recipe/generate_recipe_screen.dart';
import '../generate_recipe/scan_inventory_screen.dart';
import '../generate_recipe/scan_meal_screen.dart';
import '../generate_recipe/voice_inventory_screen.dart';
import '../generate_recipe/scan_receipt_screen.dart';
import '../inventory/inventory_screen.dart';
import '../recipes/recipes_list_screen.dart';
import '../recipes/favorites_screen.dart';
import '../recipes/create_recipe_screen.dart';
import '../meal_plans/meal_plans_screen.dart';
import '../shopping_lists/shopping_lists_screen.dart';
import '../profile/profile_screen.dart';
import '../admin/admin_stats_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final name = auth.currentUser?.name.split(' ').first ?? '';
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Buenos días'
        : hour < 19
            ? 'Buenas tardes'
            : 'Buenas noches';

    final actions = <_QuickAction>[
      _QuickAction('Generar receta', Icons.auto_awesome,
          (ctx) => const GenerateRecipeScreen()),
      _QuickAction('Sacar foto', Icons.camera_alt, (ctx) => const ScanInventoryScreen()),
      _QuickAction('Escanear ticket', Icons.receipt_long,
          (ctx) => const ScanReceiptScreen()),
      _QuickAction('Calorías de mi plato', Icons.restaurant_menu,
          (ctx) => const ScanMealScreen()),
      _QuickAction('Mi inventario', Icons.kitchen, (ctx) => const InventoryScreen()),
      _QuickAction('Dictar inventario', Icons.mic, (ctx) => const VoiceInventoryScreen()),
      _QuickAction('Recetas', Icons.menu_book, (ctx) => const RecipesListScreen()),
      _QuickAction('Comida proteica', Icons.fitness_center,
          (ctx) => const RecipesListScreen(initialDietTag: 'proteico')),
      _QuickAction('Comida vegana', Icons.eco,
          (ctx) => const RecipesListScreen(initialDietTag: 'vegano')),
      _QuickAction('Hipotiroidismo', Icons.medical_information_outlined,
          (ctx) => const RecipesListScreen(initialDietTag: 'hipotiroidismo')),
      _QuickAction('Hipertiroidismo', Icons.medical_information_outlined,
          (ctx) => const RecipesListScreen(initialDietTag: 'hipertiroidismo')),
      _QuickAction('Favoritos', Icons.favorite, (ctx) => const FavoritesScreen()),
      _QuickAction('Compartir receta', Icons.share, (ctx) => const CreateRecipeScreen()),
      _QuickAction('Plan semanal', Icons.calendar_month,
          (ctx) => const MealPlansScreen()),
      _QuickAction('Listas de compras', Icons.shopping_cart,
          (ctx) => const ShoppingListsScreen()),
      if (auth.currentUser?.role == 'admin')
        _QuickAction('Panel Admin', Icons.admin_panel_settings,
            (ctx) => const AdminStatsScreen()),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chef AI by Shinra'),
        actions: [
          PopupMenuButton<ThemeMode>(
            icon: const Icon(Icons.brightness_6_outlined),
            onSelected: (mode) => context.read<ThemeModeController>().setMode(mode),
            itemBuilder: (_) => const [
              PopupMenuItem(value: ThemeMode.light, child: Text('Claro')),
              PopupMenuItem(value: ThemeMode.dark, child: Text('Oscuro')),
              PopupMenuItem(value: ThemeMode.system, child: Text('Automático')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$greeting, $name.',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text('¿Qué cocinaremos hoy?',
                  style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 24),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.3,
                  children: actions
                      .map((action) => _ActionCard(action: action))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction {
  final String label;
  final IconData icon;
  final Widget Function(BuildContext) builder;

  _QuickAction(this.label, this.icon, this.builder);
}

class _ActionCard extends StatelessWidget {
  final _QuickAction action;

  const _ActionCard({required this.action});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.secondaryContainer,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: action.builder)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(action.icon, size: 32, color: scheme.onSecondaryContainer),
              const SizedBox(height: 8),
              Text(
                action.label,
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.onSecondaryContainer),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
