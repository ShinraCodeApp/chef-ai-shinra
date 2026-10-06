import 'package:chef_ai_app/core/diet_tags.dart';
import 'package:chef_ai_app/core/expiry.dart';
import 'package:chef_ai_app/core/i18n.dart';
import 'package:chef_ai_app/core/i18n_en.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => AppLanguage.instance.debugSet('es'));

  test('castellano por defecto: devuelve el texto tal cual', () {
    AppLanguage.instance.debugSet('es');
    expect(tr('Generar receta'), 'Generar receta');
    expect(tr('Hola, {name}', {'name': 'Ana'}), 'Hola, Ana');
  });

  test('inglés: traduce y reemplaza variables', () {
    AppLanguage.instance.debugSet('en');
    expect(tr('Generar receta'), 'Generate recipe');
    expect(tr('Hola, {name}', {'name': 'Ana'}), 'Hi, Ana');
    expect(expiryLabel(3), 'expires in 3 days');
    expect(dietTagLabel('vegetariano'), 'vegetarian');
    expect(dietTagLabel('Vegetarian'), 'vegetarian');
    expect(difficultyLabel('easy'), 'Easy');
  });

  test('sin traducción: queda el castellano', () {
    AppLanguage.instance.debugSet('en');
    expect(tr('Texto que no existe'), 'Texto que no existe');
  });

  test('voz y lectura siguen el idioma', () {
    AppLanguage.instance.debugSet('en');
    expect(AppLanguage.instance.speechLocale, 'en_US');
    expect(AppLanguage.instance.ttsLanguage, 'en-US');
    AppLanguage.instance.debugSet('es');
    expect(AppLanguage.instance.speechLocale, 'es_AR');
  });

  test('las traducciones mantienen las mismas variables', () {
    final placeholder = RegExp(r'\{\w+\}');
    for (final entry in kEnglish.entries) {
      final a = placeholder.allMatches(entry.key).map((m) => m[0]).toList()..sort();
      final b = placeholder.allMatches(entry.value).map((m) => m[0]).toList()..sort();
      expect(b, a, reason: entry.key);
    }
  });
}
