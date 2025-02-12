import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

/// Clase para almacenar la información de cada tag y su cantidad de logs.
class LogStat {
  final String tag;
  final int count;
  LogStat({required this.tag, required this.count});
}

class AutenticationPage extends StatefulWidget {
  final String token;
  const AutenticationPage({Key? key, required this.token}) : super(key: key);

  @override
  _AutenticationPageState createState() => _AutenticationPageState();
}

class _AutenticationPageState extends State<AutenticationPage>
    with SingleTickerProviderStateMixin {
  late String token;
  List<dynamic> _usuarios = [];
  List<dynamic> _logs = [];
  List<LogStat> _logStats = []; // Datos procesados para el gráfico de barras.
  String? _error;
  TabController? _tabController;
  int? _selectedUserId; // Para la pestaña de Cuotas

  // Variable para almacenar el tag seleccionado en el dropdown de Logs.
  String _selectedTag = 'Todos';

  @override
  void initState() {
    super.initState();
    token = widget.token;
    // Ahora tenemos 4 pestañas: Usuarios, Logs, Estadísticas y Cuotas.
    _tabController = TabController(length: 4, vsync: this);
    _tabController!.addListener(_tabChanged);
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

  /// Obtiene los logs desde la API (global, sin usuario específico).
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
            // Reiniciamos el tag seleccionado a "Todos" cada vez que se actualicen los logs.
            _selectedTag = 'Todos';
          });
          // Procesamos los logs para generar los datos del gráfico.
          _procesarDatosParaStats();
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

  /// Procesa los datos de _logs para obtener las estadísticas (cantidad de logs por tag).
  void _procesarDatosParaStats() {
    Map<String, int> logCountByTag = {};
    for (var log in _logs) {
      String tag = log['tag'] ?? 'Otros';
      if (!logCountByTag.containsKey(tag)) {
        logCountByTag[tag] = 0;
      }
      logCountByTag[tag] = logCountByTag[tag]! + 1;
    }
    List<LogStat> stats = logCountByTag.entries
        .map((entry) => LogStat(tag: entry.key, count: entry.value))
        .toList();
    // Ordenamos alfabéticamente los tags.
    stats.sort((a, b) => a.tag.compareTo(b.tag));
    setState(() {
      _logStats = stats;
    });
  }

  /// Actualiza el plan del usuario usando la ruta y método (POST) original.
  Future<void> _actualizarPlanUsuario(int usuarioId, String nuevoPlan) async {
    var usuario =
        _usuarios.firstWhere((u) => u['id'] == usuarioId, orElse: () => null);
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

  /// Cada vez que se cambia de pestaña, si se va a Logs o Estadísticas se actualizan los logs.
  void _tabChanged() {
    if (_tabController!.index == 1 || _tabController!.index == 2) {
      _obtenerLogsDesdeAPI();
    }
  }

  /// Función para formatear el timestamp recibido.
  String formatTimestamp(String timestamp) {
    try {
      DateTime dt = DateTime.parse(timestamp).toLocal();
      return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} "
          "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}";
    } catch (e) {
      return timestamp;
    }
  }

  /// Función para obtener la cuota de un usuario desde la API.
  /// Se envían como query parameters 'telefon', 'nickname' y 'email'.
  Future<dynamic> _obtenerCuotaPorUsuario(int usuarioId) async {
    final usuario =
        _usuarios.firstWhere((u) => u['id'] == usuarioId, orElse: () => null);
    if (usuario == null) throw Exception("Usuario no encontrado");
    final url = 'https://imagia3.ieti.site/api/admin/usuaris/quota';
    final uri = Uri.parse(url).replace(queryParameters: {
      'telefon': usuario['telefon']?.toString() ?? '',
      'nickname': usuario['nickname'] ?? '',
      'email': usuario['email'] ?? '',
    });
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'OK') {
        return data['data'];
      } else {
        throw Exception("Error: ${data['message']}");
      }
    } else {
      throw Exception("Error en la petición: ${response.statusCode}");
    }
  }

  /// Función para actualizar la cuota de un usuario.
  Future<void> _actualizarCuotaUsuario(
      int usuarioId, int limit, int disponible) async {
    final usuario =
        _usuarios.firstWhere((u) => u['id'] == usuarioId, orElse: () => null);
    if (usuario == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Usuario no encontrado'),
        backgroundColor: Colors.red,
      ));
      return;
    }
    final url = 'https://imagia3.ieti.site/api/admin/usuaris/quota/actualitzar';
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
          'limit': limit,
          'disponible': disponible,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK') {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Cuota actualizada con éxito'),
          ));
          // Forzar la actualización de la cuota consultando nuevamente.
          setState(() {});
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error al actualizar cuota: ${data['message']}'),
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
        content: Text('Error de conexión: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  /// Función que devuelve la lista de tags únicos extraídos de _logs.
  List<String> _getAllTags() {
    final Set<String> tags =
        _logs.map((log) => log['tag']?.toString() ?? 'No disponible').toSet();
    return tags.toList();
  }

  /// Función que devuelve los logs filtrados según el tag seleccionado.
  List<dynamic> _getFilteredLogs() {
    if (_selectedTag == 'Todos') {
      return _logs;
    } else {
      return _logs.where((log) => log['tag'] == _selectedTag).toList();
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
            Tab(
                child: Text('Estadísticas',
                    style: TextStyle(color: Colors.white))),
            Tab(
                child: Text('Cuotas',
                    style:
                        TextStyle(color: Colors.white))), // Pestaña de Cuotas
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Pestaña de Usuarios.
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _error != null
                ? Center(
                    child: Text(
                      _error!,
                      style: TextStyle(
                          color: Colors.red, fontWeight: FontWeight.bold),
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
                                        fontSize: 16.0),
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
                                  // Dropdown para cambiar el plan (Free o Premium).
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
                                        .map((String value) =>
                                            DropdownMenuItem<String>(
                                              value: value,
                                              child: Text(value),
                                            ))
                                        .toList(),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      )
                    : Center(child: Text('Cargando usuarios...')),
          ),
          // Pestaña de Logs.
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _logs.isNotEmpty
                ? Column(
                    children: [
                      // Dropdown para filtrar por tag.
                      DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedTag,
                        items: (() {
                          List<String> tags = _getAllTags();
                          tags.insert(0, 'Todos');
                          return tags
                              .map((tag) => DropdownMenuItem<String>(
                                    value: tag,
                                    child: Text(tag),
                                  ))
                              .toList();
                        }()),
                        onChanged: (String? newTag) {
                          setState(() {
                            _selectedTag = newTag!;
                          });
                        },
                      ),
                      SizedBox(height: 16),
                      // Lista de logs filtrados.
                      Expanded(
                        child: _getFilteredLogs().isNotEmpty
                            ? ListView.builder(
                                itemCount: _getFilteredLogs().length,
                                itemBuilder: (context, index) {
                                  var log = _getFilteredLogs()[index];
                                  String fechaFormateada =
                                      log['timestamp'] != null
                                          ? formatTimestamp(log['timestamp'])
                                          : 'No disponible';
                                  return Card(
                                    margin: EdgeInsets.symmetric(vertical: 8.0),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'ID: ${log['id'] ?? 'No disponible'}',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16.0),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            'Tag: ${log['tag'] ?? 'No disponible'}',
                                            style: TextStyle(fontSize: 16.0),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            'Mensaje: ${log['mensaje'] ?? 'No disponible'}',
                                            style: TextStyle(fontSize: 16.0),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            'Fecha: $fechaFormateada',
                                            style: TextStyle(fontSize: 16.0),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              )
                            : Center(
                                child: Text('No hay logs con este tag'),
                              ),
                      ),
                    ],
                  )
                : Center(
                    child: Text(
                      'No hay logs disponibles.',
                      style: TextStyle(
                          color: Color.fromARGB(255, 230, 0, 0),
                          fontWeight: FontWeight.bold),
                    ),
                  ),
          ),
          // Pestaña de Estadísticas (Gráfico de barras).
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _logStats.isNotEmpty
                ? CustomPaint(
                    size: Size(double.infinity, 300),
                    painter: StatsChartPainter(_logStats),
                  )
                : Center(child: Text('Cargando datos del gráfico...')),
          ),
          // Pestaña de Cuotas.
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _usuarios.isNotEmpty
                ? _buildCuotasTab()
                : Center(
                    child: Text('Cargando usuarios para consultar cuotas...')),
          ),
        ],
      ),
    );
  }
}

