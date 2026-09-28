import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/diet_tags.dart';
import '../../core/meal_type_schedule.dart';
import '../../models/meal_plan.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/meal_plans_provider.dart';
import '../../providers/shopping_lists_provider.dart';
import '../../widgets/empty_state.dart';
import '../profile/profile_screen.dart';
import '../recipes/recipe_detail_screen.dart';
import '../shopping_lists/shopping_lists_screen.dart';

const _mealTypeLabels = {
  'breakfast': 'Desayuno',
  'mid_morning': 'Colación mañana',
  'lunch': 'Almuerzo',
  'post_workout': 'Post-entreno',
  'snack': 'Merienda',
  'dinner': 'Cena',
};

const _defaultMealTypes = ['breakfast', 'lunch', 'snack', 'dinner'];

const _goalLabels = {
  'lose_weight': 'Bajar de peso',
  'gain_muscle': 'Ganar músculo',
  'maintain': 'Mantenerme',
  'eat_healthier': 'Comer más sano',
  'save_money': 'Ahorrar dinero',
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
    final result = await showDialog<_GenerateChoice>(
      context: context,
      builder: (ctx) => const _GeneratePlanDialog(),
    );
    if (result == null || !mounted) return;
    setState(() => _isGenerating = true);
    final plan = await context
        .read<MealPlansProvider>()
        .generate(result.days, mealTypes: result.mealTypes);
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
    final user = context.watch<AuthProvider>().currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Plan semanal')),
      body: Column(
        children: [
          if (user != null) _DietSummaryCard(user: user),
          Expanded(
            child: provider.isLoading && provider.mealPlans.isEmpty
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
                    final entriesByDate = <String, List<MealPlanEntry>>{};
                    for (final entry in plan.entries) {
                      entriesByDate.putIfAbsent(entry.date, () => []).add(entry);
                    }
                    final sortedDates = entriesByDate.keys.toList()..sort();
                    for (final dateKey in sortedDates) {
                      entriesByDate[dateKey]!.sort((a, b) {
                        final orderA = kMealTypeOrder.indexOf(a.mealType);
                        final orderB = kMealTypeOrder.indexOf(b.mealType);
                        return orderA.compareTo(orderB);
                      });
                    }
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ExpansionTile(
                        title: Text('${plan.startDate} → ${plan.endDate}'),
                        subtitle: Text('${plan.entries.length} comidas planificadas'),
                        children: [
                          ...sortedDates.map((dateKey) => Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 6),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_formatDayHeader(dateKey),
                                        style: Theme.of(context).textTheme.titleSmall),
                                    ...entriesByDate[dateKey]!.map((e) => CheckboxListTile(
                                          controlAffinity: ListTileControlAffinity.leading,
                                          contentPadding: EdgeInsets.zero,
                                          value: e.completed,
                                          onChanged: (_) => context
                                              .read<MealPlansProvider>()
                                              .toggleEntryCompleted(plan.id, e.id),
                                          title: Text(
                                            e.recipe.title,
                                            style: e.completed
                                                ? const TextStyle(
                                                    decoration: TextDecoration.lineThrough)
                                                : null,
                                          ),
                                          subtitle: Text(
                                              _mealTypeLabels[e.mealType] ?? e.mealType),
                                          secondary: IconButton(
                                            icon: const Icon(Icons.chevron_right),
                                            onPressed: () => Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) => RecipeDetailScreen(
                                                    recipeId: e.recipe.id),
                                              ),
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
          ),
        ],
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

  String _formatDayHeader(String dateKey) {
    final date = DateTime.tryParse(dateKey);
    if (date == null) return dateKey;
    final formatted = DateFormat('EEEE d/MM', 'es').format(date);
    return formatted[0].toUpperCase() + formatted.substring(1);
  }
}

class _GenerateChoice {
  final int days;
  final List<String> mealTypes;
  _GenerateChoice(this.days, this.mealTypes);
}

class _GeneratePlanDialog extends StatefulWidget {
  const _GeneratePlanDialog();

  @override
  State<_GeneratePlanDialog> createState() => _GeneratePlanDialogState();
}

class _GeneratePlanDialogState extends State<_GeneratePlanDialog> {
  int _days = 7;
  final Set<String> _selectedMealTypes = _defaultMealTypes.toSet();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Generar plan semanal'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('¿Para cuántos días?'),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 7, label: Text('7 días')),
                ButtonSegment(value: 15, label: Text('15 días')),
                ButtonSegment(value: 30, label: Text('30 días')),
              ],
              selected: {_days},
              onSelectionChanged: (s) => setState(() => _days = s.first),
            ),
            const SizedBox(height: 20),
            const Text('¿Qué comidas incluye el día?'),
            const Text(
              'Sumá colación de media mañana o post-entreno para planes con más comidas, '
              'como los de fisicoculturismo.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            ..._mealTypeLabels.entries.map((entry) => CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(entry.value),
                  value: _selectedMealTypes.contains(entry.key),
                  onChanged: (checked) => setState(() {
                    if (checked == true) {
                      _selectedMealTypes.add(entry.key);
                    } else {
                      _selectedMealTypes.remove(entry.key);
                    }
                  }),
                )),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _selectedMealTypes.isEmpty
              ? null
              : () => Navigator.of(context)
                  .pop(_GenerateChoice(_days, _selectedMealTypes.toList())),
          child: const Text('Generar'),
        ),
      ],
    );
  }
}

class _DietSummaryCard extends StatelessWidget {
  final User user;

  const _DietSummaryCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final goalLabel = user.goal != null ? _goalLabels[user.goal] ?? user.goal : null;
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mi objetivo: ${goalLabel ?? 'sin definir'}',
                      style: Theme.of(context).textTheme.titleSmall),
                  if (user.dietPreferences.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: user.dietPreferences
                          .map((tag) => Chip(
                                label: Text(dietTagLabel(tag)),
                                visualDensity: VisualDensity.compact,
                              ))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
              child: const Text('Editar'),
            ),
          ],
        ),
      ),
    );
  }
}
