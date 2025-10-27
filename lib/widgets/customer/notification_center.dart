import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/app_colors.dart';
import '../../models/notification_model.dart';
import '../../services/notification_service.dart';
import '../../screens/customer/track_order_screen.dart';
import '../../screens/customer/order_details_screen.dart';

/// Notification Center Screen
class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (notificationService.unreadCount > 0)
            TextButton(
              onPressed: () {
                setState(() {
                  notificationService.markAllAsRead();
                });
              },
              child: const Text(
                'Mark all read',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: () {
              _showClearConfirmation();
            },
          ),
        ],
      ),
      body: StreamBuilder<NotificationModel>(
        stream: notificationService.notificationStream,
        builder: (context, snapshot) {
          final notifications = notificationService.notificationHistory;

          if (notifications.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _buildNotificationCard(notification);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.grey100,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_none,
              size: 60,
              color: AppColors.grey400,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'We\'ll notify you when something arrives',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.error,
        child: const Icon(
          Icons.delete,
          color: AppColors.white,
        ),
      ),
      onDismissed: (direction) {
        setState(() {
          notificationService.notificationHistory.remove(notification);
        });
      },
      child: InkWell(
        onTap: () {
          _handleNotificationTap(notification);
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: notification.isRead ? AppColors.white : AppColors.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: notification.isRead ? AppColors.grey200 : AppColors.primary.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getNotificationColor(notification.type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: _getNotificationIcon(notification.type),
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notification.body,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatTimestamp(notification.timestamp),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Arrow
              Icon(
                Icons.chevron_right,
                color: AppColors.grey400,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getNotificationIcon(NotificationType type) {
    IconData iconData;
    Color color;

    switch (type) {
      case NotificationType.orderConfirmed:
        iconData = Icons.check_circle_outline;
        color = AppColors.success;
        break;
      case NotificationType.driverAssigned:
        iconData = Icons.local_shipping_outlined;
        color = AppColors.primary;
        break;
      case NotificationType.orderPickedUp:
        iconData = Icons.inventory_outlined;
        color = AppColors.warning;
        break;
      case NotificationType.driverNearby:
        iconData = Icons.location_on_outlined;
        color = AppColors.accent;
        break;
      case NotificationType.orderDelivered:
        iconData = Icons.celebration_outlined;
        color = AppColors.success;
        break;
      case NotificationType.orderCancelled:
        iconData = Icons.cancel_outlined;
        color = AppColors.error;
        break;
      case NotificationType.promotional:
        iconData = Icons.local_offer_outlined;
        color = AppColors.accent;
        break;
      default:
        iconData = Icons.notifications_outlined;
        color = AppColors.textSecondary;
    }

    return Icon(iconData, color: color, size: 24);
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.orderConfirmed:
      case NotificationType.orderDelivered:
        return AppColors.success;
      case NotificationType.driverAssigned:
      case NotificationType.orderPickedUp:
        return AppColors.primary;
      case NotificationType.driverNearby:
        return AppColors.accent;
      case NotificationType.orderCancelled:
        return AppColors.error;
      case NotificationType.promotional:
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM dd, yyyy').format(timestamp);
    }
  }

  void _handleNotificationTap(NotificationModel notification) {
    // Mark as read
    if (!notification.isRead) {
      setState(() {
        notificationService.markAsRead(notification.id);
      });
    }

    // Navigate based on notification type
    if (notification.trackingNumber != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TrackOrderScreen(
            trackingNumber: notification.trackingNumber!,
          ),
        ),
      );
    }
  }

  void _showClearConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear all notifications?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                notificationService.clearAll();
              });
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}
