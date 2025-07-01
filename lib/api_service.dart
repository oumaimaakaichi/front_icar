import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://192.168.1.11:8000/api';

  Future<List<dynamic>> getDemandesTechnicien(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/demandeInconnu/$userId'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return data['data'];
      } else {
        throw Exception(data['message']);
      }
    } else {
      throw Exception('Échec du chargement des demandes');
    }
  }

  Future<Map<String, dynamic>> getDemandeDetails(int userId, int demandeId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/technicien/demandes/$userId/$demandeId'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return data['data'];
      } else {
        throw Exception(data['message']);
      }
    } else {
      throw Exception('Échec du chargement des détails de la demande');
    }
  }
}