/// Widget para construir la pestaña de Cuotas.
Widget _buildCuotasTab() {
  return Builder(
    builder: (context) {
      final _AutenticationPageState state =
          context.findAncestorStateOfType<_AutenticationPageState>()!;
      return Column(
        children: [
          DropdownButton<int>(
            hint: Text("Selecciona un usuario"),
            value: state._selectedUserId,
            onChanged: (int? newId) {
              state.setState(() {
                state._selectedUserId = newId;
              });
            },
            items: state._usuarios.map((user) {
              return DropdownMenuItem<int>(
                value: user['id'],
                child:
                    Text(user['nickname'] ?? user['telefon'] ?? 'Sin nombre'),
              );
            }).toList(),
          ),
          SizedBox(height: 20),
          state._selectedUserId != null
              ? FutureBuilder(
                  future: state._obtenerCuotaPorUsuario(state._selectedUserId!),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(
                          child: Text(
                        "Error: ${snapshot.error}",
                        style: TextStyle(color: Colors.red),
                      ));
                    } else if (snapshot.hasData) {
                      final cuota = snapshot.data;
                      return Column(
                        children: [
                          Card(
                            margin: EdgeInsets.symmetric(vertical: 8.0),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Cuota Total: ${cuota['quota_total']}',
                                    style: TextStyle(
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Cuota Disponible: ${cuota['quota_disponible']}',
                                    style: TextStyle(fontSize: 16.0),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Botón para modificar la cuota
                          ElevatedButton(
                            onPressed: () {
                              state._mostrarDialogActualizarCuota(
                                  state._selectedUserId!);
                            },
                            child: Text("Modificar cuota"),
                          ),
                        ],
                      );
                    } else {
                      return Center(child: Text("No hay datos"));
                    }
                  },
                )
              : Center(child: Text("Selecciona un usuario para ver su cuota")),
        ],
      );
    },
  );
}

