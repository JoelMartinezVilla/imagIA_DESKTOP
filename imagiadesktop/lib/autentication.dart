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
    _tabController!.addListener(_tabChanged); // Listener para cuando cambie de pestaña
    _obtenerUsuariosDesdeAPI();
  }

  /// Devuelve el plan formateado (Free o Premium).
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

  /// Obtiene los logs desde la API (global, sin usuario específico)  
  /// Se usan parámetros de consulta opcionales: 'contenido' y 'tag' (aquí se dejan como null).
  Future<void> _obtenerLogsDesdeAPI({String? contenido, String? tag}) async {
    print("Obteniendo logs con parámetros: contenido: $contenido, tag: $tag");
    final url = 'https://imagia3.ieti.site/api/admin/logs';
    final uri = Uri.parse(url).replace(queryParameters: {
      'contenido': contenido,
      'tag': tag,
    });

    try {
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      print('Respuesta del servidor: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data.containsKey('data')) {
          setState(() {
            _logs = data['data'];
            _tabController?.animateTo(1); // Cambiar a la pestaña de logs
          });
        } else {
          setState(() {
            _error = 'No se encontraron logs para los parámetros dados.';
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

  /// Actualiza el plan del usuario usando la ruta anterior.
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

  /// Método que se llama cuando cambia la pestaña.
  /// (En este ejemplo, cuando se selecciona la pestaña de Logs se hace la petición de logs)
  void _tabChanged() {
    if (_tabController!.index == 1) {
      _obtenerLogsDesdeAPI(); // Obtiene los logs (globales) cuando se selecciona la pestaña de logs
    }
  }

  /// Función para formatear la fecha del timestamp recibido.
  String formatTimestamp(String timestamp) {
    try {
      DateTime dt = DateTime.parse(timestamp).toLocal();
      return "${dt.year}-${dt.month.toString().padLeft(2,'0')}-${dt.day.toString().padLeft(2,'0')} "
             "${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}:${dt.second.toString().padLeft(2,'0')}";
    } catch (e) {
      return timestamp;
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
            Tab(child: Text('Usuarios', style: TextStyle(color: Colors.white))),
            Tab(child: Text('Logs', style: TextStyle(color: Colors.white))),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Pestaña de Usuarios
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _error != null
                ? Center(
                    child: Text(
                      _error!,
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
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
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
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
                                  // Dropdown para cambiar el plan (Free o Premium)
                                  DropdownButton<String>(
                                    value: currentPlan,
                                    onChanged: (String? newPlan) {
                                      if (newPlan != null && newPlan != currentPlan) {
                                        _actualizarPlanUsuario(usuario['id'], newPlan);
                                      }
                                    },
                                    items: <String>['Free', 'Premium']
                                        .map((String value) => DropdownMenuItem<String>(
                                              value: value,
                                              child: Text(value),
                                            ))
                                        .toList(),
                                  ),
                                  // Botón para ver logs
                                  ElevatedButton(
                                    onPressed: () {
                                      _obtenerLogsDesdeAPI(); // Obtiene los logs globales
                                    },
                                    child: Text('Ver Logs'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      )
                    : Center(child: Text('Cargando usuarios...')),
          ),
          // Pestaña de Logs
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _logs.isNotEmpty
                ? ListView.builder(
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      var log = _logs[index];
                      // Usamos la función formatTimestamp para mostrar la fecha de forma legible.
                      String fechaFormateada = log['timestamp'] != null ? formatTimestamp(log['timestamp']) : 'No disponible';
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 8.0),
                        child: ListTile(
                          title: Text(
                            'Acción: ${log['message'] ?? 'No disponible'}',
                            style: TextStyle(color: Colors.black),
                          ),
                          subtitle: Text(
                            'Fecha: $fechaFormateada',
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                      );
                    },
                  )
                : Center(
                    child: Text(
                      'No hay logs disponibles.',
                      style: TextStyle(color: const Color.fromARGB(255, 230, 0, 0)),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
