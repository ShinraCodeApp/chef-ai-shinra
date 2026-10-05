import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../core/cooking.dart';
import '../../core/notifications_service.dart';
import '../../core/quantity_format.dart';
import '../../models/recipe.dart';
import '../../core/i18n.dart';

/// Modo cocina: un paso por pantalla con letra grande, la pantalla no se
/// apaga, la voz lee cada paso y los pasos con tiempo ofrecen temporizador.
class CookingModeScreen extends StatefulWidget {
  final Recipe recipe;
  const CookingModeScreen({super.key, required this.recipe});

  @override
  State<CookingModeScreen> createState() => _CookingModeScreenState();
}

class _CookingModeScreenState extends State<CookingModeScreen> {
  static const _timerNotificationId = 8000;

  final _pageController = PageController();
  final _tts = FlutterTts();
  int _page = 0; // 0 = ingredientes, 1..n = pasos
  bool _voiceOn = true;
  final Set<int> _checkedIngredients = {};

  Timer? _ticker;
  Duration? _remaining;
  int? _timerStep;

  List<RecipeStep> get _steps => widget.recipe.instructions;
  int get _pageCount => _steps.length + 1;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable().catchError((_) {});
    _tts.setLanguage(AppLanguage.instance.ttsLanguage);
  }

  @override
  void dispose() {
    WakelockPlus.disable().catchError((_) {});
    _tts.stop();
    _ticker?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() => _page = page);
    _tts.stop();
    if (_voiceOn && page > 0) {
      _tts.speak(tr('Paso {page}. {instruction}', {'page': page, 'instruction': _steps[page - 1].instruction}));
    }
  }

  void _go(int delta) {
    final target = (_page + delta).clamp(0, _pageCount - 1);
    _pageController.animateToPage(target,
        duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  void _startTimer(int stepIndex, int minutes) {
    _ticker?.cancel();
    final end = DateTime.now().add(Duration(minutes: minutes));
    // también como notificación, por si la app queda en segundo plano
    NotificationsService.instance
        .scheduleAt(
          id: _timerNotificationId,
          when: end,
          title: tr('⏰ ¡Tiempo!'),
          body: tr('Paso {v}: {instruction}', {'v': stepIndex + 1, 'instruction': _steps[stepIndex].instruction}),
        )
        .catchError((_) {});
    setState(() {
      _timerStep = stepIndex;
      _remaining = Duration(minutes: minutes);
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      final left = end.difference(DateTime.now());
      if (left.isNegative || left.inSeconds == 0) {
        t.cancel();
        setState(() => _remaining = Duration.zero);
        if (_voiceOn) _tts.speak(tr('¡Tiempo! Terminó el paso {v}.', {'v': stepIndex + 1}));
      } else {
        setState(() => _remaining = left);
      }
    });
  }

  void _stopTimer() {
    _ticker?.cancel();
    NotificationsService.instance.cancel(_timerNotificationId).catchError((_) {});
    setState(() {
      _remaining = null;
      _timerStep = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipe.title, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: _voiceOn ? tr('Silenciar voz') : tr('Leer los pasos en voz alta'),
            icon: Icon(_voiceOn ? Icons.volume_up : Icons.volume_off),
            onPressed: () {
              setState(() => _voiceOn = !_voiceOn);
              if (!_voiceOn) _tts.stop();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(value: (_page + 1) / _pageCount),
            if (_remaining != null) _timerBar(scheme),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pageCount,
                onPageChanged: _onPageChanged,
                itemBuilder: (_, i) => i == 0 ? _ingredientsPage() : _stepPage(i - 1),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _page == 0 ? null : () => _go(-1),
                      icon: const Icon(Icons.arrow_back),
                      label: Text(tr('Anterior')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _page == _pageCount - 1
                        ? FilledButton.icon(
                            onPressed: () => Navigator.of(context).pop(true),
                            icon: const Icon(Icons.check),
                            label: Text(tr('¡Terminé!')),
                          )
                        : FilledButton.icon(
                            onPressed: () => _go(1),
                            icon: const Icon(Icons.arrow_forward),
                            label: Text(_page == 0 ? tr('Empezar') : tr('Siguiente')),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timerBar(ColorScheme scheme) {
    final done = _remaining == Duration.zero;
    return Container(
      width: double.infinity,
      color: done ? scheme.errorContainer : scheme.primaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(done ? Icons.alarm_on : Icons.timer_outlined),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              done
                  ? tr('¡Tiempo! (paso {v})', {'v': _timerStep! + 1})
                  : tr('Paso {v}: {_remaining}', {'v': _timerStep! + 1, '_remaining': formatTimer(_remaining!)}),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          TextButton(onPressed: _stopTimer, child: Text(done ? tr('Listo') : tr('Cancelar'))),
        ],
      ),
    );
  }

  Widget _ingredientsPage() {
    final items = widget.recipe.recipeIngredients;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(tr('Preparate'), style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 4),
        Text(tr('Tildá lo que ya tenés a mano.'),
            style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 12),
        for (var i = 0; i < items.length; i++)
          CheckboxListTile(
            value: _checkedIngredients.contains(i),
            onChanged: (v) => setState(() =>
                v == true ? _checkedIngredients.add(i) : _checkedIngredients.remove(i)),
            title: Text(
              '${formatQuantity(items[i].quantity, items[i].unit)} — ${items[i].ingredient.name}',
              style: const TextStyle(fontSize: 20),
            ),
          ),
      ],
    );
  }

  Widget _stepPage(int index) {
    final step = _steps[index];
    final minutes = parseStepMinutes(step.instruction);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr('Paso {v} de {_steps}', {'v': index + 1, '_steps': _steps.length}),
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          Text(step.instruction,
              style: const TextStyle(fontSize: 28, height: 1.35, fontWeight: FontWeight.w500)),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              if (minutes != null && _timerStep != index)
                FilledButton.tonalIcon(
                  onPressed: () => _startTimer(index, minutes),
                  icon: const Icon(Icons.timer_outlined),
                  label: Text(tr('Temporizador {minutes} min', {'minutes': minutes})),
                ),
              OutlinedButton.icon(
                onPressed: () => _tts.speak(step.instruction),
                icon: const Icon(Icons.replay),
                label: Text(tr('Repetir')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
