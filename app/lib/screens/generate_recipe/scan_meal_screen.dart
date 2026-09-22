import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/api_client.dart';

class _MealAnalysisItem {
  final String name;
  final double approxGrams;

  _MealAnalysisItem({required this.name, required this.approxGrams});

  factory _MealAnalysisItem.fromJson(Map<String, dynamic> json) =>
      _MealAnalysisItem(
        name: json['name'] as String,
        approxGrams: (json['approxGrams'] as num).toDouble(),
      );
}

class _MealAnalysis {
  final String dishName;
  final String description;
  final double estimatedServingGrams;
  final double confidence;
  final List<_MealAnalysisItem> items;
  final double calories;
  final double proteinG;
  final double fatG;
  final double carbsG;
  final double fiberG;
  final double sugarG;
  final double sodiumMg;

  _MealAnalysis({
    required this.dishName,
    required this.description,
    required this.estimatedServingGrams,
    required this.confidence,
    required this.items,
    required this.calories,
    required this.proteinG,
    required this.fatG,
    required this.carbsG,
    required this.fiberG,
    required this.sugarG,
    required this.sodiumMg,
  });

  factory _MealAnalysis.fromJson(Map<String, dynamic> json) {
    final nutrition = json['nutrition'] as Map<String, dynamic>;
    return _MealAnalysis(
      dishName: json['dishName'] as String,
      description: json['description'] as String,
      estimatedServingGrams: (json['estimatedServingGrams'] as num).toDouble(),
      confidence: (json['confidence'] as num).toDouble(),
      items: (json['items'] as List? ?? [])
          .map((e) => _MealAnalysisItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      calories: (nutrition['calories'] as num).toDouble(),
      proteinG: (nutrition['proteinG'] as num).toDouble(),
      fatG: (nutrition['fatG'] as num).toDouble(),
      carbsG: (nutrition['carbsG'] as num).toDouble(),
      fiberG: (nutrition['fiberG'] as num).toDouble(),
      sugarG: (nutrition['sugarG'] as num).toDouble(),
      sodiumMg: (nutrition['sodiumMg'] as num).toDouble(),
    );
  }
}

/// Escanea una foto de un plato ya preparado y usa IA para estimar qué es,
/// de qué tamaño es la porción y sus calorías y macros aproximados.
class ScanMealScreen extends StatefulWidget {
  const ScanMealScreen({super.key});

  @override
  State<ScanMealScreen> createState() => _ScanMealScreenState();
}

class _ScanMealScreenState extends State<ScanMealScreen> {
  final _picker = ImagePicker();
  File? _image;
  bool _isAnalyzing = false;
  String? _error;
  _MealAnalysis? _result;

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;
    setState(() {
      _image = File(picked.path);
      _result = null;
      _error = null;
    });
  }

  Future<void> _analyze() async {
    if (_image == null) return;
    setState(() {
      _isAnalyzing = true;
      _error = null;
    });
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(_image!.path),
      });
      final response = await ApiClient.instance.dio.post(
        '/ai/meal/analyze',
        data: formData,
      );
      setState(() =>
          _result = _MealAnalysis.fromJson(response.data as Map<String, dynamic>));
    } catch (_) {
      setState(() => _error =
          'No se pudo analizar el plato. Revisá que el backend tenga GEMINI_API_KEY configurada.');
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Calorías de mi plato')),
      body: SafeArea(
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_image != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(_image!, height: 220, fit: BoxFit.cover),
              )
            else
              Container(
                height: 220,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(Icons.restaurant_menu, size: 64),
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Sacar foto'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Galería'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_image != null)
              FilledButton.icon(
                onPressed: _isAnalyzing ? null : _analyze,
                icon: _isAnalyzing
                    ? const SizedBox(
                        height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.auto_awesome),
                label: const Text('Analizar con IA'),
              ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: scheme.error)),
            ],
            if (_result != null) ...[
              const SizedBox(height: 24),
              Text(_result!.dishName, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(_result!.description, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(
                    avatar: const Icon(Icons.scale, size: 16),
                    label: Text('${_result!.estimatedServingGrams.toStringAsFixed(0)} g aprox.'),
                  ),
                  Chip(
                    avatar: const Icon(Icons.percent, size: 16),
                    label: Text(
                        'Confianza: ${(_result!.confidence * 100).toStringAsFixed(0)}%'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Card(
                color: scheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Calorías estimadas',
                          style: TextStyle(color: scheme.onPrimaryContainer)),
                      Text(
                        '${_result!.calories.toStringAsFixed(0)} kcal',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: scheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Macronutrientes (aprox.)',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _nutritionChip('Proteína', _result!.proteinG, 'g'),
                  _nutritionChip('Grasas', _result!.fatG, 'g'),
                  _nutritionChip('Carbs', _result!.carbsG, 'g'),
                  _nutritionChip('Fibra', _result!.fiberG, 'g'),
                  _nutritionChip('Azúcares', _result!.sugarG, 'g'),
                  _nutritionChip('Sodio', _result!.sodiumMg, 'mg'),
                ],
              ),
              if (_result!.items.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text('Detectado en el plato',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ..._result!.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text('• ${item.name} — ${item.approxGrams.toStringAsFixed(0)} g'),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                'Estimación aproximada generada por IA a partir de la foto; puede variar del valor real.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: scheme.outline),
              ),
            ],
          ],
        ),
        ),
      ),
    );
  }

  Widget _nutritionChip(String label, double value, String unit) {
    return Chip(label: Text('$label: ${value.toStringAsFixed(0)}$unit'));
  }
}
