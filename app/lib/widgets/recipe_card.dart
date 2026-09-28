import 'package:flutter/material.dart';
import '../core/diet_tags.dart';
import '../core/recipe_images.dart';
import '../models/recipe.dart';

class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback onTap;

  /// Etiqueta que no hace falta repetir en la tarjeta (ej. la del filtro activo
  /// de la lista: en "Comida vegana" no tiene sentido mostrar "vegano" en todas).
  final String? hiddenTag;

  const RecipeCard({
    super.key,
    required this.recipe,
    required this.onTap,
    this.hiddenTag,
  });

  /// Orden de prioridad para elegir qué etiquetas mostrar: primero las
  /// restricciones (lo que la persona NO puede comer), después las de salud y
  /// por último los estilos de comida.
  static const _tagPriority = [
    'vegano',
    'vegetariano',
    'sin_tacc',
    'bajo_yodo',
    'hipotiroidismo',
    'hipertiroidismo',
    'keto',
    'proteico',
    'fitness',
    'comida_cruda',
    'economico',
    'anime',
  ];
  static const _maxTags = 3;

  List<String> _visibleTags() {
    final tags = recipe.dietTags.where((t) => t != hiddenTag).toSet();
    // "vegano" ya implica "vegetariano".
    if (tags.contains('vegano')) tags.remove('vegetariano');
    int rank(String t) {
      final i = _tagPriority.indexOf(t);
      return i == -1 ? _tagPriority.length : i;
    }

    return tags.toList()..sort((a, b) => rank(a).compareTo(rank(b)));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _thumbnail(scheme),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(recipe.title,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(
                      recipe.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: [
                        _chip(context, Icons.timer_outlined, '${recipe.prepTimeMinutes} min'),
                        _chip(context, Icons.people_outline, '${recipe.servings} porciones'),
                        if (recipe.estimatedCostTotal != null)
                          _chip(context, Icons.attach_money,
                              recipe.estimatedCostTotal!.toStringAsFixed(0)),
                      ],
                    ),
                    ..._tagsRow(context),
                  ],
                ),
              ),
              Icon(
                recipe.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: recipe.isFavorite ? scheme.error : scheme.outline,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _thumbnail(ColorScheme scheme) {
    final placeholder = Container(
      color: scheme.primaryContainer,
      child: Icon(Icons.restaurant, color: scheme.onPrimaryContainer),
    );
    final localAsset = localRecipeImageAsset(recipe.title);
    final url = recipe.imageUrl;

    Widget image;
    if (localAsset != null) {
      image = Image.asset(
        localAsset,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => placeholder,
      );
    } else if (url != null && url.isNotEmpty) {
      image = Image.network(
        url,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            color: scheme.surfaceContainerHighest,
            child: const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => placeholder,
      );
    } else {
      image = placeholder;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(width: 56, height: 56, child: image),
    );
  }

  List<Widget> _tagsRow(BuildContext context) {
    final tags = _visibleTags();
    if (tags.isEmpty) return const [];
    final shown = tags.take(_maxTags).toList();
    final extra = tags.length - shown.length;
    return [
      const SizedBox(height: 6),
      Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          ...shown.map((t) => _tagPill(context, dietTagLabel(t))),
          if (extra > 0) _tagPill(context, '+$extra'),
        ],
      ),
    ];
  }

  Widget _tagPill(BuildContext context, String label) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: scheme.onSecondaryContainer),
      ),
    );
  }

  Widget _chip(BuildContext context, IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Theme.of(context).colorScheme.outline),
        const SizedBox(width: 2),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
