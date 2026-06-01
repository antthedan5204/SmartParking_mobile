import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/booking.dart';
import '../../domain/entities/payment.dart';
import '../../domain/repositories/parking_repository.dart';
import 'parking_provider.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/realtime_notification_service.dart';
import '../../../../core/localization/app_localizations.dart';
import '../pages/notifications_page.dart';
import 'dart:async';
import '../../../auth/presentation/providers/auth_provider.dart';

class BookingState {
  final bool isLoading;
  final String? errorMessage;
  final Booking? lastBooking;
  final Payment? lastPayment;
  final List<Booking> userBookings;

  const BookingState({
    this.isLoading = false,
    this.errorMessage,
    this.lastBooking,
    this.lastPayment,
    this.userBookings = const [],
  });

  BookingState copyWith({
    bool? isLoading,
    String? errorMessage,
    Booking? lastBooking,
    Payment? lastPayment,
    List<Booking>? userBookings,
  }) {
    return BookingState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      lastBooking: lastBooking ?? this.lastBooking,
      lastPayment: lastPayment ?? this.lastPayment,
      userBookings: userBookings ?? this.userBookings,
    );
  }
}

class BookingNotifier extends StateNotifier<BookingState> {
  final ParkingRepository repository;
  final Ref ref;
  StreamSubscription? _notificationSub;
  final Set<String> _shownNotifications = {};



  BookingNotifier(this.repository, this.ref) : super(const BookingState()) {
    // Listen for real-time updates to sync booking state
    _notificationSub = RealtimeNotificationService().notificationStream.listen((data) {
      // Refresh bookings whenever a real-time notification arrives
      loadUserBookings();
      // Also invalidate slots so map/list reflect new status
      ref.invalidate(parkingSlotsProvider);
      ref.read(parkingLotsProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _notificationSub?.cancel();
    super.dispose();
  }

  void clear() {
    _shownNotifications.clear();
    state = const BookingState();
  }



  String _t(String vi, String en) {
    final langCode = ref.read(localeProvider).languageCode;
    return langCode == 'en' ? en : vi;
  }

  Future<void> loadUserBookings() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await repository.getUserBookings();
    await result.fold(
      (failure) async =>
          state = state.copyWith(isLoading: false, errorMessage: failure.message),
      (bookings) async {
        state = state.copyWith(isLoading: false, userBookings: bookings);
        await _syncUpcomingReminders(bookings);
      },
    );
  }

  Future<Map<String, dynamic>?> processBookingAndPayment({
    required int lotId,
    required int slotId,
    required int vehicleId,
    required double amount,
    required DateTime startTime,
    required DateTime endTime,
    required PaymentMethod method,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null, lastBooking: null, lastPayment: null);

    // 1. Create Booking
    final bookingResult = await repository.createBooking(
      slotId: slotId,
      vehicleId: vehicleId,
      startTime: startTime,
      endTime: endTime,
    );

    return await bookingResult.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return null;
      },
      (booking) async {
        // 2. Create Payment
        final paymentResult = await repository.createPayment(
          bookingId: booking.id,
          amount: amount,
          paymentMethod: method.index,
          transactionId: 'VIRTUAL_${DateTime.now().millisecondsSinceEpoch}',
        );

        return paymentResult.fold(
          (failure) async {
            state = state.copyWith(isLoading: false, errorMessage: failure.message);
            return null;
          },
          (payment) async {
            state = state.copyWith(
              isLoading: false,
              lastBooking: booking,
              lastPayment: payment,
            );

            // Refresh cached slot/lots state so UI reflects current occupancy.
            ref.invalidate(parkingSlotsProvider);
            ref.read(parkingLotsProvider.notifier).refresh();
            
            // 3. Schedule Notifications
            await _scheduleRemindersForBooking(booking);

            return {'booking': booking, 'payment': payment};
          },
        );
      },
    );
  }

