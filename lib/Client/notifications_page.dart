import 'package:car_mobile/Client/PieceRecommandeePage.dart';
import 'package:flutter/material.dart';
import 'package:car_mobile/Client/notification_model.dart';
import 'package:car_mobile/Client/notification_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> with TickerProviderStateMixin {
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  bool _hasMoreData = true;
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _loadNotifications();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMoreData) {
        _loadMoreNotifications();
      }
    }
  }

  Future<void> _loadNotifications() async {
    try {
      setState(() => _isLoading = true);

      final response = await NotificationService.getClientNotifications(page: 1);
      final List<dynamic> notificationsData = response['notifications'] ?? [];

      setState(() {
        _notifications = notificationsData
            .map((json) => NotificationModel.fromJson(json))
            .toList();

        _hasMoreData = response['pagination']?['current_page'] <
            response['pagination']?['last_page'];
        _currentPage = 1;
      });

      _animationController.forward();
    } catch (e) {
      _showErrorSnackBar('Erreur: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMoreNotifications() async {
    if (_isLoadingMore || !_hasMoreData) return;

    try {
      setState(() => _isLoadingMore = true);

      final nextPage = _currentPage + 1;
      final response = await NotificationService.getClientNotifications(page: nextPage);
      final List<dynamic> notificationsData = response['notifications'] ?? [];

      setState(() {
        _notifications.addAll(
            notificationsData.map((json) => NotificationModel.fromJson(json))
        );
        _currentPage = nextPage;
        _hasMoreData = response['pagination']?['current_page'] <
            response['pagination']?['last_page'];
      });
    } catch (e) {
      _showErrorSnackBar('Erreur: ${e.toString()}');
    } finally {
      setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _markAsRead(NotificationModel notification) async {
    if (notification.isRead) return;

    final success = await NotificationService.markAsRead(notification.id);
    if (success) {
      setState(() {
        final index = _notifications.indexWhere((n) => n.id == notification.id);
        if (index != -1) {
          _notifications[index] = NotificationModel(
            id: notification.id,
            type: notification.type,
            message: notification.message,
            demandeId: notification.demandeId,
            pieces: notification.pieces,
            readAt: DateTime.now(),
            createdAt: notification.createdAt,
            formattedDate: notification.formattedDate,
          );
        }
      });
    }
  }

  Future<void> _markAllAsRead() async {
    final success = await NotificationService.markAllAsRead();
    if (success) {
      setState(() {
        _notifications = _notifications.map((n) => n.isRead
            ? n
            : NotificationModel(
          id: n.id,
          type: n.type,
          message: n.message,
          demandeId: n.demandeId,
          pieces: n.pieces,
          readAt: DateTime.now(),
          createdAt: n.createdAt,
          formattedDate: n.formattedDate,
        )).toList();
      });
      _showSuccessSnackBar('Toutes marquées comme lues');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey.shade800,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notifications',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            if (_unreadCount > 0)
              Text(
                '$_unreadCount non lue${_unreadCount > 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blue.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        actions: [
          if (_unreadCount > 0)
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                icon: const Icon(Icons.done_all, size: 20),
                label: const Text('Tout lire'),
                onPressed: _markAllAsRead,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue.shade600,
                  backgroundColor: Colors.blue.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _notifications.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
        onRefresh: _loadNotifications,
        color: Colors.blue.shade600,
        child: ListView.builder(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: _notifications.length + (_isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == _notifications.length) {
              return _buildLoadingMoreIndicator();
            }
            return AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: _animationController,
                    curve: Interval(
                      (index * 0.1).clamp(0.0, 1.0),
                      ((index + 1) * 0.1).clamp(0.0, 1.0),
                      curve: Curves.easeOutCubic,
                    ),
                  )),
                  child: FadeTransition(
                    opacity: _animationController,
                    child: _buildNotificationItem(_notifications[index], index),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
          ),
          const SizedBox(height: 16),
          Text(
            'Chargement des notifications...',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingMoreIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              size: 64,
              color: Colors.blue.shade300,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Aucune notification',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vous êtes à jour !',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(NotificationModel notification, int index) {
    final isUnread = !notification.isRead;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        elevation: isUnread ? 2 : 1,
        shadowColor: Colors.black.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            await _markAsRead(notification);

            if (notification.demandeId != null &&
                notification.type.contains('PieceRecommandee')) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PieceRecommandeePage(
                    demandeId: notification.demandeId!,
                  ),
                ),
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isUnread ? Colors.blue.shade50 : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: isUnread
                  ? Border.all(color: Colors.blue.shade100, width: 1)
                  : null,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildNotificationIcon(notification),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.getNotificationTitle(),
                              style: TextStyle(
                                fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                                fontSize: 16,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),
                          if (isUnread)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.blue.shade600,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        notification.message,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            notification.formattedDate,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade400,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(NotificationModel notification) {
    final IconData iconData = _getNotificationIcon(notification.type);
    final Color iconColor = _getNotificationColor(notification.type);
    final bool isUnread = !notification.isRead;

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: isUnread
            ? iconColor.withOpacity(0.15)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        iconData,
        color: isUnread ? iconColor : Colors.grey.shade400,
        size: 24,
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    if (type.contains('PieceRecommandee')) return Icons.build_circle_rounded;
    if (type.contains('Demande')) return Icons.assignment_turned_in_rounded;
    if (type.contains('Paiement')) return Icons.payment_rounded;
    return Icons.notifications_rounded;
  }

  Color _getNotificationColor(String type) {
    if (type.contains('PieceRecommandee')) return Colors.orange.shade600;
    if (type.contains('Demande')) return Colors.green.shade600;
    if (type.contains('Paiement')) return Colors.purple.shade600;
    return Colors.blue.shade600;
  }
}