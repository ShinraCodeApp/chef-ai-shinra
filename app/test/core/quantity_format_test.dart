import 'package:chef_ai_app/core/quantity_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatQuantity', () {
    test('gramos: sin ".0" y pasa a kilos desde 1000 g', () {
      expect(formatQuantity(210, 'g'), '210 g');
      expect(formatQuantity(1000, 'g'), '1 kg');
      expect(formatQuantity(1500, 'g'), '1.5 kg');
    });

    test('kilos menores a 1 se muestran en gramos', () {
      expect(formatQuantity(0.5, 'kg'), '500 g');
      expect(formatQuantity(2, 'kg'), '2 kg');
    });

    test('líquidos: ml y litros', () {
      expect(formatQuantity(200, 'ml'), '200 ml');
      expect(formatQuantity(1000, 'ml'), '1 l');
      expect(formatQuantity(0.25, 'l'), '250 ml');
    });

    test('unidades en singular y plural, sin decimales de más', () {
      expect(formatQuantity(1, 'unidad'), '1 unidad');
      expect(formatQuantity(2, 'unidad'), '2 unidades');
      expect(formatQuantity(12, 'unidad'), '12 unidades');
    });

    test('evita ruido de punto flotante', () {
      expect(formatQuantity(59.999999, 'g'), '60 g');
    });
  });
}