  Future<bool> cancelBooking(int id) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await repository.cancelBooking(id);
    
    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
      (_) {
        state = state.copyWith(isLoading: false);
        // Cancel all scheduled notifications for this booking in parallel.
        Future.wait([
          NotificationService().cancelNotification(id),
          NotificationService().cancelNotification(id + 10000),
          NotificationService().cancelNotification(id + 20000),
        ]);
        // Refresh cached slot/lots state so slot becomes available immediately in UI.
        ref.invalidate(parkingSlotsProvider);
        ref.read(parkingLotsProvider.notifier).refresh();
        // Refresh bookings
        loadUserBookings();
        return true;
      },
    );
  }

  Future<bool> extendBooking({
    required int bookingId,
    required DateTime newEndTime,
    required double extraAmount,
    required PaymentMethod method,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    // 1. Update Booking EndTime
    final result = await repository.extendBooking(bookingId: bookingId, newEndTime: newEndTime);
    
    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
      (updatedBooking) async {
        // 2. Create Payment for extra amount
        if (extraAmount > 0) {
          final paymentResult = await repository.createPayment(
             bookingId: bookingId,
             amount: extraAmount,
             paymentMethod: method.index,
             transactionId: 'EXTEND_${DateTime.now().millisecondsSinceEpoch}',
          );
          
          if (paymentResult.isLeft()) {
             // We still update local state but warn about payment? 
          }
        }
        
        state = state.copyWith(isLoading: false);
        // Slot occupancy can change around extension boundaries, force refresh.
        ref.invalidate(parkingSlotsProvider);
        ref.read(parkingLotsProvider.notifier).refresh();
        
        // 3. Reschedule End Notification
        NotificationService().cancelNotification(bookingId + 10000);
        await _scheduleRemindersForBooking(updatedBooking, onlyEnd: true, isExtension: true);
        
        loadUserBookings();
        return true;
      },
    );
  }

  Future<void> _syncUpcomingReminders(List<Booking> bookings) async {
    for (final booking in bookings) {
      if (booking.status == BookingStatus.cancelled ||
          booking.status == BookingStatus.completed) {
        // Clear any leftover notifications for these statuses in parallel.
        await Future.wait([
          NotificationService().cancelNotification(booking.id),
          NotificationService().cancelNotification(booking.id + 10000),
          NotificationService().cancelNotification(booking.id + 20000),
        ]);
        continue;
      }
      await _scheduleRemindersForBooking(booking);
      await _updateLockScreenWidget(booking);
    }
  }

  Future<void> _updateLockScreenWidget(Booking booking) async {
    // Only show countdown for active (Checked-in) or Confirmed but starting soon
    if (booking.status == BookingStatus.checkedIn || booking.status == BookingStatus.confirmed) {
      final now = DateTime.now();
      final localEnd = booking.endTime.toLocal();
      
      bool shouldShow = false;
      if (booking.status == BookingStatus.checkedIn) {
        shouldShow = now.isBefore(localEnd);
      } else {
        final localStart = booking.startTime.toLocal();
        shouldShow = now.isAfter(localStart.subtract(const Duration(minutes: 30))) && 
                     now.isBefore(localEnd);
      }

      if (shouldShow) {
        final checkoutStr = '${localEnd.hour.toString().padLeft(2, '0')}:${localEnd.minute.toString().padLeft(2, '0')}';
        final isCheckedIn = booking.status == BookingStatus.checkedIn;
        await NotificationService().showOngoingBookingTimer(
          id: booking.id + 20000,
          title: isCheckedIn 
              ? _t('Đang đỗ xe: ${booking.slotNumber ?? ""}', 'Currently parked: ${booking.slotNumber ?? ""}') 
              : _t('Sắp đến giờ đỗ: ${booking.slotNumber ?? ""}', 'Upcoming parking: ${booking.slotNumber ?? ""}'),
          body: _t('Tại ${booking.lotName ?? "bãi đỗ"}. Trả chỗ lúc: $checkoutStr', 'At ${booking.lotName ?? "parking lot"}. Checkout: $checkoutStr'),
          endTime: localEnd,
        );
      } else {
        await NotificationService().cancelNotification(booking.id + 20000);
      }
    } else {
      await NotificationService().cancelNotification(booking.id + 20000);
    }
  }

  Future<void> togglePinToLockScreen(Booking booking) async {
     final localEnd = booking.endTime.toLocal();
     final checkoutStr = '${localEnd.hour.toString().padLeft(2, '0')}:${localEnd.minute.toString().padLeft(2, '0')}';
     
     await NotificationService().showOngoingBookingTimer(
      id: booking.id + 20000,
      title: _t('Theo dõi đơn: #${booking.id}', 'Track booking: #${booking.id}'),
      body: _t('Tại ${booking.lotName ?? ""}. Trả chỗ lúc: $checkoutStr', 'At ${booking.lotName ?? ""}. Checkout: $checkoutStr'),
      endTime: localEnd,
    );
  }

  Future<void> _scheduleRemindersForBooking(
    Booking booking, {
    bool onlyEnd = false,
    bool isExtension = false,
  }) async {
    final now = DateTime.now();
    final localStart = booking.startTime.toLocal();
    final localEnd = booking.endTime.toLocal();

    // 1. Start Reminder
    if (!onlyEnd && booking.status == BookingStatus.confirmed) {
      final startReminderTime = localStart.subtract(const Duration(minutes: 10));
      final title = _t('Sắp đến giờ đỗ xe!', 'Upcoming parking time!');
      final bodyImm = _t('Đơn đặt chỗ của bạn (${booking.lotName ?? ""}) sẽ bắt đầu trong ít phút nữa!', 'Your booking (${booking.lotName ?? ""}) will start in a few minutes!');
      final bodyTimer = _t('Đơn đặt chỗ tại ${booking.lotName ?? "bãi đỗ"} sẽ bắt đầu sau 10 phút nữa.', 'Your booking at ${booking.lotName ?? "parking lot"} will start in 10 minutes.');

      if (now.isAfter(startReminderTime) && now.isBefore(localStart)) {
        final notifId = '${booking.id}_start_imm';
        if (!_shownNotifications.contains(notifId)) {
          _shownNotifications.add(notifId);
          await NotificationService().showNotification(
            id: booking.id,
            title: title,
            body: bodyImm,
          );
          ref.read(notificationsProvider.notifier).addNotification(
            AppNotification(
              id: notifId,
              title: title,
              message: bodyImm,
              timestamp: DateTime.now(),
              type: NotificationType.reminder,
            )
          );
        }
      } else if (startReminderTime.isAfter(now)) {


        await NotificationService().scheduleBookingReminder(
          id: booking.id,
          title: title,
          body: bodyTimer,
          scheduledDate: startReminderTime,
        );
        Timer(startReminderTime.difference(now), () {
          ref.read(notificationsProvider.notifier).addNotification(
            AppNotification(
              id: booking.id.toString() + '_start_timer',
              title: title,
              message: bodyTimer,
              timestamp: DateTime.now(),
              type: NotificationType.reminder,
            )
          );
        });
      }
    }

    // 2. End Reminder
    if (booking.status == BookingStatus.confirmed || booking.status == BookingStatus.checkedIn) {
      final endReminderTime = localEnd.subtract(const Duration(minutes: 10));
      final title = isExtension ? _t('Hết hạn gửi xe (Đã gia hạn)!', 'Parking expired (Extended)!') : _t('Sắp hết hạn gửi xe!', 'Parking about to expire!');
      final bodyPrefix = isExtension ? _t('Thời gian mới', 'New time') : _t('Đơn đặt tại ${booking.lotName ?? "bãi đỗ"} sẽ hết hạn', 'Booking at ${booking.lotName ?? "parking lot"} will expire');
      final bodyImm = _t('$bodyPrefix trong ít phút nữa. Vui lòng lưu ý!', '$bodyPrefix in a few minutes. Please note!');
      final bodyTimer = _t('$bodyPrefix sau 10 phút nữa. Vui lòng lưu ý!', '$bodyPrefix in 10 minutes. Please note!');
      
      if (now.isAfter(endReminderTime) && now.isBefore(localEnd)) {
        final notifId = '${booking.id}_end_imm';
        if (!_shownNotifications.contains(notifId)) {
          _shownNotifications.add(notifId);
          await NotificationService().showNotification(
            id: booking.id + 10000,
            title: title,
            body: bodyImm,
          );
          ref.read(notificationsProvider.notifier).addNotification(
            AppNotification(
              id: notifId,
              title: title,
              message: bodyImm,
              timestamp: DateTime.now(),
              type: NotificationType.reminder,
            )
          );
        }
      } else if (endReminderTime.isAfter(now)) {
      

        await NotificationService().scheduleBookingReminder(
          id: booking.id + 10000,
          title: title,
          body: bodyTimer,
          scheduledDate: endReminderTime,
        );
        Timer(endReminderTime.difference(now), () {
          ref.read(notificationsProvider.notifier).addNotification(
            AppNotification(
              id: booking.id.toString() + '_end_timer',
              title: title,
              message: bodyTimer,
              timestamp: DateTime.now(),
              type: NotificationType.reminder,
            )
          );
        });
      }
    }
  }
}

final bookingProvider = StateNotifierProvider<BookingNotifier, BookingState>((ref) {
  final notifier = BookingNotifier(ref.read(parkingRepositoryProvider), ref);
  
  ref.listen(authProvider, (previous, next) {
    if (next.status == AuthStatus.unauthenticated) {
      notifier.clear();
    }
  });
  
  return notifier;
});
