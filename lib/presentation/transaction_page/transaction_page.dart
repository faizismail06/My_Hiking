import 'package:flutter/material.dart';
import '../../api/api_service.dart';
import '../../core/app_export.dart';
import 'bloc/transaction_bloc.dart';
import 'models/transactionlist_item_model.dart';
import 'models/transaction_model.dart';
import 'widgets/transactionlist_item_widget.dart';

class TransactionPage extends StatefulWidget {
  const TransactionPage({super.key});

  static Widget builder(BuildContext context) {
    return BlocProvider<TransactionBloc>(
      create: (context) => TransactionBloc(TransactionState(
        transactionModelObj: TransactionModel(),
      ))
        ..add(TransactionInitialEvent()),
      child: const TransactionPage(),
    );
  }

  @override
  _TransactionPageState createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
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
        context.read<TransactionBloc>().add(TransactionUserIdEvent(userId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
        return BlocBuilder<TransactionBloc,
        TransactionState>(
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
      child: BlocSelector<TransactionBloc, TransactionState, TransactionModel?>(
        selector: (state) => state.transactionModelObj,
        builder: (context, transactionModelObj) {
          return ListView.separated(
            padding: EdgeInsets.zero,
            physics: const BouncingScrollPhysics(),
            shrinkWrap: true,
            separatorBuilder: (context, index) {
              return SizedBox(height: 18.h);
            },
            itemCount: transactionModelObj?.transactionlistItemList.length ?? 0,
            itemBuilder: (context, index) {
              TransactionItemModel model =
                  transactionModelObj?.transactionlistItemList[index] ??
                      TransactionItemModel();
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
        NavigatorService.pushNamed(AppRoutes.paymentUploadScreen);
      case "verified":
        NavigatorService.pushNamed(AppRoutes.ticketScreen);
        break;
      case "unverified":
        NavigatorService.pushNamed(AppRoutes.pendingVerificationScreen);
        break;
      default:
        print('Status transaksi tidak dikenali: $status');
    }
  }
}
