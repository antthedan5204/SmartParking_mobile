import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../domain/entities/booking.dart';
import '../../domain/entities/payment.dart';
import '../../../../core/constants/app_text_styles.dart';

class PaymentSuccessPage extends StatelessWidget {
  final Booking booking;
  final Payment payment;

  const PaymentSuccessPage({
    super.key,
    required this.booking,
    required this.payment,
  });

  @override
  Widget build(BuildContext context) {
    final format = DateFormat('hh:mm a  dd:MM:yyyy');
    final duration = booking.endTime.difference(booking.startTime);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF1A237E)),
          onPressed: () => context.go('/home'),
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
                          'Bill No. 00${booking.id}',
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
                    'HOÁ ĐƠN',
                    style: AppTextStyles.heading2.copyWith(
                      color: const Color(0xFF1A237E),
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Thanh toán thành công',
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Divider(),
                  ),

                  // Parking Details
                  _buildSectionTitle('Thông tin gửi xe'),
                  _buildInfoRow('Bãi đỗ', booking.lotName ?? 'Smart Park'),
                  _buildInfoRow('Vị trí', 'Ô số ${booking.slotId}'),
                  _buildInfoRow('Biển số xe', booking.vehiclePlateNumber ?? 'N/A'),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Divider(),
                  ),

                  // Time Duration
                  _buildSectionTitle('Thời gian'),
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
                        _buildStatusLabel('Vào'),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${duration.inHours} Giờ',
                            style: const TextStyle(
                              color: Color(0xFF6366F1),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        _buildStatusLabel('Ra'),
                      ],
                    ),
                  ),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Divider(),
                  ),

                  // Payment Details
                  _buildSectionTitle('Chi tiết thanh toán'),
                  _buildPriceRow('Phí gửi xe', '${payment.amount.toStringAsFixed(0)} đ'),
                  _buildPriceRow('Khuyến mãi', '-0 đ', isDiscount: true),
                  _buildPriceRow('Tổng cộng', '${payment.amount.toStringAsFixed(0)} đ', isTotal: true),
                  
                  const SizedBox(height: 32),
                  // Action Icons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 60),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => _downloadInvoice(context),
                          child: _buildActionIcon(Icons.file_download_outlined),
                        ),
                        GestureDetector(
                          onTap: () => _shareInvoice(context),
                          child: _buildActionIcon(Icons.share_outlined),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Cảm ơn bạn đã sử dụng dịch vụ của chúng tôi!',
                    style: TextStyle(color: Colors.grey, fontSize: 10),
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
                onPressed: () => context.go('/home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text(
                  'ĐÓNG',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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

  String _buildInvoiceText() {
    final format = DateFormat('HH:mm, dd/MM/yyyy');
    final now = DateFormat('HH:mm:ss, dd/MM/yyyy').format(DateTime.now());
    return '''
📄 HÓA ĐƠN GỬI XE - SMART PARK
-------------------------------
Mã đơn: #${booking.id}
Thời gian in: $now

📍 CHI TIẾT BÃI ĐỖ
Bãi đỗ: ${booking.lotName ?? 'Smart Park'}
Vị trí: Ô số ${booking.slotId}
Biển số xe: ${booking.vehiclePlateNumber}

⏰ THỜI GIAN
Vào: ${format.format(booking.startTime.toLocal())}
Ra: ${format.format(booking.endTime.toLocal())}

💰 THANH TOÁN
Tổng tiền: ${NumberFormat.currency(locale: 'vi_VN', symbol: 'VNĐ').format(payment.amount)}
Trạng thái: THÀNH CÔNG
Mã giao dịch: ${payment.transactionId}

Cảm ơn bạn đã sử dụng dịch vụ của Smart Park!
''';
  }

  Future<void> _shareInvoice(BuildContext context) async {
    final text = _buildInvoiceText();
    await Share.share(text, subject: 'Hóa đơn gửi xe Smart Park');
  }

  Future<void> _downloadInvoice(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đang tạo file hóa đơn...'),
        duration: Duration(seconds: 1),
      ),
    );
    
    // Giả lập tải về thành công
    await Future.delayed(const Duration(seconds: 1));
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã lưu hóa đơn vào máy thành công!'),
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
