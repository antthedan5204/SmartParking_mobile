import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../parking/domain/entities/parking_lot.dart';
import '../../../parking/domain/entities/parking_slot.dart';
import '../../../parking/presentation/pages/payment_success_page.dart';
import '../providers/manage_slots_provider.dart';
import '../providers/booking_management_provider.dart';

class ManagerBookingPage extends ConsumerStatefulWidget {
  final ParkingLot lot;
  final ParkingSlot slot;

  const ManagerBookingPage({
    super.key,
    required this.lot,
    required this.slot,
  });

  @override
  ConsumerState<ManagerBookingPage> createState() => _ManagerBookingPageState();
}

class _ManagerBookingPageState extends ConsumerState<ManagerBookingPage> {
  bool _isProcessing = false;
  late DateTime _startTime;
  late DateTime _endTime;
  final TextEditingController _plateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now().add(const Duration(minutes: 5));
    _startTime = _startTime.subtract(Duration(minutes: _startTime.minute % 5));
    _endTime = _startTime.add(const Duration(hours: 1));
  }

  @override
  void dispose() {
    _plateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final duration = _endTime.difference(_startTime);
    final double hours = duration.inMinutes / 60.0;
    final totalPrice = widget.lot.pricePerHour * hours;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1A237E)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.translate('bookForGuestTitle'),
          style: AppTextStyles.subtitle1.copyWith(color: const Color(0xFF1A237E), fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.local_parking_rounded, color: Color(0xFF6366F1), size: 20),
                ),
                const SizedBox(width: 8),
                Text(
                  'SMART',
                  style: AppTextStyles.subtitle1.copyWith(
                    color: const Color(0xFF1A237E),
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'PARK',
                  style: AppTextStyles.subtitle1.copyWith(
                    color: const Color(0xFF6366F1),
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _isProcessing 
        ? _buildProcessingState(l10n)
        : _buildUnifiedSelectionState(context, totalPrice, l10n),
    );
  }

  Widget _buildProcessingState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Color(0xFF1A237E)),
          const SizedBox(height: 24),
          Text(l10n.translate('processingBooking'), style: AppTextStyles.subtitle1),
        ],
      ),
    );
  }

  Widget _buildUnifiedSelectionState(BuildContext context, double totalPrice, AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          _buildFigmaCard(
            title: l10n.translate('lotDetails'),
            icon: Icons.directions_car_outlined,
            child: Column(
              children: [
                _buildFigmaInfoRow(l10n.translate('lotNameLabel'), widget.lot.name),
                _buildFigmaInfoRow(l10n.translate('parkingSlotLabel'), '${l10n.translate('slotPrefix') ?? 'Ô số '}${widget.slot.slotNumber}'),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TextField(
                    controller: _plateController,
                    decoration: InputDecoration(
                      labelText: l10n.translate('guestLicensePlate'),
                      hintText: l10n.translate('guestLicensePlateHint'),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildFigmaCard(
            title: l10n.translate('estimatedTime'),
            child: Column(
              children: [
                _buildTimelineUI(l10n),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),
                _buildPriceRow(l10n.translate('subTotal'), '${totalPrice.toStringAsFixed(0)} ${l10n.translate('currencyShort')}'),
                _buildPriceRow(l10n.translate('discount'), '-0 ${l10n.translate('currencyShort')}', isDiscount: true),
                _buildPriceRow(l10n.translate('totalAmount'), '${totalPrice.toStringAsFixed(0)} ${l10n.translate('currencyShort')}', isTotal: true),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.translate('paymentMethodTitle'),
            style: AppTextStyles.subtitle1.copyWith(
              fontWeight: FontWeight.w900,
              color: const Color(0xFF1A237E),
            ),
          ),
          const SizedBox(height: 12),
          _buildFigmaPaymentMethod(
            title: l10n.translate('cashPayment'),
            subtitle: l10n.translate('cashPaymentDesc'),
            icon: Icons.money_rounded,
            color: Colors.green,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => _handlePayment(totalPrice, l10n),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text(
                l10n.translate('confirmBooking'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildFigmaCard({required String title, IconData? icon, required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTextStyles.subtitle1.copyWith(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF1A237E),
                ),
              ),
              if (icon != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F4FF),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: const Color(0xFF1A237E), size: 20),
                ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildFigmaInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.body2.copyWith(color: Colors.grey[600])),
          Text(value, style: AppTextStyles.body2.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTimelineUI(AppLocalizations l10n) {
    final format = DateFormat('hh:mm a  dd:MM:yyyy');
    return Column(
      children: [
        Row(
          children: [
            const Icon(Icons.circle, size: 10, color: Color(0xFF1A237E)),
            const SizedBox(width: 12),
            InkWell(
              onTap: () => _pickTime(true),
              child: Text(format.format(_startTime.toLocal()), style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(left: 4, top: 4, bottom: 4),
            height: 30,
            width: 2,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ),
        Row(
          children: [
            const Icon(Icons.circle, size: 10, color: Color(0xFF1A237E)),
            const SizedBox(width: 12),
            InkWell(
              onTap: () => _pickTime(false),
              child: Text(format.format(_endTime.toLocal()), style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(l10n.translate('timeIn'), style: AppTextStyles.caption.copyWith(color: Colors.grey)),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_endTime.difference(_startTime).inHours} ${l10n.translate('hourText')}',
                style: AppTextStyles.caption.copyWith(color: const Color(0xFF1A237E), fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Text(l10n.translate('timeOut'), style: AppTextStyles.caption.copyWith(color: Colors.grey)),
          ],
        ),
      ],
    );
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context, 
      initialTime: TimeOfDay.fromDateTime(isStart ? _startTime : _endTime),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = DateTime(_startTime.year, _startTime.month, _startTime.day, picked.hour, picked.minute);
          if (_endTime.isBefore(_startTime)) _endTime = _startTime.add(const Duration(hours: 1));
        } else {
          final newEnd = DateTime(_endTime.year, _endTime.month, _endTime.day, picked.hour, picked.minute);
          if (newEnd.isAfter(_startTime)) _endTime = newEnd;
        }
      });
    }
  }

  Widget _buildPriceRow(String label, String value, {bool isDiscount = false, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.body2.copyWith(
            color: isTotal ? const Color(0xFF1A237E) : Colors.grey[600],
            fontWeight: isTotal ? FontWeight.w900 : FontWeight.normal,
          )),
          Text(value, style: AppTextStyles.body2.copyWith(
            fontWeight: FontWeight.w900,
            color: isDiscount ? const Color(0xFFEF5350) : (isTotal ? const Color(0xFF1A237E) : Colors.black87),
          )),
        ],
      ),
    );
  }

  Widget _buildFigmaPaymentMethod({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF1A237E),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.subtitle2.copyWith(fontWeight: FontWeight.bold)),
                Text(subtitle, style: AppTextStyles.caption.copyWith(color: Colors.grey)),
              ],
            ),
          ),
          const Icon(Icons.check_circle_rounded, color: Color(0xFF1A237E)),
        ],
      ),
    );
  }

  Future<void> _handlePayment(double finalAmount, AppLocalizations l10n) async {
    final plate = _plateController.text.trim();
    if (plate.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.translate('pleaseEnterGuestLicensePlate'))),
      );
      return;
    }

    final duration = _endTime.difference(_startTime);
    if (duration.inHours <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.translate('minParkingTimeIs1Hour'))),
      );
      return;
    }

    setState(() => _isProcessing = true);
    final messenger = ScaffoldMessenger.of(context);
    
    final result = await ref.read(manageSlotsProvider.notifier).bookOnBehalf(
      slotId: widget.slot.id,
      lotId: widget.lot.id,
      plateNumber: plate,
      durationHours: duration.inHours,
      amount: finalAmount,
      lotName: widget.lot.name,
      slotNumber: widget.slot.slotNumber,
    );

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (result != null) {
      ref.read(bookingManagementProvider.notifier).loadBookings();
      
      // Navigate to PaymentSuccessPage
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PaymentSuccessPage(
            booking: result['booking'],
            payment: result['payment'],
          ),
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.translate('bookForGuestFailed')),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }
}
