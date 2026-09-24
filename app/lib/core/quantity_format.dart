/// Formatea una cantidad de ingrediente eligiendo la unidad más legible:
/// - Sólidos (g/kg): gramos si es menos de 1 kilo, kilos si es 1 kilo o más.
/// - Líquidos (ml/l): mililitros si es menos de 1 litro, litros si es 1 litro o más.
/// - El resto de las unidades (ej. "unidad") se muestran tal cual, sin decimales de más.
/// Nunca deja un ".0" colgando: 1.0 se muestra "1", 1.5 se muestra "1.5".
String formatQuantity(double quantity, String unit) {
  switch (unit) {
    case 'kg':
    case 'g':
      final grams = unit == 'kg' ? quantity * 1000 : quantity;
      if (grams >= 1000) {
        return '${_trim(grams / 1000)} kg';
      }
      return '${_trim(grams)} g';
    case 'l':
    case 'ml':
      final milliliters = unit == 'l' ? quantity * 1000 : quantity;
      if (milliliters >= 1000) {
        return '${_trim(milliliters / 1000)} l';
      }
      return '${_trim(milliliters)} ml';
    default:
      return '${_trim(quantity)} $unit';
  }
}

/// Redondea a 2 decimales para evitar ruido de punto flotante (ej. 59.999999)
/// y después saca los ceros de más: 60.00 -> "60", 1.50 -> "1.5".
String _trim(double n) {
  final normalized = double.parse(n.toStringAsFixed(2));
  if (normalized == normalized.roundToDouble()) {
    return normalized.toStringAsFixed(0);
  }
  var s = normalized.toStringAsFixed(2);
  s = s.replaceFirst(RegExp(r'0$'), '');
  s = s.replaceFirst(RegExp(r'\.$'), '');
  return s;
}
