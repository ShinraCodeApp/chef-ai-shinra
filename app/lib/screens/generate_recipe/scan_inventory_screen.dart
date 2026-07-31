import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/api_client.dart';
import '../../providers/inventory_provider.dart';

const _stateLabels = {
  'fresh': 'Fresco',
  'frozen': 'Congelado',
  'opened': 'Abierto',
  'expired': 'Vencido',
  'unknown': 'Sin determinar',
};

class _DetectedItem {
  final String name;
  final double approxQuantity;
  final String unit;
  final String state;
  final double confidence;
  final String ingredientId;
  bool selected = true;
  late final TextEditingController quantityController;

  _DetectedItem({
    required this.name,
    required this.approxQuantity,
    required this.unit,
    required this.state,
    required this.confidence,
    required this.ingredientId,
  }) {
    quantityController = TextEditingController(text: approxQuantity.toString());
  }
}

class ScanInventoryScreen extends StatefulWidget {
  const ScanInventoryScreen({super.key});

  @override
  State<ScanInventoryScreen> createState() => _ScanInventoryScreenState();
}

class _ScanInventoryScreenState extends State<ScanInventoryScreen> {
  final _picker = ImagePicker();
  File? _image;
  bool _isAnalyzing = false;
  bool _isSaving = false;
  String? _error;
  List<_DetectedItem>? _results;

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;
    setState(() {
      _image = File(picked.path);
      _results = null;
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
        '/ai/inventory/scan',
        data: formData,
      );
      final items = (response.data as List)
          .map((e) => _DetectedItem(
                name: e['name'] as String,
                approxQuantity: (e['approxQuantity'] as num).toDouble(),
                unit: e['unit'] as String,
                state: e['state'] as String,
                confidence: (e['confidence'] as num).toDouble(),
                ingredientId: e['ingredientId'] as String,
              ))
          .toList();
      setState(() => _results = items);
    } catch (_) {
      setState(() => _error =
          'No se pudo analizar la imagen. Revisá que el backend tenga GEMINI_API_KEY configurada.');
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  Future<void> _addSelectedToInventory() async {
    final selected = _results!.where((item) => item.selected).toList();
    if (selected.isEmpty) return;
    setState(() => _isSaving = true);
    final inventory = context.read<InventoryProvider>();
    var successCount = 0;
    for (final item in selected) {
      final quantity = double.tryParse(item.quantityController.text) ?? item.approxQuantity;
      final state = item.state == 'unknown' ? 'fresh' : item.state;
      final ok = await inventory.addItem(
        ingredientId: item.ingredientId,
        quantity: quantity,
        unit: item.unit,
        state: state,
      );
      if (ok) successCount++;
    }
    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$successCount ítems agregados al inventario.')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escanear heladera/alacena')),
      body: SingleChildScrollView(
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
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(Icons.kitchen_outlined, size: 64),
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
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            if (_results != null) ...[
              const SizedBox(height: 24),
              Text('Ingredientes detectados', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (_results!.isEmpty)
                const Text('No se detectó ningún ingrediente en la imagen.')
              else
                ..._results!.map((item) => Card(
                      child: CheckboxListTile(
                        value: item.selected,
                        onChanged: (value) =>
                            setState(() => item.selected = value ?? false),
                        title: Text(item.name),
                        subtitle: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: item.quantityController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  isDense: true,
                                  suffixText: item.unit,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(_stateLabels[item.state] ?? item.state),
                          ],
                        ),
                      ),
                    )),
              if (_results!.isNotEmpty) ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _isSaving ? null : _addSelectedToInventory,
                  icon: _isSaving
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.add_shopping_cart),
                  label: const Text('Agregar seleccionados al inventario'),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
