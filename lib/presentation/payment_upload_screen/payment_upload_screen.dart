import 'dart:async';

import 'package:flutter/material.dart';
import 'package:another_stepper/dto/stepper_data.dart';
import 'package:another_stepper/widgets/another_stepper.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:myhiking/presentation/pending_verification_screen/bloc/pending_verification_bloc.dart';
import 'package:myhiking/presentation/pending_verification_screen/pending_verification_screen.dart';
import '../../api/api_service.dart';
import '../../core/app_export.dart';
import '../../theme/custom_button_style.dart';
import '../../widgets/app_bar/appbar_subtitle.dart';
import '../../widgets/app_bar/custom_app_bar.dart';
import '../../widgets/custom_elevated_button.dart';
import '../../widgets/custom_outlined_button.dart';
import 'bloc/payment_upload_bloc.dart';
import 'models/payment_upload_model.dart';
import 'package:file_picker/file_picker.dart'; // Import file_picker

class PaymentUploadScreen extends StatefulWidget {
  final int orderId;
  final int? transaksiId;

  const PaymentUploadScreen({
    super.key,
    required this.orderId,
    this.transaksiId,
  });

  @override
  _PaymentUploadScreenState createState() => _PaymentUploadScreenState();
}

class _PaymentUploadScreenState extends State<PaymentUploadScreen> {
  String? _fileName;
  String? _filePath;
  PaymentUploadModel? paymentUpload;
  late Timer _timer;
  Duration _remainingTime = Duration(hours: 1); // 1 jam mundur
  String _formattedTime = '';

