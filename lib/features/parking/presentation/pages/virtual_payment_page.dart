import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../domain/entities/booking.dart';
import '../../domain/entities/parking_lot.dart';
import '../../domain/entities/payment.dart';
import '../providers/parking_provider.dart';
import '../providers/booking_provider.dart';
import '../providers/vehicle_provider.dart';
import '../widgets/add_vehicle_dialog.dart';
import 'payment_success_page.dart';

class VirtualPaymentPage extends ConsumerStatefulWidget {
  final ParkingLot lot;
  final double amount;
  final int? selectedSlotId;
  final String? selectedSlotNumber;
  final DateTime? startTime;
  final DateTime? endTime;

  const VirtualPaymentPage({
    super.key,
    required this.lot,
    required this.amount,
    this.selectedSlotId,
    this.selectedSlotNumber,
    this.startTime,
    this.endTime,
  });

  @override
  ConsumerState<VirtualPaymentPage> createState() => _VirtualPaymentPageState();
}

class _VirtualPaymentPageState extends ConsumerState<VirtualPaymentPage> {
  PaymentMethod _selectedMethod = PaymentMethod.momo;
  bool _isProcessing = false;
  late DateTime _startTime;
  late DateTime _endTime;
  int? _selectedVehicleId;
  bool _agreedToTerms = false;

