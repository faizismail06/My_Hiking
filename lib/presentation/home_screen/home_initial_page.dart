import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/app_export.dart';
import '../../routes/app_routes.dart';
import '../../widgets/custom_search_view.dart';
import 'bloc/home_bloc.dart';
import 'models/home_initial_model.dart';
import 'models/homelist_item_model.dart';
import 'widgets/homelist_item_widget.dart';
import 'package:myhiking/api/api_service.dart';

class HomeInitialPage extends StatefulWidget {
  const HomeInitialPage({super.key});

  @override
  HomeInitialPageState createState() => HomeInitialPageState();

  static Widget builder(BuildContext context) {
    return BlocProvider<HomeBloc>(
      create: (context) => HomeBloc(
        HomeState(
          homeInitialModelObj: HomeInitialModel(),
        ),
      )..add(HomeInitialEvent()),
      child: const HomeInitialPage(),
    );
  }
}

class HomeInitialPageState extends State<HomeInitialPage> {
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
          // Row with user info and friend button
          Padding(
            padding: EdgeInsets.only(left: 14.h, right: 14.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User info section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Hai ${userName.isNotEmpty ? userName : "Pengguna"}",
                      style: CustomTextStyles.titleMediumGray80001,
                    ),
                    GestureDetector(
                      onTap: () {
                        // onTapTxtIdCounter(context);
                      },
                      child: Text(
                        userId.toString(),
                        style: CustomTextStyles.bodySmallGray800,
                      ),
                    ),
                  ],
                ),
                // Friend button
                GestureDetector(
                  onTap: () {
                    if (userId != 0) {
                      Navigator.of(context, rootNavigator: true).pushNamed(
                        AppRoutes.friendScreen,
                        arguments: userId,
                      );
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.all(8.h),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(12.h),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.people,
                          color: Colors.white,
                          size: 20.h,
                        ),
                        SizedBox(width: 4.h),
                        Text(
                          'Teman',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.h,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 4.h),
          Padding(
            padding: EdgeInsets.only(left: 8.h, right: 16.h),
            child:
                BlocSelector<HomeBloc, HomeState, TextEditingController?>(
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
                    context.read<HomeBloc>().add(HomeSearchEvent(query));
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
      child: BlocSelector<HomeBloc, HomeState, HomeInitialModel?>(
        selector: (state) => state.homeInitialModelObj,
        builder: (context, homeInitialModelObj) {
          return ListView.separated(
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            separatorBuilder: (context, index) {
              return SizedBox(height: 0);
            },
            itemCount: homeInitialModelObj?.homelistItemList.length ?? 0,
            itemBuilder: (context, index) {
              HomelistItemModel model =
                  homeInitialModelObj?.homelistItemList[index] ??
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
