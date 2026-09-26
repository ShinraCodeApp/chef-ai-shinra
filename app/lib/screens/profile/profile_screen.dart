import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api_client.dart';
import '../../core/diet_tags.dart';
import '../../models/user.dart';
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
  late final TextEditingController _healthNotesController;
  String? _sex;
  String? _goal;
  String? _activityLevel;
  late Set<String> _dietPreferences;
  late Set<String> _allergies;
  bool _isSaving = false;
  bool _isEditing = false;
  bool _loadingAdvice = false;
  List<String>? _advice;

  @override
  void initState() {
    super.initState();
    _loadFromUser(context.read<AuthProvider>().currentUser!);
  }

  void _loadFromUser(User user) {
    _ageController = TextEditingController(text: user.age?.toString() ?? '');
    _weightController = TextEditingController(text: user.weightKg?.toString() ?? '');
    _heightController = TextEditingController(text: user.heightCm?.toString() ?? '');
    _budgetController =
        TextEditingController(text: user.monthlyBudget?.toString() ?? '');
    _familyController =
        TextEditingController(text: user.familyMembers?.toString() ?? '');
    _healthNotesController = TextEditingController(text: user.healthNotes ?? '');
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
    _healthNotesController.dispose();
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
        'healthNotes': _healthNotesController.text,
      });
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Perfil actualizado.')));
        setState(() {
          _isEditing = false;
          _advice = null;
        });
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

  Future<void> _fetchAdvice() async {
    setState(() => _loadingAdvice = true);
    try {
      final response = await ApiClient.instance.dio.get('/ai/health-advice');
      final tips = (response.data['tips'] as List? ?? [])
          .map((e) => e.toString())
          .toList();
      if (mounted) setState(() => _advice = tips);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('No se pudieron generar los consejos. Probá de nuevo.')));
      }
    } finally {
      if (mounted) setState(() => _loadingAdvice = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi perfil'),
        actions: [
          TextButton(
            onPressed: () => setState(() => _isEditing = !_isEditing),
            child: Text(_isEditing ? 'Ver' : 'Editar'),
          ),
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
              if (_isEditing) _buildEditForm() else _buildReadOnlyView(user),
              const SizedBox(height: 24),
              _buildAdviceSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlyView(User? user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _readRow('Edad', user?.age?.toString()),
        _readRow('Sexo', user?.sex != null ? _sexOptions[user!.sex] : null),
        _readRow('Peso', user?.weightKg != null ? '${user!.weightKg} kg' : null),
        _readRow('Altura', user?.heightCm != null ? '${user!.heightCm} cm' : null),
        _readRow('Objetivo', user?.goal != null ? _goalOptions[user!.goal] : null),
        _readRow('Actividad física',
            user?.activityLevel != null ? _activityOptions[user!.activityLevel] : null),
        _readRow('Presupuesto mensual',
            user?.monthlyBudget != null ? '\$${user!.monthlyBudget}' : null),
        _readRow('Integrantes de familia', user?.familyMembers?.toString()),
        const SizedBox(height: 16),
        Text('Condición de salud / dieta especial',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(
          (user?.healthNotes?.trim().isNotEmpty ?? false)
              ? user!.healthNotes!
              : 'No cargaste ninguna. Tocá "Editar" para agregarla.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        Text('Preferencias dietarias', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        _readChips((user?.dietPreferences ?? []).map(dietTagLabel).toList()),
        const SizedBox(height: 20),
        Text('Alergias / intolerancias', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        _readChips(user?.allergies ?? []),
      ],
    );
  }

  Widget _readRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(label, style: TextStyle(color: Colors.grey.shade600)),
          ),
          Expanded(
            child: Text(
              (value == null || value.isEmpty) ? '—' : value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _readChips(List<String> values) {
    if (values.isEmpty) {
      return Text('Ninguna', style: TextStyle(color: Colors.grey.shade600));
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: values.map((v) => Chip(label: Text(v))).toList(),
    );
  }

  Widget _buildEditForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        Text('Condición de salud / dieta especial',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Contanos si tenés alguna enfermedad, estás embarazada o necesitás comer '
          'diferente por algún motivo que no esté en las opciones de abajo. Lo usamos '
          'para darte consejos y recomendaciones más precisas.',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _healthNotesController,
          maxLines: 3,
          maxLength: 500,
          decoration: const InputDecoration(
            hintText: 'Ej: gastritis, embarazo, resistencia a la insulina...',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
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
    );
  }

  Widget _buildAdviceSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Consejos para tu situación',
                    style: Theme.of(context).textTheme.titleMedium),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_advice == null)
            OutlinedButton.icon(
              onPressed: _loadingAdvice ? null : _fetchAdvice,
              icon: _loadingAdvice
                  ? const SizedBox(
                      height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.auto_awesome),
              label: Text(_loadingAdvice ? 'Generando...' : 'Ver consejos con IA'),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ..._advice!.map((tip) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('•  '),
                          Expanded(child: Text(tip)),
                        ],
                      ),
                    )),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _loadingAdvice ? null : _fetchAdvice,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Generar de nuevo'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
