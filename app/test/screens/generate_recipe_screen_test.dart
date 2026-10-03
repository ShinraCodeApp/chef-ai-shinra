import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:chef_ai_app/core/api_client.dart';
import 'package:chef_ai_app/providers/recipes_provider.dart';
import 'package:chef_ai_app/screens/generate_recipe/generate_recipe_screen.dart';

void main() {
  // La pantalla pide /users/me/ai-info al abrirse: en los tests no hay red ni
  // almacenamiento seguro, así que toda request falla al instante.
  setUpAll(() {
    ApiClient.instance.dio.interceptors.insert(
      0,
      InterceptorsWrapper(
        onRequest: (options, handler) =>
            handler.reject(DioException(requestOptions: options)),
      ),
    );
  });

  group('GenerateRecipeScreen', () {
    Widget buildSubject() {
      return MaterialApp(
        home: ChangeNotifierProvider(
          create: (_) => RecipesProvider(),
          child: const GenerateRecipeScreen(),
        ),
      );
    }

    testWidgets('muestra campo de ingredientes y botón generar', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.text('¿Qué ingredientes tenés?'), findsOneWidget);
      expect(find.text('Generar receta'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 100)); // deja terminar la request de ai-info
    });

    testWidgets('muestra error si se intenta generar sin ingredientes', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.tap(find.text('Generar receta'));
      await tester.pump();
      expect(find.text('Agregá al menos un ingrediente.'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('agrega ingrediente al presionar el botón +', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.enterText(
        find.byType(TextField).first,
        'pollo',
      );
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
      expect(find.text('pollo'), findsOneWidget);
    });
  });
}