  @override
  void initState() {
    super.initState();
    if (widget.startTime != null && widget.endTime != null) {
      _startTime = widget.startTime!;
      _endTime = widget.endTime!;
    } else {
      _startTime = DateTime.now().add(const Duration(minutes: 5));
      _startTime = _startTime.subtract(
        Duration(minutes: _startTime.minute % 5),
      );
      _endTime = _startTime.add(const Duration(hours: 1));
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    await ref.read(vehicleProvider.notifier).loadVehicles();
    final vehicles = ref.read(vehicleProvider).vehicles;
    if (vehicles.isNotEmpty && mounted) {
      setState(() {
        _selectedVehicleId = vehicles.first.id;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bookingState = ref.watch(bookingProvider);
    final vehicleState = ref.watch(vehicleProvider);

    final duration = _endTime.difference(_startTime);
    final double hours = duration.inMinutes / 60.0;
    final totalPrice = widget.lot.pricePerHour * hours;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF1A237E),
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          l10n.translate('paymentTitle'),
          style: AppTextStyles.subtitle1.copyWith(
            color: const Color(0xFF1A237E),
            fontWeight: FontWeight.bold,
          ),
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
                  child: const Icon(
                    Icons.local_parking_rounded,
                    color: Color(0xFF6366F1),
                    size: 20,
                  ),
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
          : _buildUnifiedSelectionState(
              context,
              l10n,
              bookingState,
              vehicleState,
              totalPrice,
            ),
    );
  }

  Widget _buildProcessingState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Color(0xFF1A237E)),
          const SizedBox(height: 24),
          Text(l10n.processing, style: AppTextStyles.subtitle1),
        ],
      ),
    );
  }

  Widget _buildUnifiedSelectionState(
    BuildContext context,
    AppLocalizations l10n,
    BookingState state,
    VehicleState vehicleState,
    double totalPrice,
  ) {
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
                _buildFigmaInfoRow(
                  l10n.translate('lotNameLabel'),
                  widget.lot.name,
                ),
                _buildFigmaInfoRow(
                  l10n.translate('parkingSlotLabel'),
                  '${l10n.translate('slotPrefix')}${widget.selectedSlotNumber ?? '8'}',
                ),
                _buildVehicleSelector(vehicleState, l10n),
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
                _buildPriceRow(
                  l10n.translate('subTotal'),
                  '${totalPrice.toStringAsFixed(0)} ${l10n.translate('currencyShort')}',
                ),
                _buildPriceRow(
                  l10n.translate('discount'),
                  '-0 ${l10n.translate('currencyShort')}',
                  isDiscount: true,
                ),
                _buildPriceRow(
                  l10n.translate('totalAmount'),
                  '${totalPrice.toStringAsFixed(0)} ${l10n.translate('currencyShort')}',
                  isTotal: true,
                ),
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
            method: PaymentMethod.momo,
            title: l10n.translate('momoWallet'),
            subtitle: l10n.translate('momoDesc'),
            icon: Icons.account_balance_wallet_rounded,
            color: const Color(0xFFA50064),
          ),
          const SizedBox(height: 12),
          _buildFigmaPaymentMethod(
            method: PaymentMethod.vnpay,
            title: l10n.translate('vnpayPortal'),
            subtitle: l10n.translate('vnpayDesc'),
            icon: Icons.qr_code_scanner_rounded,
            color: const Color(0xFF005BAA),
          ),
          const SizedBox(height: 32),
          if (_selectedVehicleId != null) ...[
            Row(
              children: [
                Checkbox(
                  value: _agreedToTerms,
                  activeColor: const Color(0xFF6366F1),
                  onChanged: (val) {
                    setState(() => _agreedToTerms = val ?? false);
                  },
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showTermsDialog(context),
                    child: Text.rich(
                      TextSpan(
                        text: l10n.translate('termsPrefix'),
                        style: AppTextStyles.body2,
                        children: [
                          TextSpan(
                            text: l10n.translate('termsLink'),
                            style: AppTextStyles.body2.copyWith(
                              color: const Color(0xFF6366F1),
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: (_selectedVehicleId == null)
                  ? () => _addNewVehicle(context)
                  : (_agreedToTerms
                        ? () => _showQRSimulation(context, totalPrice)
                        : null),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                (_selectedVehicleId == null)
                    ? l10n.translate('registerLicensePlate')
                    : l10n.translate('payBtn'),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showQRSimulation(BuildContext context, double finalAmount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context).translate('scanQRCode'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              AppLocalizations.of(context)
                  .translate('pleaseScanToPay')
                  .replaceAll('{amount}', finalAmount.toStringAsFixed(0)),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Icon(
                Icons.qr_code_2_rounded,
                size: 160,
                color: _selectedMethod == PaymentMethod.momo
                    ? const Color(0xFFA50064)
                    : const Color(0xFF005BAA),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    AppLocalizations.of(context).translate('waitingForScan'),
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Sử dụng biến _handlePayment mà không truyền context từ Dialog
                  _handlePayment(finalAmount);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context).translate('confirmScanned'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFigmaCard({
    required String title,
    IconData? icon,
    required Widget child,
  }) {
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
          Text(
            label,
            style: AppTextStyles.body2.copyWith(color: Colors.grey[600]),
          ),
          Text(
            value,
            style: AppTextStyles.body2.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleSelector(
    VehicleState vehicleState,
    AppLocalizations l10n,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            l10n.translate('licensePlateLabel'),
            style: AppTextStyles.body2.copyWith(color: Colors.grey[600]),
          ),
          vehicleState.vehicles.isEmpty
              ? TextButton(
                  onPressed: () => _addNewVehicle(context),
                  child: Text(
                    l10n.translate('addNow'),
                    style: const TextStyle(color: Color(0xFF6366F1)),
                  ),
                )
              : DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedVehicleId,
                    isDense: true,
                    items: vehicleState.vehicles
                        .map(
                          (v) => DropdownMenuItem(
                            value: v.id,
                            child: Text(
                              v.licensePlate,
                              style: AppTextStyles.body2.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedVehicleId = val);
                    },
                  ),
                ),
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
              child: Text(
                format.format(_startTime.toLocal()),
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
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
              child: Text(
                format.format(_endTime.toLocal()),
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n.translate('timeIn'),
              style: AppTextStyles.caption.copyWith(color: Colors.grey),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_endTime.difference(_startTime).inHours} ${l10n.translate('hourText')}',
                style: AppTextStyles.caption.copyWith(
                  color: const Color(0xFF1A237E),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              l10n.translate('timeOut'),
              style: AppTextStyles.caption.copyWith(color: Colors.grey),
            ),
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
          _startTime = DateTime(
            _startTime.year,
            _startTime.month,
            _startTime.day,
            picked.hour,
            picked.minute,
          );
          if (_endTime.isBefore(_startTime))
            _endTime = _startTime.add(const Duration(hours: 1));
        } else {
          final newEnd = DateTime(
            _endTime.year,
            _endTime.month,
            _endTime.day,
            picked.hour,
            picked.minute,
          );
          if (newEnd.isAfter(_startTime)) _endTime = newEnd;
        }
      });
    }
  }

  Widget _buildPriceRow(
    String label,
    String value, {
    bool isDiscount = false,
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.body2.copyWith(
              color: isTotal ? const Color(0xFF1A237E) : Colors.grey[600],
              fontWeight: isTotal ? FontWeight.w900 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.body2.copyWith(
              fontWeight: FontWeight.w900,
              color: isDiscount
                  ? const Color(0xFFEF5350)
                  : (isTotal ? const Color(0xFF1A237E) : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFigmaPaymentMethod({
    required PaymentMethod method,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedMethod == method;
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = method),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF1A237E) : Colors.transparent,
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
                  Text(
                    title,
                    style: AppTextStyles.subtitle2.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  void _addNewVehicle(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const AddVehicleDialog(),
    );
    if (result == true && mounted) {
      await ref.read(vehicleProvider.notifier).loadVehicles();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thêm biển số thành công'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handlePayment(double finalAmount) async {
    if (_selectedVehicleId == null) return;

    // Khởi tạo messenger TRƯỚC khi chạy lệnh async
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _isProcessing = true);

    final result = await ref
        .read(bookingProvider.notifier)
        .processBookingAndPayment(
          lotId: widget.lot.id,
          slotId: widget.selectedSlotId ?? 0,
          vehicleId: _selectedVehicleId!,
          amount: finalAmount,
          startTime: _startTime,
          endTime: _endTime,
          method: _selectedMethod,
        );

    if (!mounted) return;

    if (result != null) {
      if (mounted) setState(() => _isProcessing = false);
      debugPrint(
        'DEBUG: Payment successful, attempting to navigate to /payment-success',
      );
      try {
        if (!mounted) return;
        context.go(
          '/payment-success',
          extra: {'booking': result['booking'], 'payment': result['payment']},
        );
        debugPrint('DEBUG: Navigation command executed');
      } catch (e) {
        debugPrint('DEBUG: Navigation error: $e');
        // Nếu context.go lỗi, thử dùng push truyền thống (fallback)
        if (mounted) {
          Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute(
              builder: (_) => PaymentSuccessPage(
                booking: result['booking'],
                payment: result['payment'],
              ),
            ),
          );
        }
      }
    } else {
      debugPrint('DEBUG: Payment failed, result is null');
      if (mounted) setState(() => _isProcessing = false);
      final errorKey = ref.read(bookingProvider).errorMessage;
      final error = errorKey != null
          ? AppLocalizations.of(context).translate(errorKey)
          : AppLocalizations.of(context).translate('paymentFailed');
      messenger.showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: const Color(0xFFEF5350),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showTermsDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n.translate('termsTitle'),
          style: AppTextStyles.subtitle1.copyWith(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.translate('termsRule1'), style: AppTextStyles.body2),
            const SizedBox(height: 8),
            Text(l10n.translate('termsRule2'), style: AppTextStyles.body2),
            const SizedBox(height: 8),
            Text(l10n.translate('termsRule3'), style: AppTextStyles.body2),
            const SizedBox(height: 8),
            Text(l10n.translate('termsRule4'), style: AppTextStyles.body2),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              l10n.translate('closeBtn'),
              style: AppTextStyles.button.copyWith(
                color: const Color(0xFF6366F1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
