import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:myhiking/presentation/pending_verification_screen/bloc/pending_verification_bloc.dart';
import 'package:myhiking/presentation/pending_verification_screen/pending_verification_screen.dart';
import 'package:myhiking/presentation/payment_upload_screen/bloc/payment_upload_bloc.dart';
import 'package:myhiking/presentation/payment_upload_screen/payment_upload_screen.dart';
import '../../../api/api_service.dart';
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
          text: "Incomplete".tr,
          buttonStyle: CustomButtonStyles.fillRed2,
          buttonTextStyle: CustomTextStyles.titleSmallOnPrimary,
          onPressed: () {
            final orderId = transactionlistItemModelObj.pesananId;
            if (orderId == null) {
              print('Pesanan ID tidak valid');
              return;
            }

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => BlocProvider(
                  create: (context) =>
                      PaymentUploadBloc(apiService: ApiService()),
                  child: PaymentUploadScreen(
                    orderId: orderId,
                    transaksiId: transactionlistItemModelObj.id,
                  ),
                ),
              ),
            );
          },
        );
        break;

      case 'unverified':
        statusButton = CustomElevatedButton(
          height: 26.h,
          width: 98.h,
          text: "Proses".tr,
          buttonStyle: CustomButtonStyles.outlineTeal1,
          buttonTextStyle: CustomTextStyles.titleSmallOnPrimary,
          onPressed: () {
            final orderId = transactionlistItemModelObj.pesananId;
            if (orderId == null) {
              print('Pesanan ID tidak valid');
              return;
            }

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => BlocProvider(
                  create: (context) =>
                      PendingVerificationBloc(apiService: ApiService()),
                  child: PendingVerificationScreen(orderId: orderId),
                ),
              ),
            );
          },
        );
        break;

      case 'verified':
        statusButton = CustomElevatedButton(
          height: 26.h,
          width: 98.h,
          text: "Selesai".tr,
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
        statusButton =
            Text('Status tidak dikenal', style: TextStyle(color: Colors.red));
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
