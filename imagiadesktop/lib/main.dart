import 'package:flutter/material.dart';
import 'dart:convert'; 
import 'dart:io'; 
import 'package:http/http.dart' as http; 
import 'autentication.dart'; // Importar la nueva pantalla

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
    _cargarDades();
  }

  Future<File> _getLocalFile() async {
    final path = './lib/';
    return File('$path/dades.json');
  }

  Future<void> _guardarDades() async {
    final File file = await _getLocalFile();
    Map<String, dynamic> datos = {
      'urls': [_urlController.text], 
      'usuarios': [_usuarioController.text] 
    };

    try {
      await file.writeAsString(jsonEncode(datos));
      print('Datos guardados: ${jsonEncode(datos)}');
      print('Archivo guardado correctamente en ${file.path}');
    } catch (e) {
      print('Error al guardar los datos: $e');
    }
  }

  Future<void> _cargarDades() async {
    try {
      final File file = await _getLocalFile();
      if (await file.exists()) {
        String contents = await file.readAsString();
        Map<String, dynamic> datos = jsonDecode(contents);

        if (datos.isNotEmpty) {
          setState(() {
            _urlController.text = datos['urls'].isNotEmpty ? datos['urls'].last : '';
            _usuarioController.text = datos['usuarios'].isNotEmpty ? datos['usuarios'].last : '';
          });
        }
      }
    } catch (e) {
      print("Error al cargar datos: $e");
    }
  }

  Future<void> _realizarSolicitudDeLogin() async {
    final url = _urlController.text.trim(); 
    final usuario = _usuarioController.text.trim();
    final password = _passwordController.text.trim();

    if (url.isEmpty || usuario.isEmpty || password.isEmpty) {
      _mostrarMensajeError('Todos los campos son obligatorios');
      return;
    }

    try {
      final uri = Uri.parse('$url/api/usuaris/registrar');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'usuario': usuario,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Inicio de sesión exitoso'),
        ));
        print('Respuesta del servidor: ${response.body}');

        // Navegar a la pantalla de autenticación
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AutenticationPage()), // Redirigir a la pantalla de autenticación
        );
      } else {
        _mostrarMensajeError('Error en la solicitud: ${response.statusCode}');
        print('Error en la solicitud: ${response.statusCode}');
      }
    } catch (e) {
      _mostrarMensajeError('Error de conexión: $e');
      print('Error de conexión: $e');
    }
  }

  void _validarYGuardarDatos() {
    if (_urlController.text.isEmpty) {
      _mostrarMensajeError('Falta la URL del servidor');
    } else if (_usuarioController.text.isEmpty) {
      _mostrarMensajeError('Falta el usuario');
    } else if (_passwordController.text.isEmpty) {
      _mostrarMensajeError('Falta la contraseña');
    } else {
      _guardarDades();
      _realizarSolicitudDeLogin();
    }
  }

  void _mostrarMensajeError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(mensaje),
      backgroundColor: Colors.red,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[800],
        centerTitle: true,
        title: Text(
          'IMAGIA3 DESKTOP',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24.0,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 250,
                child: TextField(
                  controller: _urlController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'URL del servidor',
                    prefixIcon: Icon(Icons.language),
                  ),
                ),
              ),
              SizedBox(height: 16.0),
              SizedBox(
                width: 250,
                child: TextField(
                  controller: _usuarioController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Usuario',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
              ),
              SizedBox(height: 16.0),
              SizedBox(
                width: 250,
                child: TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Contraseña',
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                ),
              ),
              SizedBox(height: 24.0),
              ElevatedButton(
                onPressed: _validarYGuardarDatos,
                child: Text('Acceder'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
