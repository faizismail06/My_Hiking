import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/app_export.dart';
import '../models/tiket_saya_model.dart';

class ActiveTicketItemWidget extends StatelessWidget {
  final TiketItemModel model;
  final VoidCallback? onTap;
  final bool isPendingPaymentCard;
  final Duration? pendingRemainingTime;
  final bool isCountdownSyncing;
  final VoidCallback? onPayNowTap;
  final bool isOverdueCard;
  final int overdueDays;

  const ActiveTicketItemWidget({
    super.key,
    required this.model,
    this.onTap,
    this.isPendingPaymentCard = false,
    this.pendingRemainingTime,
    this.isCountdownSyncing = false,
    this.onPayNowTap,
    this.isOverdueCard = false,
    this.overdueDays = 0,
  });

  @override
  Widget build(BuildContext context) {
    DateTime? tanggal;
    try {
      tanggal = DateTime.parse(model.tanggalNaik ?? '');
    } catch (_) {}

    if (isPendingPaymentCard) {
      return GestureDetector(
        onTap: onTap,
        child: _buildPendingPaymentCard(tanggal),
      );
    }

    if (isOverdueCard) {
      return GestureDetector(
        onTap: onTap,
        child: _buildOverdueCard(tanggal),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: _buildRegularTicketCard(tanggal),
    );
  }

  Widget _buildRegularTicketCard(DateTime? tanggal) {
    return Container(
      padding: EdgeInsets.all(16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.h),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12.h,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
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
          Expanded(
            child: _buildTicketInfo(tanggal),
          ),
          _buildStatusBadge(),
        ],
      ),
    );
  }

  Widget _buildPendingPaymentCard(DateTime? tanggal) {
    final isSyncing = isCountdownSyncing || pendingRemainingTime == null;
    final remaining = pendingRemainingTime ?? Duration.zero;
    final isExpired = !isSyncing && remaining <= Duration.zero;

    return Container(
      padding: EdgeInsets.all(14.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.h),
        border: Border.all(color: const Color(0xFFF59E72), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10.h,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54.h,
                height: 54.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14.h),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFEF4444), Color(0xFFF87171)],
                  ),
                ),
                child: Icon(
                  Icons.confirmation_number_rounded,
                  color: Colors.white,
                  size: 30.h,
                ),
              ),
              SizedBox(width: 12.h),
              Expanded(
                child: _buildTicketInfo(tanggal),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          if (isSyncing)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 14.h,
                  height: 14.h,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8.h),
                Text(
                  'Sinkronisasi waktu...',
                  style: TextStyle(
                    fontSize: 13.fSize,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Sisa Waktu: ',
                  style: TextStyle(
                    fontSize: 14.fSize,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827),
                  ),
                ),
                Text(
                  _formatDuration(remaining),
                  style: TextStyle(
                    fontSize: 16.fSize,
                    fontWeight: FontWeight.w800,
                    color: isExpired
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFFF97316),
                  ),
                ),
                SizedBox(width: 6.h),
                Icon(
                  isExpired ? Icons.timer_off_rounded : Icons.lock_rounded,
                  color: isExpired
                      ? const Color(0xFF9CA3AF)
                      : const Color(0xFFF97316),
                  size: 16.h,
                ),
              ],
            ),
          SizedBox(height: 12.h),
          SizedBox(
            width: double.infinity,
            height: 44.h,
            child: ElevatedButton(
              onPressed: isExpired ? null : onPayNowTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: isExpired
                    ? const Color(0xFFE5E7EB)
                    : const Color(0xFFF97316),
                foregroundColor:
                    isExpired ? const Color(0xFF9CA3AF) : Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22.h),
                ),
              ),
              child: Text(
                isExpired ? 'Waktu Habis' : 'Bayar Sekarang',
                style: TextStyle(
                  fontSize: 15.fSize,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverdueCard(DateTime? tanggal) {
    return Container(
      padding: EdgeInsets.all(14.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.h),
        border: Border.all(color: const Color(0xFFEF4444), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withValues(alpha: 0.10),
            blurRadius: 12.h,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 48.h,
                height: 48.h,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
                  ),
                  borderRadius: BorderRadius.circular(12.h),
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.white,
                  size: 24.h,
                ),
              ),
              SizedBox(width: 14.h),
              Expanded(
                child: _buildTicketInfo(tanggal),
              ),
              _buildOverdueBadge(),
            ],
          ),
          SizedBox(height: 10.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12.h, vertical: 8.h),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(10.h),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.schedule_rounded,
                  size: 16.h,
                  color: const Color(0xFFDC2626),
                ),
                SizedBox(width: 8.h),
                Expanded(
                  child: Text(
                    'Pendakian sudah melewati tanggal turun $overdueDays hari yang lalu. Segera lakukan check-out.',
                    style: TextStyle(
                      fontSize: 11.fSize,
                      color: const Color(0xFFDC2626),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverdueBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.h, vertical: 6.h),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(20.h),
      ),
      child: Text(
        'Overdue',
        style: TextStyle(
          fontSize: 12.fSize,
          fontWeight: FontWeight.w700,
          color: const Color(0xFFDC2626),
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildTicketInfo(DateTime? tanggal) {
    return Column(
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
                  ? DateFormat('dd MMM yyyy', 'id_ID').format(tanggal)
                  : '-',
              style: TextStyle(
                fontSize: 12.fSize,
                color: const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final safeDuration = duration.isNegative ? Duration.zero : duration;
    final hours = safeDuration.inHours.toString().padLeft(2, '0');
    final minutes =
        safeDuration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds =
        safeDuration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
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
