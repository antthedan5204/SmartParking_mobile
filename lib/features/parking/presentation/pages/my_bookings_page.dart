import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../domain/entities/booking.dart';
import '../providers/booking_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../widgets/extend_booking_dialog.dart';
import '../../domain/entities/payment.dart';
import 'payment_success_page.dart';

class MyBookingsPage extends ConsumerStatefulWidget {
  final bool isManagementMode;
  const MyBookingsPage({super.key, this.isManagementMode = false});

  @override
  ConsumerState<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends ConsumerState<MyBookingsPage> {
  static final DateFormat _formatter = DateFormat('HH:mm, dd/MM/yyyy');
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bookingProvider.notifier).loadUserBookings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bookingProvider);
    final now = DateTime.now();
    final l10n = AppLocalizations.of(context);

    // Categorize bookings
    final activeBookings = state.userBookings.where((b) {
      if (b.status == BookingStatus.checkedIn) return true;
      if (b.status == BookingStatus.confirmed &&
          !now.isAfter(b.endTime.toLocal()))
        return true;
      return false;
    }).toList();

    final historyBookings = state.userBookings.where((b) {
      if (b.status == BookingStatus.checkedIn) return false;
      if (b.status == BookingStatus.confirmed &&
          !now.isAfter(b.endTime.toLocal()))
        return false;
      return true;
    }).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            widget.isManagementMode
                ? l10n.translate('manageParking')
                : l10n.translate('myBookings'),
          ),
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          centerTitle: true,
          automaticallyImplyLeading: Navigator.canPop(context),
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: <Widget>[
              Tab(text: l10n.translate('upcomingBookings')),
              Tab(text: l10n.translate('historyBookings')),
            ],
          ),
        ),
        body: state.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : TabBarView(
                children: [
                  activeBookings.isEmpty
                      ? _buildEmptyState(
                          l10n.translate('noActiveBookings'),
                          l10n,
                        )
                      : _buildBookingsList(activeBookings, isHistory: false),
                  historyBookings.isEmpty
                      ? _buildEmptyState(
                          l10n.translate('noHistoryBookings'),
                          l10n,
                        )
                      : _buildBookingsList(historyBookings, isHistory: true),
                ],
              ),
      ),
    );
  }

  Widget _buildEmptyState(String message, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_rounded,
            size: 64,
            color: AppColors.textHint.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: AppTextStyles.subtitle2,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.translate('bookingsWillAppearHere'),
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsList(List<Booking> bookings, {required bool isHistory}) {
    return RefreshIndicator(
      onRefresh: () => ref.read(bookingProvider.notifier).loadUserBookings(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final booking = bookings[index];
          return _buildBookingCard(
            booking,
            isHistory: isHistory,
            context: context,
          );
        },
      ),
    );
  }

  Widget _buildBookingCard(
    Booking booking, {
    required bool isHistory,
    required BuildContext context,
  }) {
    final l10n = AppLocalizations.of(context);
    final formatter = _formatter;
    final isConfirmed = booking.status == BookingStatus.confirmed;
    final isCompleted = booking.status == BookingStatus.completed;
    final isCancelled = booking.status == BookingStatus.cancelled;
    final isCheckedIn = booking.status == BookingStatus.checkedIn;
    final now = DateTime.now();
    final localStartTime = booking.startTime.toLocal();
    final localEndTime = booking.endTime.toLocal();

    // Logic for management
    final bool canCancel =
        isConfirmed &&
        now.isBefore(localStartTime.subtract(const Duration(minutes: 30)));
    final bool canExtend =
        isConfirmed &&
        now.isAfter(localStartTime) &&
        now.isBefore(localEndTime);
    final bool isExpired = now.isAfter(localEndTime);
    final bool isNearStart =
        isConfirmed && !isExpired && now.isBefore(localStartTime) && !canCancel;

    final bool isOvertime = isCheckedIn && now.isAfter(localEndTime);

    Color statusColor = AppColors.primary;
    String statusText = l10n.translate('statusBooked');
    if (isOvertime) {
      statusColor = AppColors.danger;
      statusText = l10n.translate('statusOvertimeWithFee');
    } else if (isCompleted) {
      statusColor = AppColors.success;
      statusText = l10n.translate('statusCompleted');
    } else if (isCancelled) {
      statusColor = AppColors.danger;
      statusText = l10n.translate('statusCancelled');
    } else if (isCheckedIn) {
      statusColor = Colors.blue;
      statusText = l10n.translate('statusCheckedIn');
    }

    Widget card = GestureDetector(
      onTap: () => context.push('/booking-details', extra: {'booking': booking}),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: statusColor.withValues(alpha: 0.1),
              child: Row(
                children: [
                  Icon(Icons.circle, size: 8, color: statusColor),
                  const SizedBox(width: 8),
                  Text(
                    statusText,
                    style: AppTextStyles.caption.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (isCompleted || isCheckedIn)
                    IconButton(
                      icon: const Icon(Icons.receipt_long_rounded, size: 18),
                      onPressed: () => _viewInvoice(booking),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      visualDensity: VisualDensity.compact,
                      color: statusColor,
                      tooltip: l10n.translate('viewInvoice'),
                    ),
                  if (!isHistory &&
                      !isCancelled &&
                      !isCompleted &&
                      !isCheckedIn)
                    IconButton(
                      icon: const Icon(Icons.push_pin_rounded, size: 16),
                      onPressed: () {
                        ref
                            .read(bookingProvider.notifier)
                            .togglePinToLockScreen(booking);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              l10n.translate('pinnedToLockScreenSuccess'),
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      visualDensity: VisualDensity.compact,
                      color: AppColors.textSecondary,
                      tooltip: l10n.translate('pinToLockScreen'),
                    ),
                  const SizedBox(width: 8),
                  Text(
                    '#${booking.id}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.location_on_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              booking.lotName ?? l10n.translate('unknownLot'),
                              style: AppTextStyles.subtitle2,
                            ),
                            if (booking.slotNumber != null)
                              Text(
                                '${l10n.translate('slotPrefix')}${booking.slotNumber}',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildTimeInfo(
                        l10n.translate('timeStart'),
                        formatter.format(booking.startTime),
                      ),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: AppColors.textHint,
                      ),
                      _buildTimeInfo(
                        l10n.translate('timeEnd'),
                        formatter.format(booking.endTime),
                        crossAxisAlignment: CrossAxisAlignment.end,
                      ),
                    ],
                  ),

                  if (isOvertime) ...[
                    Builder(
                      builder: (context) {
                        final overtimeMinutes = now
                            .difference(localEndTime)
                            .inMinutes;
                        final penaltyFee = overtimeMinutes > 10
                            ? overtimeMinutes * 1000
                            : 0;
                        return Container(
                          margin: const EdgeInsets.only(top: 16),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.warning_amber_rounded,
                                    color: AppColors.danger,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      l10n.translate('overtimeWarning'),
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.danger,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (penaltyFee > 0) ...[
                                const SizedBox(height: 8),
                                Text(
                                  '${l10n.translate('penaltyFeePrefix')}${NumberFormat.decimalPattern().format(penaltyFee)} ${l10n.translate('currencyShort')}',
                                  style: AppTextStyles.subtitle2.copyWith(
                                    color: AppColors.danger,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ));

    if (isHistory) {
      // Use ColorFiltered instead of Opacity to avoid expensive saveLayer.
      return ColorFiltered(
        colorFilter: ColorFilter.mode(
          Colors.white.withValues(alpha: 0.45),
          BlendMode.srcATop,
        ),
        child: card,
      );
    }
    return card;
  }

  Widget _buildTimeInfo(
    String label,
    String value, {
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start,
  }) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  void _showQRCode(Booking booking, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.translate('qrCodeTitle'), textAlign: TextAlign.center),
        content: SizedBox(
          width: 250,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              QrImageView(
                data: 'BOOKING:${booking.id}',
                version: QrVersions.auto,
                size: 200,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: AppColors.primary,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text('#${booking.id}', style: AppTextStyles.subtitle2),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.translate('close')),
          ),
        ],
      ),
    );
  }

  void _handleCancel(Booking booking, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.translate('cancelConfirmTitle')),
        content: Text(l10n.translate('cancelConfirmSub')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.translate('noBtn')),
          ),
          TextButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              final success = await ref
                  .read(bookingProvider.notifier)
                  .cancelBooking(booking.id);
              if (success && mounted) {
                messenger.showSnackBar(
                  SnackBar(content: Text(l10n.translate('cancelSuccess'))),
                );
              }
            },
            child: Text(
              l10n.translate('cancelBookingBtn'),
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }

  void _handleExtend(Booking booking) {
    showDialog(
      context: context,
      builder: (context) => ExtendBookingDialog(booking: booking),
    );
  }

  void _viewInvoice(Booking booking) {
    // Tạo Payment dummy từ dữ liệu Booking để hiển thị lên màn hình hóa đơn
    final dummyPayment = Payment(
      id: booking.id,
      bookingId: booking.id,
      amount: booking.totalPrice,
      method: PaymentMethod.momo,
      status: PaymentStatus.success,
      transactionId: 'REPRINT_${booking.id}',
      createdAt: DateTime.now(),
    );

    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) =>
            PaymentSuccessPage(booking: booking, payment: dummyPayment),
      ),
    );
  }
}
