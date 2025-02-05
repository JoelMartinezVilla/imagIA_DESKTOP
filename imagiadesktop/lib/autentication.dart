import 'package:flutter/material.dart';

class AutenticationPage extends StatelessWidget {
  final String token;

  AutenticationPage({required this.token});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Autenticación Exitosa'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '¡Has accedido con éxito!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Redirigir o cerrar sesión si es necesario.
                Navigator.pop(context);
              },
              child: Text('Volver a la página de inicio'),
            ),
          ],
        ),
      ),
    );
  }
}
