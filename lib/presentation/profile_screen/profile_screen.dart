import 'package:flutter/material.dart';
import 'package:myhiking/api/api_service.dart';
import 'package:myhiking/presentation/data_profile_screen/bloc/data_profile_bloc.dart';
import 'package:myhiking/presentation/data_profile_screen/data_profile_screen.dart';
import 'package:myhiking/presentation/landing_screen/landing_screen.dart';
import 'package:myhiking/presentation/profile_screen/bloc/profile_bloc.dart';
import '../../core/app_export.dart';
import '../../widgets/custom_icon_button.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  static Widget builder(BuildContext context) {
    return BlocProvider<ProfileBloc>(
      create: (context) => ProfileBloc(const ProfileState()),
      child: const ProfileScreen(),
    );
  }

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String userName = '';
  int userId = 0;
  bool isLoading = true;
  @override
  void initState() {
    super.initState();
    // Inisialisasi data awal
    context.read<ProfileBloc>().add(ProfileInitialEvent());
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
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        return SafeArea(
            child: Scaffold(
          backgroundColor: appTheme.gray50,
          body: Container(
            width: double.maxFinite,
            padding: EdgeInsets.only(top: 20.h),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                _buildProfileHeader(context),
                SizedBox(height: 44.h),
                _buildProfileSettings(context),
              ],
            ),
          ),
        ));
      },
    );
  }

  /// Section Widget: Profile Header
  Widget _buildProfileHeader(BuildContext context) {
    return SizedBox(
      height: 156.h,
      width: double.maxFinite,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            width: 224.h,
            margin: EdgeInsets.only(bottom: 30.h),
            padding: EdgeInsets.only(left: 58.h, top: 14.h, bottom: 14.h),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.7),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    userName,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 0.h),
                  child: Text(
                    "ID : ${userId.toString()}",
                    style: CustomTextStyles.titleMediumOnPrimary_1,
                  ),
                ),
                SizedBox(height: 4.h)
              ],
            ),
          ),
          CustomImageView(
            imagePath: ImageConstant.imgAmping91,
            height: 156.h,
            width: 228.h,
            alignment: Alignment.centerLeft,
          ),
        ],
      ),
    );
  }

  /// Section Widget: Profile Settings
  Widget _buildProfileSettings(BuildContext context) {
    return Container(
      width: double.maxFinite,
      margin: EdgeInsets.symmetric(horizontal: 24.h),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => onTapProfileone(context),
            child: Container(
              padding: EdgeInsets.all(12.h),
              decoration: BoxDecoration(
                color: theme.colorScheme.onPrimary,
                borderRadius: BorderRadiusStyle.roundedBorder14,
                border: Border.all(
                  color: theme.colorScheme.onPrimary,
                  width: 1.h,
                ),
                boxShadow: [
                  BoxShadow(
                    color: appTheme.blueGray40019.withOpacity(0.08),
                    spreadRadius: 2.h,
                    blurRadius: 2.h,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Card(
                    clipBehavior: Clip.antiAlias,
                    elevation: 0,
                    margin: EdgeInsets.only(left: 4.h, bottom: 2.h),
                    color: appTheme.blueGray50,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadiusStyle.roundedBorder14,
                    ),
                    child: Container(
                      height: 24.h,
                      width: 24.h,
                      decoration: BoxDecoration(
                        color: appTheme.blueGray50,
                        borderRadius: BorderRadiusStyle.roundedBorder14,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomImageView(
                            imagePath: ImageConstant.imgOutlineUsers,
                            height: 20.h,
                            width: double.maxFinite,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 14.h),
                    child: Text(
                      "lbl_data_profile".tr,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                  const Spacer(),
                  CustomImageView(
                    imagePath: ImageConstant.imgArrowRight,
                    height: 24.h,
                    width: 24.h,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 10.h),
          GestureDetector(
            onTap: () => onTapTransaction(context),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.h, vertical: 12.h),
              decoration: BoxDecoration(
                color: theme.colorScheme.onPrimary,
                borderRadius: BorderRadiusStyle.roundedBorder14,
                border:
                    Border.all(color: theme.colorScheme.onPrimary, width: 1.h),
                boxShadow: [
                  BoxShadow(
                    color: appTheme.blueGray40019.withOpacity(0.08),
                    spreadRadius: 2.h,
                    blurRadius: 2.h,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              width: double.maxFinite,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: 6.h),
                    child: CustomIconButton(
                      height: 24.h,
                      width: 24.h,
                      padding: EdgeInsets.all(4.h),
                      decoration: IconButtonStyleHelper.fillBlueGray,
                      child: CustomImageView(
                        imagePath: ImageConstant.imgClock,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 14.h),
                    child: Text(
                      "lbl_cek_transaksi".tr,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                  const Spacer(),
                  CustomImageView(
                    imagePath: ImageConstant.imgArrowRight,
                    height: 24.h,
                    width: 24.h,
                    alignment: Alignment.bottomCenter,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 10.h),
          GestureDetector(
              onTap: () => onLogout(context),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.h, vertical: 12.h),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onPrimary,
                  borderRadius: BorderRadiusStyle.roundedBorder14,
                  border: Border.all(
                      color: theme.colorScheme.onPrimary, width: 1.h),
                  boxShadow: [
                    BoxShadow(
                      color: appTheme.blueGray40019.withOpacity(0.08),
                      spreadRadius: 2.h,
                      blurRadius: 2.h,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                width: double.maxFinite,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 6.h),
                      child: CustomIconButton(
                        height: 24.h,
                        width: 24.h,
                        padding: EdgeInsets.all(4.h),
                        decoration: IconButtonStyleHelper.fillBlueGray,
                        child: Icon(Icons.logout,
                            color: theme.colorScheme.primary, size: 18),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: 14.h),
                      child: Text(
                        "Log Out".tr,
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                    const Spacer(),
                    CustomImageView(
                      imagePath: ImageConstant.imgArrowRight,
                      height: 24.h,
                      width: 24.h,
                      alignment: Alignment.bottomCenter,
                    ),
                  ],
                ),
              ))
        ],
      ),
    );
  }

  void onTapProfileone(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) => DataProfileBloc(apiService: ApiService()),
          child: DataProfileScreen(
            userId: userId, // Use widget to access jalurId
          ),
        ),
      ),
    );
  }

  void onTapTransaction(BuildContext context) {
    NavigatorService.pushNamed(AppRoutes.transaksiPage);
  }

  void onLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Keluar dari akun Anda?",
            style: TextStyle(fontSize: 16, color: theme.colorScheme.primary),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Tutup pop-up tanpa keluar
              },
              child: Text("Batalkan"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Menutup pop-up
                Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRoutes.loginScreen,
                    (route) =>
                        false); // Menuju ke halaman login dan menghapus stack
              },
              child: Text(
                "Keluar",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}
