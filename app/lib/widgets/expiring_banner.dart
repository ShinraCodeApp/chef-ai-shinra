import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/expiry.dart';
import '../providers/inventory_provider.dart';
import '../screens/generate_recipe/generate_recipe_screen.dart';

/// Cartel del inicio con lo que vence en los próximos 3 días y un atajo para
/// cocinar con eso antes de tirarlo.
class ExpiringBanner extends StatefulWidget {
  const ExpiringBanner({super.key});

  @override
  State<ExpiringBanner> createState() => _ExpiringBannerState();
}

class _ExpiringBannerState extends State<ExpiringBanner> {
  @override
  void initState() {
    super.initState();
    // carga el inventario (y reprograma los avisos) al entrar al inicio
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<InventoryProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = context.watch<InventoryProvider>().items;
    final soon = expiringSoon(items, DateTime.now());
    if (soon.isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final names = soon.map((i) => i.ingredient.name).toSet().toList();
    final preview = soon.take(3).map((i) =>
        '${i.ingredient.name} (${expiryLabel(daysUntilExpiry(i, now)!)})');

    return Card(
      color: scheme.tertiaryContainer,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule, color: scheme.onTertiaryContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    soon.length == 1
                        ? '1 producto por vencer'
                        : '${soon.length} productos por vencer',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: scheme.onTertiaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              preview.join(' · ') + (soon.length > 3 ? '…' : ''),
              style: TextStyle(color: scheme.onTertiaryContainer),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Cocinar con esto'),
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => GenerateRecipeScreen(
                    initialIngredients: names,
                    initialRequest: 'Usá primero lo que está por vencer',
                  ),
                )),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
