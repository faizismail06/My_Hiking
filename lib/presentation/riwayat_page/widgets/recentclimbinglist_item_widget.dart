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

  @override
  Widget build(BuildContext context) {
    // Parsing tanggal dalam build method setelah objek tersedia
    DateTime tanggal =
        DateTime.parse(recentclimbinglistItemModelObj.tanggalNaik.toString());

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
          color: theme.colorScheme.onPrimary,
          borderRadius: BorderRadiusStyle.roundedBorder6,
          boxShadow: [
            BoxShadow(
              color: appTheme.blueGray40019,
              spreadRadius: 2.h,
              blurRadius: 2.h,
              offset: const Offset(4, 4),
            ),
          ],
        ),
        child: Row(
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
