import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/organization.dart';
import '../models/task.dart';
import '../utils/constants.dart';

class OrganizationService {
  // Aqui geteamos las organizaciones del backend
  Future<List<Organization>> getOrganizations() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/organizaciones'),
      );

      if (response.statusCode == 200) {
        List<dynamic> body = json.decode(response.body);
        return body.map((json) => Organization.fromJson(json)).toList();
      } else {
        throw Exception(
          'Error al conectar con el backend: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception(
        'No se pudo conectar al backend. ¿Está corriendo en el puerto 1337? Error: $e',
      );
    }
  }

  Future<List<Task>> fetchTasksByOrganization(String organizacionId) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${AppConstants.baseUrl}/organizaciones/$organizacionId/tareas',
        ),
      );

      if (response.statusCode == 200) {
        final dynamic decodedBody = json.decode(response.body);

        if (decodedBody is List<dynamic>) {
          return decodedBody
              .map(
                (dynamic jsonItem) =>
                    Task.fromJson(jsonItem as Map<String, dynamic>),
              )
              .toList();
        }

        if (decodedBody is Map<String, dynamic> &&
            decodedBody['tareas'] is List<dynamic>) {
          final List<dynamic> tareas = decodedBody['tareas'] as List<dynamic>;
          return tareas
              .map(
                (dynamic jsonItem) =>
                    Task.fromJson(jsonItem as Map<String, dynamic>),
              )
              .toList();
        }

        throw Exception('Formato de respuesta de tareas no válido');
      }

      throw Exception('Error al obtener tareas: ${response.statusCode}');
    } catch (e) {
      throw Exception(
        'No se pudieron cargar las tareas de la organización. Error: $e',
      );
    }
  }

  Future<void> createTaskByOrganization({
    required String organizacionId,
    required String titulo,
    required DateTime fechaInicio,
    required DateTime fechaFin,
    required List<String> usuarios,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(
          '${AppConstants.baseUrl}/organizaciones/$organizacionId/tareas',
        ),
        headers: <String, String>{'Content-Type': 'application/json'},
        body: json.encode(<String, dynamic>{
          'titulo': titulo,
          'fechaInicio': fechaInicio.toUtc().toIso8601String(),
          'fechaFin': fechaFin.toUtc().toIso8601String(),
          'usuarios': usuarios,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      }

      throw Exception(
        'Error al crear tarea: ${response.statusCode} - ${response.body}',
      );
    } catch (e) {
      throw Exception('No se pudo crear la tarea. Error: $e');
    }
  }

  Future<Task> updateTask(String taskId, String? status, Task task) async {
    try {
      final response = await http.put(
        Uri.parse('${AppConstants.baseUrl}/organizaciones/task/$taskId'),
        headers: <String, String>{'Content-Type': 'application/json'},
        body: json.encode(<String, dynamic>{
          'titulo': task.titulo,
          'fechaInicio': task.fechaInicio.toUtc().toIso8601String(),
          'fechaFin': task.fechaFin.toUtc().toIso8601String(),
          'usuarios': task.usuarios.map((u) => u.id).toList(),
          'status': status ?? task.status,
        }),
      );

      if (response.statusCode == 200) {
        final dynamic decodedBody = json.decode(response.body);

        if (decodedBody != null) {
          return Task.fromJson(decodedBody as Map<String, dynamic>);
        }

        throw Exception('Task response format not valid');
      } else if (response.statusCode == 404) {
        throw Exception('Task not found: $taskId');
      }

      throw Exception('Task not updated');
    } catch (error) {
      throw Exception(error.toString());
    }
  }
}
