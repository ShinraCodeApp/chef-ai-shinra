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
import '../../core/i18n.dart';

Map<String, String> get _mealTypeLabels => {
  'breakfast': tr('Desayuno'),
  'mid_morning': tr('Colación mañana'),
  'lunch': tr('Almuerzo'),
  'post_workout': tr('Post-entreno'),
  'snack': tr('Merienda'),
  'dinner': tr('Cena'),
};

const _defaultMealTypes = ['breakfast', 'lunch', 'snack', 'dinner'];

Map<String, String> get _goalLabels => {
  'lose_weight': tr('Bajar de peso'),
  'gain_muscle': tr('Ganar músculo'),
  'maintain': tr('Mantenerme'),
  'eat_healthier': tr('Comer más sano'),
  'save_money': tr('Ahorrar dinero'),
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
          SnackBar(content: Text(tr('No se pudo generar el plan.'))),
        );
      }
    }
  }

  Future<void> _onToggleEntry(MealPlan plan, MealPlanEntry entry) async {
    final provider = context.read<MealPlansProvider>();
    final dayCompleted = await provider.toggleEntryCompleted(plan.id, entry.id);
    if (dayCompleted && mounted) {
      final streak = provider.streakForPlan(plan);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(streak > 1
              ? tr('¡Completaste el día! 🔥 Racha: {streak} días seguidos', {'streak': streak})
              : tr('¡Completaste el día! 🎉')),
        ),
      );
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
        SnackBar(content: Text(tr('No se pudo generar la lista de compras.'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MealPlansProvider>();
    final user = context.watch<AuthProvider>().currentUser;
    return Scaffold(
      appBar: AppBar(title: Text(tr('Plan semanal'))),
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
                  children: [
                    SizedBox(height: 80),
                    EmptyState(
                      icon: Icons.calendar_month_outlined,
                      message: tr('Todavía no generaste ningún plan de comidas.'),
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
                    final streak = provider.streakForPlan(plan);
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ExpansionTile(
                        title: Text('${plan.startDate} → ${plan.endDate}'),
                        subtitle: Text(streak > 0
                            ? tr('{plan} comidas planificadas · 🔥 {streak} días seguidos', {'plan': plan.entries.length, 'streak': streak})
                            : tr('{plan} comidas planificadas', {'plan': plan.entries.length})),
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
                                          onChanged: (_) => _onToggleEntry(plan, e),
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
                              label: Text(tr('Generar lista de compras')),
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
        label: Text(tr('Generar plan')),
      ),
    );
  }

  String _formatDayHeader(String dateKey) {
    final date = DateTime.tryParse(dateKey);
    if (date == null) return dateKey;
    final formatted = DateFormat(tr('EEEE d/MM'), 'es').format(date);
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
      title: Text(tr('Generar plan semanal')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr('¿Para cuántos días?')),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              segments: [
                ButtonSegment(value: 7, label: Text(tr('7 días'))),
                ButtonSegment(value: 15, label: Text(tr('15 días'))),
                ButtonSegment(value: 30, label: Text(tr('30 días'))),
              ],
              selected: {_days},
              onSelectionChanged: (s) => setState(() => _days = s.first),
            ),
            const SizedBox(height: 20),
            Text(tr('¿Qué comidas incluye el día?')),
            Text(
              tr('Sumá colación de media mañana o post-entreno para planes con más comidas, '
              'como los de fisicoculturismo.'),
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
          child: Text(tr('Cancelar')),
        ),
        FilledButton(
          onPressed: _selectedMealTypes.isEmpty
              ? null
              : () => Navigator.of(context)
                  .pop(_GenerateChoice(_days, _selectedMealTypes.toList())),
          child: Text(tr('Generar')),
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
                  Text(tr('Mi objetivo: {definir}', {'definir': goalLabel ?? tr('sin definir')}),
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
              child: Text(tr('Editar')),
            ),
          ],
        ),
      ),
    );
  }
}
