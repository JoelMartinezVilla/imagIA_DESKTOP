import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App de sesión',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: PantallaInicioConLogica(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class PantallaInicioConLogica extends StatefulWidget {
  @override
  _PantallaInicioConLogicaState createState() =>
      _PantallaInicioConLogicaState();
}

class _PantallaInicioConLogicaState extends State<PantallaInicioConLogica> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _usuarioController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarDades(); // Cargar los datos guardados al iniciar la pantalla
  }

  // Obtener el directorio donde se guardarán los datos (en este caso, documentos del sistema)
  Future<String> _getLocalPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path; 
  }

  // Crear el archivo donde se guardarán los datos
  Future<File> _getLocalFile() async {
    final path = await _getLocalPath();
    return File('$path/dades.json'); // Guarda en el directorio de documentos del sistema
  }

  // Guardar la URL del servidor y el usuario en el archivo
  Future<void> _guardarDades() async {
    final File file = await _getLocalFile();
    Map<String, String> dades = {
      'url': _urlController.text,
      'usuario': _usuarioController.text,
    };
    await file.writeAsString(jsonEncode(dades));
  }

  // Cargar los datos guardados del archivo
  Future<void> _cargarDades() async {
    try {
      final File file = await _getLocalFile();
      if (await file.exists()) {
        String contents = await file.readAsString();
        Map<String, dynamic> dades = jsonDecode(contents);
        setState(() {
          _urlController.text = dades['url'] ?? '';
          _usuarioController.text = dades['usuario'] ?? '';
        });
      }
    } catch (e) {
      // Si ocurre un error, no hacemos nada
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Inicio de sesión'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Campo de URL del servidor
              TextField(
                controller: _urlController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'URL del servidor',
                ),
              ),
              SizedBox(height: 16.0),

              // Campo de Usuario
              TextField(
                controller: _usuarioController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Usuario',
                ),
              ),
              SizedBox(height: 16.0),

              // Campo de Contraseña
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Contraseña',
                ),
                obscureText: true,
              ),
              SizedBox(height: 24.0),

              // Botón de Acceder
              ElevatedButton(
                onPressed: () {
                  _guardarDades(); // Guarda la URL y el usuario al presionar el botón
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text("Datos guardados correctamente."),
                  ));
                },
                child: Text('Acceder'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
