import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/diet_tags.dart';
import '../../providers/auth_provider.dart';

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

/// Se muestra una única vez, después de registrarse, para conocer al usuario
/// (peso, altura, objetivo, dieta) antes de que empiece a usar la app. Se puede
/// saltear y completar más tarde desde el perfil.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  String? _goal;
  String? _activityLevel;
  final _dietPreferences = <String>{};
  bool _isSaving = false;

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _finish({required bool onboardingCompleted}) async {
    setState(() => _isSaving = true);
    try {
      await context.read<AuthProvider>().updateProfile({
        if (_weightController.text.isNotEmpty)
          'weightKg': double.tryParse(_weightController.text),
        if (_heightController.text.isNotEmpty)
          'heightCm': double.tryParse(_heightController.text),
        if (_goal != null) 'goal': _goal,
        if (_activityLevel != null) 'activityLevel': _activityLevel,
        'dietPreferences': _dietPreferences.toList(),
        'onboardingCompleted': onboardingCompleted,
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo guardar. Probá de nuevo.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('¡Bienvenido a Chef AI by Shinra!',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                'Contanos un poco sobre vos para armarte recetas y planes a tu medida.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
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
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _goal,
                decoration: const InputDecoration(labelText: '¿Qué querés lograr?'),
                items: _goalOptions.entries
                    .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                    .toList(),
                onChanged: (value) => setState(() => _goal = value),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _activityLevel,
                decoration: const InputDecoration(labelText: 'Actividad física'),
                items: _activityOptions.entries
                    .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                    .toList(),
                onChanged: (value) => setState(() => _activityLevel = value),
              ),
              const SizedBox(height: 20),
              Text('¿Qué dieta seguís?', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _dietOptions
                    .map((tag) => FilterChip(
                          label: Text(dietTagLabel(tag)),
                          selected: _dietPreferences.contains(tag),
                          onSelected: (selected) => setState(() {
                            selected
                                ? _dietPreferences.add(tag)
                                : _dietPreferences.remove(tag);
                          }),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _isSaving ? null : () => _finish(onboardingCompleted: true),
                child: _isSaving
                    ? const SizedBox(
                        height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Empezar'),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: _isSaving ? null : () => _finish(onboardingCompleted: true),
                  child: const Text('Completar más tarde'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
