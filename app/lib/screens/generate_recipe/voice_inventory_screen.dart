import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
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
  final String ingredientId;
  bool selected = true;
  late final TextEditingController quantityController;

  _DetectedItem({
    required this.name,
    required this.approxQuantity,
    required this.unit,
    required this.state,
    required this.ingredientId,
  }) {
    quantityController = TextEditingController(text: approxQuantity.toString());
  }
}

/// Permite dictar por voz los alimentos que se tienen para agregarlos al inventario,
/// en vez de tener que escribirlos o sacarles una foto.
class VoiceInventoryScreen extends StatefulWidget {
  const VoiceInventoryScreen({super.key});

  @override
  State<VoiceInventoryScreen> createState() => _VoiceInventoryScreenState();
}

class _VoiceInventoryScreenState extends State<VoiceInventoryScreen> {
  final _speech = stt.SpeechToText();
  final _textController = TextEditingController();
  bool _speechAvailable = false;
  bool _isListening = false;
  bool _isAnalyzing = false;
  bool _isSaving = false;
  String? _error;
  List<_DetectedItem>? _results;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    final available = await _speech.initialize(
      onError: (error) => setState(() => _error = 'Error de reconocimiento de voz: ${error.errorMsg}'),
    );
    if (mounted) setState(() => _speechAvailable = available);
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      return;
    }
    if (!_speechAvailable) {
      setState(() => _error = 'El reconocimiento de voz no está disponible en este dispositivo.');
      return;
    }
    setState(() {
      _error = null;
      _isListening = true;
    });
    await _speech.listen(
      onResult: (result) {
        setState(() => _textController.text = result.recognizedWords);
      },
      listenOptions: stt.SpeechListenOptions(localeId: 'es_AR'),
    );
  }

  Future<void> _analyze() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      setState(() => _error = 'Dictá o escribí qué alimentos tenés primero.');
      return;
    }
    setState(() {
      _isAnalyzing = true;
      _error = null;
    });
    try {
      final response = await ApiClient.instance.dio.post(
        '/ai/inventory/parse-voice',
        data: {'text': text},
      );
      final items = (response.data as List)
          .map((e) => _DetectedItem(
                name: e['name'] as String,
                approxQuantity: (e['approxQuantity'] as num).toDouble(),
                unit: e['unit'] as String,
                state: e['state'] as String,
                ingredientId: e['ingredientId'] as String,
              ))
          .toList();
      setState(() => _results = items);
    } catch (_) {
      setState(() => _error =
          'No se pudo interpretar el dictado. Revisá que el backend tenga GEMINI_API_KEY configurada.');
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
  void dispose() {
    _speech.stop();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dictar inventario')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Decí qué alimentos tenés, por ejemplo: "tengo dos kilos de papa, una docena de huevos y medio litro de leche"',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _textController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Lo que dictes aparece acá (también podés escribirlo)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _toggleListening,
                icon: Icon(_isListening ? Icons.stop : Icons.mic),
                label: Text(_isListening ? 'Detener' : 'Empezar a dictar'),
                style: _isListening
                    ? FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error)
                    : null,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _isAnalyzing ? null : _analyze,
                icon: _isAnalyzing
                    ? const SizedBox(
                        height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.auto_awesome),
                label: const Text('Interpretar con IA'),
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
                  const Text('No se detectó ningún ingrediente en el dictado.')
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
      ),
    );
  }
}
