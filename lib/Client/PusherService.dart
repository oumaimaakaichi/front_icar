import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:pusher_client/pusher_client.dart';

class PusherService {
  late PusherClient pusher;

  Future<void> initPusher(String userId) async {
    pusher = PusherClient(
      "578a7ae3cd4fb422dc77",
      PusherOptions(
        cluster: "mt1",
        encrypted: true,
      ),
      enableLogging: true,
    );

    await pusher.connect();

    // S'abonner au canal privé de l'utilisateur
    Channel channel = pusher.subscribe('private-user.$userId');

    // Écouter les événements de notification
    channel.bind('App\\Notifications\\PieceRecommandeeNotification', (event) {
      if (event != null) {
        // Traiter la notification
        final data = json.decode(event.data!);
        _showNotification(data);
      }
    });
  }

  void _showNotification(Map<String, dynamic> data) {
    // Afficher la notification locale
    FlutterLocalNotificationsPlugin().show(
      0,
      'Nouvelles pièces recommandées',
      'Des pièces ont été recommandées pour votre demande #${data['demande_id']}',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'channel_id',
          'channel_name',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }

  void dispose() {
    pusher.disconnect();
  }
}