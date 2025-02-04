import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Importar la clase AutenticationPage
import 'package:imagiadesktop/autentication.dart';

// Simulamos una clase MockHttpClient para interceptar las llamadas de http
class MockHttpClient extends http.Client {
  @override
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    // Simulamos una respuesta exitosa con una lista de usuarios
    return http.Response(
      jsonEncode([
        {'id': '1', 'nombre': 'Juan', 'plan': 'Free'},
        {'id': '2', 'nombre': 'Ana', 'plan': 'Premium'},
      ]),
      200,
    );
  }

  @override
  Future<http.Response> put(Uri url, {Map<String, String>? headers, body}) async {
    // Simulamos una respuesta exitosa cuando se cambia el plan
    return http.Response(jsonEncode({'status': 'success'}), 200);
  }
}

void main() {
  testWidgets('Probar la autenticación y carga de usuarios', (WidgetTester tester) async {
    // Creamos una instancia de la clase MockHttpClient
    final mockClient = MockHttpClient();

    // Inyectamos un token ficticio para la prueba
    final token = 'fake_token';

    // Creamos la aplicación con el widget AutenticationPage con el token
    await tester.pumpWidget(MaterialApp(
      home: AutenticationPage(token: token), // Usamos el token simulado
    ));

    // Simulamos la llamada a la API para obtener los usuarios
    await tester.pump(); // Esperamos que el widget se renderice

    // Verificamos que los usuarios se hayan cargado correctamente
    expect(find.text('Juan'), findsOneWidget);
    expect(find.text('Ana'), findsOneWidget);

    // Simulamos la acción de cambiar el plan
    final dropdownButton = find.byType(DropdownButton<String>).first;
    await tester.tap(dropdownButton); // Abrimos el Dropdown
    await tester.pumpAndSettle(); // Esperamos que el Dropdown se expanda

    // Verificamos que las opciones 'Free' y 'Premium' estén presentes
    expect(find.text('Free'), findsOneWidget);
    expect(find.text('Premium'), findsOneWidget);

    // Simulamos la selección de un nuevo plan
    await tester.tap(find.text('Premium').last); // Seleccionamos 'Premium'
    await tester.pumpAndSettle(); // Esperamos que el cambio se realice

    // Verificamos que el plan se haya actualizado correctamente
    // Podrías verificar que el mensaje de snack bar o alguna indicación se muestra en pantalla
    expect(find.text('Plan de usuario actualizado a Premium'), findsOneWidget);
  });
}
