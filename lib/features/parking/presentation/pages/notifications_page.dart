import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/services/realtime_notification_service.dart';

/// Simple in-memory notification model for display purposes.
class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final NotificationType type;
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    this.isRead = false,
  });

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        title: title,
        message: message,
        timestamp: timestamp,
        type: type,
        isRead: isRead ?? this.isRead,
      );
}

enum NotificationType { booking, payment, reminder, system }

/// State notifier managing the notification list.
class NotificationsNotifier extends StateNotifier<List<AppNotification>> {
  StreamSubscription? _subscription;

  NotificationsNotifier() : super([]) {
    _subscription = RealtimeNotificationService().notificationStream.listen((data) {
      final title = data['title'] ?? '';
      final message = data['message'] ?? '';
      
      // Determine type based on keywords
      NotificationType type = NotificationType.system;
      final lowerTitle = title.toLowerCase();
      if (lowerTitle.contains('đặt chỗ') || lowerTitle.contains('booking')) {
        type = NotificationType.booking;
      } else if (lowerTitle.contains('thanh toán') || lowerTitle.contains('payment')) {
        type = NotificationType.payment;
      } else if (lowerTitle.contains('nhắc nhở') || lowerTitle.contains('sắp hết')) {
        type = NotificationType.reminder;
      }

      addNotification(AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        message: message,
        timestamp: DateTime.now(),
        type: type,
      ));
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void markAsRead(String id) {
    state = [
      for (final n in state)
        if (n.id == id) n.copyWith(isRead: true) else n,
    ];
  }

  void markAllAsRead() {
    state = [for (final n in state) n.copyWith(isRead: true)];
  }

  void removeNotification(String id) {
    state = state.where((n) => n.id != id).toList();
  }

  int get unreadCount => state.where((n) => !n.isRead).length;

  /// Add a notification to the top of the list.
  void addNotification(AppNotification notification) {
    state = [notification, ...state];
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, List<AppNotification>>((ref) {
  return NotificationsNotifier();
});

// -------------- UI --------------

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    final notifier = ref.read(notificationsProvider.notifier);
    final unread = notifier.unreadCount;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context, unread, notifier),
            // Content
            Expanded(
              child: notifications.isEmpty
                  ? _buildEmptyState()
                  : _buildNotificationList(notifications, notifier),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, int unreadCount, NotificationsNotifier notifier) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Thông báo', style: AppTextStyles.heading2),
                const SizedBox(height: 4),
                Text(
                  unreadCount > 0
                      ? 'Bạn có $unreadCount thông báo chưa đọc'
                      : 'Tất cả đã được đọc',
                  style: AppTextStyles.body2,
                ),
              ],
            ),
          ),
          if (unreadCount > 0)
            Material(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => notifier.markAllAsRead(),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(
                    'Đọc tất cả',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
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
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_off_outlined,
              size: 56,
              color: AppColors.textHint.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 20),
          Text('Chưa có thông báo',
              style: AppTextStyles.subtitle1
                  .copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Text(
            'Các thông báo mới sẽ xuất hiện tại đây',
            style: AppTextStyles.body2,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList(
      List<AppNotification> notifications, NotificationsNotifier notifier) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return _buildNotificationCard(context, notification, notifier);
      },
    );
  }

  Widget _buildNotificationCard(BuildContext context,
      AppNotification notification, NotificationsNotifier notifier) {
    final meta = _typeMeta(notification.type);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: AppColors.danger, size: 24),
      ),
      onDismissed: (_) => notifier.removeNotification(notification.id),
      child: GestureDetector(
        onTap: () {
          if (!notification.isRead) {
            notifier.markAsRead(notification.id);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: notification.isRead
                ? Colors.white
                : AppColors.primary.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: notification.isRead
                  ? AppColors.borderLight
                  : AppColors.primary.withValues(alpha: 0.15),
              width: 1,
            ),
            boxShadow: [
              if (!notification.isRead)
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: meta.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(meta.icon, color: meta.color, size: 20),
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
                            style: AppTextStyles.subtitle2.copyWith(
                              fontWeight: notification.isRead
                                  ? FontWeight.w500
                                  : FontWeight.w700,
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
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: AppTextStyles.body2.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _timeAgo(notification.timestamp),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textHint,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _TypeMeta _typeMeta(NotificationType type) {
    switch (type) {
      case NotificationType.booking:
        return const _TypeMeta(
            icon: Icons.calendar_today_rounded, color: AppColors.primary);
      case NotificationType.payment:
        return const _TypeMeta(
            icon: Icons.payment_rounded, color: AppColors.success);
      case NotificationType.reminder:
        return const _TypeMeta(
            icon: Icons.access_time_rounded, color: AppColors.warning);
      case NotificationType.system:
        return const _TypeMeta(
            icon: Icons.info_outline_rounded, color: AppColors.info);
    }
  }

  String _timeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}

class _TypeMeta {
  final IconData icon;
  final Color color;
  const _TypeMeta({required this.icon, required this.color});
}
