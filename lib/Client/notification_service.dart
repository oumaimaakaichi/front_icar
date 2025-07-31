import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class NotificationService {
  static const String baseUrl = 'http://localhost:8000/api';
  static const _storage = FlutterSecureStorage();

  // Récupérer les infos d'authentification (user ID + token)
  static Future<Map<String, dynamic>> _getAuthData() async {
    final userDataJson = await _storage.read(key: 'user_data');
    final token = await _storage.read(key: 'auth_token');

    if (userDataJson == null || token == null) {
      throw Exception('Utilisateur non connecté');
    }

    final userData = jsonDecode(userDataJson);
    return {
      'userId': userData['id'],
      'token': token,
    };
  }

  // Construire les headers HTTP
  static Future<Map<String, String>> _getHeaders() async {
    final authData = await _getAuthData();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer ${authData['token']}',
    };
  }

  // 🔔 Récupérer les notifications du client connecté
  static Future<Map<String, dynamic>> getClientNotifications({int page = 1}) async {
    try {
      final authData = await _getAuthData();
      final headers = await _getHeaders();

      final response = await http.get(
        Uri.parse('$baseUrl/notificationsPrix/demandes-client/${authData['userId']}?page=$page'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur lors de la récupération des notifications: $e');
    }
  }

  // 🔴 Nombre de notifications non lues
  static Future<int> getUnreadCount() async {
    try {
      final authData = await _getAuthData();
      final headers = await _getHeaders();

      final response = await http.get(
        Uri.parse('$baseUrl/notificationsPrix/unread-count/${authData['userId']}'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['count'] ?? 0;
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      return 0;
    }
  }

  // ✅ Marquer une notification comme lue
// ✅ Marquer une notification comme lue
  static Future<bool> markAsRead(String notificationId) async {
    try {
      final authData = await _getAuthData(); // 🔺 Récupère userId ici
      final headers = await _getHeaders();

      final response = await http.patch(
        Uri.parse('$baseUrl/notificationsPrix/${authData['userId']}/read'), // 🔄 Ajout de l'id
        headers: headers,
        body: jsonEncode({
          'notification_id': notificationId, // On peut passer l'id dans le body si besoin
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

// ✅ Marquer toutes les notifications comme lues
  static Future<bool> markAllAsRead() async {
    try {
      final authData = await _getAuthData();
      final headers = await _getHeaders();

      final response = await http.patch(
        Uri.parse('$baseUrl/notificationsPrix/read-all/${authData['userId']}'), // 🔄 Correction URL
        headers: headers,
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // 💾 Sauvegarder le count local
  static Future<void> saveNotificationCount(int count) async {
    await _storage.write(key: 'notification_count', value: count.toString());
  }

  // 📦 Lire le count local
  static Future<int> getLocalNotificationCount() async {
    final count = await _storage.read(key: 'notification_count');
    return int.tryParse(count ?? '0') ?? 0;
  }
}
