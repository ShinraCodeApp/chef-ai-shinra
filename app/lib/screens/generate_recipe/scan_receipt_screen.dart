import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/api_client.dart';
import '../../providers/inventory_provider.dart';

class _DetectedReceiptItem {
  final String name;
  final double quantity;
  final String unit;
  final double unitPrice;
  final String ingredientId;
  bool selected = true;
  late final TextEditingController quantityController;
  late final TextEditingController priceController;

  _DetectedReceiptItem({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    required this.ingredientId,
  }) {
    quantityController = TextEditingController(text: quantity.toString());
    priceController = TextEditingController(text: unitPrice.toString());
  }
}

/// Escanea una foto de un ticket de compra: detecta producto, cantidad/peso y
/// precio con IA, y al confirmar carga los ítems al inventario junto con su precio.
class ScanReceiptScreen extends StatefulWidget {
  const ScanReceiptScreen({super.key});

  @override
  State<ScanReceiptScreen> createState() => _ScanReceiptScreenState();
}

class _ScanReceiptScreenState extends State<ScanReceiptScreen> {
  final _picker = ImagePicker();
  File? _image;
  bool _isAnalyzing = false;
  bool _isSaving = false;
  String? _error;
  List<_DetectedReceiptItem>? _results;

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
        '/ai/receipt/scan',
        data: formData,
      );
      final items = (response.data as List)
          .map((e) => _DetectedReceiptItem(
                name: e['name'] as String,
                quantity: (e['quantity'] as num).toDouble(),
                unit: e['unit'] as String,
                unitPrice: (e['unitPrice'] as num).toDouble(),
                ingredientId: e['ingredientId'] as String,
              ))
          .toList();
      setState(() => _results = items);
    } catch (_) {
      setState(() => _error =
          'No se pudo analizar el ticket. Revisá que el backend tenga GEMINI_API_KEY configurada.');
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  Future<void> _addSelectedToInventory() async {
    final selected = _results!.where((item) => item.selected).toList();
    if (selected.isEmpty) return;
    setState(() => _isSaving = true);
    final inventory = context.read<InventoryProvider>();
    final dio = ApiClient.instance.dio;
    var successCount = 0;
    for (final item in selected) {
      final quantity = double.tryParse(item.quantityController.text) ?? item.quantity;
      final price = double.tryParse(item.priceController.text) ?? item.unitPrice;
      final ok = await inventory.addItem(
        ingredientId: item.ingredientId,
        quantity: quantity,
        unit: item.unit,
        source: 'photo',
      );
      if (ok && price > 0) {
        try {
          await dio.post('/ingredients/${item.ingredientId}/prices', data: {
            'price': price,
            'unit': item.unit,
          });
        } catch (_) {
          // el precio es un plus informativo: si falla, igual se guarda el ítem en inventario
        }
      }
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
      appBar: AppBar(title: const Text('Escanear ticket de compra')),
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
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(Icons.receipt_long_outlined, size: 64),
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
              Text('Productos detectados', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (_results!.isEmpty)
                const Text('No se detectó ningún producto en el ticket.')
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
                                  labelText: 'Cantidad',
                                  suffixText: item.unit,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: item.priceController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  labelText: 'Precio',
                                  prefixText: '\$',
                                ),
                              ),
                            ),
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
      ),
    );
  }
}
