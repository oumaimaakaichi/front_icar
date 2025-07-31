import 'package:car_mobile/NotificationModel.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NotificationServiceT {
  static Future<Map<String, dynamic>> getNotifications(int technicienId) async {
    final response = await http.get(
      Uri.parse('http://localhost:8000/api/notificationsT/technicien/$technicienId'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load notifications - ${response.statusCode}');
    }
  }

  static Future<bool> markAsRead(int notificationId) async {
    final response = await http.post(
      Uri.parse('http://localhost:8000/api/notificationsT/$notificationId/mark-as-read'),
    );
    return response.statusCode == 200;
  }

  static Future<bool> markAllAsRead(int technicienId) async {
    final response = await http.post(
      Uri.parse('http://localhost:8000/api/notificationsT/technicien/$technicienId/mark-all-read'),
    );
    return response.statusCode == 200;
  }

  static Future<List<NotificationModelT>> getUnreadNotifications(int technicienId) async {
    final response = await http.get(
      Uri.parse('http://localhost:8000/api/notificationsT/technicien/$technicienId/unread'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      final notifications = data['data'] as List;
      return notifications.map((json) => NotificationModelT.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load unread notifications');
    }
  }
}