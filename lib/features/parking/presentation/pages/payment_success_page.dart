import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
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
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.translate('generatingInvoice')),
          duration: const Duration(seconds: 1),
        ),
      );

      final pdfData = await _generatePdf(PdfPageFormat.a4, l10n);
      final filename = 'HoaDon_SmartPark_${booking.id}.pdf';
      String savePath;

      if (Platform.isAndroid) {
        // Try saving to public Downloads folder on Android
        Directory? downloadDir = Directory('/storage/emulated/0/Download');
        if (!await downloadDir.exists()) {
          downloadDir = await getExternalStorageDirectory();
        }
        savePath = '${downloadDir?.path}/$filename';
      } else {
        // For iOS, save to Application Documents directory
        final dir = await getApplicationDocumentsDirectory();
        savePath = '${dir.path}/$filename';
      }

      final file = File(savePath);
      try {
        await file.writeAsBytes(pdfData);
      } catch (e) {
        // Fallback to app directory if permission denied
        if (Platform.isAndroid) {
          final fallbackDir = await getExternalStorageDirectory();
          savePath = '${fallbackDir?.path}/$filename';
          final fallbackFile = File(savePath);
          await fallbackFile.writeAsBytes(pdfData);
        } else {
          rethrow;
        }
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.translate('saveInvoiceSuccess')}\nĐã lưu tại: $savePath'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi xuất PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<Uint8List> _generatePdf(PdfPageFormat format, AppLocalizations l10n) async {
    final pdf = pw.Document(version: PdfVersion.pdf_1_5, compress: true);
    final font = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();
    final fontBlack = await PdfGoogleFonts.robotoBlack();

    final dateFormat = DateFormat('HH:mm, dd/MM/yyyy');
    final duration = booking.endTime.difference(booking.startTime);

    pdf.addPage(
      pw.Page(
        pageFormat: format,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('SMART PARK', style: pw.TextStyle(font: fontBlack, fontSize: 24, color: PdfColors.indigo)),
                    pw.Text('${l10n.translate('billNo')} 00${booking.id}', style: pw.TextStyle(font: fontBold, fontSize: 14, color: PdfColors.grey700)),
                  ]
                )
              ),
              pw.SizedBox(height: 20),
              pw.Center(
                child: pw.Text(l10n.translate('invoiceTitle').toUpperCase(), style: pw.TextStyle(font: fontBlack, fontSize: 28, color: PdfColors.indigo900)),
              ),
              pw.Center(
                child: pw.Text(l10n.translate('paymentSuccessTitle'), style: pw.TextStyle(font: fontBold, fontSize: 16, color: PdfColors.green)),
              ),
              pw.SizedBox(height: 30),
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Text(l10n.translate('parkingInfoTitle'), style: pw.TextStyle(font: fontBold, fontSize: 18, color: PdfColors.indigo800)),
              pw.SizedBox(height: 10),
              _buildPdfRow(l10n.translate('parkingLotLabel'), booking.lotName ?? 'Smart Park', font, fontBold),
              _buildPdfRow(l10n.translate('slotLabel'), '${l10n.translate('slotPrefix') ?? 'Ô số '}${booking.slotId}', font, fontBold),
              _buildPdfRow(l10n.translate('licensePlateLabel'), booking.vehiclePlateNumber ?? 'N/A', font, fontBold),
              
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 10),
              
              pw.Text(l10n.translate('timeTitle'), style: pw.TextStyle(font: fontBold, fontSize: 18, color: PdfColors.indigo800)),
              pw.SizedBox(height: 10),
              _buildPdfRow(l10n.translate('timeIn'), dateFormat.format(booking.startTime.toLocal()), font, fontBold),
              _buildPdfRow(l10n.translate('timeOut'), dateFormat.format(booking.endTime.toLocal()), font, fontBold),
              _buildPdfRow('Thời lượng', '${duration.inHours} ${l10n.translate('hourText')}', font, fontBold),

              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 10),

              pw.Text(l10n.translate('paymentDetailsTitle'), style: pw.TextStyle(font: fontBold, fontSize: 18, color: PdfColors.indigo800)),
              pw.SizedBox(height: 10),
              _buildPdfRow(l10n.translate('parkingFeeLabel'), '${payment.amount.toStringAsFixed(0)} ${l10n.translate('currencyShort')}', font, fontBold),
              _buildPdfRow(l10n.translate('discount'), '-0 ${l10n.translate('currencyShort')}', font, fontBold, valueColor: PdfColors.red),
              pw.SizedBox(height: 5),
              _buildPdfRow(l10n.translate('totalAmount'), '${payment.amount.toStringAsFixed(0)} ${l10n.translate('currencyShort')}', font, fontBlack, isTotal: true),

              pw.Spacer(),
              pw.Divider(),
              pw.Center(
                child: pw.Text(l10n.translate('thanksForUsingSmartPark'), style: pw.TextStyle(font: font, fontSize: 12, color: PdfColors.grey600)),
              ),
              pw.SizedBox(height: 5),
              pw.Center(
                child: pw.Text('Ngày in: ${DateFormat('HH:mm:ss, dd/MM/yyyy').format(DateTime.now())}', style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey500)),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildPdfRow(String label, String value, pw.Font font, pw.Font valueFont, {PdfColor? valueColor, bool isTotal = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(font: font, fontSize: isTotal ? 16 : 14, color: isTotal ? PdfColors.indigo900 : PdfColors.grey700)),
          pw.Text(value, style: pw.TextStyle(font: valueFont, fontSize: isTotal ? 16 : 14, color: valueColor ?? (isTotal ? PdfColors.indigo900 : PdfColors.black))),
        ],
      ),
    );
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
