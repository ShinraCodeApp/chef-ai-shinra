import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/meal_plans_provider.dart';
import '../../providers/shopping_lists_provider.dart';
import '../../widgets/empty_state.dart';
import '../recipes/recipe_detail_screen.dart';
import '../shopping_lists/shopping_lists_screen.dart';

const _mealTypeLabels = {
  'breakfast': 'Desayuno',
  'lunch': 'Almuerzo',
  'snack': 'Merienda',
  'dinner': 'Cena',
};

class MealPlansScreen extends StatefulWidget {
  const MealPlansScreen({super.key});

  @override
  State<MealPlansScreen> createState() => _MealPlansScreenState();
}

class _MealPlansScreenState extends State<MealPlansScreen> {
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MealPlansProvider>().load();
    });
  }

  Future<void> _generate() async {
    final days = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('¿Para cuántos días?'),
        children: [7, 15, 30]
            .map((d) => SimpleDialogOption(
                  onPressed: () => Navigator.of(ctx).pop(d),
                  child: Text('$d días'),
                ))
            .toList(),
      ),
    );
    if (days == null) return;
    setState(() => _isGenerating = true);
    final plan = await context.read<MealPlansProvider>().generate(days);
    if (mounted) {
      setState(() => _isGenerating = false);
      if (plan == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo generar el plan.')),
        );
      }
    }
  }

  Future<void> _generateShoppingList(String mealPlanId) async {
    final list =
        await context.read<ShoppingListsProvider>().generateFromMealPlan(mealPlanId);
    if (!mounted) return;
    if (list != null) {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const ShoppingListsScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo generar la lista de compras.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MealPlansProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Plan semanal')),
      body: provider.isLoading && provider.mealPlans.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => provider.load(),
              child: provider.mealPlans.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 80),
                    EmptyState(
                      icon: Icons.calendar_month_outlined,
                      message: 'Todavía no generaste ningún plan de comidas.',
                    ),
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: provider.mealPlans.length,
                  itemBuilder: (context, index) {
                    final plan = provider.mealPlans[index];
                    final entriesByDate = <String, List<dynamic>>{};
                    for (final entry in plan.entries) {
                      entriesByDate.putIfAbsent(entry.date, () => []).add(entry);
                    }
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ExpansionTile(
                        title: Text('${plan.startDate} → ${plan.endDate}'),
                        subtitle: Text('${plan.entries.length} comidas planificadas'),
                        children: [
                          ...entriesByDate.entries.map((dateEntry) => Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 6),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(dateEntry.key,
                                        style: Theme.of(context).textTheme.titleSmall),
                                    ...dateEntry.value.map((e) => ListTile(
                                          dense: true,
                                          contentPadding: EdgeInsets.zero,
                                          title: Text(e.recipe.title),
                                          subtitle: Text(
                                              _mealTypeLabels[e.mealType] ?? e.mealType),
                                          onTap: () => Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) => RecipeDetailScreen(
                                                  recipeId: e.recipe.id),
                                            ),
                                          ),
                                        )),
                                  ],
                                ),
                              )),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: OutlinedButton.icon(
                              onPressed: () => _generateShoppingList(plan.id),
                              icon: const Icon(Icons.shopping_cart_outlined),
                              label: const Text('Generar lista de compras'),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isGenerating ? null : _generate,
        icon: _isGenerating
            ? const SizedBox(
                height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.auto_awesome),
        label: const Text('Generar plan'),
      ),
    );
  }
}
