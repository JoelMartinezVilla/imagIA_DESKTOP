import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AutenticationPage extends StatefulWidget {
  final String token; // Recibe el token desde el main

  AutenticationPage({required this.token});

  @override
  _AutenticationPageState createState() => _AutenticationPageState();
}

class _AutenticationPageState extends State<AutenticationPage> {
  List<dynamic> _usuarios = []; // Lista de usuarios que obtendremos del servidor
  bool _loading = true; // Indicador de carga
  String _error = ''; // Para manejar errores

  @override
  void initState() {
    super.initState();
    _obtenerUsuarios(); // Llamada inicial para obtener el listado de usuarios
  }

  // Función para obtener la lista de usuarios desde el servidor
  Future<void> _obtenerUsuarios() async {
    final String url = "https://imagia3.com/api/admin/usuaris"; 

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}', 
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _usuarios = jsonDecode(response.body);
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Error al obtener usuarios: ${response.statusCode}';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error de conexión: $e';
        _loading = false;
      });
    }
  }

  // Función para cambiar el plan de un usuario
  Future<void> _cambiarPlan(String userId, String nuevoPlan) async {
    final String url = "https://tu-servidor.com/api/admin/usuaris/$userId/plan"; // Cambiar por la URL real

    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}', // Autorización con token
        },
        body: jsonEncode({'plan': nuevoPlan}), // Cambiar plan
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Plan de usuario actualizado a $nuevoPlan'),
          backgroundColor: Colors.green,
        ));
        _obtenerUsuarios(); // Refrescar la lista tras actualizar
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al cambiar plan: ${response.statusCode}'),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error de conexión: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[800],
        title: Text(
          'Lista de Usuarios',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24.0,
          ),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? Center(child: SizedBox()) // Eliminamos el CircularProgressIndicator
          : _error.isNotEmpty
              ? Center(
                  child: Text(_error, style: TextStyle(color: Colors.red)),
                )
              : ListView.builder(
                  itemCount: _usuarios.length,
                  itemBuilder: (context, index) {
                    final usuario = _usuarios[index];
                    final planActual = usuario['plan'];

                    return ListTile(
                      title: Text(usuario['nombre']),
                      subtitle: Text('Plan actual: $planActual'),
                      trailing: DropdownButton<String>(
                        value: planActual,
                        items: ['Free', 'Premium'].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (nuevoPlan) {
                          if (nuevoPlan != null) {
                            _cambiarPlan(usuario['id'], nuevoPlan); 
                          }
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
