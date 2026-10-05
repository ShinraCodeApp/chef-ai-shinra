import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../core/i18n.dart';

/// Botón de micrófono reutilizable. Escucha hasta que el usuario para de hablar
/// y llama [onResult] con el texto transcripto.
class VoiceInputButton extends StatefulWidget {
  const VoiceInputButton({
    super.key,
    required this.onResult,
    this.locale,
  });

  final void Function(String text) onResult;
  final String? locale; // null = el idioma de la app

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton>
    with SingleTickerProviderStateMixin {
  final _stt = SpeechToText();
  bool _available = false;
  bool _listening = false;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    final ok = await _stt.initialize(onError: (_) => _stopListening());
    if (mounted) setState(() => _available = ok);
  }

  Future<void> _startListening() async {
    if (!_available) return;
    setState(() => _listening = true);
    await _stt.listen(
      listenOptions: SpeechListenOptions(localeId: widget.locale ?? AppLanguage.instance.speechLocale),
      onResult: (result) {
        if (result.finalResult) {
          widget.onResult(result.recognizedWords);
          _stopListening();
        }
      },
    );
  }

  void _stopListening() {
    _stt.stop();
    if (mounted) setState(() => _listening = false);
  }

  @override
  void dispose() {
    _pulse.dispose();
    _stt.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_available) return const SizedBox.shrink();
    final color = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, _) => IconButton(
        icon: Icon(
          _listening ? Icons.mic : Icons.mic_none,
          color: _listening
              ? Color.lerp(color.error, color.primary, _pulse.value)
              : color.onSurfaceVariant,
        ),
        tooltip: _listening ? tr('Escuchando…') : tr('Dictado por voz'),
        onPressed: _listening ? _stopListening : _startListening,
      ),
    );
  }
}

/// TextField con botón de micrófono integrado al final.
class VoiceTextField extends StatelessWidget {
  const VoiceTextField({
    super.key,
    required this.controller,
    this.decoration = const InputDecoration(),
    this.keyboardType,
    this.maxLines = 1,
    this.onSubmitted,
    this.onChanged,
    this.locale,
    this.appendMode = false,
  });

  final TextEditingController controller;
  final InputDecoration decoration;
  final TextInputType? keyboardType;
  final int? maxLines;
  final void Function(String)? onSubmitted;
  final void Function(String)? onChanged;
  final String? locale; // null = el idioma de la app

  /// Si true, el texto dictado se agrega al existente; si false lo reemplaza.
  final bool appendMode;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: decoration.copyWith(
        suffixIcon: VoiceInputButton(
          locale: locale,
          onResult: (text) {
            final newText = appendMode
                ? '${controller.text}${controller.text.isEmpty ? '' : ' '}$text'
                : text;
            controller.value = TextEditingValue(
              text: newText,
              selection: TextSelection.collapsed(offset: newText.length),
            );
            onChanged?.call(newText);
          },
        ),
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      onSubmitted: onSubmitted,
      onChanged: onChanged,
    );
  }
}
