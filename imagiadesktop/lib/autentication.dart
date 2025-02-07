import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AutenticationPage extends StatefulWidget {
  final String token;
  const AutenticationPage({Key? key, required this.token}) : super(key: key);

  @override
  _AutenticationPageState createState() => _AutenticationPageState();
}

class _AutenticationPageState extends State<AutenticationPage> with SingleTickerProviderStateMixin {
  late String token;
  List<dynamic> _usuarios = [];
  List<dynamic> _logs = [];
  String? _error;
  TabController? _tabController;
  int? _selectedUserId;

  @override
  void initState() {
    super.initState();
    token = widget.token;
    _tabController = TabController(length: 2, vsync: this);
    _obtenerUsuariosDesdeAPI();
  }

  /// Función auxiliar para normalizar el valor del plan.
  String normalizePlan(dynamic plan) {
    if (plan == null) return 'Free';
    String p = plan.toString().toLowerCase();
    if (p == 'free') return 'Free';
    if (p == 'premium') return 'Premium';
    return 'Free';
  }

  /// Obtiene la lista de usuarios desde la API.
  Future<void> _obtenerUsuariosDesdeAPI() async {
    final url = 'https://imagia3.ieti.site/api/admin/usuaris';
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
        if (data.containsKey('data')) {
          setState(() {
            _usuarios = (data['data'] as List).map((usuario) {
              usuario['pla'] = normalizePlan(usuario['pla']);
              return usuario;
            }).toList();
          });
        } else {
          setState(() {
            _error = 'La respuesta no contiene la lista de usuarios';
          });
        }
      } else {
        setState(() {
          _error = 'Error al obtener usuarios: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error de conexión: $e';
      });
    }
  }

  /// Obtiene los logs de un usuario desde la API.
  Future<void> _obtenerLogsDesdeAPI(int usuarioId) async {
    final url = 'https://imagia3.ieti.site/api/admin/logs/$usuarioId';
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
        if (data.containsKey('logs')) {
          setState(() {
            _logs = data['logs'];
            _selectedUserId = usuarioId;
            _tabController!.animateTo(1); // Cambia a la pestaña de logs
          });
        } else {
          setState(() {
            _error = 'La respuesta no contiene logs';
          });
        }
      } else {
        setState(() {
          _error = 'Error al obtener logs: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error de conexión: $e';
      });
    }
  }

  /// Actualiza el plan de un usuario enviando los campos que espera el servidor.
  Future<void> _actualizarPlanUsuario(int usuarioId, String nuevoPlan) async {
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
          'Administración',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24.0,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Usuarios'),
            Tab(text: 'Logs'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Padding(
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
                                            _actualizarPlanUsuario(
                                                usuario['id'], newPlan);
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
                                  SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed: () {
                                      _obtenerLogsDesdeAPI(usuario['id']);
                                    },
                                    child: Text('Ver Logs'),
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
          // Pestaña de logs
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _logs.isNotEmpty
                ? ListView.builder(
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      var log = _logs[index];
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 8.0),
                        child: ListTile(
                          title: Text('Acción: ${log['accion'] ?? 'No disponible'}'),
                          subtitle: Text('Fecha: ${log['fecha'] ?? 'No disponible'}'),
                        ),
                      );
                    },
                  )
                : Center(
                    child: Text('No hay logs disponibles.'),
                  ),
          ),
        ],
      ),
    );
  }
}
