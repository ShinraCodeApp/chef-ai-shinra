import 'package:flutter/material.dart';
import '../core/i18n.dart';

/// Aviso que aparece al elegir "Cerebro sano" o "Texturas suaves" en el perfil:
/// qué cambia en el plan semanal y qué cuidados tener. Es orientativo, no
/// reemplaza al médico, al nutricionista ni al fonoaudiólogo.
class SpecialDietNotice extends StatelessWidget {
  final Set<String> selected;

  const SpecialDietNotice({super.key, required this.selected});

  @override
  Widget build(BuildContext context) {
    final brain = selected.contains('cerebro_sano');
    final soft = selected.contains('textura_suave');
    if (!brain && !soft) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(top: 12),
      color: scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (brain)
              Text(tr(
                'Cerebro sano: tu plan semanal va a priorizar hojas verdes, verduras, frutos rojos, frutos secos, legumbres, granos integrales, pescado y aceite de oliva (dieta MIND), con poca sal. Si tomás anticoagulantes, consultá a tu médico por las hojas verdes (vitamina K).',
              )),
            if (brain && soft) const SizedBox(height: 8),
            if (soft)
              Text(tr(
                'Texturas suaves: las comidas van a ser blandas y húmedas (purés, cremas, guisos tiernos). La textura adecuada y si los líquidos deben espesarse los indica el fonoaudiólogo.',
              )),
            const SizedBox(height: 8),
            Text(
              tr('Es una guía general: no reemplaza la indicación de tu médico o nutricionista.'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
