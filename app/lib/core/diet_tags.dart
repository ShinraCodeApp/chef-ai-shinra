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
  'anime': 'platos anime',
};

String dietTagLabel(String tag) => kDietTagLabels[tag] ?? tag;
