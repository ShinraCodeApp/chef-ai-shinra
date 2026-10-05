import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/api_client.dart';
import '../../providers/inventory_provider.dart';

class _DetectedReceiptItem {
  final String name;
  double quantity;
  final String unit;
  double unitPrice;
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
    priceController = TextEditingController(text: unitPrice.toStringAsFixed(2));
  }

  void dispose() {
    quantityController.dispose();
    priceController.dispose();
  }

  double get currentPrice => double.tryParse(priceController.text) ?? unitPrice;
  double get currentQuantity => double.tryParse(quantityController.text) ?? quantity;
}

class ScanReceiptScreen extends StatefulWidget {
  const ScanReceiptScreen({super.key});

  @override
  State<ScanReceiptScreen> createState() => _ScanReceiptScreenState();
}

class _ScanReceiptScreenState extends State<ScanReceiptScreen> {
  final _picker = ImagePicker();
  final List<File> _images = [];
  bool _isAnalyzing = false;
  bool _isSaving = false;
  String? _error;
  List<_DetectedReceiptItem>? _results;

  @override
  void dispose() {
    _results?.forEach((i) => i.dispose());
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;
    setState(() {
      _images.add(File(picked.path));
      _error = null;
    });
  }

  void _removeImage(int index) {
    setState(() => _images.removeAt(index));
  }

  Future<void> _analyze() async {
    if (_images.isEmpty) return;
    setState(() {
      _isAnalyzing = true;
      _error = null;
      _results?.forEach((i) => i.dispose());
      _results = null;
    });

    final dio = ApiClient.instance.dio;
    final allItems = <_DetectedReceiptItem>[];

    try {
      for (final image in _images) {
        final formData = FormData.fromMap({
          'image': await MultipartFile.fromFile(image.path),
        });
        final response = await dio.post('/ai/receipt/scan', data: formData);
        final items = (response.data as List).map((e) => _DetectedReceiptItem(
              name: e['name'] as String,
              quantity: (e['quantity'] as num).toDouble(),
              unit: e['unit'] as String,
              // lo pagado por todo el renglón (el campo "Precio" de la pantalla)
              unitPrice: ((e['totalPrice'] ?? e['unitPrice']) as num).toDouble(),
              ingredientId: e['ingredientId'] as String,
            ));
        allItems.addAll(items);
      }

      // Fusionar duplicados sumando cantidades
      final merged = <String, _DetectedReceiptItem>{};
      for (final item in allItems) {
        if (merged.containsKey(item.ingredientId)) {
          final existing = merged[item.ingredientId]!;
          existing.quantity += item.quantity;
          existing.unitPrice += item.unitPrice;
          existing.quantityController.text = existing.quantity.toString();
          existing.priceController.text = existing.unitPrice.toStringAsFixed(2);
          item.dispose();
        } else {
          merged[item.ingredientId] = item;
        }
      }

      setState(() => _results = merged.values.toList());
    } catch (e) {
      String msg = 'No se pudo analizar el ticket.';
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map && data['message'] != null) {
          msg = data['message'].toString();
        } else {
          msg = 'Error ${e.response?.statusCode ?? ''}: ${e.message}';
        }
      } else {
        msg = 'Error: ${e.toString()}';
      }
      setState(() => _error = msg);
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  double get _total => _results == null
      ? 0
      : _results!
          .where((i) => i.selected)
          .fold(0, (sum, i) => sum + i.currentPrice);

  Future<void> _addSelectedToInventory() async {
    final selected = _results!.where((item) => item.selected).toList();
    if (selected.isEmpty) return;
    setState(() => _isSaving = true);
    final inventory = context.read<InventoryProvider>();
    final dio = ApiClient.instance.dio;
    var successCount = 0;
    for (final item in selected) {
      final ok = await inventory.addItem(
        ingredientId: item.ingredientId,
        quantity: item.currentQuantity,
        unit: item.unit,
        source: 'photo',
      );
      if (ok && item.currentPrice > 0) {
        try {
          // total pagado + cantidad comprada: el servidor lo guarda como
          // precio por kg / litro / unidad
          await dio.post('/ingredients/${item.ingredientId}/prices', data: {
            'price': item.currentPrice,
            'unit': item.unit,
            if (item.currentQuantity > 0) 'quantity': item.currentQuantity,
          });
        } catch (_) {}
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Escanear ticket de compra')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Galería de fotos
              if (_images.isEmpty)
                Container(
                  height: 160,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(Icons.receipt_long_outlined, size: 64),
                  ),
                )
              else
                SizedBox(
                  height: 160,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _images.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (_, index) => Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(_images[index],
                              width: 120, height: 160, fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _removeImage(index),
                            child: Container(
                              decoration: BoxDecoration(
                                color: colorScheme.errorContainer,
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(4),
                              child: Icon(Icons.close,
                                  size: 16, color: colorScheme.onErrorContainer),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Botones de foto
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: Text(_images.isEmpty ? 'Sacar foto' : 'Agregar foto'),
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

              if (_images.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '${_images.length} foto${_images.length > 1 ? 's' : ''} — tocá × para quitar',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _isAnalyzing ? null : _analyze,
                  icon: _isAnalyzing
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.auto_awesome),
                  label: Text(_images.length > 1
                      ? 'Analizar ${_images.length} fotos con IA'
                      : 'Analizar con IA'),
                ),
              ],

              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: colorScheme.error)),
              ],

              if (_results != null) ...[
                const SizedBox(height: 24),
                Text('Productos detectados',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (_results!.isEmpty)
                  const Text('No se detectó ningún producto en el ticket.')
                else ...[
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
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    labelText: 'Cantidad',
                                    suffixText: item.unit,
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: item.priceController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    labelText: 'Total pagado',
                                    prefixText: '\$',
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )),

                  // Total
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total seleccionado',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: colorScheme.onPrimaryContainer,
                                )),
                        Text(
                          '\$${_total.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
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
