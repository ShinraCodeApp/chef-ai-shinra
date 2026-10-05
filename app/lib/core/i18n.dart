import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'i18n_en.dart';

/// Idioma de la app: castellano por defecto, inglés opcional (Perfil).
///
/// Los textos se escriben en castellano en el código y se pasan por [tr]; si
/// el idioma es inglés se busca la traducción en [kEnglish] (si falta, queda
/// el castellano). Los valores variables van como {nombre}:
///   tr('Hola, {name}', {'name': user.name})
class AppLanguage extends ChangeNotifier {
  AppLanguage._();
  static final instance = AppLanguage._();

  static const _prefsKey = 'app_language';
  static const supported = ['es', 'en'];

  String _code = 'es';
  String get code => _code;
  bool get isEnglish => _code == 'en';

  /// Idioma del dictado por voz (speech_to_text) y de la lectura (flutter_tts).
  String get speechLocale => isEnglish ? 'en_US' : 'es_AR';
  String get ttsLanguage => isEnglish ? 'en-US' : 'es-AR';

  Future<void> load() async {
    try {
      final saved = (await SharedPreferences.getInstance()).getString(_prefsKey);
      if (saved != null && supported.contains(saved)) _code = saved;
    } catch (_) {}
    notifyListeners();
  }

  Future<void> set(String code) async {
    if (!supported.contains(code) || code == _code) return;
    _code = code;
    notifyListeners();
    try {
      await (await SharedPreferences.getInstance()).setString(_prefsKey, code);
    } catch (_) {}
  }

  /// Solo para tests.
  @visibleForTesting
  void debugSet(String code) => _code = code;
}

String tr(String spanish, [Map<String, Object?> args = const {}]) {
  var text = AppLanguage.instance.isEnglish ? (kEnglish[spanish] ?? spanish) : spanish;
  args.forEach((key, value) => text = text.replaceAll('{$key}', '${value ?? ''}'));
  return text;
}
