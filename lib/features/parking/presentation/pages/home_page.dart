import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/booking_provider.dart';
import '../providers/parking_provider.dart';
import '../../domain/entities/booking.dart';
import 'package:smart_parking/features/parking/presentation/widgets/voice_booking_dialog.dart';
import '../../domain/entities/parking_lot.dart';
import '../widgets/parking_lot_details_sheet.dart';
import 'select_slot_page.dart';

import 'main_shell_page.dart';
import '../providers/voice_booking_provider.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bookingProvider.notifier).loadUserBookings();
      ref.read(parkingLotsProvider.notifier).refresh();
    });
  }

  String _getGreeting(AppLocalizations l10n) {
    final hour = DateTime.now().hour;
    if (hour < 12) return l10n.translate('goodMorning');
    if (hour < 18) return l10n.translate('goodAfternoon');
    return l10n.translate('goodEvening');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.homeBackground,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: FloatingActionButton(
            onPressed: () => showVoiceBookingDialog(context, ref),
            backgroundColor: AppColors.primary,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.mic_none_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          await Future.wait([
            ref.read(bookingProvider.notifier).loadUserBookings(),
            ref.read(parkingLotsProvider.notifier).refresh(),
          ]);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Consumer(
                builder: (context, ref, child) {
                  final authState = ref.watch(authProvider);
                  final userName = authState.user?.name ?? '';
                  return _buildHeader(userName, context, l10n);
                },
              ),
            ),

            SliverToBoxAdapter(
              child: Consumer(
                builder: (context, ref, child) {
                  final bookingState = ref.watch(bookingProvider);
                  final now = DateTime.now();
                  final activeBookings = bookingState.userBookings.where((b) {
                    if (b.status == BookingStatus.checkedIn) return true;
                    if (b.status == BookingStatus.confirmed &&
                        !now.isAfter(b.endTime.toLocal())) {
                      return true;
                    }
                    return false;
                  }).toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle(
                        activeBookings.isNotEmpty
                            ? l10n.translate('currentBooking')
                            : l10n.translate('noCurrentBooking'),
                        Icons.local_parking_rounded,
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                        child: activeBookings.isNotEmpty
                            ? _buildActiveBookingCard(
                                activeBookings.first,
                                context,
                                l10n,
                              )
                            : _buildNoActiveBookingCard(context, l10n),
                      ),
                    ],
                  );
                },
              ),
            ),

            SliverToBoxAdapter(child: _buildQuickActions(context, l10n)),

            SliverToBoxAdapter(
              child: _buildSectionTitle(
                l10n.translate('recentParkingLots'),
                Icons.location_on_rounded,
              ),
            ),

            Consumer(
              builder: (context, ref, child) {
                final parkingState = ref.watch(parkingLotsProvider);
                final topLots = parkingState.lots.take(3).toList();

                if (parkingState.isLoading) {
                  return const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  );
                } else if (topLots.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: Text(
                        l10n.translate('noRecentParkingLots'),
                        style: AppTextStyles.body2.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                } else {
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: EdgeInsets.fromLTRB(
                          20,
                          0,
                          20,
                          index == topLots.length - 1
                              ? kNavBarTotalHeight + 8
                              : 12,
                        ),
                        child: _buildParkingLotCard(
                          topLots[index],
                          context,
                          l10n,
                        ),
                      ),
                      childCount: topLots.length,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    String userName,
    BuildContext context,
    AppLocalizations l10n,
  ) {
    final firstName = userName.split(' ').last;
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 16,
        20,
        24,
      ),
      decoration: const BoxDecoration(
        gradient: AppColors.homeHeaderGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting(l10n),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    Text(
                      firstName.isNotEmpty ? firstName : l10n.translate('user'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => context.go('/notifications'),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.notifications_none_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildHeaderChip(
                Icons.local_parking_rounded,
                l10n.translate('searchParkingHome'),
                () => context.go('/parking'),
              ),
              const SizedBox(width: 12),
              _buildHeaderChip(
                Icons.history_rounded,
                l10n.translate('historyHome'),
                () => context.go('/bookings'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderChip(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          Text(
            title,
            style: AppTextStyles.subtitle1.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveBookingCard(
    Booking booking,
    BuildContext context,
    AppLocalizations l10n,
  ) {
    final isCheckedIn = booking.status == BookingStatus.checkedIn;
    final localEnd = booking.endTime.toLocal();
    final remaining = localEnd.difference(DateTime.now());
    final isOvertime = isCheckedIn && remaining.isNegative;

    final hours = remaining.abs().inHours;
    final minutes = remaining.abs().inMinutes % 60;

    final statusColor = isOvertime
        ? AppColors.danger
        : (isCheckedIn ? AppColors.success : AppColors.primary);
    final statusLabel = isOvertime
        ? l10n.translate('parkingOvertime')
        : (isCheckedIn
              ? l10n.translate('parkingNow')
              : l10n.translate('bookedNow'));
    final statusIcon = isOvertime
        ? Icons.warning_rounded
        : (isCheckedIn
              ? Icons.directions_car_rounded
              : Icons.event_available_rounded);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [statusColor, statusColor.withValues(alpha: 0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: Colors.white, size: 14),
                      const SizedBox(width: 5),
                      Text(
                        statusLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  '#${booking.id}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              booking.lotName ?? l10n.translate('parkingLot'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (booking.slotNumber != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${l10n.translate('slotPrefix') ?? 'Ô số '}${booking.slotNumber}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.timer_outlined,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isOvertime
                        ? l10n
                              .translate('overtimeFormat')
                              .replaceAll('{hours}', hours.toString())
                              .replaceAll('{minutes}', minutes.toString())
                        : remaining.isNegative
                        ? l10n.translate('timeToPark')
                        : hours > 0
                        ? l10n
                              .translate('remainingTimeFormatHM')
                              .replaceAll('{hours}', hours.toString())
                              .replaceAll('{minutes}', minutes.toString())
                        : l10n
                              .translate('remainingTimeFormatM')
                              .replaceAll('{minutes}', minutes.toString()),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    DateFormat('HH:mm').format(localEnd),
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            if (isOvertime) ...[
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.translate('notCheckedOutWarning'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Builder(
                builder: (context) {
                  final overtimeMinutes = DateTime.now()
                      .difference(localEnd)
                      .inMinutes;
                  final penaltyFee = overtimeMinutes > 10
                      ? overtimeMinutes * 1000
                      : 0;
                  if (penaltyFee > 0) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.monetization_on_outlined,
                            color: Colors.yellowAccent,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${l10n.translate('penaltyFeePrefix')}${NumberFormat.decimalPattern().format(penaltyFee)} ${l10n.translate('currencyShort')}',
                              style: const TextStyle(
                                color: Colors.yellowAccent,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => context.go('/bookings'),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  l10n.translate('viewBookingDetails'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoActiveBookingCard(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    return GestureDetector(
      onTap: () => context.go('/parking'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.local_parking_rounded,
                color: AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.translate('noCurrentBooking'),
                    style: AppTextStyles.subtitle2,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.translate('tapToSearchParking'),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          _buildActionButton(
            icon: Icons.search_rounded,
            label: l10n.translate('parking'),
            color: AppColors.primary,
            onTap: () => context.go('/parking'),
          ),
          const SizedBox(width: 12),
          _buildActionButton(
            icon: Icons.receipt_long_rounded,
            label: l10n.translate('bookings'),
            color: AppColors.quickActionBookings,
            onTap: () => context.go('/bookings'),
          ),
          const SizedBox(width: 12),
          _buildActionButton(
            icon: Icons.help_outline_rounded,
            label: l10n.translate('helpCenter'),
            color: AppColors.quickActionHelp,
            onTap: () => context.push('/help-center'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.12),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParkingLotCard(
    ParkingLot lot,
    BuildContext context,
    AppLocalizations l10n,
  ) {
    final total = lot.totalSlots;
    final available = lot.availableSlots ?? 0;
    final occupancy = total > 0 ? (available / total) : 0.0;

    Color statusColor;
    String statusText;
    if (occupancy > 0.5) {
      statusColor = AppColors.occupancyHigh;
      statusText = l10n.translate('lotsPlenty');
    } else if (occupancy > 0.2) {
      statusColor = AppColors.occupancyMedium;
      statusText = l10n.translate('lotsFew');
    } else {
      statusColor = available > 0 ? AppColors.occupancyLow : AppColors.danger;
      statusText = available > 0
          ? l10n.translate('lotsAlmostFull')
          : l10n.translate('lotsFull');
    }

    return GestureDetector(
      onTap: () => _showDetails(context, lot),
      child: Container(
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.local_parking_rounded,
                  color: AppColors.primary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (lot.name),
                      style: AppTextStyles.subtitle2.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      (lot.address),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            statusText,
                            style: AppTextStyles.caption.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n
                              .translate('slotCountFormat')
                              .replaceAll('{available}', available.toString())
                              .replaceAll('{total}', total.toString()),
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${_formatPrice(lot.pricePerHour)}${l10n.translate('currencyShort')}',
                    style: AppTextStyles.subtitle2.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    l10n.translate('perHour'),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: AppColors.textHint,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatPrice(double price) {
    if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}k';
    }
    return price.toStringAsFixed(0);
  }

  void _showDetails(BuildContext context, ParkingLot lot) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ParkingLotDetailsSheet(
        lot: lot,
        onNavigate: () {
          // TODO: Implement map navigation
          Navigator.pop(context);
        },
        onPay: () {
          Navigator.pop(context);
          Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute(builder: (context) => SelectSlotPage(lot: lot)),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: 48,
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.translate('noParkingLots'),
            style: AppTextStyles.subtitle1.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
