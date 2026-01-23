import 'package:flutter/material.dart';
import '../../api/api_service.dart';
import '../../core/app_export.dart';
import 'bloc/transaksi_bloc.dart';
import 'models/transactionlist_item_model.dart';
import 'models/transaksi_model.dart';
import 'widgets/transactionlist_item_widget.dart';

class TransaksiPage extends StatefulWidget {
  const TransaksiPage({super.key});

  static Widget builder(BuildContext context) {
    return BlocProvider<TransaksiBloc>(
      create: (context) => TransaksiBloc(TransaksiState(
        transaksiModelObj: TransaksiModel(),
      ))
        ..add(TransaksiInitialEvent()),
      child: const TransaksiPage(),
    );
  }

  @override
  _TransaksiPageState createState() => _TransaksiPageState();
}

class _TransaksiPageState extends State<TransaksiPage> {
  String userId = '';
  String userName = '';

  @override
  void initState() {
    super.initState();
    _getUserProfile();
  }

  Future<void> _getUserProfile() async {
    final token = await ApiService().getToken();
    if (token != null) {
      final response = await ApiService().getUserProfile(token);
      print('User Profile berhasil diterima, userId: $userId');

      if (response['success']) {
        setState(() {
          userId = response['data']['id'].toString();
          userName = response['data']['name'];
        });
        // Send userId to BLoC
        context.read<TransaksiBloc>().add(TransaksiUserIdEvent(userId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
        return BlocBuilder<TransaksiBloc,
        TransaksiState>(
      builder: (context, state) {
    if (state.isLoading) {
      return Container(
        color: Colors.white, // Mengatur latar belakang menjadi putih
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
                Colors.green.shade900), // Warna hijau untuk indikator loading
          ),
        ),
      );
    }
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: Container(),
        ),
        backgroundColor: appTheme.gray50,
        body: Container(
          width: double.maxFinite,
          decoration: BoxDecoration(
            color: appTheme.gray50,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              SizedBox(height: 20.h),
              _buildWomanReceiveSection(context),
              Expanded(
                child: SizedBox(
                  width: double.maxFinite,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 22.h),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "lbl_transaksi".tr,
                            style: CustomTextStyles.titleMediumBlack900,
                          ),
                          SizedBox(height: 10.h),
                          _buildTransactionList(context),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  });
  }

  Widget _buildWomanReceiveSection(BuildContext context) {
    return Container(
      width: double.maxFinite,
      margin: EdgeInsets.only(left: 22.h),
      child: Row(
        children: [
          CustomImageView(
            imagePath: ImageConstant.imgWomanReceivedDividend,
            height: 174.h,
            width: 174.h,
          ),
          SizedBox(width: 4.h),
          Expanded(
            child: Container(
              width: double.maxFinite,
              padding: EdgeInsets.only(
                left: 32.h,
                top: 14.h,
                bottom: 14.h,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.7),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "lbl_hello".tr,
                    style: CustomTextStyles.titleMediumOnPrimary_2,
                  ),
                  Text(
                    '$userName'.tr,
                    style: theme.textTheme.titleLarge,
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTransactionList(BuildContext context) {
    return Expanded(
      child: BlocSelector<TransaksiBloc, TransaksiState, TransaksiModel?>(
        selector: (state) => state.transaksiModelObj,
        builder: (context, transaksiModelObj) {
          return ListView.separated(
            padding: EdgeInsets.zero,
            physics: const BouncingScrollPhysics(),
            shrinkWrap: true,
            separatorBuilder: (context, index) {
              return SizedBox(height: 18.h);
            },
            itemCount: transaksiModelObj?.transactionlistItemList.length ?? 0,
            itemBuilder: (context, index) {
              TransactionModel model =
                  transaksiModelObj?.transactionlistItemList[index] ??
                      TransactionModel();
              return TransactionlistItemWidget(
                model,
                onTapRecentclimbing: () {
                  _handleTapRecentClimbing(
                      context, model.status, model.id.toString());
                },
              );
            },
          );
        },
      ),
    );
  }

  void _handleTapRecentClimbing(
      BuildContext context, String? status, String? id) {
    switch (status) {
      case "incomplete":
        NavigatorService.pushNamed(AppRoutes.rincianPembayaranUploadScreen);
      case "verified":
        NavigatorService.pushNamed(AppRoutes.tiketScreen);
        break;
      case "unverified":
        NavigatorService.pushNamed(AppRoutes.menungguVerifikasiScreen);
        break;
      default:
        print('Status transaksi tidak dikenali: $status');
    }
  }
}
