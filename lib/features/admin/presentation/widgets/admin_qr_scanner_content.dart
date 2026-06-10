import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../parking/domain/entities/booking.dart';
import '../providers/booking_management_provider.dart';

class AdminQrScannerContent extends ConsumerStatefulWidget {
  const AdminQrScannerContent({super.key});

  @override
  ConsumerState<AdminQrScannerContent> createState() =>
      _AdminQrScannerContentState();
}

class _AdminQrScannerContentState extends ConsumerState<AdminQrScannerContent> {
  bool _isProcessing = false;

  void _resumeScanner() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    });
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code != null) {
      setState(() {
        _isProcessing = true;
      });

      // Process the QR code
      if (mounted) {
        if (code.startsWith('BOOKING:')) {
          final bookingIdStr = code.split(':')[1];
          final bookingId = int.tryParse(bookingIdStr);
          if (bookingId != null) {
            final bookings = ref.read(bookingManagementProvider).bookings;
            try {
              final booking = bookings.firstWhere((b) => b.id == bookingId);

              if (booking.status == BookingStatus.confirmed ||
                  booking.status == BookingStatus.checkedIn) {
                final isCheckIn = booking.status == BookingStatus.confirmed;
                final title = isCheckIn
                    ? 'Xác nhận Check-in'
                    : 'Xác nhận Check-out';

                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    title: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isCheckIn 
                              ? 'Bạn có chắc chắn muốn cho xe này vào bãi?'
                              : 'Bạn có chắc chắn muốn cho xe này ra bãi?',
                          style: const TextStyle(fontSize: 16, color: Colors.black87),
                        ),
                        const SizedBox(height: 20),
                        Text('Mã đơn: #${booking.id}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('Biển số: ${booking.vehiclePlateNumber ?? "Không rõ"}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        const SizedBox(height: 8),
                        Text('Ô đỗ: ${booking.slotNumber ?? "Không rõ"}', style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _resumeScanner();
                        },
                        child: const Text('HỦY', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(ctx);

                          final success = isCheckIn
                              ? await ref
                                    .read(bookingManagementProvider.notifier)
                                    .checkInBooking(bookingId)
                              : await ref
                                    .read(bookingManagementProvider.notifier)
                                    .completeBooking(bookingId);

                          if (success && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${isCheckIn ? "Check-in" : "Check-out"} thành công đơn #${booking.id}!',
                                ),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          } else if (mounted) {
                            final error =
                                ref
                                    .read(bookingManagementProvider)
                                    .errorMessage ??
                                'Lỗi thao tác';
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(error),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                          _resumeScanner();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Xác nhận'),
                      ),
                    ],
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Đơn #${booking.id} đang ở trạng thái không hợp lệ.',
                    ),
                    backgroundColor: Colors.orange,
                  ),
                );
                _resumeScanner();
              }
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Không tìm thấy đơn đặt hoặc bạn không có quyền!',
                  ),
                  backgroundColor: Colors.red,
                ),
              );
              _resumeScanner();
            }
          } else {
            _resumeScanner();
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mã QR không hợp lệ!'),
              backgroundColor: Colors.red,
            ),
          );
          _resumeScanner();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text('Quét mã QR', style: AppTextStyles.heading2),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Hướng camera vào mã QR của đơn đặt để check-in/check-out tự động.',
            style: AppTextStyles.body1.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  MobileScanner(onDetect: _onDetect),
                  // Frame QR
                  Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.8),
                        width: 4,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  if (_isProcessing)
                    Container(
                      color: Colors.black.withValues(alpha: 0.7),
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: AppColors.primary),
                            SizedBox(height: 16),
                            Text(
                              'Đang xử lý...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
