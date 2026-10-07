import 'i18n.dart';

/// Etiqueta legible para cada dietTag/preferencia (los valores crudos usan
/// snake_case porque así los espera el backend, pero no deben mostrarse así).
const Map<String, String> kDietTagLabels = {
  'proteico': 'proteico',
  'vegetariano': 'vegetariano',
  'vegano': 'vegano',
  'sin_tacc': 'sin tacc',
  'keto': 'keto',
  'fitness': 'fitness',
  'economico': 'económico',
  'comida_cruda': 'comida cruda',
  'hipotiroidismo': 'hipotiroidismo',
  'hipertiroidismo': 'hipertiroidismo',
  'bajo_yodo': 'bajo en yodo',
  'anime': 'platos anime',
  'cerebro_sano': 'cerebro sano',
  'textura_suave': 'texturas suaves',
  'jugos': 'jugos y licuados',
};

/// Recetas generadas antes de pedirle a la IA las etiquetas en castellano
/// pueden traerlas en inglés ("Vegetarian", "gluten-free"...).
const Map<String, String> _englishDietTags = {
  'vegetarian': 'vegetariano',
  'vegan': 'vegano',
  'gluten_free': 'sin_tacc',
  'gluten-free': 'sin_tacc',
  'high_protein': 'proteico',
  'high-protein': 'proteico',
  'protein': 'proteico',
  'budget': 'economico',
  'cheap': 'economico',
  'low_cost': 'economico',
  'raw': 'comida_cruda',
};

String dietTagLabel(String tag) {
  final key = tag.trim().toLowerCase().replaceAll(' ', '_');
  final normalized = _englishDietTags[key] ?? key;
  final label = kDietTagLabels[normalized];
  return label == null ? tag : tr(label);
}

const Map<String, String> kDifficultyLabels = {
  'easy': 'Fácil',
  'medium': 'Media',
  'hard': 'Difícil',
};

String difficultyLabel(String difficulty) {
  final label = kDifficultyLabels[difficulty.toLowerCase()];
  return label == null ? difficulty : tr(label);
}
