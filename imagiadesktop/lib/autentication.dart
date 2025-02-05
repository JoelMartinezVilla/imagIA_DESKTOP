import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AutenticationPage extends StatefulWidget {
  final String token;
  const AutenticationPage({Key? key, required this.token}) : super(key: key);

  @override
  _AutenticationPageState createState() => _AutenticationPageState();
}

class _AutenticationPageState extends State<AutenticationPage> {
  late String token;
  List<dynamic> _usuarios = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    token = widget.token;
    _obtenerUsuariosDesdeAPI();  // Cargar usuarios desde la API
  }

  /// Función auxiliar para normalizar el valor del plan.
  /// Devuelve "Free" o "Premium" (con mayúscula inicial).
  String normalizePlan(dynamic plan) {
    if (plan == null) return 'Free';
    String p = plan.toString().toLowerCase();
    if (p == 'free') return 'Free';
    if (p == 'premium') return 'Premium';
    return 'Free';
  }

  /// Obtiene la lista de usuarios desde la API.
  Future<void> _obtenerUsuariosDesdeAPI() async {
    final url = 'https://imagia3.ieti.site/api/admin/usuaris'; // URL de la API
    final uri = Uri.parse(url);

    try {
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        // Se asume que la respuesta contiene la lista de usuarios en la clave "data"
        if (data.containsKey('data')) {
          setState(() {
            _usuarios = (data['data'] as List).map((usuario) {
              usuario['pla'] = normalizePlan(usuario['pla']);
              return usuario;
            }).toList();
          });
          print('Lista de usuarios obtenida: $_usuarios');
        } else {
          setState(() {
            _error = 'La respuesta no contiene la lista de usuarios';
          });
        }
      } else {
        setState(() {
          _error = 'Error al obtener usuarios: ${response.statusCode}';
        });
        print('Error al obtener usuarios: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _error = 'Error de conexión: $e';
      });
      print('Error de conexión: $e');
    }
  }

  /// Actualiza el plan de un usuario enviando los campos que espera el servidor.
  Future<void> _actualizarPlanUsuario(int usuarioId, String nuevoPlan) async {
    // Buscamos el usuario en la lista para obtener sus otros datos
    var usuario = _usuarios.firstWhere((u) => u['id'] == usuarioId, orElse: () => null);
    if (usuario == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Usuario no encontrado'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    final url = 'https://imagia3.ieti.site/api/admin/usuaris/pla/actualitzar';
    final uri = Uri.parse(url);

    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        // Enviamos los campos que espera el servidor: telefon, nickname, email y pla.
        body: jsonEncode({
          'telefon': usuario['telefon'],
          'nickname': usuario['nickname'],
          'email': usuario['email'],
          'pla': nuevoPlan,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK') {
          setState(() {
            usuario['pla'] = normalizePlan(nuevoPlan);
          });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Plan actualizado a ${normalizePlan(nuevoPlan)}'),
          ));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error al actualizar el plan'),
            backgroundColor: Colors.red,
          ));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al comunicarse con el servidor'),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      print('Error al actualizar el plan: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error de conexión al actualizar el plan'),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[800],
        centerTitle: true,
        title: Text(
          'Usuarios',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24.0,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _error != null
            ? Center(
                child: Text(
                  _error!,
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : _usuarios.isNotEmpty
                ? ListView.builder(
                    itemCount: _usuarios.length,
                    itemBuilder: (context, index) {
                      var usuario = _usuarios[index];
                      // Obtenemos el plan normalizado
                      String currentPlan = normalizePlan(usuario['pla']);
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 8.0),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Nickname: ${usuario['nickname'] ?? 'No disponible'}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.0,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Email: ${usuario['email'] ?? 'No disponible'}',
                                style: TextStyle(fontSize: 16.0),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Plan: $currentPlan',
                                style: TextStyle(fontSize: 16.0),
                              ),
                              // Desplegable para cambiar el plan
                              Row(
                                children: [
                                  Text(
                                    'Cambiar plan: ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16.0,
                                    ),
                                  ),
                                  DropdownButton<String>(
                                    value: currentPlan,
                                    onChanged: (String? newPlan) {
                                      if (newPlan != null &&
                                          newPlan != currentPlan) {
                                        _actualizarPlanUsuario(usuario['id'], newPlan);
                                      }
                                    },
                                    items: <String>['Free', 'Premium']
                                        .map<DropdownMenuItem<String>>((String value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(value),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  )
                : Center(
                    child: Text('Cargando usuarios...'),
                  ),
      ),
    );
  }
}
