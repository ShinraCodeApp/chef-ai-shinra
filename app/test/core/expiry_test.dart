import 'package:chef_ai_app/core/expiry.dart';
import 'package:chef_ai_app/models/ingredient.dart';
import 'package:chef_ai_app/models/inventory_item.dart';
import 'package:flutter_test/flutter_test.dart';

InventoryItem item(String name, String? expires) => InventoryItem(
      id: name,
      ingredientId: name,
      ingredient: Ingredient(id: name, name: name, category: 'otros', unit: 'unidad'),
      quantity: 1,
      unit: 'unidad',
      state: 'fresh',
      expirationDate: expires,
      source: 'manual',
    );

void main() {
  // lunes 5 de octubre de 2026, 9:00
  final now = DateTime(2026, 10, 5, 9);

  test('días hasta el vencimiento', () {
    expect(daysUntilExpiry(item('leche', '2026-10-05'), now), 0);
    expect(daysUntilExpiry(item('leche', '2026-10-06'), now), 1);
    expect(daysUntilExpiry(item('leche', '2026-10-01'), now), -4);
    expect(daysUntilExpiry(item('arroz', null), now), isNull);
  });

  test('por vencer: hoy hasta 3 días, ordenado, sin los vencidos ni los sin fecha', () {
    final items = [
      item('yogur', '2026-10-08'),
      item('leche', '2026-10-06'),
      item('queso', '2026-10-09'), // 4 días: afuera
      item('pan', '2026-10-03'), // ya venció: afuera
      item('arroz', null),
      item('huevos', '2026-10-05'),
    ];
    expect(expiringSoon(items, now).map((i) => i.id), ['huevos', 'leche', 'yogur']);
  });

  test('textos', () {
    expect(expiryLabel(0), 'vence hoy');
    expect(expiryLabel(1), 'vence mañana');
    expect(expiryLabel(3), 'vence en 3 días');
  });

  test('avisos a las 10 hs del día anterior y del mismo día, sin horarios pasados', () {
    final plan = planExpiryReminders([
      item('leche', '2026-10-07'),
      item('huevos', '2026-10-05'), // hoy: el aviso de "mañana" ya pasó
      item('pan', '2026-10-01'),
    ], now);

    expect(plan.map((r) => r.title), [
      'Huevos: vence hoy',
      'Leche: vence mañana',
      'Leche: vence hoy',
    ]);
    expect(plan.first.when, DateTime(2026, 10, 5, 10));
    expect(plan[1].when, DateTime(2026, 10, 6, 10));
    expect(plan.map((r) => r.id).toSet().length, 3, reason: 'ids distintos');
  });
}
