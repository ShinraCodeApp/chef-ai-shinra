import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/diet_tags.dart';
import '../../core/meal_type_schedule.dart';
import '../../models/meal_plan.dart';
import '../../models/recipe.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/meal_plans_provider.dart';
import '../../providers/shopping_lists_provider.dart';
import '../../widgets/empty_state.dart';
import '../profile/profile_screen.dart';
import '../recipes/recipe_detail_screen.dart';
import 'recipe_picker_screen.dart';
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

enum _EntryAction { view, change, suggest, mealType, move, remove }

class _MealPlansScreenState extends State<MealPlansScreen> {
  bool _isGenerating = false;

  /// Plan recién creado: se muestra abierto para empezar a editarlo.
  String? _expandedPlanId;

  /// Comidas que la IA está reemplazando o agregando (muestran un spinner).
  final Set<String> _busy = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MealPlansProvider>().load();
    });
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _newPlan() async {
    final useAi = await showModalBottomSheet<bool>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(tr('Nuevo plan'),
                  style: Theme.of(ctx).textTheme.titleMedium),
            ),
            ListTile(
              leading: const Icon(Icons.auto_awesome),
              title: Text(tr('Pedírselo a la IA')),
              subtitle: Text(tr('Arma todas las comidas según tu perfil y lo que tenés en casa.')),
              onTap: () => Navigator.of(ctx).pop(true),
            ),
            ListTile(
              leading: const Icon(Icons.edit_calendar_outlined),
              title: Text(tr('Armarlo yo')),
              subtitle: Text(tr('Empezás con el plan vacío y elegís cada comida.')),
              onTap: () => Navigator.of(ctx).pop(false),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (useAi == null || !mounted) return;
    if (useAi) {
      await _generate();
    } else {
      await _createManual();
    }
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
      setState(() {
        _isGenerating = false;
        if (plan != null) _expandedPlanId = plan.id;
      });
      if (plan == null) _showMessage(tr('No se pudo generar el plan.'));
    }
  }

  Future<void> _createManual() async {
    final days = await showDialog<int>(
      context: context,
      builder: (ctx) => const _ManualPlanDialog(),
    );
    if (days == null || !mounted) return;
    final plan = await context.read<MealPlansProvider>().createManual(days);
    if (!mounted) return;
    if (plan == null) {
      _showMessage(tr('No se pudo crear el plan.'));
      return;
    }
    setState(() => _expandedPlanId = plan.id);
    _showMessage(tr('Plan creado. Tocá + en cada día para sumar comidas.'));
  }

  Future<void> _deletePlan(MealPlan plan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('¿Eliminar el plan?')),
        content: Text(tr('Se borran todas sus comidas. Las recetas siguen en la app.')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(tr('Cancelar')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(tr('Eliminar')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final ok = await context.read<MealPlansProvider>().deletePlan(plan.id);
    if (!ok && mounted) _showMessage(tr('No se pudo eliminar el plan.'));
  }

  Future<void> _addMeal(MealPlan plan, String dateKey) async {
    final choice = await showDialog<_AddMealChoice>(
      context: context,
      builder: (ctx) => _AddMealDialog(dayLabel: _formatDayHeader(dateKey)),
    );
    if (choice == null || !mounted) return;
    final provider = context.read<MealPlansProvider>();
    if (choice.useAi) {
      final busyKey = '$dateKey-add';
      setState(() => _busy.add(busyKey));
      final ok = await provider.addEntry(plan.id,
          date: dateKey, mealType: choice.mealType);
      if (!mounted) return;
      setState(() => _busy.remove(busyKey));
      if (!ok) _showMessage(tr('La IA no pudo proponer una comida. Probá de nuevo.'));
      return;
    }
    final recipe = await _pickRecipe();
    if (recipe == null || !mounted) return;
    final ok = await provider.addEntry(plan.id,
        date: dateKey, mealType: choice.mealType, recipeId: recipe.id);
    if (!ok && mounted) _showMessage(tr('No se pudo guardar el cambio.'));
  }

  Future<Recipe?> _pickRecipe() => Navigator.of(context).push<Recipe>(
        MaterialPageRoute(builder: (_) => const RecipePickerScreen()),
      );

  Future<void> _onEntryAction(
      MealPlan plan, MealPlanEntry entry, _EntryAction action) async {
    final provider = context.read<MealPlansProvider>();
    bool ok = true;
    switch (action) {
      case _EntryAction.view:
        Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => RecipeDetailScreen(recipeId: entry.recipe.id)));
        return;
      case _EntryAction.change:
        final recipe = await _pickRecipe();
        if (recipe == null || !mounted) return;
        ok = await provider.updateEntry(plan.id, entry.id, recipeId: recipe.id);
      case _EntryAction.suggest:
        setState(() => _busy.add(entry.id));
        ok = await provider.suggestEntry(plan.id, entry.id);
        if (!mounted) return;
        setState(() => _busy.remove(entry.id));
        if (!ok) {
          _showMessage(tr('La IA no pudo proponer una comida. Probá de nuevo.'));
          return;
        }
      case _EntryAction.mealType:
        final mealType = await _chooseOption(
          title: tr('¿Qué comida es?'),
          options: _mealTypeLabels,
          current: entry.mealType,
        );
        if (mealType == null || mealType == entry.mealType || !mounted) return;
        ok = await provider.updateEntry(plan.id, entry.id, mealType: mealType);
      case _EntryAction.move:
        final date = await _chooseOption(
          title: tr('Mover a otro día'),
          options: {for (final d in _planDates(plan)) d: _formatDayHeader(d)},
          current: entry.date,
        );
        if (date == null || date == entry.date || !mounted) return;
        ok = await provider.updateEntry(plan.id, entry.id, date: date);
      case _EntryAction.remove:
        ok = await provider.removeEntry(plan.id, entry.id);
    }
    if (!ok && mounted) _showMessage(tr('No se pudo guardar el cambio.'));
  }

  /// Lista de opciones (clave → texto) con la actual marcada.
  Future<String?> _chooseOption({
    required String title,
    required Map<String, String> options,
    required String current,
  }) {
    return showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(title),
        children: options.entries
            .map((o) => SimpleDialogOption(
                  onPressed: () => Navigator.of(ctx).pop(o.key),
                  child: Row(
                    children: [
                      Icon(o.key == current
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked),
                      const SizedBox(width: 12),
                      Expanded(child: Text(o.value)),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  Future<void> _onToggleEntry(MealPlan plan, MealPlanEntry entry) async {
    final provider = context.read<MealPlansProvider>();
    final dayCompleted = await provider.toggleEntryCompleted(plan.id, entry.id);
    if (dayCompleted && mounted) {
      final streak = provider.streakForPlan(plan);
      _showMessage(streak > 1
          ? tr('¡Completaste el día! 🔥 Racha: {streak} días seguidos', {'streak': streak})
          : tr('¡Completaste el día! 🎉'));
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
      _showMessage(tr('No se pudo generar la lista de compras.'));
    }
  }

  /// Todos los días del plan, tengan o no comidas.
  List<String> _planDates(MealPlan plan) {
    final start = DateTime.tryParse(plan.startDate);
    final end = DateTime.tryParse(plan.endDate);
    if (start == null || end == null) {
      return plan.entries.map((e) => e.date).toSet().toList()..sort();
    }
    final dates = <String>[];
    for (var d = start; !d.isAfter(end); d = DateTime(d.year, d.month, d.day + 1)) {
      dates.add(DateFormat('yyyy-MM-dd').format(d));
    }
    return dates;
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
                              const SizedBox(height: 80),
                              EmptyState(
                                icon: Icons.calendar_month_outlined,
                                message: tr('Todavía no tenés ningún plan. Pedíselo a la IA o armalo vos.'),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: provider.mealPlans.length,
                            itemBuilder: (context, index) =>
                                _buildPlanCard(provider, provider.mealPlans[index]),
                          ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isGenerating ? null : _newPlan,
        icon: _isGenerating
            ? const SizedBox(
                height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.add),
        label: Text(_isGenerating ? tr('Generando plan…') : tr('Nuevo plan')),
      ),
    );
  }

  Widget _buildPlanCard(MealPlansProvider provider, MealPlan plan) {
    final entriesByDate = <String, List<MealPlanEntry>>{};
    for (final entry in plan.entries) {
      entriesByDate.putIfAbsent(entry.date, () => []).add(entry);
    }
    for (final dayEntries in entriesByDate.values) {
      dayEntries.sort((a, b) => kMealTypeOrder
          .indexOf(a.mealType)
          .compareTo(kMealTypeOrder.indexOf(b.mealType)));
    }
    final streak = provider.streakForPlan(plan);
    final count = plan.entries.length == 1
        ? tr('1 comida planificada')
        : tr('{plan} comidas planificadas', {'plan': plan.entries.length});
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ExpansionTile(
        key: PageStorageKey(plan.id),
        initiallyExpanded: plan.id == _expandedPlanId,
        title: Text('${plan.startDate} → ${plan.endDate}'),
        subtitle: Text(streak > 0
            ? '$count · ${tr('🔥 {streak} días seguidos', {'streak': streak})}'
            : count),
        children: [
          ..._planDates(plan).map((dateKey) =>
              _buildDay(plan, dateKey, entriesByDate[dateKey] ?? const [])),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  onPressed: plan.entries.isEmpty
                      ? null
                      : () => _generateShoppingList(plan.id),
                  icon: const Icon(Icons.shopping_cart_outlined),
                  label: Text(tr('Generar lista de compras')),
                ),
                TextButton.icon(
                  onPressed: () => _deletePlan(plan),
                  style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error),
                  icon: const Icon(Icons.delete_outline),
                  label: Text(tr('Eliminar plan')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDay(MealPlan plan, String dateKey, List<MealPlanEntry> entries) {
    const spinner = Padding(
      padding: EdgeInsets.all(12),
      child: SizedBox(
          width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 4, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(_formatDayHeader(dateKey),
                    style: Theme.of(context).textTheme.titleSmall),
              ),
              _busy.contains('$dateKey-add')
                  ? spinner
                  : IconButton(
                      tooltip: tr('Agregar comida'),
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () => _addMeal(plan, dateKey),
                    ),
            ],
          ),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(tr('Sin comidas todavía'),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ),
          ...entries.map((e) => CheckboxListTile(
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                value: e.completed,
                onChanged: (_) => _onToggleEntry(plan, e),
                title: Text(
                  e.recipe.title,
                  style: e.completed
                      ? const TextStyle(decoration: TextDecoration.lineThrough)
                      : null,
                ),
                subtitle: Text(_mealTypeLabels[e.mealType] ?? e.mealType),
                secondary: _busy.contains(e.id)
                    ? spinner
                    : PopupMenuButton<_EntryAction>(
                        tooltip: tr('Editar comida'),
                        onSelected: (action) => _onEntryAction(plan, e, action),
                        itemBuilder: (_) => [
                          _menuItem(_EntryAction.view, Icons.menu_book_outlined, tr('Ver receta')),
                          _menuItem(_EntryAction.change, Icons.swap_horiz, tr('Cambiar por otra receta')),
                          _menuItem(_EntryAction.suggest, Icons.auto_awesome, tr('Que la IA proponga otra')),
                          _menuItem(_EntryAction.mealType, Icons.schedule, tr('Cambiar comida del día')),
                          _menuItem(_EntryAction.move, Icons.event, tr('Mover a otro día')),
                          _menuItem(_EntryAction.remove, Icons.delete_outline, tr('Quitar del plan')),
                        ],
                      ),
              )),
        ],
      ),
    );
  }

  PopupMenuItem<_EntryAction> _menuItem(
          _EntryAction action, IconData icon, String label) =>
      PopupMenuItem(
        value: action,
        child: ListTile(
          leading: Icon(icon),
          title: Text(label),
          contentPadding: EdgeInsets.zero,
          dense: true,
        ),
      );

  String _formatDayHeader(String dateKey) {
    final date = DateTime.tryParse(dateKey);
    if (date == null) return dateKey;
    final formatted = AppLanguage.instance.isEnglish
        ? DateFormat('EEEE MM/d', 'en').format(date)
        : DateFormat('EEEE d/MM', 'es').format(date);
    return formatted[0].toUpperCase() + formatted.substring(1);
  }
}

class _ManualPlanDialog extends StatefulWidget {
  const _ManualPlanDialog();

  @override
  State<_ManualPlanDialog> createState() => _ManualPlanDialogState();
}

class _ManualPlanDialogState extends State<_ManualPlanDialog> {
  int _days = 7;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(tr('Armar plan a mano')),
      content: Column(
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
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(tr('Cancelar')),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_days),
          child: Text(tr('Crear')),
        ),
      ],
    );
  }
}

class _AddMealChoice {
  final String mealType;
  final bool useAi;
  _AddMealChoice(this.mealType, this.useAi);
}

class _AddMealDialog extends StatefulWidget {
  final String dayLabel;
  const _AddMealDialog({required this.dayLabel});

  @override
  State<_AddMealDialog> createState() => _AddMealDialogState();
}

class _AddMealDialogState extends State<_AddMealDialog> {
  String _mealType = 'lunch';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(tr('Agregar comida')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.dayLabel, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _mealTypeLabels.entries
                  .map((e) => ChoiceChip(
                        label: Text(e.value),
                        selected: _mealType == e.key,
                        onSelected: (_) => setState(() => _mealType = e.key),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
      actionsOverflowButtonSpacing: 8,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(tr('Cancelar')),
        ),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).pop(_AddMealChoice(_mealType, true)),
          icon: const Icon(Icons.auto_awesome, size: 18),
          label: Text(tr('Pedir a la IA')),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_AddMealChoice(_mealType, false)),
          child: Text(tr('Elegir receta')),
        ),
      ],
    );
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
