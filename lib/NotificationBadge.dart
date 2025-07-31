import 'package:car_mobile/NotificationService.dart';
import 'package:flutter/material.dart';
import 'package:car_mobile/Client/notification_service.dart';

class NotificationBadge extends StatefulWidget {
  final int technicienId;
  final VoidCallback onTap;
  final Color? badgeColor;
  final Color? textColor;

  const NotificationBadge({
    Key? key,
    required this.technicienId,
    required this.onTap,
    this.badgeColor,
    this.textColor,
  }) : super(key: key);

  @override
  State<NotificationBadge> createState() => _NotificationBadgeState();
}

class _NotificationBadgeState extends State<NotificationBadge> {
  int _unreadCount = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    if (_isLoading || !mounted) return;

    setState(() => _isLoading = true);

    try {
      final count = await NotificationServiceT.getUnreadCount(widget.technicienId);
      if (mounted) {
        setState(() {
          _unreadCount = count;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_none),
          onPressed: () {
            widget.onTap();
            // Rafraîchir après un délai pour permettre à la page de s'ouvrir
            Future.delayed(const Duration(milliseconds: 300), _loadUnreadCount);
          },
        ),
        if (_unreadCount > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: widget.badgeColor ?? Colors.red,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 1.5,
                ),
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                _unreadCount > 99 ? '99+' : _unreadCount.toString(),
                style: TextStyle(
                  color: widget.textColor ?? Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        if (_isLoading)
          Positioned(
            right: 6,
            top: 6,
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: widget.badgeColor ?? Colors.red,
              ),
            ),
          ),
      ],
    );
  }
}