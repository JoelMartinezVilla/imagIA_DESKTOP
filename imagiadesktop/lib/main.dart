import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';

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

  // Crear el archivo donde se guardarán los datos en la ruta especificada
  Future<File> _getLocalFile() async {
    final path = '/home/super/Documents/GitHub/imagIA_DESKTOP/imagiadesktop/lib/';

    // Retorna el archivo con la nueva ruta
    return File('$path/dades.json');
  }

  // Guardar la URL del servidor y el usuario en el archivo (sobrescribe los anteriores)
  Future<void> _guardarDades() async {
    final File file = await _getLocalFile();

    // Crear un nuevo mapa de datos con los valores actuales (sobrescribiendo los anteriores)
    Map<String, dynamic> datos = {
      'urls': [_urlController.text], // Crear una nueva lista con la nueva URL
      'usuarios': [_usuarioController.text] // Crear una nueva lista con el nuevo usuario
    };

    try {
      // Guardar los datos actualizados en el archivo (sobreescribe el archivo anterior)
      await file.writeAsString(jsonEncode(datos));

      // Depuración: Mostrar los datos que se han guardado
      print('Datos guardados: ${jsonEncode(datos)}');
      print('Archivo guardado correctamente en ${file.path}');
    } catch (e) {
      // Manejar cualquier error en la escritura del archivo
      print('Error al guardar los datos: $e');
    }
  }

  // Cargar los datos guardados del archivo
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

  // Validación de los campos
  void _validarYGuardarDatos() {
    // Verificar si alguno de los campos está vacío
    if (_urlController.text.isEmpty) {
      _mostrarMensajeError('Falta la URL del servidor');
    } else if (_usuarioController.text.isEmpty) {
      _mostrarMensajeError('Falta el usuario');
    } else if (_passwordController.text.isEmpty) {
      _mostrarMensajeError('Falta la contraseña');
    } else {
      // Si todos los campos están completos, guardar los datos
      _guardarDades();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Datos guardados correctamente."),
      ));
      print("Contraseña usada: ${_passwordController.text}");
    }
  }

  // Función para mostrar el mensaje de error
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
              // Campo de URL del servidor con ícono
              SizedBox(
                width: 250, 
                child: TextField(
                  controller: _urlController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'URL del servidor',
                    prefixIcon: Icon(Icons.language), // Ícono para URL
                  ),
                ),
              ),
              SizedBox(height: 16.0),

              // Campo de Usuario con ícono
              SizedBox(
                width: 250, 
                child: TextField(
                  controller: _usuarioController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Usuario',
                    prefixIcon: Icon(Icons.person), // Ícono para Usuario
                  ),
                ),
              ),
              SizedBox(height: 16.0),

              // Campo de Contraseña con ícono
              SizedBox(
                width: 250, 
                child: TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Contraseña',
                    prefixIcon: Icon(Icons.lock), // Ícono para Contraseña
                  ),
                  obscureText: true,
                ),
              ),
              SizedBox(height: 24.0),

              // Botón de Acceder
              ElevatedButton(
                onPressed: _validarYGuardarDatos, // Validar antes de guardar
                child: Text('Acceder'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
