import 'package:flutter/material.dart';
import '../../../core/app_export.dart';
import '../../../widgets/custom_radio_button.dart';
import '../models/paymentmethodslist_item_model.dart';

class PaymentmethodslistItemWidget extends StatelessWidget {
  const PaymentmethodslistItemWidget(
    this.paymentmethodslistItemModelObj, {
    super.key,
    required this.isSelected, // Parameter isSelected untuk status terpilih
    this.onTapRadioGroup,
  });

  final PaymentmethodslistItemModel paymentmethodslistItemModelObj;
  final bool isSelected;
  final ValueChanged<String>? onTapRadioGroup; // Menggunakan ValueChanged

  @override
  Widget build(BuildContext context) {
    // Menggunakan GestureDetector untuk mendeteksi klik pada elemen
    return GestureDetector(
      onTap: () {
        onTapRadioGroup
            ?.call(paymentmethodslistItemModelObj.namaPayment.toString());
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 12.h,
          vertical: 14.h,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.onPrimary,
          borderRadius: BorderRadius.circular(20), // Rounded corner
          border: Border.all(
            color: theme.colorScheme.primary,
            width: 0.75.h,
          ),
          boxShadow: [
            BoxShadow(
              color: appTheme.blueGray40019,
              spreadRadius: 2.h,
              blurRadius: 1.h,
              offset: const Offset(4, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Gambar metode pembayaran (Gopay/BCA/BRI)
            CustomImageView(
              imagePath: paymentmethodslistItemModelObj
                  .imagePath, // Menggunakan getter imagePath
              height: 45.h,
              width: 45.h,
              margin: EdgeInsets.only(right: 12.h),
            ),

            // Nama metode pembayaran
            Padding(
              padding: EdgeInsets.only(bottom: 6.h),
              child: Text(
                paymentmethodslistItemModelObj.namaPayment ?? '',
                style: CustomTextStyles.titleSmallGray900,
              ),
            ),
            const Spacer(),
            // CustomRadioButton untuk memilih metode pembayaran
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 17.h,
                  height: 17.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.transparent,
                    border: Border.all(
                      color: theme.colorScheme.primary,
                      width: 1.5.h,
                    ),
                  ),
                ),
                CustomRadioButton(
                  value: paymentmethodslistItemModelObj
                      .namaPayment, // Nilai unik sebagai value
                  groupValue: isSelected
                      ? paymentmethodslistItemModelObj.namaPayment
                      : null, // Cocokkan dengan yang dipilih
                  onChange: (value) {
                    if (onTapRadioGroup != null) {
                      onTapRadioGroup!(value); // Panggil callback saat dipilih
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