/// Función para mostrar un diálogo que permita actualizar la cuota del usuario.
extension on _AutenticationPageState {
  void _mostrarDialogActualizarCuota(int usuarioId) {
    final TextEditingController limitController = TextEditingController();
    final TextEditingController disponibleController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Actualizar cuota"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: limitController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: "Cuota Total"),
              ),
              TextField(
                controller: disponibleController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: "Cuota Disponible"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () async {
                int? limit = int.tryParse(limitController.text);
                int? disponible = int.tryParse(disponibleController.text);
                if (limit == null || disponible == null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content:
                        Text("Por favor, ingresa valores numéricos válidos"),
                    backgroundColor: Colors.red,
                  ));
                  return;
                }
                await _actualizarCuotaUsuario(usuarioId, limit, disponible);
                Navigator.of(context).pop();
                // Opcional: Volver a recargar la cuota para actualizar la vista.
                setState(() {});
              },
              child: Text("Actualizar"),
            ),
          ],
        );
      },
    );
  }
}

/// Función para actualizar la cuota de un usuario.
Future<void> _actualizarCuotaUsuario(
    int usuarioId, int limit, int disponible) async {
  final _AutenticationPageState state =
      (await WidgetsBinding.instance!.renderViewElement)!
          .findAncestorStateOfType<_AutenticationPageState>()!;
  final usuario = state._usuarios
      .firstWhere((u) => u['id'] == usuarioId, orElse: () => null);
  if (usuario == null) {
    ScaffoldMessenger.of(state.context).showSnackBar(SnackBar(
      content: Text('Usuario no encontrado'),
      backgroundColor: Colors.red,
    ));
    return;
  }
  final url = 'https://imagia3.ieti.site/api/admin/usuaris/quota/actualitzar';
  final uri = Uri.parse(url);
  try {
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${state.token}',
      },
      body: jsonEncode({
        'telefon': usuario['telefon'],
        'nickname': usuario['nickname'],
        'email': usuario['email'],
        'limit': limit,
        'disponible': disponible,
      }),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'OK') {
        ScaffoldMessenger.of(state.context).showSnackBar(SnackBar(
          content: Text('Cuota actualizada con éxito'),
        ));
        state.setState(() {}); // Actualiza la vista
      } else {
        ScaffoldMessenger.of(state.context).showSnackBar(SnackBar(
          content: Text('Error al actualizar cuota: ${data['message']}'),
          backgroundColor: Colors.red,
        ));
      }
    } else {
      ScaffoldMessenger.of(state.context).showSnackBar(SnackBar(
        content: Text('Error al comunicarse con el servidor'),
        backgroundColor: Colors.red,
      ));
    }
  } catch (e) {
    ScaffoldMessenger.of(state.context).showSnackBar(SnackBar(
      content: Text('Error de conexión: $e'),
      backgroundColor: Colors.red,
    ));
  }
}

