import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/app_export.dart';
import '../../../theme/custom_button_style.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../models/tiket_saya_model.dart';

class ActiveTicketItemWidget extends StatelessWidget {
  final TiketItemModel model;
  final VoidCallback? onTap;

  const ActiveTicketItemWidget({
    super.key,
    required this.model,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    DateTime? tanggal;
    try {
      tanggal = DateTime.parse(model.tanggalNaik ?? '');
    } catch (_) {}

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.h),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12.h,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Mountain icon container
            Container(
              width: 48.h,
              height: 48.h,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _statusGradientStart(model.status),
                    _statusGradientEnd(model.status),
                  ],
                ),
                borderRadius: BorderRadius.circular(12.h),
              ),
              child: Icon(
                _statusIcon(model.status),
                color: Colors.white,
                size: 24.h,
              ),
            ),
            SizedBox(width: 14.h),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    model.gunung ?? 'Gunung',
                    style: TextStyle(
                      fontSize: 15.fSize,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A2E),
                      letterSpacing: 0.1,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  if (model.jalur != null && model.jalur!.isNotEmpty)
                    Text(
                      model.jalur!,
                      style: TextStyle(
                        fontSize: 12.fSize,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  SizedBox(height: 3.h),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 12.h,
                        color: const Color(0xFF9CA3AF),
                      ),
                      SizedBox(width: 4.h),
                      Text(
                        tanggal != null
                            ? DateFormat('dd MMM yyyy', 'id_ID')
                                .format(tanggal)
                            : '-',
                        style: TextStyle(
                          fontSize: 12.fSize,
                          color: const Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Status badge
            _buildStatusBadge(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    final status = model.status ?? '';
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case 'Bayar':
        bgColor = const Color(0xFFFEE2E2);
        textColor = const Color(0xFFDC2626);
        label = 'Bayar';
        break;
      case 'Booking':
        bgColor = const Color(0xFFDCFCE7);
        textColor = const Color(0xFF16A34A);
        label = 'Booking';
        break;
      case 'Sedang Mendaki':
        bgColor = const Color(0xFFFEF3C7);
        textColor = const Color(0xFFD97706);
        label = 'Mendaki';
        break;
      default:
        bgColor = const Color(0xFFF3F4F6);
        textColor = const Color(0xFF6B7280);
        label = status.isNotEmpty ? status : '-';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.h, vertical: 6.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20.h),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12.fSize,
          fontWeight: FontWeight.w700,
          color: textColor,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  IconData _statusIcon(String? status) {
    switch (status) {
      case 'Bayar':
        return Icons.payment_rounded;
      case 'Booking':
        return Icons.confirmation_number_outlined;
      case 'Sedang Mendaki':
        return Icons.terrain_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }

  Color _statusGradientStart(String? status) {
    switch (status) {
      case 'Bayar':
        return const Color(0xFFEF4444);
      case 'Booking':
        return const Color(0xFF22C55E);
      case 'Sedang Mendaki':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF6B7280);
    }
  }

  Color _statusGradientEnd(String? status) {
    switch (status) {
      case 'Bayar':
        return const Color(0xFFF87171);
      case 'Booking':
        return const Color(0xFF4ADE80);
      case 'Sedang Mendaki':
        return const Color(0xFFFBBF24);
      default:
        return const Color(0xFF9CA3AF);
    }
  }
}
