import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Azul tecnológico (primario) + verde Shinra (secundario), según la identidad
// de marca de Chef AI by Shinra.
const Color kShinraBlue = Color(0xFF2563EB);
const Color kShinraGreen = Color(0xFF22C55E);
// Fondo oscuro del ícono/splash oficial (gorro de chef + circuitos).
const Color kShinraSplashBg = Color(0xFF001122);

ThemeData buildChefAiTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: kShinraBlue,
    secondary: kShinraGreen,
    brightness: brightness,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
    ),
  );
}

/// Persiste la preferencia de tema (claro/oscuro/automático) entre sesiones.
class ThemeModeController extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  static const _prefsKey = 'theme_mode';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_prefsKey);
    _mode = switch (stored) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    notifyListeners();
  }

  Future<void> setMode(ThemeMode mode) async {
    _mode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, mode.name);
  }
}