  @override
  void initState() {
    super.initState();
    // Menambahkan event setelah widget pertama kali dibangun
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PaymentUploadBloc>().add(
            FetchPaymentUploadEvent(
              transactionId: widget.transaksiId.toString(),
              filePath: '',
              isLoading: true,
            ),
          );
    });

    _updateTime(context, widget.orderId);
  }

  Future<void> _pickFile() async {
    try {
      // Gunakan FilePicker untuk memilih file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png'], // Hanya file gambar
      );

      if (result != null) {
        setState(() {
          _filePath = result.files.single.path; // Simpan path lengkap file
          _fileName = result.files.single.name; // Simpan nama file tanpa path
        });
        print("File dipilih: $_filePath");
      } else {
        print("Pemilihan file dibatalkan oleh pengguna.");
      }
    } catch (e) {
      print("Error saat memilih file: $e");
    }
  }

  void _updateTime(BuildContext context, int orderId) {
    _formattedTime = _formatDuration(_remainingTime);

    // Start a timer to update the remaining time every second
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingTime.inSeconds > 0) {
          _remainingTime = _remainingTime - Duration(seconds: 1);
        } else {
          _timer.cancel(); // Stop the timer when it reaches 0
          _formattedTime = _formatDuration(_remainingTime);

          // Otomatis membatalkan order
          onTapBatal(context, orderId);
        }
        _formattedTime = _formatDuration(_remainingTime);
      });
    });
  }

  String _formatDuration(Duration duration) {
    // Format the duration to the desired string, like "00:59:58"
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PaymentUploadBloc, PaymentUploadState>(
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
        return SafeArea(
          child: Scaffold(
            appBar: _buildAppBar(context),
            body: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 14.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildStepperSection(context),
                  SizedBox(height: 12.h),
                  // Mulai bagian dekorasi
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 6.h, vertical: 14.h),
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
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildTimerRow(context),
                        SizedBox(height: 18.h),
                        _buildPaymentDetailsStack(context, state),
                        SizedBox(height: 16.h),
                        GestureDetector(
                          onTap: _pickFile,
                          child: Container(
                            width: double.maxFinite,
                            height: 48.h,
                            margin: EdgeInsets.symmetric(horizontal: 18.h),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.onPrimary,
                              borderRadius: BorderRadius.circular(14.h),
                              border: Border.all(
                                color: appTheme.gray50004,
                                width: 1.h,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CustomImageView(
                                  imagePath: ImageConstant.imgProfile,
                                  height: 24.h,
                                  width: 24.h,
                                ),
                                SizedBox(width: 12.h),
                                Text(
                                  _fileName == null
                                      ? "msg_upload_bukti_pembayaran".tr
                                      : _fileName!,
                                  style: theme.textTheme.labelLarge!.copyWith(
                                    color: appTheme.gray50004,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 16.h),
                        CustomElevatedButton(
                          height: 48.h,
                          text: "lbl_kirim2".tr.toUpperCase(),
                          margin: EdgeInsets.symmetric(horizontal: 18.h),
                          buttonStyle: CustomButtonStyles.fillPrimary,
                          buttonTextStyle: theme.textTheme.labelLarge!,
                          onPressed: () {
                            _uploadBuktiPembayaran();
                          },
                        ),
                        SizedBox(height: 16.h),
                        CustomOutlinedButton(
                          text: "lbl_kembali_ke_home".tr.toUpperCase(),
                          margin: EdgeInsets.symmetric(horizontal: 18.h),
                          onPressed: () {
                            NavigatorService.pushNamed(AppRoutes.homeScreen);
                          },
                        ),
                      ],
                    ),
                  ),
                  // Akhir bagian dekorasi
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return CustomAppBar(
      height: 40.h,
      title: Container(
        width: double.maxFinite,
        margin:
            EdgeInsets.symmetric(horizontal: 13.h), // Adjust margins as needed
        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween, // Space between items
          children: [
            // Back Button
            IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.of(context).pop(); // Navigate back
              },
              padding: EdgeInsets.only(right: 16.h), // Adjust padding as needed
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.only(
                      left: 12.h), // Tambahkan padding untuk teks
                  child: AppbarSubtitleOne(
                    text: "lbl_booking".tr,
                  ),
                ),
              ),
            ),
            SizedBox(width: 50.h), // You can adjust this width
          ],
        ),
      ),
    );
  }

  /// Section Widget
  Widget _buildStepperSection(BuildContext context) {
    return Container(
      width: double.maxFinite,
      margin: EdgeInsets.only(left: 8.h),
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
                  ),
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
                  ),
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
    );
  }

  /// Section Widget
  Widget _buildTimerRow(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 14.h),
      padding: EdgeInsets.symmetric(
        horizontal: 14.h,
        vertical: 6.h,
      ),
      decoration: BoxDecoration(
        color: appTheme.gray30002,
        borderRadius: BorderRadiusStyle.roundedBorder6,
      ),
      width: double.maxFinite,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomImageView(
            imagePath: ImageConstant.imgMdiClockOutline,
            height: 24.h,
            width: 24.h,
          ),
          SizedBox(width: 8.h),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "msg_selesaikan_pembayaran".tr,
                    style: theme.textTheme.labelSmall,
                  ),
                  Text(
                    _formattedTime,
                    style: CustomTextStyles.labelMediumPrimary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Section Widget
  Widget _buildPaymentDetailsStack(
      BuildContext context, PaymentUploadState state) {
    return SizedBox(
      width: double.maxFinite,
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        margin: EdgeInsets.symmetric(horizontal: 14.h),
        color: appTheme.gray30002.withOpacity(0.25),
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: theme.colorScheme.primary,
            width: 2.h,
          ),
          borderRadius: BorderRadiusStyle.roundedBorder20,
        ),
        child: Container(
          height: 348.h,
          width: double.maxFinite,
          decoration: BoxDecoration(
            color: appTheme.gray30002.withOpacity(0.25),
            borderRadius: BorderRadiusStyle.roundedBorder20,
            border: Border.all(
              color: theme.colorScheme.primary,
              width: 2.h,
            ),
            boxShadow: [
              BoxShadow(
                color: appTheme.black900.withOpacity(0.025),
                spreadRadius: 2.h,
                blurRadius: 2.h,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              CustomImageView(
                imagePath: ImageConstant.imgPaymentByTapping,
                height: 174.h,
                width: 190.h,
                alignment: Alignment.topCenter,
              ),
              Container(
                width: 240.h,
                margin: EdgeInsets.only(bottom: 16.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "ID_order".tr,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: CustomTextStyles.labelMediumGray50004,
                    ),
                    Text(
                      widget.orderId.toString(),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: CustomTextStyles.labelMediumGray50004,
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      "Rp ${NumberFormat('#,##0', 'id_ID').format(state.paymentUploadModelObj?.totalBayar.toInt() ?? 0)}",
                      style: theme.textTheme.headlineSmall,
                    ),

                    SizedBox(height: 8.h), // Jarak dari elemen sebelumnya
                    Container(
                      width: double.maxFinite,
                      margin: EdgeInsets.symmetric(
                          horizontal:
                              16), // Margin untuk menjaga elemen tidak terlalu ke kiri/kanan
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment
                            .center, // Posisikan Row di tengah secara horizontal
                        children: [
                          Container(
                            height: 36.h,
                            width: 54.h,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadiusStyle.roundedBorder6,
                            ),
                            child: CustomImageView(
                              imagePath: state.paymentUploadModelObj?.payment
                                      .imagePath ??
                                  '',
                              height: 36.h,
                              width: 38.h,
                              radius: BorderRadius.circular(8.h),
                            ),
                          ),
                          SizedBox(
                              width:
                                  12), // Jarak horizontal antara gambar dan teks
                          Column(
                            mainAxisAlignment: MainAxisAlignment
                                .center, // Posisikan elemen di tengah secara vertikal
                            crossAxisAlignment: CrossAxisAlignment
                                .center, // Rata tengah secara horizontal
                            children: [
                              Text(
                                state.paymentUploadModelObj?.payment
                                        .namaPembayaran ??
                                    '',
                                style: CustomTextStyles.labelLargeBluegray40002,
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(
                                  height: 6
                                      .h), // Jarak antara nama pembayaran dan nomor pembayaran
                              Text(
                                state.paymentUploadModelObj?.payment
                                        .nomorPembayaran ??
                                    '',
                                style: CustomTextStyles.titleSmallLightblue900
                                    .copyWith(
                                  decoration: TextDecoration.underline,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 6.h),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Section Widget
  Widget _buildUploadProofRow(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 26.h,
        vertical: 8.h,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.onPrimary,
        borderRadius: BorderRadiusStyle.roundedBorder14,
        border: Border.all(
          color: appTheme.gray50004,
          width: 1.h,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomImageView(
            imagePath: ImageConstant.imgProfile,
            height: 24.h,
            width: 24.h,
          ),
          SizedBox(width: 18.h),
          Align(
            alignment: Alignment.topCenter,
            child: Text(
              "msg_upload_bukti_pembayaran".tr,
              style: CustomTextStyles.labelLargeGray50004,
            ),
          ),
        ],
      ),
    );
  }

  /// Section Widget
  Widget _buildReturnHomeColumn(BuildContext context) {
    return Container(
      width: double.maxFinite,
      padding: EdgeInsets.symmetric(horizontal: 18.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomOutlinedButton(
            text: "lbl_kembali_ke_home".tr.toUpperCase(),
            margin: EdgeInsets.only(bottom: 12.h),
            onPressed: () {
              onTapKembalikehome(context);
            },
          ),
        ],
      ),
    );
  }

  /// Navigates to the paymentMethodScreen when the action is triggered.
  void onTapArrowdownone(BuildContext context) {
    NavigatorService.pushNamed(
      AppRoutes.paymentMethodScreen,
    );
  }

  final ApiService apiService = ApiService();

  void _uploadBuktiPembayaran() async {
    if (_fileName == null || _filePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pilih file terlebih dahulu')),
      );
      return;
    }

    try {
      // Panggil API service untuk upload bukti pembayaran
      await apiService.uploadBuktiPembayaran(
        widget.transaksiId.toString(),
        _filePath!,
      );

      // Navigasi langsung ke layar berikutnya tanpa loading
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => BlocProvider(
              create: (context) =>
                  PendingVerificationBloc(apiService: ApiService()),
              child: PendingVerificationScreen(orderId: widget.orderId),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengunggah bukti pembayaran: ${e.toString()}'),
        ),
      );
    }
  }

  /// Navigates to the pendingVerificationScreen when the action is triggered.
  void onTapKirim(BuildContext context) {
    NavigatorService.pushNamed(
      AppRoutes.pendingVerificationScreen,
    );
  }

  /// Navigates to the homeScreen when the action is triggered.
  void onTapKembalikehome(BuildContext context) {
    NavigatorService.pushNamed(
      AppRoutes.homeScreen,
    );
  }

  void onTapBatal(BuildContext context, int orderId) async {
    try {
      // Kirim permintaan DELETE ke server
      final response = await http.delete(
        Uri.parse('$baseUrl/order/$orderId'),
        headers: {
          'Authorization': 'Bearer YOUR_TOKEN_HERE',
        },
      );

      // Periksa status respons
      if (response.statusCode == 200) {
        // Tampilkan notifikasi sukses
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("order telah dibatalkan")),
        );

        // Navigasi ke layar tertentu jika diperlukan
        Navigator.of(context, rootNavigator: true)
            .pushReplacementNamed(AppRoutes.homeScreen);
      } else {
        // Tampilkan pesan kesalahan
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal membatalkan order: ${response.body}"),
          ),
        );
      }
    } catch (e) {
      // Tangani kesalahan koneksi atau lainnya
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Terjadi kesalahan: $e")),
      );
    }
  }
}
