import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/app_export.dart';
import '../../widgets/custom_search_view.dart';
import 'bloc/beranda_bloc.dart';
import 'models/beranda_initial_model.dart';
import 'models/homelist_item_model.dart';
import 'widgets/homelist_item_widget.dart';
import 'package:myhiking/api/api_service.dart';

class BerandaInitialPage extends StatefulWidget {
  const BerandaInitialPage({super.key});

  @override
  BerandaInitialPageState createState() => BerandaInitialPageState();

  static Widget builder(BuildContext context) {
    return BlocProvider<BerandaBloc>(
      create: (context) => BerandaBloc(
        BerandaState(
          berandaInitialModelObj: BerandaInitialModel(),
        ),
      )..add(BerandaInitialEvent()),
      child: const BerandaInitialPage(),
    );
  }
}

class BerandaInitialPageState extends State<BerandaInitialPage> {
  String userName = '';
  int userId = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
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
            userName = response['data']['name'];
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
    return Container(
      // child: Container(
      width: double.maxFinite,
      padding: EdgeInsets.symmetric(horizontal: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20.h),
          Padding(
            padding: EdgeInsets.only(left: 14.h),
            child: Text(
              "Hai ${userName.isNotEmpty ? userName : "Pengguna"}",
              style: CustomTextStyles.titleMediumGray80001,
            ),
          ),
          GestureDetector(
            onTap: () {
              // onTapTxtIdCounter(context);
            },
            child: Padding(
              padding: EdgeInsets.only(left: 14.h),
              child: Text(
                userId.toString(),
                style: CustomTextStyles.bodySmallGray800,
              ),
            ),
          ),
          SizedBox(height: 4.h),
          Padding(
            padding: EdgeInsets.only(left: 8.h, right: 16.h),
            child:
                BlocSelector<BerandaBloc, BerandaState, TextEditingController?>(
              selector: (state) => state.searchController,
              builder: (context, searchController) {
                return CustomSearchView(
                  controller: searchController,
                  hintText: "lbl_cari".tr,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 10.h,
                    vertical: 12.h,
                  ),
                  onChanged: (query) {
                    // Dispatch the search event with the query
                    context.read<BerandaBloc>().add(BerandaSearchEvent(query));
                  },
                );
              },
            ),
          ),
          SizedBox(height: 6.h),
          Expanded(
              child: SingleChildScrollView(
            child: _buildHomeList(context),
          ))
        ],
      ),
    );
    // );
  }

  /// Section Widget
  Widget _buildHomeList(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(right: 4),
      child: BlocSelector<BerandaBloc, BerandaState, BerandaInitialModel?>(
        selector: (state) => state.berandaInitialModelObj,
        builder: (context, berandaInitialModelObj) {
          return ListView.separated(
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            separatorBuilder: (context, index) {
              return SizedBox(height: 0);
            },
            itemCount: berandaInitialModelObj?.homelistItemList.length ?? 0,
            itemBuilder: (context, index) {
              HomelistItemModel model =
                  berandaInitialModelObj?.homelistItemList[index] ??
                      HomelistItemModel();
              return HomelistItemWidget(
                  model); // Memanggil widget dengan model gunung
            },
          );
        },
      ),
    );
  }
}
