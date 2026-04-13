import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/app_export.dart';
import '../models/tiket_saya_model.dart';

class HikingRecordCardWidget extends StatelessWidget {
  final TiketItemModel model;
  final int index;

  const HikingRecordCardWidget({
    super.key,
    required this.model,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    DateTime? tanggalNaik;
    DateTime? tanggalTurun;
    try {
      tanggalNaik = DateTime.parse(model.tanggalNaik ?? '');
    } catch (_) {}
    try {
      tanggalTurun = DateTime.parse(model.tanggalTurun ?? '');
    } catch (_) {}

    // Calculate duration
    String durationText = '';
    if (tanggalNaik != null && tanggalTurun != null) {
      final duration = tanggalTurun.difference(tanggalNaik);
      if (duration.inDays > 0) {
        durationText = '${duration.inDays} hari';
      } else {
        durationText = '${duration.inHours} jam';
      }
    }

    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.white,
            const Color(0xFFF0FDF4).withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(18.h),
        border: Border.all(
          color: const Color(0xFFE5E7EB).withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16.h,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18.h),
        child: Stack(
          children: [
            // Decorative accent
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 4.h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF059669),
                      const Color(0xFF34D399),
                      const Color(0xFF6EE7B7),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16.h, 18.h, 16.h, 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Mountain name + number
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Mountain icon
                      Container(
                        width: 44.h,
                        height: 44.h,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF059669),
                              Color(0xFF10B981),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12.h),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.landscape_rounded,
                            color: Colors.white,
                            size: 24.h,
                          ),
                        ),
                      ),
                      SizedBox(width: 12.h),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              model.gunung ?? 'Gunung',
                              style: TextStyle(
                                fontSize: 16.fSize,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1A1A2E),
                                letterSpacing: 0.1,
                              ),
                            ),
                            if (model.jalur != null &&
                                model.jalur!.isNotEmpty) ...[
                              SizedBox(height: 2.h),
                              Text(
                                'Via ${model.jalur}',
                                style: TextStyle(
                                  fontSize: 12.fSize,
                                  color: const Color(0xFF6B7280),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Completed badge
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 10.h, vertical: 5.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20.h),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: const Color(0xFF059669),
                              size: 14.h,
                            ),
                            SizedBox(width: 4.h),
                            Text(
                              'Selesai',
                              style: TextStyle(
                                fontSize: 11.fSize,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF059669),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),
                  // Info row
                  Container(
                    padding: EdgeInsets.all(12.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12.h),
                    ),
                    child: Row(
                      children: [
                        _buildInfoChip(
                          Icons.calendar_today_rounded,
                          tanggalNaik != null
                              ? DateFormat('dd MMM yyyy', 'id_ID')
                                  .format(tanggalNaik)
                              : '-',
                          'Tanggal',
                        ),
                        Container(
                          width: 1,
                          height: 32.h,
                          color: const Color(0xFFE5E7EB),
                        ),
                        if (durationText.isNotEmpty) ...[
                          _buildInfoChip(
                            Icons.timer_outlined,
                            durationText,
                            'Durasi',
                          ),
                          Container(
                            width: 1,
                            height: 32.h,
                            color: const Color(0xFFE5E7EB),
                          ),
                        ],
                        _buildInfoChip(
                          Icons.receipt_long_rounded,
                          '#${model.id ?? '-'}',
                          'ID Pesanan',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            icon,
            size: 16.h,
            color: const Color(0xFF059669),
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.fSize,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A2E),
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10.fSize,
              color: const Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }
}
