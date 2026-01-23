import 'package:flutter/material.dart';
import 'package:myhiking/presentation/route_screen/models/route_model.dart';
import '../../../core/app_export.dart';
// ignore_for_file: must_be_immutable
class RoutelistsectionItemWidget extends StatelessWidget {
  final RouteModel routeModel; // Model data untuk item

  RoutelistsectionItemWidget(this.routeModel, {super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 145.h,
        padding: EdgeInsets.symmetric(
          horizontal: 20.h,
          vertical: 12.h,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.onPrimary,
          borderRadius: BorderRadiusStyle.roundedBorder10,
          boxShadow: [
            BoxShadow(
              color: appTheme.black900.withOpacity(0.08),
              spreadRadius: 1.h,
              blurRadius: 2.h,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 8.h),
            // Menampilkan nama jalur
            Text(
              routeModel.name,
              style: CustomTextStyles.labelLargeInterGray500,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            // Menampilkan jarak
            Text(
              "${routeModel.distance} km",
              style: CustomTextStyles.labelMediumPrimary,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            // Menampilkan nama gunung jika diperlukan
            Text(
              routeModel.gunung.nama,
              style: CustomTextStyles.bodySmallGray50003,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}