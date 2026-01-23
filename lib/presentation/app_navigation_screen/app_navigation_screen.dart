import 'package:flutter/material.dart';
import 'package:myhiking/presentation/pop_up_data_diri_lengkap_dialog/pop_up_data_diri_lengkap_dialog.dart';
import '../../core/app_export.dart';
import '../pop_up_pw_diganti_dialog/pop_up_pw_diganti_dialog.dart';
import '../ubahpw_dialog/ubahpw_dialog.dart';
import 'bloc/app_navigation_bloc.dart';
import 'models/app_navigation_model.dart';

class AppNavigationScreen extends StatelessWidget {
  const AppNavigationScreen({super.key});

  static Widget builder(BuildContext context) {
    return BlocProvider<AppNavigationBloc>(
      create: (context) => AppNavigationBloc(AppNavigationState(
        appNavigationModelObj: const AppNavigationModel(),
      ))
        ..add(AppNavigationInitialEvent()),
      child: const AppNavigationScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppNavigationBloc, AppNavigationState>(
      builder: (context, state) {
        return SafeArea(
          child: Scaffold(
            backgroundColor: const Color(0xFFFFFFFF),
            body: SizedBox(
              width: double.maxFinite,
              child: Column(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFFFFF),
                    ),
                    child: Column(
                      children: [
                        SizedBox(height: 10.h),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.h),
                          child: Text(
                            "App Navigation",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: const Color(0xFF000000),
                              fontSize: 20.fSize,
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                        SizedBox(height: 10.h),
                        Padding(
                          padding: EdgeInsets.only(left: 20.h),
                          child: Text(
                            "Untuk Ngecek tampilan menyeluruh.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: const Color(0xFF888888),
                              fontSize: 16.fSize,
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                        SizedBox(height: 5.h),
                        Divider(
                          height: 1.h,
                          thickness: 1.h,
                          color: const Color(0xFF000000),
                        )
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFFFFF),
                        ),
                        child: Column(
                          children: [
                            _buildScreenTitle(
                              context,
                              screenTitle: "Landing",
                              onTapScreenTitle: () =>
                                  OnTapScreenTitle(AppRoutes.landingScreen),
                            ),
                            _buildScreenTitle(
                              context,
                              screenTitle: "Login",
                              onTapScreenTitle: () =>
                                  OnTapScreenTitle(AppRoutes.loginScreen),
                            ),
                            _buildScreenTitle(
                              context,
                              screenTitle: "Regist",
                              onTapScreenTitle: () =>
                                  OnTapScreenTitle(AppRoutes.registScreen),
                            ),
                            _buildScreenTitle(
                              context,
                              screenTitle: "Reset Kirim Email",
                              onTapScreenTitle: () => OnTapScreenTitle(
                                  AppRoutes.resetKirimEmailScreen),
                            ),
                            _buildScreenTitle(
                              context,
                              screenTitle: "Kode Verifikasi",
                              onTapScreenTitle: () => OnTapScreenTitle(
                                  AppRoutes.kodeVerifikasiScreen),
                            ),
                            _buildScreenTitle(
                              context,
                              screenTitle: "Reset Page Two",
                              onTapScreenTitle: () => OnTapScreenTitle(
                                  AppRoutes.resetPageTwoScreen),
                            ),
                            _buildScreenTitle(
                              context,
                              screenTitle: "pop up pw diganti - Dialog",
                              onTapScreenTitle: () => onTapDialogTitle(context,
                                  PopUpPwDigantiDialog.builder(context)),
                            ),
                            _buildScreenTitle(
                              context,
                              screenTitle: "BOOKING",
                              onTapScreenTitle: () =>
                                  OnTapScreenTitle(AppRoutes.bookingScreen),
                            ),
                            _buildScreenTitle(
                              context,
                              screenTitle: "Pilihan bank pembayaran",
                              onTapScreenTitle: () => OnTapScreenTitle(
                                  AppRoutes.pilihanBankPembayaranScreen),
                            ),
                            _buildScreenTitle(
                              context,
                              screenTitle: "rincian pembayaran & upload",
                              onTapScreenTitle: () => OnTapScreenTitle(
                                  AppRoutes.rincianPembayaranUploadScreen),
                            ),
                            _buildScreenTitle(
                              context,
                              screenTitle: "Menunggu Verifikasi",
                              onTapScreenTitle: () => OnTapScreenTitle(
                                  AppRoutes.menungguVerifikasiScreen),
                            ),
                            _buildScreenTitle(
                              context,
                              screenTitle: "Sukses",
                              onTapScreenTitle: () =>
                                  OnTapScreenTitle(AppRoutes.suksesScreen),
                            ),
                            _buildScreenTitle(
                              context,
                              screenTitle: "Pesanan dibatalkan",
                              onTapScreenTitle: () => OnTapScreenTitle(
                                  AppRoutes.pesananDibatalkanScreen),
                            ),
                            _buildScreenTitle(
                              context,
                              screenTitle: "Beranda",
                              onTapScreenTitle: () =>
                                  OnTapScreenTitle(AppRoutes.berandaScreen),
                            ),
                            _buildScreenTitle(
                              context,
                              screenTitle: "Detail Mountain",
                              onTapScreenTitle: () => OnTapScreenTitle(
                                  AppRoutes.detailMountainScreen),
                            ),
                            _buildScreenTitle(
                              context,
                              screenTitle: "Route",
                              onTapScreenTitle: () =>
                                  OnTapScreenTitle(AppRoutes.routeScreen),
                            ),
                            _buildScreenTitle(
                              context,
                              screenTitle: "Tata Tertib",
                              onTapScreenTitle: () =>
                                  OnTapScreenTitle(AppRoutes.tataTertibScreen),
                            ),
                            _buildScreenTitle(
                              context,
                              screenTitle: "PROFILE",
                              onTapScreenTitle: () =>
                                  OnTapScreenTitle(AppRoutes.profileScreen),
                            ),
                            _buildScreenTitle(
                              context,
                              screenTitle: "DATA PROFILE",
                              onTapScreenTitle: () =>
                                  OnTapScreenTitle(AppRoutes.dataProfileScreen),
                            ),
                            _buildScreenTitle(
                              context,
                              screenTitle: "Tiket",
                              onTapScreenTitle: () =>
                                  OnTapScreenTitle(AppRoutes.tiketScreen),
                            ),
                            _buildScreenTitle(
                              context,
                              screenTitle: "ubahpw - Dialog",
                              onTapScreenTitle: () => onTapDialogTitle(
                                  context, UbahpwDialog.builder(context)),
                            ),
                            _buildScreenTitle(
                              context,
                              screenTitle: "pop up data diri lengkap - Dialog",
                              onTapScreenTitle: () => onTapDialogTitle(context,
                                  PopUpDataDiriLengkapDialog.builder(context)),
                            ),
                            _buildScreenTitle(
                              context,
                              screenTitle: "transaksi page",
                              onTapScreenTitle: () =>
                                  OnTapScreenTitle(AppRoutes.transaksiPage),
                            ),
                            _buildScreenTitle(
                              context,
                              screenTitle: "Riwayat",
                              onTapScreenTitle: () =>
                                  OnTapScreenTitle(AppRoutes.riwayatPage),
                            )
                          ],
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Common click event for dialog
  void onTapDialogTitle(
    BuildContext context,
    Widget className,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          contentPadding: EdgeInsets.zero,
          content: className,
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
        );
      },
    );
  }

  /// Common widget
  Widget _buildScreenTitle(
    BuildContext context, {
    required String screenTitle,
    Function? onTapScreenTitle,
  }) {
    return GestureDetector(
      onTap: () {
        onTapScreenTitle?.call();
      },
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFFFFFF),
        ),
        child: Column(
          children: [
            SizedBox(height: 10.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.h),
              child: Text(
                screenTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF000000),
                  fontSize: 20.fSize,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            SizedBox(height: 10.h),
            SizedBox(height: 5.h),
            Divider(
              height: 1.h,
              thickness: 1.h,
              color: const Color(0xFF888888),
            ),
          ],
        ),
      ),
    );
  }

  void OnTapScreenTitle(String routeName) {
    NavigatorService.pushNamed(routeName);
  }
}
