import 'package:flutter/material.dart';

class NotificationModelT {
  final int id;
  final int technicienId;
  final int demandeId;
  final String titre;
  final String message;
  final String type;
  final bool lu;
  final DateTime? luAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String tempsEcoule;
  final bool estRecente;
  final Map<String, dynamic>? demande;

  NotificationModelT({
    required this.id,
    required this.technicienId,
    required this.demandeId,
    required this.titre,
    required this.message,
    required this.type,
    required this.lu,
    this.luAt,
    required this.createdAt,
    required this.updatedAt,
    required this.tempsEcoule,
    required this.estRecente,
    this.demande,
  });

  factory NotificationModelT.fromJson(Map<String, dynamic> json) {
    return NotificationModelT(
      id: json['id'] as int? ?? 0,
      technicienId: json['technicien_id'] as int? ?? 0,
      demandeId: json['demande_id'] as int? ?? 0,
      titre: json['titre'] as String? ?? 'Sans titre',
      message: json['message'] as String? ?? '',
      type: json['type'] as String? ?? 'information',
      lu: json['lu'] as bool? ?? false,
      luAt: json['lu_at'] != null ? DateTime.tryParse(json['lu_at'] as String) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      tempsEcoule: json['temps_ecoule'] as String? ?? '',
      estRecente: json['est_recente'] as bool? ?? false,
      demande: json['demande'] != null
          ? Map<String, dynamic>.from(json['demande'] as Map)
          : null,
    );
  }

  IconData getTypeIcon() {
    switch (type) {
      case 'assignation':
        return Icons.assignment_turned_in;
      case 'modification':
        return Icons.edit_note;
      case 'annulation':
        return Icons.cancel_outlined;
      case 'urgence':
        return Icons.warning_amber;
      default:
        return Icons.notifications_none;
    }
  }

  Color getTypeColor() {
    switch (type) {
      case 'assignation':
        return Colors.green.shade700;
      case 'modification':
        return Colors.orange.shade700;
      case 'annulation':
        return Colors.red.shade700;
      case 'urgence':
        return Colors.deepOrange;
      default:
        return Colors.blue.shade700;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'technicien_id': technicienId,
      'demande_id': demandeId,
      'titre': titre,
      'message': message,
      'type': type,
      'lu': lu,
      'lu_at': luAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'temps_ecoule': tempsEcoule,
      'est_recente': estRecente,
      'demande': demande,
    };
  }
}