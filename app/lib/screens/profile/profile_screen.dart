import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/diet_tags.dart';
import '../../providers/auth_provider.dart';

const _sexOptions = {'male': 'Masculino', 'female': 'Femenino', 'other': 'Otro'};
const _goalOptions = {
  'lose_weight': 'Bajar de peso',
  'gain_muscle': 'Ganar músculo',
  'maintain': 'Mantenerme',
  'eat_healthier': 'Comer más sano',
  'save_money': 'Ahorrar dinero',
};
const _activityOptions = {
  'sedentary': 'Sedentario',
  'light': 'Actividad leve',
  'moderate': 'Actividad moderada',
  'active': 'Activo',
  'very_active': 'Muy activo',
};
const _dietOptions = [
  'proteico',
  'vegetariano',
  'vegano',
  'sin_tacc',
  'keto',
  'fitness',
  'economico',
  'comida_cruda',
  'hipotiroidismo',
  'hipertiroidismo',
];
const _allergyOptions = [
  'celiaquia',
  'diabetes',
  'hipertension',
  'lactosa',
  'mani',
  'mariscos',
  'soja',
  'huevo',
];

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _ageController;
  late final TextEditingController _weightController;
  late final TextEditingController _heightController;
  late final TextEditingController _budgetController;
  late final TextEditingController _familyController;
  String? _sex;
  String? _goal;
  String? _activityLevel;
  late Set<String> _dietPreferences;
  late Set<String> _allergies;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser!;
    _ageController = TextEditingController(text: user.age?.toString() ?? '');
    _weightController = TextEditingController(text: user.weightKg?.toString() ?? '');
    _heightController = TextEditingController(text: user.heightCm?.toString() ?? '');
    _budgetController =
        TextEditingController(text: user.monthlyBudget?.toString() ?? '');
    _familyController =
        TextEditingController(text: user.familyMembers?.toString() ?? '');
    _sex = user.sex;
    _goal = user.goal;
    _activityLevel = user.activityLevel;
    _dietPreferences = user.dietPreferences.toSet();
    _allergies = user.allergies.toSet();
  }

  @override
  void dispose() {
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _budgetController.dispose();
    _familyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await context.read<AuthProvider>().updateProfile({
        if (_ageController.text.isNotEmpty) 'age': int.tryParse(_ageController.text),
        if (_weightController.text.isNotEmpty)
          'weightKg': double.tryParse(_weightController.text),
        if (_heightController.text.isNotEmpty)
          'heightCm': double.tryParse(_heightController.text),
        if (_budgetController.text.isNotEmpty)
          'monthlyBudget': double.tryParse(_budgetController.text),
        if (_familyController.text.isNotEmpty)
          'familyMembers': int.tryParse(_familyController.text),
        if (_sex != null) 'sex': _sex,
        if (_goal != null) 'goal': _goal,
        if (_activityLevel != null) 'activityLevel': _activityLevel,
        'dietPreferences': _dietPreferences.toList(),
        'allergies': _allergies.toList(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Perfil actualizado.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('No se pudo guardar el perfil.')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(auth.currentUser?.email ?? '',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Edad'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _sex,
                    decoration: const InputDecoration(labelText: 'Sexo'),
                    items: _sexOptions.entries
                        .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                        .toList(),
                    onChanged: (value) => setState(() => _sex = value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _weightController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Peso (kg)'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _heightController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Altura (cm)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _goal,
              decoration: const InputDecoration(labelText: 'Objetivo'),
              items: _goalOptions.entries
                  .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (value) => setState(() => _goal = value),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _activityLevel,
              decoration: const InputDecoration(labelText: 'Actividad física'),
              items: _activityOptions.entries
                  .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (value) => setState(() => _activityLevel = value),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _budgetController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Presupuesto mensual'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _familyController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Integrantes familia'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Preferencias dietarias', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _dietOptions
                  .map((tag) => FilterChip(
                        label: Text(dietTagLabel(tag)),
                        selected: _dietPreferences.contains(tag),
                        onSelected: (selected) => setState(() {
                          selected ? _dietPreferences.add(tag) : _dietPreferences.remove(tag);
                        }),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 20),
            Text('Alergias / intolerancias', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _allergyOptions
                  .map((tag) => FilterChip(
                        label: Text(tag),
                        selected: _allergies.contains(tag),
                        onSelected: (selected) => setState(() {
                          selected ? _allergies.add(tag) : _allergies.remove(tag);
                        }),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Guardar cambios'),
            ),
          ],
        ),
        ),
      ),
    );
  }
}
