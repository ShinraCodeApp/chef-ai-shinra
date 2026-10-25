import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/i18n.dart';
import '../../core/recipe_images.dart';
import '../../models/paginated.dart';
import '../../models/recipe.dart';
import '../../widgets/empty_state.dart';

/// Elegir una receta para el plan: buscador sobre todas las recetas o solo
/// las favoritas. Devuelve la [Recipe] elegida con `Navigator.pop`.
class RecipePickerScreen extends StatefulWidget {
  const RecipePickerScreen({super.key});

  @override
  State<RecipePickerScreen> createState() => _RecipePickerScreenState();
}

class _RecipePickerScreenState extends State<RecipePickerScreen> {
  final _dio = ApiClient.instance.dio;
  final _scroll = ScrollController();
  Timer? _debounce;

  String _search = '';
  bool _onlyFavorites = false;
  List<Recipe> _recipes = [];
  int _page = 1;
  int _totalPages = 1;
  bool _isLoading = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 300) {
        _loadNextPage();
      }
    });
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load({bool reset = true}) async {
    if (reset) _page = 1;
    setState(() {
      _isLoading = true;
      _failed = false;
    });
    try {
      if (_onlyFavorites) {
        final response = await _dio.get('/recipes/favorites');
        final query = _search.toLowerCase();
        _recipes = (response.data as List)
            .map((e) => Recipe.fromJson(e as Map<String, dynamic>))
            .where((r) => query.isEmpty || r.title.toLowerCase().contains(query))
            .toList();
        _totalPages = 1;
      } else {
        final response = await _dio.get('/recipes', queryParameters: {
          'page': _page,
          'limit': 20,
          if (_search.isNotEmpty) 'search': _search,
        });
        final paginated = Paginated<Recipe>.fromJson(
          response.data as Map<String, dynamic>,
          Recipe.fromJson,
        );
        _recipes = reset ? paginated.items : [..._recipes, ...paginated.items];
        _totalPages = paginated.totalPages;
      }
    } catch (_) {
      _failed = true;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _loadNextPage() {
    if (_isLoading || _page >= _totalPages) return;
    _page++;
    _load(reset: false);
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _search = value.trim();
      _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('Elegir receta'))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              autofocus: false,
              decoration: InputDecoration(
                hintText: tr('Buscar receta…'),
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                FilterChip(
                  label: Text(tr('Solo favoritas')),
                  avatar: const Icon(Icons.favorite, size: 16),
                  selected: _onlyFavorites,
                  onSelected: (v) {
                    _onlyFavorites = v;
                    _load();
                  },
                ),
              ],
            ),
          ),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_isLoading && _recipes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_failed && _recipes.isEmpty) {
      return EmptyState(
        icon: Icons.cloud_off,
        message: tr('No se pudieron cargar las recetas.'),
      );
    }
    if (_recipes.isEmpty) {
      return EmptyState(
        icon: Icons.search_off,
        message: tr('No hay recetas que coincidan.'),
      );
    }
    return ListView.separated(
      controller: _scroll,
      itemCount: _recipes.length + (_page < _totalPages ? 1 : 0),
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        if (index >= _recipes.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final recipe = _recipes[index];
        final imageUrl = recipeImageUrl(recipe.title) ?? recipe.imageUrl;
        return ListTile(
          leading: imageUrl != null && imageUrl.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    imageUrl,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Icon(Icons.restaurant),
                  ),
                )
              : const Icon(Icons.restaurant),
          title: Text(recipe.title),
          subtitle: Text(tr('{min} min', {'min': recipe.prepTimeMinutes})),
          onTap: () => Navigator.of(context).pop(recipe),
        );
      },
    );
  }
}
