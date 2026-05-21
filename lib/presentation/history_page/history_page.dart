import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myhiking/presentation/payment_method_screen/payment_method_screen.dart';
import '../../api/api_service.dart';
import '../../core/app_export.dart';
import 'bloc/history_bloc.dart';
import 'models/recentclimbinglist_item_model.dart';
import 'models/history_model.dart';
import 'widgets/recentclimbinglist_item_widget.dart';

// Mengubah HistoryPage menjadi StatefulWidget
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  // Fungsi builder untuk menyediakan BlocProvider
  static Widget builder(BuildContext context) {
    return BlocProvider<HistoryBloc>(
      create: (context) => HistoryBloc(HistoryState(
        historyModelObj: HistoryModel(),
      ))
        ..add(HistoryInitialEvent()),
      child: const HistoryPage(),
    );
  }

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
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
      if (response['success']) {
        setState(() {
          userId = response['data']['id'].toString();
          userName = response['data']['name'];
        });
        // Kirim userId ke BLoC
        context.read<HistoryBloc>().add(HistoryUserIdEvent(userId));
      }
    }
    print("Navigating with $userId");

    // print(userName);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
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
              _buildHikingEquipmentSection(context),
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
                            "lbl_riwayat".tr,
                            style: CustomTextStyles.titleMediumBlack900,
                          ),
                          SizedBox(height: 10.h),
                          _buildRecentClimbingList(context),
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
  }

  /// Widget untuk menampilkan bagian peralatan pendakian
  Widget _buildHikingEquipmentSection(BuildContext context) {
    return Container(
      width: double.maxFinite,
      margin: EdgeInsets.only(left: 10.h),
      child: Row(
        children: [
          CustomImageView(
            imagePath: ImageConstant.imgriwayat,
            height: 136.h,
            width: 186.h,
          ),
          SizedBox(width: 8.h),
          Expanded(
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Container(
                width: double.maxFinite,
                margin: EdgeInsets.only(bottom: 28.h),
                padding: EdgeInsets.only(
                  left: 30.h,
                  top: 8.h,
                  bottom: 8.h,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.7),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 4.h),
                    Text(
                      "lbl_hello".tr,
                      style: CustomTextStyles.titleMediumOnPrimary_2,
                    ),
                    Text(
                      '$userName'.tr, // Ambil nama user yang sedang login
                      style: theme.textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  /// Widget untuk menampilkan daftar pendakian terbaru
  Widget _buildRecentClimbingList(BuildContext context) {
    return Expanded(
      child: BlocSelector<HistoryBloc, HistoryState, HistoryModel?>(
        selector: (state) => state.historyModelObj,
        builder: (context, historyModelObj) {
          return ListView.separated(
            padding: EdgeInsets.zero,
            physics: const BouncingScrollPhysics(),
            shrinkWrap: true,
            separatorBuilder: (context, index) {
              return SizedBox(height: 16.h);
            },
            itemCount: historyModelObj?.recentclimbinglistItemList.length ?? 0,
            itemBuilder: (context, index) {
              RecentclimbinglistItemModel model =
                  historyModelObj?.recentclimbinglistItemList[index] ??
                      RecentclimbinglistItemModel();
              return RecentclimbinglistItemWidget(
                model,
                onTapRecentclimbing: () {
                  // Navigate to ticket action screen
                  _navigateToTicketAction(context, model);
                },
              );
            },
          );
        },
      ),
    );
  }

  /// Navigate to ticket action screen
  void _navigateToTicketAction(
      BuildContext context, RecentclimbinglistItemModel model) {
    int parsedPesananId = int.tryParse(model.id.toString()) ?? 0;
    final status = (model.status ?? '').trim();

    if (parsedPesananId <= 0) {
      return;
    }

    if (status.toLowerCase() == 'bayar') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentMethodScreen(orderId: parsedPesananId),
        ),
      );
      return;
    }

    // Format the hiking date for display
    String formattedDate = '';
    try {
      DateTime tanggal = DateTime.parse(model.tanggalNaik.toString());
      formattedDate = DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(tanggal);
    } catch (e) {
      formattedDate = model.tanggalNaik ?? '';
    }

    final normalizedStatus = status.toLowerCase();
    if (normalizedStatus == 'cancel requested' ||
        normalizedStatus == 'cancelled') {
      Navigator.of(context, rootNavigator: true).pushNamed(
        AppRoutes.refundRequestResultPage,
        arguments: {
          'orderId': parsedPesananId,
          'mountainName': model.gunung ?? 'Gunung',
          'hikingDate': formattedDate,
        },
      );
      return;
    }

    // Use root navigator to navigate outside the nested navigator
    Navigator.of(context, rootNavigator: true).pushNamed(
      AppRoutes.ticketActionScreen,
      arguments: {
        'orderId': parsedPesananId,
        'status': status.isEmpty ? 'Booking' : status,
        'mountainName': model.gunung ?? 'Gunung',
        'hikingDate': formattedDate,
      },
    );
  }
}
