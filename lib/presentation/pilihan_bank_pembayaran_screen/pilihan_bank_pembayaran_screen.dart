import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:another_stepper/dto/stepper_data.dart';
import 'package:another_stepper/widgets/another_stepper.dart';
import 'package:myhiking/presentation/rincian_pembayaran_upload_screen/bloc/rincian_pembayaran_upload_bloc.dart';
import 'package:myhiking/presentation/rincian_pembayaran_upload_screen/rincian_pembayaran_upload_screen.dart';
import '../../api/api_service.dart';
import '../../core/app_export.dart';
import '../../theme/custom_button_style.dart';
import '../../widgets/app_bar/appbar_subtitle.dart';
import '../../widgets/app_bar/custom_app_bar.dart';
import '../../widgets/custom_elevated_button.dart';
import 'bloc/pilihan_bank_pembayaran_bloc.dart';
import 'models/paymentmethodslist_item_model.dart';
import 'widgets/paymentmethodslist_item_widget.dart';

class PilihanBankPembayaranScreen extends StatefulWidget {
  final int pesananId;
  const PilihanBankPembayaranScreen({super.key, required this.pesananId});

  @override
  _PilihanBankPembayaranScreenState createState() =>
      _PilihanBankPembayaranScreenState();
}

class _PilihanBankPembayaranScreenState
    extends State<PilihanBankPembayaranScreen> {
  String? selectedDebitCard; // Menyimpan kartu debit yang dipilih

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Memastikan BLoC siap untuk menangani event
      context
          .read<PilihanBankPembayaranBloc>()
          .add(PilihanBankPembayaranInitialEvent());
      context.read<PilihanBankPembayaranBloc>().add(FetchPaymentsEvent());
    });
  }

  @override
  Widget build(BuildContext context) {
    print("id Pesanan : ${widget.pesananId}");
    return SafeArea(
      child: Scaffold(
        appBar: _buildAppBar(context),
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: 6.h, vertical: 2.h),
          child: Column(
            children: [
              _buildPaymentSelectionStepper(context),
              SizedBox(height: 16.h),
              _buildPaymentMethodsList(context),
            ],
          ),
        ),
        bottomNavigationBar: _buildPaymentButtonSection(context),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return CustomAppBar(
      height: 40.h,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop();
            },
            padding: EdgeInsets.only(right: 16.h),
          ),
          Expanded(
            child: Center(
              child: AppbarSubtitleOne(text: "lbl_booking".tr),
            ),
          ),
          const SizedBox(width: 50),
        ],
      ),
    );
  }

  Widget _buildPaymentSelectionStepper(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnotherStepper(
            iconHeight: 26,
            iconWidth: 26,
            stepperDirection: Axis.horizontal,
            activeIndex:
                0, // You can adjust active index logic as per your need
            barThickness: 4,
            inverted: true,
            stepperList: _buildStepperDataList(),
          ),
          SizedBox(height: 38.h),
          Text(
            "msg_pilih_pembayaran".tr,
            style: CustomTextStyles.titleMediumGray900_1,
          ),
        ],
      ),
    );
  }

  List<StepperData> _buildStepperDataList() {
    return [
      StepperData(iconWidget: _buildStepperIcon("lbl_1")),
      StepperData(iconWidget: _buildStepperIcon("lbl_2")),
      StepperData(
        iconWidget: Container(
          height: 26.h,
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
    ];
  }

  Widget _buildStepperIcon(String label) {
    return Container(
      height: 26.h,
      width: 26.h,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(14.h),
      ),
      child: Center(
        child: Text(
          label.tr,
          style: CustomTextStyles.titleMediumOnPrimary_2,
        ),
      ),
    );
  }

  Widget _buildPaymentMethodsList(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(right: 2.h),
        child: BlocSelector<PilihanBankPembayaranBloc,
            PilihanBankPembayaranState, List<PaymentmethodslistItemModel>>(
          selector: (state) =>
              state.pilihanBankPembayaranModelObj?.paymentmethodslistItemList ??
              [],
          builder: (context, paymentMethodsList) {
            return ListView.separated(
              padding: EdgeInsets.zero,
              physics: const BouncingScrollPhysics(),
              shrinkWrap: true,
              separatorBuilder: (context, index) => SizedBox(height: 14.h),
              itemCount: paymentMethodsList.length,
              itemBuilder: (context, index) {
                return PaymentmethodslistItemWidget(
                  paymentMethodsList[index],
                  onTapRadioGroup: (value) {
                    setState(() {
                      selectedDebitCard =
                          value; // Simpan kartu debit yang dipilih
                    });

                    // Mengirimkan event ke Bloc
                    context.read<PilihanBankPembayaranBloc>().add(
                          PaymentmethodslistItemEvent(
                              index: index), // Pastikan event ini ditangani
                        );
                  },
                  isSelected: selectedDebitCard ==
                      paymentMethodsList[index]
                          .namaPayment, // Cek apakah item ini terpilih
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildPaymentButtonSection(BuildContext context) {
    bool isBankSelected = selectedDebitCard != null;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 18.h),
      child: CustomElevatedButton(
        height: 48.h,
        text: "lbl_bayar_sekarang".tr.toUpperCase(),
        onPressed: isBankSelected
            ? () {
                // Cari model pembayaran yang dipilih berdasarkan debitcard
                final selectedPayment = context
                    .read<PilihanBankPembayaranBloc>()
                    .state
                    .pilihanBankPembayaranModelObj
                    ?.paymentmethodslistItemList
                    .firstWhere(
                      (payment) => payment.namaPayment == selectedDebitCard,
                      orElse: () => PaymentmethodslistItemModel(),
                    );

                onTapRincian(
                  context,
                  selectedPayment?.id ?? 0,
                );
              }
            : null, // Disable button if no bank is selected
        margin: EdgeInsets.only(bottom: 12.h),
        buttonStyle: isBankSelected
            ? CustomButtonStyles
                .fillPrimary // Primary color if bank is selected
            : CustomButtonStyles.fillGray, // Gray color if no bank is selected
        buttonTextStyle: CustomTextStyles.labelLarge13,
      ),
    );
  }

  void onTapRincian(BuildContext context, int id) async {
    // Log selalu ditampilkan di awal fungsi
    print("Pesanan ID: ${widget.pesananId}, ID Payment: $id");

    try {
      // Panggil API untuk membuat transaksi
      final transactionResponse = await ApiService().createTransaction(
        widget.pesananId,
        id,
      );

      // Navigasi ke RincianPembayaranUploadScreen dengan data transaksi
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BlocProvider(
            create: (context) =>
                RincianPembayaranUploadBloc(apiService: ApiService()),
            child: RincianPembayaranUploadScreen(
              pesananId: widget.pesananId,
              transaksiId: transactionResponse.transaction.id,
            ),
          ),
        ),
      );
    } catch (e) {
      // Tangani error jika gagal membuat transaksi
      print('Error creating transaction: $e');

      // Tampilkan pesan error ke pengguna menggunakan ScaffoldMessenger
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuat transaksi. Silakan coba lagi.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
}
