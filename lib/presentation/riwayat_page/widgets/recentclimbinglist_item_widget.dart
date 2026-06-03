import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/app_export.dart';
import '../../../theme/custom_button_style.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../models/recentclimbinglist_item_model.dart';

// ignore_for_file: must_be_immutable
class RecentclimbinglistItemWidget extends StatelessWidget {
  RecentclimbinglistItemWidget(
    this.recentclimbinglistItemModelObj, {
    super.key,
    this.onTapRecentclimbing,
  });

  final RecentclimbinglistItemModel recentclimbinglistItemModelObj;
  final VoidCallback? onTapRecentclimbing;

  /// Cek apakah pendakian ini overdue (Sedang Mendaki + tanggal_turun sudah lewat)
  bool get _isOverdue {
    final status = (recentclimbinglistItemModelObj.status ?? '').trim();
    if (status != 'Sedang Mendaki') return false;
    final turunStr = recentclimbinglistItemModelObj.tanggalTurun;
    if (turunStr == null || turunStr.isEmpty) return false;
    try {
      final tanggalTurun = DateTime.parse(turunStr);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final turunDate = DateTime(tanggalTurun.year, tanggalTurun.month, tanggalTurun.day);
      return turunDate.isBefore(today);
    } catch (_) {
      return false;
    }
  }

  int get _overdueDays {
    try {
      final tanggalTurun = DateTime.parse(recentclimbinglistItemModelObj.tanggalTurun!);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final turunDate = DateTime(tanggalTurun.year, tanggalTurun.month, tanggalTurun.day);
      return today.difference(turunDate).inDays;
    } catch (_) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Parsing tanggal dalam build method setelah objek tersedia
    DateTime tanggal =
        DateTime.parse(recentclimbinglistItemModelObj.tanggalNaik.toString());

    final overdue = _isOverdue;

    return GestureDetector(
      onTap: () {
        onTapRecentclimbing?.call();
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 12.h,
          vertical: 14.h,
        ),
        decoration: BoxDecoration(
          color: overdue ? const Color(0xFFFEF2F2) : theme.colorScheme.onPrimary,
          borderRadius: BorderRadiusStyle.roundedBorder6,
          border: overdue ? Border.all(color: const Color(0xFFEF4444), width: 1) : null,
          boxShadow: [
            BoxShadow(
              color: appTheme.blueGray40019,
              spreadRadius: 2.h,
              blurRadius: 2.h,
              offset: const Offset(4, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: EdgeInsets.only(top: 2.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            // Format tanggal dengan nama bulan
                            DateFormat('EEEE, dd MMMM yyyy', 'id_ID')
                                .format(tanggal),
                            style: theme.textTheme.titleSmall,
                          ),
                          Text(
                            recentclimbinglistItemModelObj.gunung.toString(),
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                _buildStatusButton(context),
              ],
            ),
            if (overdue) ...[
              SizedBox(height: 6.h),
              Row(
                children: [
                  Icon(Icons.schedule_rounded, size: 13.h, color: const Color(0xFFDC2626)),
                  SizedBox(width: 4.h),
                  Text(
                    'Melewati tanggal turun $_overdueDays hari',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFDC2626),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusButton(BuildContext context) {
    String status = recentclimbinglistItemModelObj.status ?? '';

    // Handle the status by displaying the correct button
    switch (status) {
      case 'Booking':
        return _buildBookingButton(context);
      case 'Sedang Mendaki':
        if (_isOverdue) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFDC2626).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Overdue',
              style: TextStyle(
                color: const Color(0xFFDC2626),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          );
        }
        return _buildMendakiButton(context);
      case 'Selesai':
        return _buildSelesaiButton(context);
      default:
        return SizedBox(); // Return an empty widget if no match
    }
  }

  // Button for "Booking" status
  Widget _buildBookingButton(BuildContext context) {
    return CustomElevatedButton(
      height: 26.h,
      width: 98.h,
      text: "Booking".tr,
      buttonStyle: CustomButtonStyles.outlineTeal1,
      buttonTextStyle: CustomTextStyles.titleMediumOnPrimary,
      onPressed: () {
        // Navigate to ticket action screen
        onTapRecentclimbing?.call();
      },
    );
  }

  // Button for "Sedang Mendaki" status
  Widget _buildMendakiButton(BuildContext context) {
    return CustomElevatedButton(
      height: 26.h,
      width: 98.h,
      text: "Mendaki".tr,
      buttonStyle: CustomButtonStyles.outlineTeal,
      buttonTextStyle: CustomTextStyles.titleMediumOnPrimary,
      onPressed: () {
        // Navigate to ticket action screen with panic button
        onTapRecentclimbing?.call();
      },
    );
  }

  // Button for "Selesai" status
  Widget _buildSelesaiButton(BuildContext context) {
    return CustomElevatedButton(
      height: 26.h,
      width: 98.h,
      text: "Selesai".tr,
      buttonStyle: CustomButtonStyles.outlineTeal2,
      buttonTextStyle: CustomTextStyles.titleMediumOnPrimary,
      onPressed: () {
        // Navigate to ticket action screen
        onTapRecentclimbing?.call();
      },
    );
  }
}
