import 'package:flutter/material.dart';
import 'package:car_mobile/NotificationModel.dart';
import 'package:car_mobile/NotificationService.dart';

class NotificationsPageT extends StatefulWidget {
  final int technicienId;

  const NotificationsPageT({
    Key? key,
    required this.technicienId,
  }) : super(key: key);

  @override
  State<NotificationsPageT> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPageT>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<NotificationModelT> _allNotifications = [];
  List<NotificationModelT> _unreadNotifications = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadNotifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await NotificationServiceT.getNotifications(widget.technicienId);
      debugPrint('API Response: $response');

      if (!mounted) return;

      if (response['success'] == true) {
        final data = response['data'] as Map<String, dynamic>;
        final notificationsData = data['data'] as List;

        final notifications = notificationsData.map((item) {
          try {
            return NotificationModelT.fromJson(item as Map<String, dynamic>);
          } catch (e) {
            debugPrint('Error parsing notification: $e\nItem: $item');
            return null;
          }
        }).whereType<NotificationModelT>().toList();

        if (mounted) {
          setState(() {
            _allNotifications = notifications;
            _unreadNotifications = notifications.where((n) => !n.lu).toList();
            _isLoading = false;
          });
        }
      } else {
        throw Exception('API returned success: false');
      }
    } catch (e) {
      debugPrint('Error loading notifications: $e');
      if (mounted) {
        setState(() {
          _error = 'Erreur de chargement: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markAsRead(NotificationModelT notification) async {
    if (notification.lu) return;

    try {
      final success = await NotificationServiceT.markAsRead(notification.id);
      if (success && mounted) {
        setState(() {

          _unreadNotifications.removeWhere((n) => n.id == notification.id);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final success = await NotificationServiceT.markAllAsRead(widget.technicienId);
      if (success && mounted) {
        setState(() {
          for (var notif in _unreadNotifications) {

          }
          _unreadNotifications.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Toutes les notifications ont été marquées comme lues'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title:Text(
          'Notifications',
          style: TextStyle(color: Colors.white),
        ),


        backgroundColor: Colors.blueGrey,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_unreadNotifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.done_all),
              onPressed: _markAllAsRead,
              tooltip: 'Marquer tout comme lu',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNotifications,
            tooltip: 'Actualiser',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: 'Non lues (${_unreadNotifications.length})'),
            Tab(text: 'Toutes (${_allNotifications.length})'),
          ],
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Chargement des notifications...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return _buildErrorWidget();
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildNotificationsList(_unreadNotifications, true),
        _buildNotificationsList(_allNotifications, false),
      ],
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Erreur de chargement',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadNotifications,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(List<NotificationModelT> notifications, bool isUnreadTab) {
    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isUnreadTab ? Icons.notifications_off : Icons.inbox,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              isUnreadTab ? 'Aucune notification non lue' : 'Aucune notification',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _buildNotificationItem(notifications[index]),
      ),
    );
  }

  Widget _buildNotificationItem(NotificationModelT notification) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _markAsRead(notification),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildNotificationIcon(notification),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      notification.titre,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey[800],
                      ),
                    ),
                  ),
                  if (!notification.lu)
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                notification.message,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              if (notification.demande != null)
                Text(
                  'Demande #${notification.demandeId} - ${notification.demande?['status'] ?? ''}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.blueGrey[600],
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    notification.tempsEcoule,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  if (notification.estRecente)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Nouveau',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.green[700],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(NotificationModelT notification) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: notification.getTypeColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        notification.getTypeIcon(),
        color: notification.getTypeColor(),
        size: 24,
      ),
    );
  }
}