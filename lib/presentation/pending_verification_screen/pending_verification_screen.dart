import 'package:flutter/material.dart';
import 'package:another_stepper/dto/stepper_data.dart';
import 'package:http/http.dart' as http;
import 'package:another_stepper/widgets/another_stepper.dart';
import '../../api/api_service.dart';
import '../../core/app_export.dart';
import '../../theme/custom_button_style.dart';
import '../../widgets/custom_elevated_button.dart';
import '../../widgets/custom_outlined_button.dart';
import 'bloc/pending_verification_bloc.dart';
import 'models/pending_verification_model.dart';

class PendingVerificationScreen extends StatefulWidget {
  final int orderId;

  const PendingVerificationScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<PendingVerificationScreen> createState() =>
      _PendingVerificationScreenState();
}

class _PendingVerificationScreenState extends State<PendingVerificationScreen> {
  int userId = 0;
  bool isLoading = true;
  @override
  void initState() {
    super.initState();
    context
        .read<PendingVerificationBloc>()
        .add(FetchPendingVerificationData(widget.orderId));
    _getUser();
  }

  Future<void> _getUser() async {
    final token = await ApiService().getToken();

    // Cek apakah token null atau kosong
    if (token == null || token.isEmpty) {
      // Jika token tidak tersedia, tampilkan pesan atau ambil tindakan lain
      // print("Token is null or empty");
      if (mounted) {
        setState(() {
          isLoading =
              false; // Menyelesaikan status loading jika token tidak ada
        });
      }
      return; // Keluar dari fungsi jika token tidak ada
    }

    // print("Token: $token"); // Debugging, pastikan token ada

    try {
      final response = await ApiService().getUser(token);
      if (response['success']) {
        if (mounted) {
          setState(() {
            userId = response['data']['id'];
            isLoading = false;
          });
        }
      } else {
        // Menangani error jika API gagal
        // print("Error: ${response['message']}");
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    } catch (e) {
      // Tangani error jaringan atau kesalahan lainnya
      // print("Error fetching user: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PendingVerificationBloc, PendingVerificationState>(
      builder: (context, state) {
        if (state.isLoading) {
          return Container(
            color: Colors.white, // Mengatur latar belakang menjadi putih
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors
                    .green.shade900), // Warna hijau untuk indikator loading
              ),
            ),
          );
        }
        if (state.error != null) {
          return Center(
            child: Text("Terjadi kesalahan: ${state.error}"),
          );
        }

        final model = state.pendingVerificationModelObj;
        if (model == null) {
          return const Center(
            child: Text("Data tidak tersedia."),
          );
        }

        return SafeArea(
          child: Scaffold(
            backgroundColor: appTheme.gray5001,
            body: SingleChildScrollView(
              // Membungkus dengan SingleChildScrollView
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 12.h, vertical: 20.h),
                child: Column(
                  children: [
                    _buildVerificationHeader(context),
                    SizedBox(height: 18.h),
                    _buildBookingDetailsSection(context),
                    SizedBox(height: 8.h),
                    _buildDetailPesananCard(context, model),
                    SizedBox(height: 12.h),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailPesananCard(
      BuildContext context, PendingVerificationModel model) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 6.h, vertical: 14.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.onPrimary,
        borderRadius: BorderRadiusStyle.roundedBorder14,
        boxShadow: [
          BoxShadow(
            color: appTheme.black900.withOpacity(0.04),
            spreadRadius: 2.h,
            blurRadius: 2.h,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "msg_menunggu_verifikasi".tr,
            style: CustomTextStyles.titleLargeBlack900,
          ),
          SizedBox(height: 20.h),
          CustomImageView(
            imagePath: ImageConstant.imgVectorPrimary,
            height: 138.h,
            width: 138.h,
          ),
          SizedBox(height: 38.h),
          _buildOrderDateRow(
            context,
            namaBaris: "lbl_no_pesanan".tr,
            isiBaris: model.idPesanan.toString(),
          ),
          _buildOrderDateRow(
            context,
            namaBaris: "msg_tanggal_pesanan".tr,
            isiBaris: model.tanggalPesanan.toString(),
          ),
          _buildOrderDateRow(
            context,
            namaBaris: "lbl_nama_pemesan".tr,
            isiBaris: model.namaPemesan.toString(),
          ),
          _buildOrderDateRow(
            context,
            namaBaris: "lbl_total_anggota".tr,
            isiBaris: model.totalAnggota.toString(),
          ),
          _buildOrderDateRow(
            context,
            namaBaris: "lbl_total_harga".tr,
            isiBaris: model.totalHarga.toString(),
          ),
          SizedBox(height: 28.h),
          Text(
            "msg_pesanan_akan_diverifikasi".tr,
            style: CustomTextStyles.labelMediumGray50002,
          ),
          SizedBox(height: 10.h),
          CustomElevatedButton(
            height: 48.h,
            text: "msg_batalkan_pesanan".tr.toUpperCase(),
            buttonStyle: CustomButtonStyles.fillRed2,
            buttonTextStyle: theme.textTheme.labelLarge!,
            onPressed: () {
              final int orderId =
                  widget.orderId; // Ambil ID pesanan dari widget
              onTapBatal(context, orderId);
            },
          ),
          SizedBox(height: 10.h),
          CustomOutlinedButton(
            text: "lbl_kembali_ke_home".tr.toUpperCase(),
            onPressed: () {
              onTapKembalikehome(context);
            },
          ),
          SizedBox(height: 6.h),
        ],
      ),
    );
  }

  /// Section Widget
  Widget _buildVerificationHeader(BuildContext context) {
    return Container(
      color: Colors.transparent, // Temporary background color for visibility
      width: double.maxFinite,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 8.0), // Add some padding if needed
            child: GestureDetector(
              onTap: () {
                onTapImgArrowdownone(context);
              },
              child: Icon(
                Icons.arrow_back, // Use a default back arrow icon for testing
                size: 24, // Set size explicitly
                color: Colors.black, // Ensure visibility
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding:
                    EdgeInsets.only(right: 24.0), // Adjust padding if needed
                child: Text(
                  "lbl_verifikasi".tr,
                  style: CustomTextStyles.titleMediumGray900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Section Widget
  Widget _buildBookingDetailsSection(BuildContext context) {
    return Container(
      width: double.maxFinite,
      margin: EdgeInsets.only(left: 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.maxFinite,
            child: AnotherStepper(
              iconHeight: 24,
              iconWidth: 26,
              stepperDirection: Axis.horizontal,
              activeIndex: 0,
              barThickness: 4,
              inverted: true,
              stepperList: [
                StepperData(
                  iconWidget: Container(
                    height: 24.h,
                    width: 26.h,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadiusStyle.roundedBorder14,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "lbl_1".tr,
                          style: CustomTextStyles.titleMediumOnPrimary_2,
                        )
                      ],
                    ),
                  ),
                ),
                StepperData(
                  iconWidget: Container(
                    height: 24.h,
                    width: 26.h,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadiusStyle.roundedBorder14,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "lbl_2".tr,
                          style: CustomTextStyles.titleMediumOnPrimary_2,
                        )
                      ],
                    ),
                  ),
                ),
                StepperData(
                  iconWidget: Container(
                    height: 22.h,
                    width: 26.h,
                    decoration: BoxDecoration(
                      color: appTheme.gray5001,
                      borderRadius: BorderRadius.circular(12.h),
                      border: Border.all(
                        color: appTheme.blueGray100,
                        width: 2.h,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 26.h),
          Text(
            "lbl_detail_pesanan".tr,
            style: CustomTextStyles.titleMediumGray900_1,
          ),
        ],
      ),
    );
  }

  /// Common widget
  Widget _buildOrderDateRow(
    BuildContext context, {
    required String namaBaris,
    required String isiBaris,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          namaBaris,
          style: CustomTextStyles.titleMediumGray50003.copyWith(
            color: appTheme.gray50003,
          ),
        ),
        Text(
          isiBaris,
          style: CustomTextStyles.titleMediumGray50003.copyWith(
            color: appTheme.gray50003,
          ),
        ),
      ],
    );
  }

  /// Navigates to the homeScreen when the action is triggered.
  void onTapImgArrowdownone(BuildContext context) {
    NavigatorService.pushNamed(
      AppRoutes.homeScreen,
    );
  }

  /// Navigates to the homeScreen when the action is triggered.
  void onTapKembalikehome(BuildContext context) {
    NavigatorService.pushNamed(
      AppRoutes.homeScreen,
    );
  }

  void onTapBatal(BuildContext context, int orderId) async {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text(
            "Apakah Anda yakin ingin membatalkan pesanan ini?",
            style: TextStyle(fontSize: 16, color: Colors.black),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Tutup dialog
              },
              child: const Text("TIDAK"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // Tutup dialog

                try {
                  final response = await http.delete(
                    Uri.parse('$baseUrl/pesanan/$orderId'),
                    headers: {
                      'Authorization': 'Bearer YOUR_TOKEN_HERE',
                    },
                  );

                  if (response.statusCode == 200) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Pesanan berhasil dibatalkan")),
                      );
                      try {
                        Navigator.of(context, rootNavigator: true)
                            .pushReplacementNamed(
                                AppRoutes.orderCancelledScreen);
                      } catch (e) {
                        print("Navigation error: $e");
                        // Tampilkan error ke user jika perlu
                      }
                    }
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                "Gagal membatalkan pesanan: ${response.body}")),
                      );
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Terjadi kesalahan: $e")),
                    );
                  }
                }
              },
              child: const Text(
                "YA",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}
