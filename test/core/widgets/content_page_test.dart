import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_career/core/widgets/content_page.dart';

void main() {
  testWidgets('una pantalla raíz no muestra el botón volver', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: ContentPage(title: 'Materias', child: Text('Contenido')),
      ),
    ));

    expect(find.byIcon(Icons.arrow_back), findsNothing);
  });

  testWidgets('una pantalla secundaria muestra back y usa el fallback',
      (tester) async {
    var fallbackCalled = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ContentPage(
          title: 'Nueva materia',
          showBackButton: true,
          backFallback: () => fallbackCalled = true,
          child: const Text('Formulario'),
        ),
      ),
    ));

    await tester.tap(find.byIcon(Icons.arrow_back));

    expect(fallbackCalled, isTrue);
  });
}