/// CustomPainter para dibujar el gráfico de barras de las estadísticas.
class StatsChartPainter extends CustomPainter {
  final List<LogStat> stats;
  StatsChartPainter(this.stats);

  @override
  void paint(Canvas canvas, Size size) {
    if (stats.isEmpty) return;
    final Paint barPaint = Paint()..style = PaintingStyle.fill;
    // Colores de las barras por tag.
    List<Color> colors = [
      Colors.blue,
      Colors.green,
      Colors.red,
      Colors.orange,
      Colors.purple
    ];
    // Se reserva parte inferior para los nombres de los tags.
    final double bottomMargin = size.height * 0.3;
    final double chartHeight = size.height - bottomMargin;
    final double barWidth = size.width / (stats.length * 2);
    final double maxCount =
        stats.map((s) => s.count).reduce((a, b) => max(a, b)).toDouble();
    final textPainter = TextPainter(
        textAlign: TextAlign.center, textDirection: TextDirection.ltr);
    for (int i = 0; i < stats.length; i++) {
      final stat = stats[i];
      final double left = i * 2 * barWidth + barWidth / 2;
      final double right = left + barWidth;
      final double barHeight = (stat.count / maxCount) * chartHeight;
      final double top = chartHeight - barHeight;
      final Rect barRect = Rect.fromLTRB(left, top, right, chartHeight);
      barPaint.color = colors[i % colors.length];
      canvas.drawRect(barRect, barPaint);
      final countTextSpan = TextSpan(
          text: stat.count.toString(),
          style: TextStyle(color: Colors.black, fontSize: 12));
      textPainter.text = countTextSpan;
      textPainter.layout(minWidth: 0, maxWidth: barWidth);
      final double countX = left + (barWidth - textPainter.width) / 2;
      final double countY = top - textPainter.height - 2;
      textPainter.paint(canvas, Offset(countX, countY));
      final tagTextSpan = TextSpan(
          text: stat.tag, style: TextStyle(color: Colors.black, fontSize: 10));
      textPainter.text = tagTextSpan;
      textPainter.layout(minWidth: 0, maxWidth: barWidth);
      final double tagX = left + (barWidth - textPainter.width) / 2;
      final double tagY = size.height - textPainter.height;
      textPainter.paint(canvas, Offset(tagX, tagY));
    }
  }

  @override
  bool shouldRepaint(covariant StatsChartPainter oldDelegate) {
    return false;
  }
}
