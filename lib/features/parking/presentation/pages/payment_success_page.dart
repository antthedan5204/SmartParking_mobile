import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/booking.dart';
import '../../domain/entities/payment.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class PaymentSuccessPage extends ConsumerWidget {
  final Booking booking;
  final Payment payment;

  const PaymentSuccessPage({
    super.key,
    required this.booking,
    required this.payment,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final format = DateFormat('hh:mm a  dd:MM:yyyy');
    final duration = booking.endTime.difference(booking.startTime);

    void onClose() {
      final user = ref.read(authProvider).user;
      if ((user?.isAdmin ?? false) || (user?.isManager ?? false)) {
        // Manager uses pushReplacement, so popping returns to ManageSlotsPage
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          context.go('/admin');
        }
      } else {
        // Pop back to the previous screen (e.g. MyBookingsPage)
        // instead of hard-navigating to /home
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          context.go('/home');
        }
      }
    }
    
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF1A237E)),
          onPressed: onClose,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          children: [
            // Receipt Container
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  // Logo & Bill No
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.local_parking_rounded, color: Color(0xFF6366F1), size: 24),
                            ),
                            const SizedBox(width: 8),
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'SMART',
                                    style: AppTextStyles.subtitle2.copyWith(
                                      color: const Color(0xFF1A237E),
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'PARK',
                                    style: AppTextStyles.subtitle2.copyWith(
                                      color: const Color(0xFF6366F1),
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${l10n.translate('billNo')} 00${booking.id}',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.translate('invoiceTitle'),
                    style: AppTextStyles.heading2.copyWith(
                      color: const Color(0xFF1A237E),
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.translate('paymentSuccessTitle'),
                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Divider(),
                  ),

                  // Parking Details
                  _buildSectionTitle(l10n.translate('parkingInfoTitle')),
                  _buildInfoRow(l10n.translate('parkingLotLabel'), booking.lotName ?? 'Smart Park'),
                  _buildInfoRow(l10n.translate('slotLabel'), '${l10n.translate('slotPrefix') ?? 'Ô số '}${booking.slotId}'),
                  _buildInfoRow(l10n.translate('licensePlateLabel'), booking.vehiclePlateNumber ?? 'N/A'),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Divider(),
                  ),

                  // Time Duration
                  _buildSectionTitle(l10n.translate('timeTitle')),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        _buildTimePoint(format.format(booking.startTime.toLocal()), true),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(left: 4, top: 4, bottom: 4),
                            height: 20,
                            width: 2,
                            color: Colors.grey[300],
                          ),
                        ),
                        _buildTimePoint(format.format(booking.endTime.toLocal()), false),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Arriving / Leaving Summary
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatusLabel(l10n.translate('timeIn')),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${duration.inHours} ${l10n.translate('hourText')}',
                            style: const TextStyle(
                              color: Color(0xFF6366F1),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        _buildStatusLabel(l10n.translate('timeOut')),
                      ],
                    ),
                  ),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Divider(),
                  ),

                  // Payment Details
                  _buildSectionTitle(l10n.translate('paymentDetailsTitle')),
                  _buildPriceRow(l10n.translate('parkingFeeLabel'), '${payment.amount.toStringAsFixed(0)} ${l10n.translate('currencyShort')}'),
                  _buildPriceRow(l10n.translate('discount'), '-0 ${l10n.translate('currencyShort')}', isDiscount: true),
                  _buildPriceRow(l10n.translate('totalAmount'), '${payment.amount.toStringAsFixed(0)} ${l10n.translate('currencyShort')}', isTotal: true),
                  
                  const SizedBox(height: 32),
                  // Action Icons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 60),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => _downloadInvoice(context, l10n),
                          child: _buildActionIcon(Icons.file_download_outlined),
                        ),
                        GestureDetector(
                          onTap: () => _shareInvoice(context, l10n),
                          child: _buildActionIcon(Icons.share_outlined),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.translate('thanksForUsingService'),
                    style: const TextStyle(color: Colors.grey, fontSize: 10),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Close Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: onClose,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text(
                  l10n.translate('closeBtn'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Text(
        title,
        style: AppTextStyles.subtitle2.copyWith(
          fontWeight: FontWeight.w900,
          color: const Color(0xFF1A237E),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildTimePoint(String time, bool isStart) {
    return Row(
      children: [
        Icon(Icons.circle, size: 10, color: const Color(0xFF1A237E).withValues(alpha: isStart ? 1.0 : 0.5)),
        const SizedBox(width: 12),
        Text(
          time,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: isStart ? Colors.black87 : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusLabel(String label) {
    return Text(
      label,
      style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isDiscount = false, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isTotal ? const Color(0xFF1A237E) : Colors.grey,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 15 : 13,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: isDiscount ? Colors.red : (isTotal ? const Color(0xFF1A237E) : Colors.black87),
              fontSize: isTotal ? 15 : 13,
            ),
          ),
        ],
      ),
    );
  }

  String _buildInvoiceText(AppLocalizations l10n) {
    final format = DateFormat('HH:mm, dd/MM/yyyy');
    final now = DateFormat('HH:mm:ss, dd/MM/yyyy').format(DateTime.now());
    return '''
📄 ${l10n.translate('invoiceShareTitle')}
-------------------------------
${l10n.translate('bookingIdLabel')} #${booking.id}
${l10n.translate('printTimeLabel')} $now

📍 ${l10n.translate('parkingDetailsSection')}
${l10n.translate('parkingLotLabel')}: ${booking.lotName ?? 'Smart Park'}
${l10n.translate('slotLabel')}: ${l10n.translate('slotPrefix') ?? 'Ô số '}${booking.slotId}
${l10n.translate('licensePlateLabel')}: ${booking.vehiclePlateNumber}

⏰ ${l10n.translate('timeSection')}
${l10n.translate('timeIn')}: ${format.format(booking.startTime.toLocal())}
${l10n.translate('timeOut')}: ${format.format(booking.endTime.toLocal())}

💰 ${l10n.translate('paymentSection')}
${l10n.translate('totalMoneyLabel')} ${NumberFormat.decimalPattern().format(payment.amount)} ${l10n.translate('currencyShort')}
${l10n.translate('statusSuccessLabel')}
${l10n.translate('transactionIdLabel')} ${payment.transactionId}

${l10n.translate('thanksForUsingSmartPark')}
''';
  }

  Future<void> _shareInvoice(BuildContext context, AppLocalizations l10n) async {
    final text = _buildInvoiceText(l10n);
    await Share.share(text, subject: l10n.translate('invoiceSubject'));
  }

  Future<void> _downloadInvoice(BuildContext context, AppLocalizations l10n) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.translate('generatingInvoice')),
        duration: const Duration(seconds: 1),
      ),
    );
    
    // Giả lập tải về thành công
    await Future.delayed(const Duration(seconds: 1));
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.translate('saveInvoiceSuccess')),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildActionIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: const Color(0xFF1A237E), size: 24),
    );
  }
}
