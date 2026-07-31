import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/inventory_provider.dart';
import 'providers/recipes_provider.dart';
import 'providers/meal_plans_provider.dart';
import 'providers/shopping_lists_provider.dart';
import 'providers/admin_provider.dart';
import 'screens/auth/auth_gate.dart';

void main() {
  runApp(const ChefAiApp());
}

class ChefAiApp extends StatelessWidget {
  const ChefAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => InventoryProvider()),
        ChangeNotifierProvider(create: (_) => RecipesProvider()),
        ChangeNotifierProvider(create: (_) => MealPlansProvider()),
        ChangeNotifierProvider(create: (_) => ShoppingListsProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => ThemeModeController()..load()),
      ],
      child: Consumer<ThemeModeController>(
        builder: (context, themeController, _) => MaterialApp(
          title: 'Chef AI by Shinra',
          debugShowCheckedModeBanner: false,
          theme: buildChefAiTheme(Brightness.light),
          darkTheme: buildChefAiTheme(Brightness.dark),
          themeMode: themeController.mode,
          home: const AuthGate(),
        ),
      ),
    );
  }
}
