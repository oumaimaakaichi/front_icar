// lib/models/notification_model.dart
import 'dart:convert';

class NotificationModel {
  final String id;
  final String type;
  final String message;
  final int? demandeId;
  final List<dynamic>? pieces;
  final DateTime? readAt;
  final DateTime createdAt;
  final String formattedDate;

  NotificationModel({
    required this.id,
    required this.type,
    required this.message,
    this.demandeId,
    this.pieces,
    this.readAt,
    required this.createdAt,
    required this.formattedDate,
  });

  bool get isRead => readAt != null;

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    // Si c'est depuis l'API Laravel avec la structure de notification
    if (json.containsKey('data')) {
      final data = json['data'] is String
          ? Map<String, dynamic>.from(jsonDecode(json['data']))
          : Map<String, dynamic>.from(json['data']);

      return NotificationModel(
        id: json['id'].toString(),
        type: json['type'] ?? '',
        message: data['message'] ?? '',
        demandeId: data['demande_id'] != null
            ? int.tryParse(data['demande_id'].toString())
            : null,
        pieces: data['pieces'],
        readAt: json['read_at'] != null
            ? DateTime.parse(json['read_at'])
            : null,
        createdAt: DateTime.parse(json['created_at']),
        formattedDate: _formatDate(DateTime.parse(json['created_at'])),
      );
    } else {
      // Structure simplifiée
      return NotificationModel(
        id: json['id'].toString(),
        type: json['type'] ?? '',
        message: json['message'] ?? '',
        demandeId: json['demande_id'] != null
            ? int.tryParse(json['demande_id'].toString())
            : null,
        pieces: json['pieces'],
        readAt: json['read_at'] != null
            ? DateTime.parse(json['read_at'])
            : null,
        createdAt: DateTime.parse(json['created_at']),
        formattedDate: json['formatted_date'] ??
            _formatDate(DateTime.parse(json['created_at'])),
      );
    }
  }


  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'message': message,
      'demande_id': demandeId,
      'pieces': pieces,
      'read_at': readAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'formatted_date': formattedDate,
    };
  }

  static String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays > 0) {
      return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'Il y a ${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'Il y a ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'À l\'instant';
    }
  }

  String getNotificationIcon() {
    if (type.contains('PieceRecommandee')) {
      return '🔧';
    } else if (type.contains('Demande')) {
      return '📋';
    } else if (type.contains('Paiement')) {
      return '💳';
    } else {
      return '🔔';
    }
  }

  String getNotificationTitle() {
    if (type.contains('PieceRecommandee')) {
      return 'Pièces recommandées';
    } else if (type.contains('Demande')) {
      return 'Nouvelle demande';
    } else if (type.contains('Paiement')) {
      return 'Paiement';
    } else {
      return 'Notification';
    }
  }
}