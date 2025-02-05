import 'package:flutter/material.dart';
import 'dart:convert'; 
import 'dart:io'; 
import 'package:http/http.dart' as http; 
import 'autentication.dart'; // Importa la página de usuarios después de autenticación.

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
  String? _token;

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
      'usuarios': [_usuarioController.text],
      // Guardamos el token solo si no es null
      'token': _token ?? '',
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
            _token = datos['token'] ?? '';
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
      final uri = Uri.parse('$url/api/admin/usuaris/login');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': usuario,
          'contrasenya': password,
        }),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);

        if (body.containsKey('token')) {
          _token = body['token'];

          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Inicio de sesión exitoso'),
          ));
          print('Respuesta del servidor: ${response.body}');

          // Solo guardamos el token si no es null o vacío
          if (_token != null && _token!.isNotEmpty) {
            _guardarDades(); // Guardar los datos

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AutenticationPage(token: _token!),
              ),
            );
          } else {
            _mostrarMensajeError('No se ha recibido un token');
          }
        } else {
          _mostrarMensajeError('No se ha recibido un token');
        }
      } else {
        _mostrarMensajeError('Error en la solicitud: ${response.statusCode}');
        print('Error en la solicitud: ${response.statusCode}');
      }
    } catch (e) {
      _mostrarMensajeError('Error de conexión: $e');
      print('Error de conexión: $e');
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
        title: Text('IMAGIA3 DESKTOP',
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
                    labelText: 'Email',
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
                    labelText: 'Contrasenya',
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                ),
              ),
              SizedBox(height: 24.0),
              ElevatedButton(
                onPressed: _realizarSolicitudDeLogin,
                child: Text('Acceder'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
