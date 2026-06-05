import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:myhiking/presentation/payment_method_screen/payment_method_screen.dart';
import '../../../core/app_export.dart';
import '../../../theme/custom_button_style.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../models/transactionlist_item_model.dart';

class TransactionlistItemWidget extends StatelessWidget {
  TransactionlistItemWidget(
    this.transactionlistItemModelObj, {
    super.key,
    this.onTapRecentclimbing,
  });
  final TransactionItemModel transactionlistItemModelObj;
  final VoidCallback? onTapRecentclimbing;
  @override
  Widget build(BuildContext context) {
    DateTime? tanggal;
    try {
      tanggal =
          DateTime.parse(transactionlistItemModelObj.waktuPembayaran ?? '');
    } catch (_) {
      tanggal = null;
    }

    String status = transactionlistItemModelObj.status?.toLowerCase() ?? '';

    Widget statusButton;
    switch (status) {
      case 'incomplete':
        statusButton = CustomElevatedButton(
          height: 26.h,
          width: 98.h,
          text: "Bayar",
          buttonStyle: CustomButtonStyles.fillRed2,
          buttonTextStyle: CustomTextStyles.titleSmallOnPrimary,
          onPressed: () {
            final orderId = transactionlistItemModelObj.pesananId;
            if (orderId == null) {
              print('Pesanan ID tidak valid');
              return;
            }

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PaymentMethodScreen(orderId: orderId),
              ),
            );
          },
        );
        break;

      case 'complete':
        statusButton = CustomElevatedButton(
          height: 26.h,
          width: 98.h,
          text: "Lunas",
          buttonStyle: CustomButtonStyles.outlineTeal,
          buttonTextStyle: CustomTextStyles.titleSmallOnPrimary,
          onPressed: () {
            final orderId = transactionlistItemModelObj.pesananId;
            if (orderId == null) {
              print('Pesanan ID tidak valid');
              return;
            }

            NavigatorService.pushNamed(
              AppRoutes.ticketScreen,
              arguments: orderId,
            );
          },
        );
        break;

      default:
        statusButton = CustomElevatedButton(
          height: 26.h,
          width: 98.h,
          text: "Bayar",
          buttonStyle: CustomButtonStyles.fillRed2,
          buttonTextStyle: CustomTextStyles.titleSmallOnPrimary,
          onPressed: () {
            final orderId = transactionlistItemModelObj.pesananId;
            if (orderId != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PaymentMethodScreen(orderId: orderId),
                ),
              );
            }
          },
        );
    }

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
          color: theme.colorScheme.onPrimary ?? Colors.white,
          borderRadius: BorderRadiusStyle.roundedBorder6,
          boxShadow: [
            BoxShadow(
              color: appTheme.blueGray40019 ?? Colors.grey.withOpacity(0.2),
              spreadRadius: 2.h,
              blurRadius: 2.h,
              offset: const Offset(4, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tanggal != null
                        ? DateFormat('EEEE, dd MMMM yyyy', 'id_ID')
                            .format(tanggal)
                        : 'Anda Belum Membayar',
                    style: theme.textTheme.titleSmall,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    transactionlistItemModelObj.gunung ??
                        'Gunung tidak diketahui',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            statusButton,
          ],
        ),
      ),
    );
  }
}
